## Clock Signals
set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135} [get_ports clk100]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk100]

set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets mmcm/inst/clk_in_clk_gen]
set_clock_groups -name clk_soc -asynchronous -group [get_clocks [list [get_clocks -of_objects [get_pins mmcm/inst/mmcm_adv_inst/CLKOUT2] -filter {IS_GENERATED && MASTER_CLOCK == clk100}] [get_clocks -of_objects [get_pins mmcm/inst/mmcm_adv_inst/CLKOUT2] -filter {IS_GENERATED && MASTER_CLOCK == sys_clk_pin}]]]

## Active-low async reset
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports arstn]

## LEDs
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## USB-UART Interface
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports uart_tx]

## Pmod Header JB
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {r[0]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {r[1]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {r[2]}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports {r[3]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {b[0]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {b[1]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {b[2]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {b[3]}]

## Pmod Header JC
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {g[0]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {g[1]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {g[2]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {g[3]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports hsync]
set_property -dict {PACKAGE_PIN P13 IOSTANDARD LVCMOS33} [get_ports vsync]

## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## SW3 is assigned to a pin M5 in the 1.35v bank. This pin can also be used as
## the VREF for BANK 34. To ensure that SW3 does not define the reference voltage
## and to be able to use this pin as an ordinary I/O the following property must
## be set to enable an internal VREF for BANK 34. Since a 1.35v supply is being
## used the internal reference is set to half that value (i.e. 0.675v). Note that
## this property must be set even if SW3 is not used in the design.
set_property INTERNAL_VREF 0.675 [get_iobanks 34]