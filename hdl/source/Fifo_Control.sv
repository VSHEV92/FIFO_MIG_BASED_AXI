module Fifo_Control
#(
	parameter ID_tag = 0,
    parameter Max_Burst_Len = 64,
    parameter RW_Delay_Value = 4,
    parameter Base_Address = 0,
    parameter Memory_Size = 100,
    parameter MIG_Port_Size = 128,
    parameter IO_Fifo_Depth = 32
)
(
    input logic aclk,
    input logic aresetn,
    input logic soft_resetn,
    input logic init_calib,
    // входной AXIS интерфейс
    input  logic [MIG_Port_Size-1:0] in_tdata,
    input  logic in_tvalid,
    output logic in_tready,
    input  logic [31:0] in_wr_count,
    // выходной AXIS интерфейс
    output logic [MIG_Port_Size-1:0] out_tdata,
    output logic out_tvalid,
    input  logic out_tready,
    input  logic [31:0] out_rd_count,
    // AXI Memory Map
    // AWRITE
    output logic [3:0]  MIG_Port_AWID,
    output logic [31:0] MIG_Port_AWADDR,
    output logic [3:0]  MIG_Port_AWREGION,
    output logic [7:0]  MIG_Port_AWLEN,
    output logic [2:0]  MIG_Port_AWSIZE,
    output logic [1:0]  MIG_Port_AWBURST,
    output logic        MIG_Port_AWLOCK,
    output logic [3:0]  MIG_Port_AWCACHE,
    output logic [2:0]  MIG_Port_AWPROT,
    output logic [3:0]  MIG_Port_AWQOS,
    output logic        MIG_Port_AWVALID,
    input  logic        MIG_Port_AWREADY,
    // WRITE
    output logic [MIG_Port_Size-1:0]   MIG_Port_WDATA,
    output logic [MIG_Port_Size/8-1:0] MIG_Port_WSTRB,
    output logic                       MIG_Port_WLAST,
    output logic                       MIG_Port_WVALID,
    input  logic                       MIG_Port_WREADY,
    // RESPONSE
    input  logic [3:0] MIG_Port_BID,
    input  logic [1:0] MIG_Port_BRESP,
    output logic       MIG_Port_BREADY,
    input  logic       MIG_Port_BVALID,
    // AREAD
    output logic [3:0]  MIG_Port_ARID,
    output logic [31:0] MIG_Port_ARADDR,
    output logic [3:0]  MIG_Port_ARREGION,
    output logic [7:0]  MIG_Port_ARLEN,
    output logic [2:0]  MIG_Port_ARSIZE,
    output logic [1:0]  MIG_Port_ARBURST,
    output logic        MIG_Port_ARLOCK,
    output logic [3:0]  MIG_Port_ARCACHE,
    output logic [2:0]  MIG_Port_ARPROT,
    output logic [3:0]  MIG_Port_ARQOS,
    output logic        MIG_Port_ARVALID,
    input  logic        MIG_Port_ARREADY,
    // READ
    input  logic [3:0]                 MIG_Port_RID,
    input  logic [MIG_Port_Size-1:0]   MIG_Port_RDATA,
    input  logic [1:0]                 MIG_Port_RRESP,
    input  logic                       MIG_Port_RLAST,
    input  logic                       MIG_Port_RVALID,
    output logic                       MIG_Port_RREADY
);

// максимальный адрес памяти
localparam Max_Address = Base_Address + (Memory_Size - 1) * MIG_Port_Size / 8;
localparam Transfer_Size = $clog2(MIG_Port_Size/8); 

// вычисление минимального значения
function automatic logic [31:0] min_func (logic [31:0] mem_space, logic [31:0] fifo_space);
    logic [31:0] min_val;
    if (mem_space > fifo_space)
        min_val = fifo_space;
    else
        min_val = mem_space;

    if (min_val > Max_Burst_Len)
        min_val = Max_Burst_Len;

    return min_val;
endfunction 

// состояния конечного автомата
enum {INIT, CHECK_WR, CHECK_RD, WR, WR_AW, WR_LAST, WR_AW_LAST, WAIT_LAST, WAIT_AW, WAIT_RESP, RD_AR, RD, DELAY_WR, DELAY_RD} State;

logic int_resetn;

logic [31:0] out_Rd_space;

logic [31:0] Mem_Wr_Addr, Mem_Rd_Addr;            // адрес записи и чтения
logic [31:0] Wr_Counter;                          // счетчик оставшихся данных для записи
logic [31:0] Mem_Wr_Counter, Mem_Rd_Counter;      // число слов и свободных мест в памяти
logic [7:0]  Delay_Counter;

