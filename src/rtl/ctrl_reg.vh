`ifndef __CTRL_REG_HEADER__
`define __CTRL_REG_HEADER__

`define CR_ADDR         0       // Control register
`define CFR_ADDR        1       // Configuration register
`define SR_ADDR         2       // Status register

`define CR_WP_Loc       17      // Write protect
`define CR_WDGA_Loc     16      // WDG activation
`define CR_T_Loc        15:0    // Counter

`define CFR_EWI_Loc     18      // Early wakeup interrupt
`define CFR_WDGTB_Loc   17:16   // Timer base
`define CFR_W_Loc       15:0    // Window value

`define SR_EWIF_Loc     0       // Early wakeup interrupt flag

`endif