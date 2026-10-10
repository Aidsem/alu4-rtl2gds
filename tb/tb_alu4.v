// Self-checking exhaustive testbench for alu4. Verilog-2001.
// 8 opcodes x 16 x 16 operand pairs = 2048 vectors, one per clock, back to back.
// Run from the project root so the VCD lands in sim/.
`timescale 1ns/1ps
module tb_alu4;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a, b;
    reg  [2:0] op;
    wire [3:0] y;
    wire       c, z, n, v;

    alu4 dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .op(op),
              .y(y), .c(c), .z(z), .n(n), .v(v));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Reference model: integer arithmetic, no bit-level flag equations.
    // Returns {y[3:0], c, z, n, v}.
    function [7:0] ref_model;
        input [3:0] fa;
        input [3:0] fb;
        input [2:0] fop;
        integer ua, ub, sa, sb, r, sr, yy, cc, vv, i, bita, bitb, bitr;
        begin
            ua = fa;
            ub = fb;
            sa = (ua >= 8) ? ua - 16 : ua;   // two's-complement value
            sb = (ub >= 8) ? ub - 16 : ub;
            yy = 0; cc = 0; vv = 0;
            case (fop)
                3'd0: begin   // ADD
                    r  = ua + ub;
                    yy = r % 16;
                    cc = (r > 15) ? 1 : 0;
                    sr = sa + sb;
                    vv = (sr < -8 || sr > 7) ? 1 : 0;
                end
                3'd1: begin   // SUB, c = borrow
                    r  = ua - ub;
                    yy = (r + 16) % 16;
                    cc = (r < 0) ? 1 : 0;
                    sr = sa - sb;
                    vv = (sr < -8 || sr > 7) ? 1 : 0;
                end
                3'd2, 3'd3, 3'd4: begin   // AND, OR, XOR: per-bit, weighted sum
                    yy = 0;
                    for (i = 0; i < 4; i = i + 1) begin
                        bita = (ua / (1 << i)) % 2;
                        bitb = (ub / (1 << i)) % 2;
                        if (fop == 3'd2)      bitr = bita * bitb;
                        else if (fop == 3'd3) bitr = (bita + bitb > 0) ? 1 : 0;
                        else                  bitr = (bita != bitb) ? 1 : 0;
                        yy = yy + bitr * (1 << i);
                    end
                end
                3'd5: yy = 15 - ua;                  // NOT A
                3'd6: begin                          // SHL by 1, c = bit shifted out
                    yy = (ua * 2) % 16;
                    cc = (ua >= 8) ? 1 : 0;
                end
                3'd7: begin                          // SHR logical by 1, c = bit shifted out
                    yy = ua / 2;
                    cc = ua % 2;
                end
            endcase
            ref_model = {yy[3:0], cc[0], (yy == 0) ? 1'b1 : 1'b0,
                         (yy >= 8) ? 1'b1 : 1'b0, vv[0]};
        end
    endfunction

    integer    k, errors, checks;
    reg [7:0]  exp_prev;      // expectation for the vector applied one edge ago
    reg [7:0]  got;
    reg [2:0]  op_prev;
    reg [3:0]  a_prev, b_prev;

    task check;
        input [7:0] expv;
        input [2:0] cop;
        input [3:0] ca;
        input [3:0] cb;
        begin
            got = {y, c, z, n, v};
            checks = checks + 1;
            if (got !== expv) begin
                if (errors < 5)
                    $display("MISMATCH op=%0d a=%0d b=%0d : got y=%0d c=%b z=%b n=%b v=%b, exp y=%0d c=%b z=%b n=%b v=%b",
                             cop, ca, cb,
                             got[7:4], got[3], got[2], got[1], got[0],
                             expv[7:4], expv[3], expv[2], expv[1], expv[0]);
                errors = errors + 1;
            end
        end
    endtask

    integer rst_errors;

    initial begin
        $dumpfile("sim/alu4.vcd");
        $dumpvars(0, tb_alu4);

        errors = 0; checks = 0; rst_errors = 0;
        rst_n = 1'b0; a = 4'd0; b = 4'd0; op = 3'd0;
        exp_prev = 8'd0; op_prev = 3'd0; a_prev = 4'd0; b_prev = 4'd0;

        // reset: outputs must be 0
        repeat (3) @(posedge clk);
        #1;
        if ({y, c, z, n, v} !== 8'd0) begin
            $display("MISMATCH reset: outputs not 0 (got %b)", {y, c, z, n, v});
            rst_errors = rst_errors + 1;
        end
        @(negedge clk);
        rst_n = 1'b1;

        // exhaustive sweep: vector k is driven before edge k, its result is
        // visible after edge k+1. After edge k, compare against vector k-1.
        for (k = 0; k <= 2048; k = k + 1) begin
            if (k < 2048) begin
                op = k / 256;
                a  = (k / 16) % 16;
                b  = k % 16;
            end else begin
                op = 3'd0; a = 4'd0; b = 4'd0;   // idle, flush the pipeline
            end
            @(posedge clk);
            #1;
            if (k >= 1)
                check(exp_prev, op_prev, a_prev, b_prev);
            if (k < 2048) begin
                exp_prev = ref_model(a, b, op);
                op_prev = op; a_prev = a; b_prev = b;
            end
        end

        // async reset mid-stream: outputs must clear without a clock edge
        a = 4'd7; b = 4'd1; op = 3'd0;   // ADD 7+1 -> y=8 c=0 z=0 n=1 v=1
        repeat (2) @(posedge clk);
        #1;
        if ({y, c, z, n, v} !== ref_model(4'd7, 4'd1, 3'd0)) begin
            $display("MISMATCH pre-reset ADD 7+1: got %b", {y, c, z, n, v});
            rst_errors = rst_errors + 1;
        end
        #2 rst_n = 1'b0;                 // off-clock-edge assert
        #1;
        if ({y, c, z, n, v} !== 8'd0) begin
            $display("MISMATCH async reset: outputs not 0 (got %b)", {y, c, z, n, v});
            rst_errors = rst_errors + 1;
        end
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        errors = errors + rst_errors;
        if (errors == 0)
            $display("PASS: %0d/%0d vectors, 0 errors (+ reset checks ok)", checks, checks);
        else
            $display("FAIL: %0d errors in %0d vectors (%0d reset errors)", errors, checks, rst_errors);
        $finish;
    end

endmodule
