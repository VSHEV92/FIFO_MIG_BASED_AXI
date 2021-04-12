# input false path
set_false_path -from [get_ports sys_rst_0]
set_false_path -from [get_ports UART_0_rxd]

# output false path
set_false_path -to [get_ports UART_0_txd]
set_false_path -to [get_ports init_calib]