logic [31:0] Wr_Counter_Reg; // регистр с числом слов для записи 
logic [31:0] Rd_Counter_Reg; // регистр с числом слов для чтения 

logic [31:0] wr_count_load, rd_count_load;  // количество слов в транзакции

// ---------------------------------------------------------------------------------
// внутренний сигнал сброса
assign int_resetn = aresetn & (soft_resetn | !(State == CHECK_WR | State == CHECK_RD));

// ---------------------------------------------------------------------------------
// входной AXIS интерфейс
assign in_tready = (State == WR | State == WR_AW | State == WR_LAST | State == WR_AW_LAST) & MIG_Port_WREADY;

// ---------------------------------------------------------------------------------
// выходной AXIS интерфейс
assign out_Rd_space = IO_Fifo_Depth - out_rd_count; // число мест в выходном Fifo
assign out_tdata = MIG_Port_RDATA;
assign out_tvalid = (State == RD) & MIG_Port_RVALID; 

// ---------------------------------------------------------------------------------
// AXI MM интерфейс AWRITE
assign MIG_Port_AWID     = ID_tag;
assign MIG_Port_AWADDR   = Mem_Wr_Addr;
assign MIG_Port_AWREGION = 4'b0000;
assign MIG_Port_AWLEN    = Wr_Counter_Reg - 1;
assign MIG_Port_AWSIZE   = Transfer_Size;
assign MIG_Port_AWBURST  = 2'b01;
assign MIG_Port_AWLOCK   = 1'b0;
assign MIG_Port_AWCACHE  = 4'b0011;
assign MIG_Port_AWPROT   = 3'b010;
assign MIG_Port_AWQOS    = 4'b0000;
assign MIG_Port_AWVALID  = (State == WR | State == WR_LAST | State == WAIT_AW);

// ---------------------------------------------------------------------------------
// AXI MM интерфейс AREAD
assign MIG_Port_ARID     = ID_tag;
assign MIG_Port_ARADDR   = Mem_Rd_Addr;
assign MIG_Port_ARREGION = 4'b0000;
assign MIG_Port_ARLEN    = Rd_Counter_Reg - 1;
assign MIG_Port_ARSIZE   = Transfer_Size;
assign MIG_Port_ARBURST  = 2'b01;
assign MIG_Port_ARLOCK   = 1'b0;
assign MIG_Port_ARCACHE  = 4'b0011;
assign MIG_Port_ARPROT   = 3'b010;
assign MIG_Port_ARQOS    = 4'b0000;
assign MIG_Port_ARVALID  = State == RD_AR;

// ---------------------------------------------------------------------------------
// AXI MM интерфейс WRITE
assign MIG_Port_WDATA  = in_tdata;
assign MIG_Port_WSTRB  = '1;
assign MIG_Port_WLAST  = (State == WR_AW_LAST | State == WR_LAST);
assign MIG_Port_WVALID = (State == WR | State == WR_AW | State == WR_LAST | State == WR_AW_LAST);

// ---------------------------------------------------------------------------------
// AXI MM интерфейс RESPONSE
assign MIG_Port_BREADY  = State == WAIT_RESP;

// ---------------------------------------------------------------------------------
// AXI MM интерфейс READ
assign MIG_Port_RREADY  = State == RD;

