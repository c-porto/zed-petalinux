# SPDX-License-Identifier: GPL-2.0-only

namespace eval ::fsat_bd {
    proc create_zynq_ps {} {
    # Zynq Processing System Instance for Block Design
        set zynq_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 zynq_ps]
        set_property CONFIG.preset {ZedBoard} $zynq_ps
        set_property -dict [list \
            CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
            CONFIG.PCW_USE_M_AXI_GP0 {1} \
            CONFIG.PCW_CAN0_CAN0_IO {EMIO} \
            CONFIG.PCW_CAN0_PERIPHERAL_ENABLE {1} \
            CONFIG.PCW_SPI0_PERIPHERAL_ENABLE {1} \
            CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} \
            CONFIG.PCW_IRQ_F2P_INTR {1} \
        ] $zynq_ps

        return $zynq_ps
    }
}
