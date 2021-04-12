# ---------------------------------------------------------------------
# ----- Cкрипт для автоматической сборки демонстрационного проекта ----
# ---------------------------------------------------------------------
set Project_Name design_example

close_project -quiet
if { [file exists $Project_Name] != 0 } { 
	file delete -force $Project_Name
	puts "Delete old Project"
}

# создаем проект
create_project $Project_Name ./$Project_Name -part xc7a50tftg256-1

# запускаем скрипт по упаковке ядра и добавляем репозиторий
if { [file exists IP] == 0 } { 
	source tcl/package_IP.tcl
} else {
	close_project -quiet
}
open_project design_example/design_example.xpr
set_property  ip_repo_paths IP [current_project]
update_ip_catalog

config_ip_cache -import_from_project -use_cache_location ip_cache

# добавляем constraints к проекту
add_files -fileset constrs_1 -norecurse constraints/pins.xdc
add_files -fileset constrs_1 -norecurse constraints/timing.xdc

# -----------------------------------------------------------------
# создаем block design с microblaze
create_bd_design "bd"

# MIG
create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig
file copy -force constraints/mig_a.prj design_example/design_example.srcs/sources_1/bd/bd/ip/bd_mig_0/mig_a.prj 
set_property -name {CONFIG.XML_INPUT_FILE} -value  {mig_a.prj} -objects [get_bd_cells mig]
set_property -name {CONFIG.RESET_BOARD_INTERFACE} -value  {Custom} -objects [get_bd_cells mig]
set_property -name {CONFIG.MIG_DONT_TOUCH_PARAM} -value  {Custom} -objects [get_bd_cells mig]
set_property -name {CONFIG.BOARD_MIG_PARAM} -value  {Custom} -objects [get_bd_cells mig]

make_bd_intf_pins_external  [get_bd_intf_pins mig/DDR3]
make_bd_pins_external  [get_bd_pins mig/sys_clk_i]
make_bd_pins_external  [get_bd_pins mig/sys_rst]

# FIFO MIG BASED
create_bd_cell -type ip -vlnv VSHEV92:user:Fifo_MIG_Based_AXI:1.0 Fifo_MIG_Based_AXI_0
connect_bd_net [get_bd_pins Fifo_MIG_Based_AXI_0/aclk] [get_bd_pins mig/ui_clk]
connect_bd_intf_net [get_bd_intf_pins Fifo_MIG_Based_AXI_0/MIG_Port] [get_bd_intf_pins mig/S_AXI]
connect_bd_net [get_bd_pins mig/init_calib_complete] [get_bd_pins Fifo_MIG_Based_AXI_0/init_calib]

# ones constant
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins Fifo_MIG_Based_AXI_0/soft_resetn]

# microblaze 
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0
apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {0} axi_periph {Enabled} cache {None} clk {/mig/ui_clk (100 MHz} debug_module {Debug Only} ecc {None} local_mem {64KB} preset {None}}  [get_bd_cells microblaze_0]
set_property -dict [list CONFIG.C_FSL_LINKS {1}] [get_bd_cells microblaze_0]
set_property -dict [list CONFIG.C_AUX_RESET_HIGH.VALUE_SRC USER] [get_bd_cells rst_mig_100M]
set_property -dict [list CONFIG.C_AUX_RESET_HIGH {0}] [get_bd_cells rst_mig_100M]

connect_bd_net [get_bd_pins rst_mig_100M/aux_reset_in] [get_bd_pins mig/init_calib_complete]
connect_bd_net [get_bd_pins Fifo_MIG_Based_AXI_0/aresetn] [get_bd_pins rst_mig_100M/peripheral_aresetn]
connect_bd_net [get_bd_pins mig/aresetn] [get_bd_pins rst_mig_100M/peripheral_aresetn]

# uart
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
connect_bd_intf_net [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0/M_AXI_DP]
connect_bd_net [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins mig/ui_clk]
connect_bd_net [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins rst_mig_100M/peripheral_aresetn]
make_bd_intf_pins_external  [get_bd_intf_pins axi_uartlite_0/UART]

# axis data width conterters (in)
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_1
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells axis_dwidth_converter_1]
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {16} CONFIG.M_TDATA_NUM_BYTES {4}] [get_bd_cells axis_dwidth_converter_1]
connect_bd_net [get_bd_pins axis_dwidth_converter_1/aclk] [get_bd_pins mig/ui_clk]
connect_bd_net [get_bd_pins axis_dwidth_converter_1/aresetn] [get_bd_pins rst_mig_100M/peripheral_aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_dwidth_converter_1/M_AXIS] [get_bd_intf_pins microblaze_0/S0_AXIS]
connect_bd_intf_net [get_bd_intf_pins Fifo_MIG_Based_AXI_0/outdata] [get_bd_intf_pins axis_dwidth_converter_1/S_AXIS]

# axis data width conterters (out)
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES.VALUE_SRC USER] [get_bd_cells axis_dwidth_converter_0]
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {4} CONFIG.M_TDATA_NUM_BYTES {16}] [get_bd_cells axis_dwidth_converter_0]
connect_bd_net [get_bd_pins axis_dwidth_converter_0/aclk] [get_bd_pins mig/ui_clk]
connect_bd_net [get_bd_pins axis_dwidth_converter_0/aresetn] [get_bd_pins rst_mig_100M/peripheral_aresetn]
connect_bd_intf_net [get_bd_intf_pins microblaze_0/M0_AXIS] [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS] [get_bd_intf_pins Fifo_MIG_Based_AXI_0/indata]

create_bd_port -dir O init_calib
connect_bd_net [get_bd_ports init_calib] [get_bd_pins mig/init_calib_complete]

# сохранение block design
assign_bd_address
validate_bd_design
regenerate_bd_layout
save_bd_design
close_bd_design [get_bd_designs microblaze_bd]

make_wrapper -files [get_files design_example/design_example.srcs/sources_1/bd/bd/bd.bd] -top
add_files -norecurse design_example/design_example.srcs/sources_1/bd/bd/hdl/bd_wrapper.v
update_compile_order -fileset sources_1

# -----------------------------------------------------------------
