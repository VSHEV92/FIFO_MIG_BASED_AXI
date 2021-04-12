`timescale 1ns / 1ps

`include "../header/Environment.svh"
`include "../header/testbench_settings.svh"
`include "../header/test_set.svh"

module Fifo_MIG_Based_tb();

localparam int TDATA_WIDTH = MIG_Port_Size;
localparam Max_Address = Base_Address + Memory_Size * (MIG_Port_Size / 8);

logic   rst_n, ck, ck_n, cke, ras_n, cas_n, we_n, odt;
tri     [1:0]  dm_tdqs, dqs, dqs_n;
logic   [2:0]  ba;
logic   [13:0] addr;
tri     [15:0] dq;

logic reset, aresetn, aclk, init_calib, mmcm_locked;
bit sys_rst = 1;
bit sys_clk_i = 0;

 // AWRITE
logic [3:0]  MIG_Port_AWID;
logic [31:0] MIG_Port_AWADDR;
logic [3:0]  MIG_Port_AWREGION;
logic [7:0]  MIG_Port_AWLEN;
logic [2:0]  MIG_Port_AWSIZE;
logic [1:0]  MIG_Port_AWBURST;
logic        MIG_Port_AWLOCK;
logic [3:0]  MIG_Port_AWCACHE;
logic [2:0]  MIG_Port_AWPROT;
logic [3:0]  MIG_Port_AWQOS;
logic        MIG_Port_AWVALID;
logic        MIG_Port_AWREADY;
// WRITE
logic [MIG_Port_Size-1:0]   MIG_Port_WDATA;
logic [MIG_Port_Size/8-1:0] MIG_Port_WSTRB;
logic                       MIG_Port_WLAST;
logic                       MIG_Port_WVALID;
logic                       MIG_Port_WREADY;
// RESPONSE
logic  [3:0] MIG_Port_BID;
logic  [1:0] MIG_Port_BRESP;
logic        MIG_Port_BREADY;
logic        MIG_Port_BVALID;
// AREAD
logic [3:0]  MIG_Port_ARID;
logic [31:0] MIG_Port_ARADDR;
logic [3:0]  MIG_Port_ARREGION;
logic [7:0]  MIG_Port_ARLEN;
logic [2:0]  MIG_Port_ARSIZE;
logic [1:0]  MIG_Port_ARBURST;
logic        MIG_Port_ARLOCK;
logic [3:0]  MIG_Port_ARCACHE;
logic [2:0]  MIG_Port_ARPROT;
logic [3:0]  MIG_Port_ARQOS;
logic        MIG_Port_ARVALID;
logic        MIG_Port_ARREADY;
// READ
logic  [3:0]                 MIG_Port_RID;
logic  [MIG_Port_Size-1:0]   MIG_Port_RDATA;
logic  [1:0]                 MIG_Port_RRESP;
logic                        MIG_Port_RLAST;
logic                        MIG_Port_RVALID;
logic                        MIG_Port_RREADY;

AXIS_intf #(TDATA_WIDTH) axis_in (aclk, aresetn);
AXIS_intf #(TDATA_WIDTH) axis_out (aclk, aresetn);

Environment #(TDATA_WIDTH) env;
    
// --------------------------------------------------------------------------------------------
// тактовый сигнал
 initial forever
    #(1000.0 / 2 / CLK_FREQ) sys_clk_i = ~sys_clk_i; 

// сигнал сброса
initial 
	#RESET_DEASSERT_DELAY sys_rst = 0;

// тестовое окружение
initial begin
    env = new(GEN_MAX_DELAY_NS, MON_MAX_DELAY_NS, TRANSACTIONS_NUMB);
    env.axis_in = axis_in;
    env.axis_out = axis_out;
    wait(init_calib);
    env.run();
end

// завершение проекта по тайм-ауту
initial begin 
    #SIM_TIMEOUT_NS;
    $display("time = %t: Simulation timeout!", $time);
    $finish;
end    

