# ------------------------------------------------------
# ----- Cкрипт для автоматического запуска тестов ------
# ------------------------------------------------------

# -----------------------------------------------------------
proc launch_test_set {Test_Number Log_Dir_Name} {
	# выбераем первый тестовый набор в качествре начального   
	set Test_Set_Name ./hdl/header/test_sets/test_set
	append Test_Set_Name _$Test_Number
	append Test_Set_Name .svh
	file copy -force $Test_Set_Name ./hdl/header/test_set.svh

	# пишим номер теста в log файлы
	set fileID [open $Log_Dir_Name/Test_Results.txt a]
	puts -nonewline $fileID "TEST SET $Test_Number: "
	close $fileID
   
	set fileID [open $Log_Dir_Name/Test_Logs.txt a]
	puts $fileID ""
	puts $fileID "TEST SET $Test_Number: "
	close $fileID
	
	# запускаем моделирование
	launch_simulation
	close_sim -quiet 
}

# -----------------------------------------------------------
# процедура для проверки результатов
proc check_test_results {Log_Dir_Name Test_Name} {
	set Verification_Result 1
	# считываем весь файл
	set fileID [open $Log_Dir_Name/$Test_Name r]
	set file_data [read $fileID]
	close $fileID
	# разделяем файл на строки
	set data [split $file_data "\n"]
	foreach line $data {
		if {[string length $line] && [string first "FAIL" $line] != -1} {
			set Verification_Result 0	
			set message $Test_Name
			append message ": \"" $line "\""
			puts $message
		}
	}
	return $Verification_Result	
}

# -----------------------------------------------------------
set Verification_Result 1
set Project_Name fifo_mig_based_axi_tests
set Number_of_Test_Sets 8

# если проект с таким именем существует удаляем его
close_sim -quiet 
close_project -quiet
if { [file exists $Project_Name] != 0 } { 
	file delete -force $Project_Name
	puts "Delete old Project"
}

# создаем проект
create_project $Project_Name ./$Project_Name -part xc7a50tftg256-1

# ----------------------------------------------------------------
# выбераем первый тестовый набор в качествре начального   
set Test_Set_Name ./hdl/header/test_sets/test_set_1.svh
file copy -force $Test_Set_Name ./hdl/header/test_set.svh

# добавляем заголовочные файлы к проекту
 add_files ./hdl/header/Environment.svh
 add_files ./hdl/header/testbench_settings.svh
 add_files ./hdl/header/ddr3_model_parameters.vh

add_files ./hdl/header/test_set.svh

# добавляем исходники к проекту
add_files ./hdl/source/Fifo_Control.sv
add_files ./hdl/source/Fifo_MIG_Based_AXI.v

# # добавляем ip fifo к проекту
set pattern ips/*/*.xci
add_files [glob -nocomplain -- $pattern]
generate_target {simulation} [get_files ips/*/*.xci]

# # добавляем тестбенч к проекту
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 ./hdl/testbench/ddr3_model.sv
add_files -fileset sim_1 ./hdl/testbench/Fifo_MIG_Based_AXI_tb.sv