// ---------------------------------------------------------------------------------
// конечный автомат
always_ff @(posedge aclk) begin : fsm_block
    if(!int_resetn)
        State <= INIT;
    else 
        unique case (State) 
        INIT :      // ожидание инициализации памяти
            State <= (init_calib) ? CHECK_WR : INIT;

        CHECK_WR :  // проверка возможности записи 
            if (Mem_Wr_Counter && (in_wr_count == 1 || (Max_Burst_Len == 1 && in_wr_count)))
                State <= WR_LAST;
            else if (Mem_Wr_Counter && (in_wr_count > 1 && Max_Burst_Len > 1))
                State <= WR;
            else
                State <= CHECK_RD;

        CHECK_RD :  // проверка возможности чтения 
            State <= (Mem_Rd_Counter && out_Rd_space) ? RD_AR : CHECK_WR;

        WR:         // запись в память, адрес не считан
        	if (MIG_Port_AWREADY)
        		if (MIG_Port_WREADY && Wr_Counter == 2)
        			State <= WR_AW_LAST;
        		else
        			State <= WR_AW;
        	else
        		if (MIG_Port_WREADY && Wr_Counter == 2)
        			State <= WR_LAST;
        		else
        			State <= WR;	

        WR_AW:    // запись в память, адрес считан
            State <= (MIG_Port_WREADY && Wr_Counter == 2) ? WR_AW_LAST : WR_AW;

        WR_LAST:  // запись в память, последнее слово, адрес не считан   
			if (MIG_Port_AWREADY)
        		if (MIG_Port_WREADY)
        			State <= WAIT_RESP;
        		else
        			State <= WR_AW_LAST;
        	else
        		if (MIG_Port_WREADY)
        			State <= WAIT_AW;
        		else
        			State <= WR_LAST;	

		WR_AW_LAST:  // запись в память, последнее слово, адрес считан
			State <= (MIG_Port_WREADY) ? WAIT_RESP : WR_AW_LAST;
        
		WAIT_AW:  // ожидание считывания адреса
			State <= (MIG_Port_AWREADY) ? WAIT_RESP : WAIT_AW;
		
		WAIT_RESP:  // ожидание ответа после записи
			State <= (MIG_Port_BVALID) ? DELAY_WR : WAIT_RESP;
		
		RD_AR:       // запись адреса чтения из память
            State <= (MIG_Port_ARREADY) ? RD : RD_AR;
        
        RD:       // чтение из памяти
            State <= (MIG_Port_RVALID && MIG_Port_RLAST) ? DELAY_RD : RD;

        DELAY_WR :  // задержка после записи
            State <= (Delay_Counter == 0) ? CHECK_RD : DELAY_WR;

        DELAY_RD :  // задержка после чтения
            State <= (Delay_Counter == 0) ? CHECK_WR : DELAY_RD;

        endcase                           
end

// ---------------------------------------------------------------------------------
// счетчик числа слов для записи
assign wr_count_load = min_func(Mem_Wr_Counter, in_wr_count);
always_ff @(posedge aclk)
    if (State == CHECK_WR)
        Wr_Counter <= wr_count_load;
    else if (MIG_Port_WREADY && MIG_Port_WVALID)
        Wr_Counter <= Wr_Counter - 1;

always_ff @(posedge aclk)
    if (State == CHECK_WR)
        Wr_Counter_Reg <= wr_count_load;

assign rd_count_load = min_func(Mem_Rd_Counter, out_Rd_space);
always_ff @(posedge aclk)
    if (State == CHECK_RD)
        Rd_Counter_Reg <= rd_count_load;

// ---------------------------------------------------------------------------------
// счетчик адресов записи
always_ff @(posedge aclk)
    if(!int_resetn)
        Mem_Wr_Addr <= Base_Address;
    else if (MIG_Port_AWREADY && MIG_Port_AWVALID) begin
        Mem_Wr_Addr <= Mem_Wr_Addr + Wr_Counter_Reg * MIG_Port_Size / 8;
        if (Mem_Wr_Addr == Max_Address)
            Mem_Wr_Addr <= Base_Address;
    end

// // ---------------------------------------------------------------------------------
// счетчик адресов чтения
always_ff @(posedge aclk)
    if(!int_resetn)
        Mem_Rd_Addr <= Base_Address;
    else if (MIG_Port_ARREADY && MIG_Port_ARVALID) begin
        Mem_Rd_Addr <= Mem_Rd_Addr + Rd_Counter_Reg * MIG_Port_Size / 8;
        if (Mem_Rd_Addr == Max_Address)
            Mem_Rd_Addr <= Base_Address;
    end

// ---------------------------------------------------------------------------------
// счетчик числа свободных мест в памяти
always_ff @(posedge aclk)
    if(!int_resetn)
        Mem_Wr_Counter <= Memory_Size;
    else if (MIG_Port_WREADY && MIG_Port_WVALID)
        Mem_Wr_Counter <= Mem_Wr_Counter - 1;
    else if (MIG_Port_RVALID && MIG_Port_RREADY)
        Mem_Wr_Counter <= Mem_Wr_Counter + 1;

// ---------------------------------------------------------------------------------
// счетчик числа слов в памяти
always_ff @(posedge aclk)
    if(!int_resetn)
        Mem_Rd_Counter <= 0;
    else if (MIG_Port_WREADY && MIG_Port_WVALID)
        Mem_Rd_Counter <= Mem_Rd_Counter + 1;
    else if (MIG_Port_RVALID && MIG_Port_RREADY)
        Mem_Rd_Counter <= Mem_Rd_Counter - 1;

// ---------------------------------------------------------------------------------
// счетчик задержки после записи или считывания       
always_ff @(posedge aclk)
    if ((State == RD) || (State == WAIT_RESP))
        Delay_Counter <= RW_Delay_Value;
    else if ((State == DELAY_RD) || (State == DELAY_WR))
        Delay_Counter <= Delay_Counter - 1;

endmodule