// вывод результатов теста
final begin
    automatic int f_result; 
    automatic string file_path = find_file_path(`__FILE__);
    f_result = $fopen({file_path, "../../log_fifo_mig_based_axi_tests/Test_Results.txt"}, "a");

    $display("-------------------------------------");
    if (env.test_pass) begin
        $display("------------- TEST PASS -------------");
        $fdisplay(f_result, "TEST PASS");
    end else begin
        $display("------------- TEST FAIL -------------");
        $fdisplay(f_result, "TEST FAIL");
    end
    $display("-------------------------------------");

    $fclose(f_result);    
end 

// --------------------------------------------------------------------------------------------
assert property (@aclk (MIG_Port_AWADDR < Max_Address) || $isunknown(MIG_Port_AWADDR) ) else
	$fatal("AWADDR is greater then Max_Address. AWADDR = %0h. Max_Address = %0h.", MIG_Port_AWADDR, Max_Address);

assert property (@aclk (MIG_Port_AWADDR >= Base_Address) || $isunknown(MIG_Port_AWADDR) ) else
	$fatal("AWADDR is less then Base_Address. AWADDR = %0h. Base_Address = %0h.", MIG_Port_AWADDR, Base_Address);

assert property (@aclk (MIG_Port_ARADDR < Max_Address) || $isunknown(MIG_Port_ARADDR) ) else
	$fatal("ARADDR is greater then Max_Address. ARADDR = %0h. Max_Address = %0h.", MIG_Port_ARADDR, Max_Address);

assert property (@aclk (MIG_Port_ARADDR >= Base_Address) || $isunknown(MIG_Port_ARADDR) ) else
	$fatal("ARADDR is less then Base_Address. ARADDR = %0h. Base_Address = %0h.", MIG_Port_ARADDR, Base_Address);

// --------------------------------------------------------------------------------------------
// проверяемый блок
Fifo_MIG_Based_AXI
#(
    .ID_tag(ID_tag),
    .Max_Burst_Len(Max_Burst_Len),
    .RW_Delay_Value(RW_Delay_Value),
    .Base_Address(Base_Address),
    .Memory_Size(Memory_Size),
    .MIG_Port_Size(MIG_Port_Size),
    .IO_Fifo_Depth(IO_Fifo_Depth)
)
DUT
(
    .*,
	.soft_resetn(1'b1),
    // входной AXIS интерфейс
    .indata_tdata(axis_in.tdata),
    .indata_tvalid(axis_in.tvalid),
    .indata_tready(axis_in.tready),
    // выходной AXIS интерфейс
    .outdata_tdata(axis_out.tdata),
    .outdata_tvalid(axis_out.tvalid),
    .outdata_tready(axis_out.tready)
);

// --------------------------------------------------------------------------------------------
// ядро MIG
assign aresetn = ~reset & mmcm_locked;

mig_7series_0 MIG_inst (
    .ddr3_addr              (addr), 
    .ddr3_ba                (ba),  
    .ddr3_cas_n             (cas_n),  
    .ddr3_ck_n              (ck_n),  
    .ddr3_ck_p              (ck),  
    .ddr3_cke               (cke),  
    .ddr3_ras_n             (ras_n),  
    .ddr3_reset_n           (rst_n),  
    .ddr3_we_n              (we_n),  
    .ddr3_dq                (dq),  
    .ddr3_dqs_n             (dqs_n),  
    .ddr3_dqs_p             (dqs),  
    .init_calib_complete    (init_calib),  
    .ddr3_dm                (dm_tdqs),  
    .ddr3_odt               (odt), 
    // общие сигналы
    .ui_clk                 (aclk),  
    .ui_clk_sync_rst        (reset),  
    .mmcm_locked            (mmcm_locked),  
    .aresetn                (aresetn),  
    .sys_clk_i              (sys_clk_i),
    .sys_rst                (sys_rst),
    .app_sr_req             (0), 
    .app_ref_req            (0),  
    .app_zq_req             (0), 
    .app_sr_active          (), 
    .app_ref_ack            (),  
    .app_zq_ack             (), 
    // AWRITE
    .s_axi_awid             (MIG_Port_AWID),  
    .s_axi_awaddr           (MIG_Port_AWADDR),  
    .s_axi_awlen            (MIG_Port_AWLEN),  
    .s_axi_awsize           (MIG_Port_AWSIZE),  
    .s_axi_awburst          (MIG_Port_AWBURST),  
    .s_axi_awlock           (MIG_Port_AWLOCK),  
    .s_axi_awcache          (MIG_Port_AWCACHE),  
    .s_axi_awprot           (MIG_Port_AWPROT),  
    .s_axi_awqos            (MIG_Port_AWQOS), 
    .s_axi_awvalid          (MIG_Port_AWVALID),  
    .s_axi_awready          (MIG_Port_AWREADY),  
    // WRITE
    .s_axi_wdata            (MIG_Port_WDATA),
    .s_axi_wstrb            (MIG_Port_WSTRB),
    .s_axi_wlast            (MIG_Port_WLAST),
    .s_axi_wvalid           (MIG_Port_WVALID),
    .s_axi_wready           (MIG_Port_WREADY),
    // RESPONSE
    .s_axi_bid              (MIG_Port_BID),  
    .s_axi_bresp            (MIG_Port_BRESP),  
    .s_axi_bvalid           (MIG_Port_BVALID),  
    .s_axi_bready           (MIG_Port_BREADY),
    // AREAD
    .s_axi_arid             (MIG_Port_ARID),  
    .s_axi_araddr           (MIG_Port_ARADDR),  
    .s_axi_arlen            (MIG_Port_ARLEN),  
    .s_axi_arsize           (MIG_Port_ARSIZE),  
    .s_axi_arburst          (MIG_Port_ARBURST),  
    .s_axi_arlock           (MIG_Port_ARLOCK),  
    .s_axi_arcache          (MIG_Port_ARCACHE),  
    .s_axi_arprot           (MIG_Port_ARPROT),  
    .s_axi_arqos            (MIG_Port_ARQOS),  
    .s_axi_arvalid          (MIG_Port_ARVALID),  
    .s_axi_arready          (MIG_Port_ARREADY),
    // READ
    .s_axi_rid              (MIG_Port_RID),  
    .s_axi_rdata            (MIG_Port_RDATA),
    .s_axi_rresp            (MIG_Port_RRESP),
    .s_axi_rlast            (MIG_Port_RLAST),
    .s_axi_rvalid           (MIG_Port_RVALID),
    .s_axi_rready           (MIG_Port_RREADY)
    );

// --------------------------------------------------------------------------------------------
// модель DDR3 памяти
ddr3_model ddr3_DRAM (.*, .tdqs_n(), .cs_n(0));

endmodule
