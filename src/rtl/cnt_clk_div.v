module cnt_clk_div (
    input   wire            pclk,
    input   wire            presetn,
    input   wire    [1:0]   timer_base,

    output  wire            cnt_clk
);

    reg [14:0] div_cnt;

    always @(posedge pclk, negedge presetn) begin
        if (!presetn)
            div_cnt <= 15'b0;
        else
            div_cnt <= div_cnt + 1'b1;
    end

    // wire pre_div_clk;
    // assign pre_div_clk = pre_div_cnt[11];

    // reg [2:0] post_div_cnt;

    // always @(posedge pre_div_clk, negedge presetn) begin
    //     if (!presetn)
    //         post_div_cnt <= 3'b0;
    //     else
    //         post_div_cnt <= post_div_cnt + 1'b1;
    // end

    // assign cnt_clk =    (timer_base == 2'b00) ? pre_div_clk :
    //                     (timer_base == 2'b01) ? post_div_cnt[0] :
    //                     (timer_base == 2'b10) ? post_div_cnt[1] :
    //                     (timer_base == 2'b11) ? post_div_cnt[2] : 0;

    assign cnt_clk =    (timer_base == 2'b00) ? (div_cnt[11:0] == 12'hFFF) :
                        (timer_base == 2'b01) ? (div_cnt[12:0] == 13'h1FFF) :
                        (timer_base == 2'b10) ? (div_cnt[13:0] == 14'h3FFF) :
                        (timer_base == 2'b11) ? (div_cnt[14:0] == 15'h7FFF) : 0;

endmodule