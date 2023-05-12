`timescale 1ns/1ps
`include "../src/rtl/ctrl_reg.vh"

module tb ();

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
        #5_000_000 $finish;
    end

    reg pclk, presetn;
    reg psel, penable, pwrite;
    reg [31:0] paddr, pwdata;
    reg irq_en;
    initial begin
        pclk    = 1;
        presetn = 0;
        psel    = 0;
        penable = 0;
        pwrite  = 0;
        paddr   = 0;
        pwdata  = 0;
        irq_en  = 0;
        #2000 presetn = 1; 
    end

    always
        #5 pclk = ~pclk;

    localparam  apb_wr      = 3'b101,
                apb_rd      = 3'b100,
                apb_reset   = 3'b010;

    wire [31:0]	prdata;
    wire 	wdg_int;
    wire 	wdg_rst;

    apb_watchdog u_apb_watchdog(
        //ports
        .pclk    		( pclk    		),
        .presetn 		( presetn 		),
        .psel    		( psel    		),
        .penable 		( penable 		),
        .paddr   		( paddr   		),
        .pwrite  		( pwrite  		),
        .pwdata  		( pwdata  		),
        .prdata  		( prdata  		),
        .wdg_int 		( wdg_int 		),
        .wdg_rst 		( wdg_rst 		)
    );

    always @(posedge pclk) begin
        if (wdg_rst) begin
            presetn = 0;
            $display("  Time:%d, System Reset...\n", $time);
            #2000 presetn = 1;
        end
    end

    task APBWrite (
        input   [31:0]  Addr,
        input   [31:0]  Data
    );
        begin
            #10 {psel, pwrite} = 2'b11;
            paddr = Addr;
            pwdata = Data;
            #10 penable = 1'b0;
            #10 {psel, penable, pwrite} = apb_reset;
            // $display("W Time:%d, Addr:%d, Data:%32b", $time, Addr, Data);
            case (Addr)
                `CR_ADDR: 
                    $display("W Time:%d, Addr:  CR, WP:%0d WDGA:%0d T:%0d", $time, Data[`CR_WP_Loc], Data[`CR_WDGA_Loc], Data[`CR_T_Loc]);
                `CFR_ADDR:
                    $display("W Time:%d, Addr: CFR, EWI:%0d WDGTB:%2b W:%0d", $time, Data[`CFR_EWI_Loc], Data[`CFR_WDGTB_Loc], Data[`CFR_W_Loc]);
                `SR_ADDR:
                    $display("W Time:%d, Addr:  SR, EWIF:%0d", $time, Data[`SR_EWIF_Loc]);
                default: 
                    $display("W Time:%d, Addr:%4d, Data:%32b", $time, Addr, Data);
            endcase
        end
    endtask

    task APBRead (
        input   [31:0]  Addr
    );
        begin
            #10 {psel, pwrite} = 2'b10;
            paddr = Addr;
            #10 penable = 1'b0;
            #10 {psel, penable, pwrite} = apb_reset;
            // $display("R Time:%d, Addr:%d, Data:%32b", $time, Addr, prdata);
            case (Addr)
                `CR_ADDR: 
                    $display("R Time:%d, Addr:  CR, WP:%0d WDGA:%0d T:%0d", $time, prdata[`CR_WP_Loc], prdata[`CR_WDGA_Loc], prdata[`CR_T_Loc]);
                `CFR_ADDR:
                    $display("R Time:%d, Addr: CFR, EWI:%0d WDGTB:%2b W:%0d", $time, prdata[`CFR_EWI_Loc], prdata[`CFR_WDGTB_Loc], prdata[`CFR_W_Loc]);
                `SR_ADDR:
                    $display("R Time:%d, Addr:  SR, EWIF:%0d", $time, prdata[`SR_EWIF_Loc]);
                default: 
                    $display("R Time:%d, Addr:%4d, Data:%32b", $time, Addr, prdata);
            endcase
        end
    endtask

    initial begin
        #2010 $display("Test 1 复位测试\n");
        APBWrite(`CFR_ADDR, {13'b0, 1'b1, 2'b01, 16'hFFFF});
        APBWrite(`CR_ADDR, {14'b0, 1'b0, 1'b1, 16'h0005});
        while (presetn) 
            #10;

        #2010 $display("Test 2 中断刷新测试\n");
        APBWrite(`CFR_ADDR, {13'b0, 1'b1, 2'b00, 16'h0FFF});
        APBWrite(`CR_ADDR, {14'b0, 1'b0, 1'b1, 16'h0005});
        irq_en = 1;
        while (presetn) 
            #10;

        #2010 $display("Test 3 窗口外刷新复位测试\n");
        APBWrite(`CFR_ADDR, {13'b0, 1'b1, 2'b00, 16'h0FFF});
        APBWrite(`CR_ADDR, {14'b0, 1'b0, 1'b1, 16'hFFFF});
        #500000 APBRead(`CR_ADDR);
        APBWrite(`CR_ADDR, {15'b0, 1'b1, 16'hFFFF});

        #2010 $display("Test 4 写保护测试\n");
        APBWrite(`CFR_ADDR, {13'b0, 1'b1, 2'b00, 16'h0FFF});
        APBWrite(`CR_ADDR, {14'b0, 1'b1, 1'b1, 16'hFFFF});
        #500000 APBRead(`CR_ADDR);
        APBWrite(`CFR_ADDR, {13'b0, 1'b1, 2'b00, 16'hFFFF});
        APBRead(`CFR_ADDR);
        APBWrite(`CR_ADDR, {15'b0, 1'b1, 16'hFFFF});
    end

    always @(posedge wdg_int) begin
        $display("  Time:%d, WDG IRQ, irq_en:%0d", $time, irq_en);
        if (irq_en) begin
            APBRead(`CR_ADDR);
            APBRead(`SR_ADDR);
            APBWrite(`CR_ADDR, {15'b0, 1'b1, 16'h0005});
            APBWrite(`SR_ADDR, {31'b0, 1'b0});
            APBRead(`SR_ADDR);
            irq_en = 0;
        end
    end

endmodule