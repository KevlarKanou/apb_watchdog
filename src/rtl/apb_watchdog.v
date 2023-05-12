`include "../src/rtl/ctrl_reg.vh"

module apb_watchdog (
    input   wire            pclk,
    input   wire            presetn,
    input   wire            psel,
    input   wire            penable,
    input   wire    [31:0]  paddr,
    input   wire            pwrite,
    input   wire    [31:0]  pwdata,
    output  reg     [31:0]  prdata,
    output  wire            wdg_int,
    output  wire            wdg_rst
);

    wire apb_wr, apb_rd;
    assign apb_wr = psel & (~penable) & pwrite;
    assign apb_rd = psel & (~penable) & (~pwrite);

    reg [31:0] CR, CFR, SR;

    wire 	cnt_clk;

    cnt_clk_div u_cnt_clk_div(
        //ports
        .pclk       		( pclk       		    ),
        .presetn    		( presetn    		    ),
        .timer_base 		( CFR[`CFR_WDGTB_Loc] 	),
        .cnt_clk    		( cnt_clk    		    )
    );

    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            CR  <= {14'b0, 1'b0, 1'b0, 16'hFFFF};
        else if (apb_wr & (paddr == `CR_ADDR))
            CR  <= {14'b0, pwdata[`CR_WP_Loc], (CR[`CR_WDGA_Loc]|pwdata[`CR_WDGA_Loc]), pwdata[`CR_T_Loc]};
        else if (cnt_clk)
            CR  <= {14'b0, CR[`CR_WP_Loc], CR[`CR_WDGA_Loc], CR[`CR_T_Loc] - 1'd1};
    end

    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            CFR  <= {13'b0, 1'b0, 2'b0, 16'hFFFF};
        else if (apb_wr & (paddr == `CFR_ADDR) & (~CR[`CR_WP_Loc]))
            CFR  <= {13'b0, (CFR[`CFR_EWI_Loc]|pwdata[`CFR_EWI_Loc]), pwdata[`CFR_WDGTB_Loc], pwdata[`CFR_W_Loc]};
    end

    reg state_SR, nextstate_SR;
    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            state_SR <= 0;
        else
            state_SR <= nextstate_SR;
    end
    always @(*) begin
        case (state_SR)
            0 :
                if (CR[`CR_T_Loc] == 1)
                    nextstate_SR = 1;
            1 :
                if (CR[`CR_T_Loc] == 0)
                    nextstate_SR = 0;
            default: 
                nextstate_SR = 0;
        endcase
    end

    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            SR  <= {31'b0, 1'b0};
        else if (apb_wr & (paddr == `SR_ADDR) & (~CR[`CR_WP_Loc]))
            SR  <= {31'b0, SR[`SR_EWIF_Loc] & pwdata[`SR_EWIF_Loc]};
        else if (state_SR & (CR[`CR_T_Loc] == 0) & CFR[`CFR_EWI_Loc] & CR[`CR_WDGA_Loc])
            SR  <= {31'b0, 1'b1};
    end

    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            prdata <= 32'b0;
        else if (apb_rd) begin
            case (paddr)
                `CR_ADDR:
                    prdata <= CR;
                `CFR_ADDR:
                    prdata <= CFR;
                `SR_ADDR:
                    prdata <= SR;
                default:
                    prdata <= 32'b0;
            endcase
        end
    end

    assign wdg_int = SR[`SR_EWIF_Loc];

    reg overflow;
    always @(posedge cnt_clk, negedge presetn) begin
        if (!presetn)
            overflow <= 0;
        else if (CR[`CR_T_Loc] == 0)
            overflow <= 1;
    end

    reg WDGA_D;
    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            WDGA_D <= 0;
        else
            WDGA_D <= CR[`CR_WDGA_Loc];
    end
    assign wdg_rst = WDGA_D & (overflow | (apb_wr & (paddr == `CR_ADDR) & (CR[`CR_T_Loc] > CFR[`CFR_W_Loc])));

endmodule