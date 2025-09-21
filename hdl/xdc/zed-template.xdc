# LoRaWAN 1301 SPI
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33 PULLUP TRUE} [get_ports lorawan_spi_ss_o]; # JA1
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports lorawan_spi_sck_o]; # JA2
set_property -dict {PACKAGE_PIN Y10 IOSTANDARD LVCMOS33} [get_ports lorawan_spi_io0_o]; # JA3
set_property -dict {PACKAGE_PIN AA9 IOSTANDARD LVCMOS33} [get_ports lorawan_spi_io1_i]; # JA4

# I2C
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS18} [get_ports {iic_0_sda_io}]; # JA7
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS18} [get_ports {iic_0_scl_io}]; # JA8

# CAN 
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS33} [get_ports can_rx]; # JB1
set_property -dict {PACKAGE_PIN W11 IOSTANDARD LVCMOS33} [get_ports can_tx]; # JB2

# Zedboard LEDS
#set_property PACKAGE_PIN T22 [get_ports {leds[0]}];
#set_property PACKAGE_PIN T21 [get_ports {leds[1]}];
#set_property PACKAGE_PIN U22 [get_ports {leds[2]}];
#set_property PACKAGE_PIN U21 [get_ports {leds[3]}];
#set_property PACKAGE_PIN V22 [get_ports {leds[4]}];
#set_property PACKAGE_PIN W22 [get_ports {leds[5]}];
#set_property PACKAGE_PIN U19 [get_ports {leds[6]}];
#set_property PACKAGE_PIN U14 [get_ports {leds[7]}];

# IO Banks properties
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