# ----------------------------------------------------------------
# создание IP MIG для платы Artix 7A50T
create_ip -name mig_7series -vendor xilinx.com -library ip -version 4.2 -module_name mig_7series_0
set_property -dict [list CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom} CONFIG.SYSTEM_RESET.INSERT_VIP {0} CONFIG.CLK_REF_I.INSERT_VIP {0} CONFIG.RESET.INSERT_VIP {0} CONFIG.DDR3_RESET.INSERT_VIP {0} CONFIG.DDR2_RESET.INSERT_VIP {0} CONFIG.LPDDR2_RESET.INSERT_VIP {0} CONFIG.QDRIIP_RESET.INSERT_VIP {0} CONFIG.RLDII_RESET.INSERT_VIP {0} CONFIG.RLDIII_RESET.INSERT_VIP {0} CONFIG.CLOCK.INSERT_VIP {0} CONFIG.MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S_AXI_CTRL.INSERT_VIP {0} CONFIG.S_AXI.INSERT_VIP {0} CONFIG.SYS_CLK_I.INSERT_VIP {0} CONFIG.ARESETN.INSERT_VIP {0} CONFIG.C0_RESET.INSERT_VIP {0} CONFIG.C0_DDR3_RESET.INSERT_VIP {0} CONFIG.C0_DDR2_RESET.INSERT_VIP {0} CONFIG.C0_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C0_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C0_RLDII_RESET.INSERT_VIP {0} CONFIG.C0_RLDIII_RESET.INSERT_VIP {0} CONFIG.C0_CLOCK.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C0_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S0_AXI_CTRL.INSERT_VIP {0} CONFIG.S0_AXI.INSERT_VIP {0} CONFIG.C0_SYS_CLK_I.INSERT_VIP {0} CONFIG.C0_ARESETN.INSERT_VIP {0} CONFIG.C1_RESET.INSERT_VIP {0} CONFIG.C1_DDR3_RESET.INSERT_VIP {0} CONFIG.C1_DDR2_RESET.INSERT_VIP {0} CONFIG.C1_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C1_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C1_RLDII_RESET.INSERT_VIP {0} CONFIG.C1_RLDIII_RESET.INSERT_VIP {0} CONFIG.C1_CLOCK.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C1_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S1_AXI_CTRL.INSERT_VIP {0} CONFIG.S1_AXI.INSERT_VIP {0} CONFIG.C1_SYS_CLK_I.INSERT_VIP {0} CONFIG.C1_ARESETN.INSERT_VIP {0} CONFIG.C2_RESET.INSERT_VIP {0} CONFIG.C2_DDR3_RESET.INSERT_VIP {0} CONFIG.C2_DDR2_RESET.INSERT_VIP {0} CONFIG.C2_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C2_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C2_RLDII_RESET.INSERT_VIP {0} CONFIG.C2_RLDIII_RESET.INSERT_VIP {0} CONFIG.C2_CLOCK.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C2_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S2_AXI_CTRL.INSERT_VIP {0} CONFIG.S2_AXI.INSERT_VIP {0} CONFIG.C2_SYS_CLK_I.INSERT_VIP {0} CONFIG.C2_ARESETN.INSERT_VIP {0} CONFIG.C3_RESET.INSERT_VIP {0} CONFIG.C3_DDR3_RESET.INSERT_VIP {0} CONFIG.C3_DDR2_RESET.INSERT_VIP {0} CONFIG.C3_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C3_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C3_RLDII_RESET.INSERT_VIP {0} CONFIG.C3_RLDIII_RESET.INSERT_VIP {0} CONFIG.C3_CLOCK.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C3_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S3_AXI_CTRL.INSERT_VIP {0} CONFIG.S3_AXI.INSERT_VIP {0} CONFIG.C3_SYS_CLK_I.INSERT_VIP {0} CONFIG.C3_ARESETN.INSERT_VIP {0} CONFIG.C4_RESET.INSERT_VIP {0} CONFIG.C4_DDR3_RESET.INSERT_VIP {0} CONFIG.C4_DDR2_RESET.INSERT_VIP {0} CONFIG.C4_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C4_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C4_RLDII_RESET.INSERT_VIP {0} CONFIG.C4_RLDIII_RESET.INSERT_VIP {0} CONFIG.C4_CLOCK.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C4_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S4_AXI_CTRL.INSERT_VIP {0} CONFIG.S4_AXI.INSERT_VIP {0} CONFIG.C4_SYS_CLK_I.INSERT_VIP {0} CONFIG.C4_ARESETN.INSERT_VIP {0} CONFIG.C5_RESET.INSERT_VIP {0} CONFIG.C5_DDR3_RESET.INSERT_VIP {0} CONFIG.C5_DDR2_RESET.INSERT_VIP {0} CONFIG.C5_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C5_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C5_RLDII_RESET.INSERT_VIP {0} CONFIG.C5_RLDIII_RESET.INSERT_VIP {0} CONFIG.C5_CLOCK.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C5_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S5_AXI_CTRL.INSERT_VIP {0} CONFIG.S5_AXI.INSERT_VIP {0} CONFIG.C5_SYS_CLK_I.INSERT_VIP {0} CONFIG.C5_ARESETN.INSERT_VIP {0} CONFIG.C6_RESET.INSERT_VIP {0} CONFIG.C6_DDR3_RESET.INSERT_VIP {0} CONFIG.C6_DDR2_RESET.INSERT_VIP {0} CONFIG.C6_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C6_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C6_RLDII_RESET.INSERT_VIP {0} CONFIG.C6_RLDIII_RESET.INSERT_VIP {0} CONFIG.C6_CLOCK.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C6_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S6_AXI_CTRL.INSERT_VIP {0} CONFIG.S6_AXI.INSERT_VIP {0} CONFIG.C6_SYS_CLK_I.INSERT_VIP {0} CONFIG.C6_ARESETN.INSERT_VIP {0} CONFIG.C7_RESET.INSERT_VIP {0} CONFIG.C7_DDR3_RESET.INSERT_VIP {0} CONFIG.C7_DDR2_RESET.INSERT_VIP {0} CONFIG.C7_LPDDR2_RESET.INSERT_VIP {0} CONFIG.C7_QDRIIP_RESET.INSERT_VIP {0} CONFIG.C7_RLDII_RESET.INSERT_VIP {0} CONFIG.C7_RLDIII_RESET.INSERT_VIP {0} CONFIG.C7_CLOCK.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT0.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT1.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT2.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT3.INSERT_VIP {0} CONFIG.C7_MMCM_CLKOUT4.INSERT_VIP {0} CONFIG.S7_AXI_CTRL.INSERT_VIP {0} CONFIG.S7_AXI.INSERT_VIP {0} CONFIG.C7_SYS_CLK_I.INSERT_VIP {0} CONFIG.C7_ARESETN.INSERT_VIP {0}] [get_ips mig_7series_0]
file copy -force constraints/mig_a.prj fifo_mig_based_axi_tests/fifo_mig_based_axi_tests.srcs/sources_1/ip/mig_7series_0/mig_a.prj 
set_property -dict [list CONFIG.XML_INPUT_FILE {mig_a.prj}] [get_ips mig_7series_0]
generate_target {instantiation_template} [get_files fifo_mig_based_axi_tests/fifo_mig_based_axi_tests.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]
generate_target {simulation} [get_files fifo_mig_based_axi_tests/fifo_mig_based_axi_tests.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]

