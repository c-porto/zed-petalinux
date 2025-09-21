# SPDX-License-Identifier: GPL-2.0-only

source $script_dir/zynq_ps.tcl

namespace eval ::fsat_bd {
    proc create_base_design {name version} {
        create_bd_design $name -mode batch
        current_bd_design $name

        set parentCell [get_bd_cells /]
        set parentObj [get_bd_cells $parentCell]
        current_bd_instance $parentObj

        set ddr [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 ddr]
        set fixed_io [create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 fixed_io]
        set iic_0 [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_0]
        set zynq_ps [create_zynq_ps]

        # Create smartconnect
        set smartconnect [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0]
        set_property -dict [list \
            CONFIG.NUM_SI {1} \
        ] $smartconnect

        connect_bd_net [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins smartconnect_0/aclk]
        connect_bd_intf_net [get_bd_intf_pins zynq_ps/M_AXI_GP0] [get_bd_intf_pins smartconnect_0/S00_AXI]

        # Main processor reset
        set proc_sys_reset_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0]

        # Ground for SDIO_WP
        set xlconstant_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0]
        set_property CONFIG.CONST_VAL {0} $xlconstant_0
        
        # VCC for AXI Quad SPI
        set xlconstant_1 [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1]
        set_property CONFIG.CONST_VAL {1} $xlconstant_1

        # F2P interrupt concat
        set irq_concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 irq_concat]
        set_property -dict [list CONFIG.NUM_PORTS {16}] $irq_concat
        
        # Expose GPIO EMIO for LTC2983 irq pin
        set_property -dict [list \
            CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
            CONFIG.PCW_GPIO_EMIO_GPIO_IO {13} \
        ] $zynq_ps

        # Fixed IO and DDR
        connect_bd_intf_net -intf_net zynq_ps_ddr [get_bd_intf_ports ddr] [get_bd_intf_pins zynq_ps/DDR]
        connect_bd_intf_net -intf_net zynq_ps_fixed_io [get_bd_intf_ports fixed_io] [get_bd_intf_pins zynq_ps/FIXED_IO]

        # Create CAN BD pins
        create_bd_port -dir I -type data can_rx
        create_bd_port -dir O -type data can_tx

        connect_bd_net [get_bd_ports can_rx] [get_bd_pins zynq_ps/CAN0_PHY_RX]
        connect_bd_net [get_bd_ports can_tx] [get_bd_pins zynq_ps/CAN0_PHY_TX]

        # AXI IIC
        set axi_iic_0 [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0]
        set_property -dict [list \
            CONFIG.IIC_FREQ_KHZ {400} \
        ] $axi_iic_0

        connect_bd_intf_net [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins smartconnect_0/M00_AXI]
        connect_bd_net [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins zynq_ps/FCLK_CLK0]
        connect_bd_net [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
        connect_bd_intf_net [get_bd_intf_pins iic_0] [get_bd_intf_pins axi_iic_0/IIC]
        connect_bd_net [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins irq_concat/In0]
        assign_bd_address -offset 0x41600000 -range 64K [get_bd_addr_spaces zynq_ps/Data] [get_bd_addr_segs axi_iic_0/S_AXI/Reg]

        # LoraWan 1301 spi interface
        create_bd_port -dir O -type clk lorawan_spi_sck_o
        create_bd_port -dir I -type data lorawan_spi_io1_i
        create_bd_port -dir O -type data lorawan_spi_io0_o
        create_bd_port -dir O -type data lorawan_spi_ss_o
        #connect_bd_net [get_bd_ports lorawan_irq] [get_bd_pins zynq_ps/GPIO_I]
        
        connect_bd_net [get_bd_ports lorawan_spi_sck_o] [get_bd_pins zynq_ps/SPI0_SCLK_o]
        connect_bd_net [get_bd_ports lorawan_spi_io1_i] [get_bd_pins zynq_ps/SPI0_MISO_i]
        connect_bd_net [get_bd_ports lorawan_spi_io0_o] [get_bd_pins zynq_ps/SPI0_MOSI_o]
        connect_bd_net [get_bd_ports lorawan_spi_ss_o] [get_bd_pins zynq_ps/SPI0_SS_o]

        connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins zynq_ps/SPI0_SS_i]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins zynq_ps/SPI0_SCLK_i]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins zynq_ps/SPI0_MOSI_i]

        # System Reset
        connect_bd_net -net zynq_ps_fclk_clk0 [get_bd_pins zynq_ps/FCLK_CLK0] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins zynq_ps/M_AXI_GP0_ACLK]
        connect_bd_net -net zynq_ps_fclk_reset0_n [get_bd_pins zynq_ps/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]

        # Fabric Interrupt
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In1]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In2]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In3]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In4]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In5]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In6]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In7]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In8]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In9]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In10]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In11]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In12]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In13]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In14]
        connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins irq_concat/In15]
        connect_bd_net [get_bd_pins irq_concat/dout] [get_bd_pins zynq_ps/IRQ_F2P]

        # Set PFM properties
        set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files [current_bd_design].bd] 
        set_property PFM_NAME "spacelab.ufsc.br:sl:$name:$version" [get_files [current_bd_design].bd]
        set_property PFM.AXI_PORT {
            M_AXI_GP1 {memport "M_AXI_GP" sptag "GP" memory ""}
            S_AXI_HP1 {memport "S_AXI_HP" sptag "HP1" memory "ps7 HP1_DDR_LOWOCM"}
            S_AXI_HP2 {memport "S_AXI_HP" sptag "HP2" memory "ps7 HP2_DDR_LOWOCM"} 
            S_AXI_HP3 {memport "S_AXI_HP" sptag "HP3" memory "ps7 HP3_DDR_LOWOCM"}
        } $zynq_ps
        set_property PFM.CLOCK { 
            FCLK_CLK0 {id "0" is_default "true" proc_sys_reset "/proc_sys_reset_0" status "fixed"}
        } $zynq_ps
    }
}
