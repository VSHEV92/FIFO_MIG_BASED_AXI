module Fifo_MIG_Based_AXI
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
    input aclk,
    input aresetn,
    input soft_resetn,
    input init_calib,
    // входной AXIS интерфейс
    input  [MIG_Port_Size-1:0] indata_tdata,
    input  indata_tvalid,
    output indata_tready,
    // выходной AXIS интерфейс
    output [MIG_Port_Size-1:0] outdata_tdata,
    output outdata_tvalid,
    input  outdata_tready,
    // AXI Memory Map
    // AWRITE
    output [3:0]  MIG_Port_AWID,
    output [31:0] MIG_Port_AWADDR,
    output [3:0]  MIG_Port_AWREGION,
    output [7:0]  MIG_Port_AWLEN,
    output [2:0]  MIG_Port_AWSIZE,
    output [1:0]  MIG_Port_AWBURST,
    output        MIG_Port_AWLOCK,
    output [3:0]  MIG_Port_AWCACHE,
    output [2:0]  MIG_Port_AWPROT,
    output [3:0]  MIG_Port_AWQOS,
    output        MIG_Port_AWVALID,
    input         MIG_Port_AWREADY,
    // WRITE
    output [MIG_Port_Size-1:0]   MIG_Port_WDATA,
    output [MIG_Port_Size/8-1:0] MIG_Port_WSTRB,
    output                       MIG_Port_WLAST,
    output                       MIG_Port_WVALID,
    input                        MIG_Port_WREADY,
    // RESPONSE
    input  [3:0] MIG_Port_BID,
    input  [1:0] MIG_Port_BRESP,
    output       MIG_Port_BREADY,
    input        MIG_Port_BVALID,
    // AREAD
    output [3:0]  MIG_Port_ARID,
    output [31:0] MIG_Port_ARADDR,
    output [3:0]  MIG_Port_ARREGION,
    output [7:0]  MIG_Port_ARLEN,
    output [2:0]  MIG_Port_ARSIZE,
    output [1:0]  MIG_Port_ARBURST,
    output        MIG_Port_ARLOCK,
    output [3:0]  MIG_Port_ARCACHE,
    output [2:0]  MIG_Port_ARPROT,
    output [3:0]  MIG_Port_ARQOS,
    output        MIG_Port_ARVALID,
    input         MIG_Port_ARREADY,
    // READ
    input  [3:0]                 MIG_Port_RID,
    input  [MIG_Port_Size-1:0]   MIG_Port_RDATA,
    input  [1:0]                 MIG_Port_RRESP,
    input                        MIG_Port_RLAST,
    input                        MIG_Port_RVALID,
    output                       MIG_Port_RREADY
);

// сигналы слединения IO Fifo и блока управления памятью 
wire [MIG_Port_Size-1:0] ififo_tdata;
wire ififo_tvalid;
wire ififo_tready;
wire [MIG_Port_Size-1:0] ofifo_tdata;
wire ofifo_tvalid;
wire ofifo_tready;    

wire [31:0] in_wr_count;
wire [31:0] out_rd_count;
        