# обновляем иерархию файлов проекта
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# устанавливаем максимальное время моделирования 
set_property -name {xsim.simulate.runtime} -value {100s} -objects [get_filesets sim_1]

# создаем log файл для результатов тестирования
set Log_Dir_Name log_$Project_Name
file mkdir $Log_Dir_Name
set fileID [open $Log_Dir_Name/Test_Results.txt w]
close $fileID
set fileID [open $Log_Dir_Name/Test_Logs.txt a]
close $fileID

# запускаем тестовые наборы
for {set i 1} {$i <= $Number_of_Test_Sets} {incr i} {
   launch_test_set $i $Log_Dir_Name
}

# закрываем проект после завершения
close_project -quiet

# ---------------------------------------------------------------------------
# проверка результатов
puts ""

set Log_Dir_Name log_fifo_mig_based_axi_tests

set Test_Name Test_Results.txt
set Verification_Result [check_test_results $Log_Dir_Name $Test_Name]

# вывод результатов
puts ""
if { $Verification_Result } {
	puts "-------------------------------------------"
	puts "--------- VERIFICATION SUCCESSED ----------"
	puts "-------------------------------------------"
} else {
	puts "-------------------------------------------"
	puts "---------- VERIFICATION FAILED ------------"
	puts "-------------------------------------------"
}
