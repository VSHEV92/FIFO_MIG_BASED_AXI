# ---------------------------------------------------------------------
# ----- Cкрипт для автоматической упаковки ядра из исходников ---------
# ---------------------------------------------------------------------
set Project_Name fifo_mig_based_axi_ip

close_project -quiet
if { [file exists $Project_Name] != 0 } { 
	file delete -force $Project_Name
	puts "Delete old Project"
}

if { [file exists IP] != 0 } { 
	file delete -force IP
	puts "Delete old IP"
}
# создаем проект
create_project $Project_Name ./$Project_Name -part xc7a50tftg256-1

# добавляем исходники к проекту
add_files ./hdl/source/Fifo_Control.sv
add_files ./hdl/source/Fifo_MIG_Based_AXI.v

# добавляем ip fifo к проекту
set pattern ips/*/*.xci
add_files [glob -nocomplain -- $pattern]
generate_target {simulation} [get_files ips/*/*.xci]

# начинаем упаковку ядра
update_compile_order -fileset sources_1
ipx::package_project -root_dir IP -vendor VSHEV92 -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core IP/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory IP IP/component.xml

set_property display_name FIFO_MIG_Based_AXI [ipx::current_core]
set_property description FIFO_MIG_Based_AXI [ipx::current_core]

# устанавливаем совместимость со всеми кристалами
set_property supported_families {artix7 Production artix7 Beta artix7l Beta qartix7 Beta qkintex7 Beta qkintex7l Beta kintexu Beta kintexuplus Beta qvirtex7 Beta virtexuplus Beta qzynq Beta zynquplus Beta kintex7 Beta kintex7l Beta spartan7 Beta virtex7 Beta virtexu Beta virtexuplus58g Beta virtexuplusHBM Beta aartix7 Beta akintex7 Beta aspartan7 Beta azynq Beta zynq Beta} [ipx::current_core]

# -----------------------------------------------------------
# настройка ID tag
set_property display_name {ID tag} [ipgui::get_guiparamspec -name "ID_tag" -component [ipx::current_core] ]
set_property tooltip {ID tag} [ipgui::get_guiparamspec -name "ID_tag" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "ID_tag" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters ID_tag -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 0 [ipx::get_user_parameters ID_tag -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 15 [ipx::get_user_parameters ID_tag -of_objects [ipx::current_core]]
ipgui::move_param -component [ipx::current_core] -order 0 [ipgui::get_guiparamspec -name "ID_tag" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]

# начальный адрес
set_property tooltip {Base Address in bytes} [ipgui::get_guiparamspec -name "Base_Address" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "Base_Address" -component [ipx::current_core] ]
ipgui::move_param -component [ipx::current_core] -order 2 [ipgui::get_guiparamspec -name "Memory_Size" -component [ipx::current_core]] -parent [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core]]

# размер памяти в словах Fifo
set_property tooltip {Memory Size in fifo words} [ipgui::get_guiparamspec -name "Memory_Size" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "Memory_Size" -component [ipx::current_core] ]

# размер входного и выходного Fifo
set_property display_name {I/O Fifo Depth} [ipgui::get_guiparamspec -name "IO_Fifo_Depth" -component [ipx::current_core] ]
set_property tooltip {IO Fifo Depth} [ipgui::get_guiparamspec -name "IO_Fifo_Depth" -component [ipx::current_core] ]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "IO_Fifo_Depth" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters IO_Fifo_Depth -of_objects [ipx::current_core]]
set_property value_validation_list {32 64 128} [ipx::get_user_parameters IO_Fifo_Depth -of_objects [ipx::current_core]]

# размер шины данных MIG
set_property display_name {MIG Port Size} [ipgui::get_guiparamspec -name "MIG_Port_Size" -component [ipx::current_core] ]
set_property tooltip {MIG Port Size} [ipgui::get_guiparamspec -name "MIG_Port_Size" -component [ipx::current_core] ]
set_property widget {comboBox} [ipgui::get_guiparamspec -name "MIG_Port_Size" -component [ipx::current_core] ]
set_property value_validation_type list [ipx::get_user_parameters MIG_Port_Size -of_objects [ipx::current_core]]
set_property value_validation_list {32 64 128 256 512} [ipx::get_user_parameters MIG_Port_Size -of_objects [ipx::current_core]]

# максимальный размер burst для записи и чтения
set_property display_name {Max Burst Length} [ipgui::get_guiparamspec -name "Max_Burst_Len" -component [ipx::current_core] ]
set_property tooltip {Maximum R/W Burst Length} [ipgui::get_guiparamspec -name "Max_Burst_Len" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "Max_Burst_Len" -component [ipx::current_core] ]

# задержка после чтения или записи
set_property display_name {R/W Delay Value} [ipgui::get_guiparamspec -name "RW_Delay_Value" -component [ipx::current_core] ]
set_property tooltip {Delay after Read or Write} [ipgui::get_guiparamspec -name "RW_Delay_Value" -component [ipx::current_core] ]
set_property widget {textEdit} [ipgui::get_guiparamspec -name "RW_Delay_Value" -component [ipx::current_core] ]
set_property value_validation_type range_long [ipx::get_user_parameters RW_Delay_Value -of_objects [ipx::current_core]]
set_property value_validation_range_minimum 4 [ipx::get_user_parameters RW_Delay_Value -of_objects [ipx::current_core]]
set_property value_validation_range_maximum 32 [ipx::get_user_parameters RW_Delay_Value -of_objects [ipx::current_core]]

set_property display_name {Parameters} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]
set_property tooltip {Parameters} [ipgui::get_pagespec -name "Page 0" -component [ipx::current_core] ]

# пакуем ядро
update_compile_order -fileset sources_1
set_property core_revision 2 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::move_temp_component_back -component [ipx::current_core]
close_project -delete


# закрываем и удаляем временный проект
close_project -quiet
file delete -force $Project_Name