// блок управления памятью
Fifo_Control 
#(
    .ID_tag(ID_tag),
 	  .Max_Burst_Len(Max_Burst_Len),
    .RW_Delay_Value(RW_Delay_Value),
    .Base_Address(Base_Address),
    .Memory_Size(Memory_Size),
    .MIG_Port_Size(MIG_Port_Size),
    .IO_Fifo_Depth(IO_Fifo_Depth)
)
Fifo_Control_Inst
(
	  .aclk(aclk),
    .aresetn(aresetn),
    .soft_resetn(soft_resetn),
    .init_calib(init_calib),
    // входной AXIS интерфейс
    .in_tdata(ififo_tdata),
    .in_tvalid(ififo_tvalid),
    .in_tready(ififo_tready),
    .in_wr_count(in_wr_count),
    // выходной AXIS интерфейс
    .out_tdata(ofifo_tdata),
    .out_tvalid(ofifo_tvalid),
    .out_tready(ofifo_tready),
    .out_rd_count(out_rd_count),
    // AXI Memory Map
    // AWRITE
    .MIG_Port_AWID(MIG_Port_AWID),
    .MIG_Port_AWADDR(MIG_Port_AWADDR),
    .MIG_Port_AWREGION(MIG_Port_AWREGION),
    .MIG_Port_AWLEN(MIG_Port_AWLEN),
    .MIG_Port_AWSIZE(MIG_Port_AWSIZE),
    .MIG_Port_AWBURST(MIG_Port_AWBURST),
    .MIG_Port_AWLOCK(MIG_Port_AWLOCK),
    .MIG_Port_AWCACHE(MIG_Port_AWCACHE),
    .MIG_Port_AWPROT(MIG_Port_AWPROT),
    .MIG_Port_AWQOS(MIG_Port_AWQOS),
    .MIG_Port_AWVALID(MIG_Port_AWVALID),
    .MIG_Port_AWREADY(MIG_Port_AWREADY),
    // WRITE
    .MIG_Port_WDATA(MIG_Port_WDATA),
    .MIG_Port_WSTRB(MIG_Port_WSTRB),
    .MIG_Port_WLAST(MIG_Port_WLAST),
    .MIG_Port_WVALID(MIG_Port_WVALID),
    .MIG_Port_WREADY(MIG_Port_WREADY),
    // RESPONSE
    .MIG_Port_BID(MIG_Port_BID),
    .MIG_Port_BRESP(MIG_Port_BRESP),
    .MIG_Port_BREADY(MIG_Port_BREADY),
    .MIG_Port_BVALID(MIG_Port_BVALID),
    // AREAD
    .MIG_Port_ARID(MIG_Port_ARID),
    .MIG_Port_ARADDR(MIG_Port_ARADDR),
    .MIG_Port_ARREGION(MIG_Port_ARREGION),
    .MIG_Port_ARLEN(MIG_Port_ARLEN),
    .MIG_Port_ARSIZE(MIG_Port_ARSIZE),
    .MIG_Port_ARBURST(MIG_Port_ARBURST),
    .MIG_Port_ARLOCK(MIG_Port_ARLOCK),
    .MIG_Port_ARCACHE(MIG_Port_ARCACHE),
    .MIG_Port_ARPROT(MIG_Port_ARPROT),
    .MIG_Port_ARQOS(MIG_Port_ARQOS),
    .MIG_Port_ARVALID(MIG_Port_ARVALID),
    .MIG_Port_ARREADY(MIG_Port_ARREADY),
    // READ
    .MIG_Port_RID(MIG_Port_RID),
    .MIG_Port_RDATA(MIG_Port_RDATA),
    .MIG_Port_RRESP(MIG_Port_RRESP),
    .MIG_Port_RLAST(MIG_Port_RLAST),
    .MIG_Port_RVALID(MIG_Port_RVALID),
    .MIG_Port_RREADY(MIG_Port_RREADY)
);

// ---------------------------------------------------
// выходные и выходные Fifo
generate

if (IO_Fifo_Depth == 32 && MIG_Port_Size == 64) begin
fifo_32x64 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_32x64 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 32 && MIG_Port_Size == 128) begin
fifo_32x128 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_32x128 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 32 && MIG_Port_Size == 256) begin
fifo_32x256 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_32x256 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 32 && MIG_Port_Size == 512) begin
fifo_32x512 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_32x512 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

// -------------------------------------------------------------------
if (IO_Fifo_Depth == 64 && MIG_Port_Size == 64) begin
fifo_64x64 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_64x64 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 64 && MIG_Port_Size == 128) begin
fifo_64x128 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_64x128 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 64 && MIG_Port_Size == 256) begin
fifo_64x256 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_64x256 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 64 && MIG_Port_Size == 512) begin
fifo_64x512 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_64x512 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

// ------------------------------------------------------------------------------------
if (IO_Fifo_Depth == 128 && MIG_Port_Size == 64) begin
fifo_128x64 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_128x64 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 128 && MIG_Port_Size == 128) begin
fifo_128x128 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_128x128 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 128 && MIG_Port_Size == 256) begin
fifo_128x256 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_128x256 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end

if (IO_Fifo_Depth == 128 && MIG_Port_Size == 512) begin
fifo_128x512 ififo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(indata_tvalid),   
  .s_axis_tready(indata_tready),   
  .s_axis_tdata(indata_tdata),      
  .m_axis_tvalid(ififo_tvalid),   
  .m_axis_tready(ififo_tready),   
  .m_axis_tdata(ififo_tdata),
  .axis_rd_data_count(in_wr_count)      
);

fifo_128x512 ofifo (
  .s_axis_aresetn(aresetn),  
  .s_axis_aclk(aclk),        
  .s_axis_tvalid(ofifo_tvalid),   
  .s_axis_tready(ofifo_tready),   
  .s_axis_tdata(ofifo_tdata),      
  .m_axis_tvalid(outdata_tvalid),   
  .m_axis_tready(outdata_tready),   
  .m_axis_tdata(outdata_tdata),
  .axis_rd_data_count(out_rd_count)      
);
end
endgenerate

endmodule
