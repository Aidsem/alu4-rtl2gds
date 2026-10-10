// 4-bit ALU, registered inputs and outputs. Verilog-2001.
// Latency: operands applied before clock edge k appear on outputs after edge k+1.
// Flags: c = carry (ADD) / borrow (SUB, 1 when A < B unsigned) / bit shifted out (SHL, SHR),
//        z = (y == 0), n = y[3], v = signed overflow (ADD, SUB only; 0 otherwise).
module alu4 (
    input  wire       clk,
    input  wire       rst_n,   // async, active low; clears every register
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [3:0] y,
    output reg        c,
    output reg        z,
    output reg        n,
    output reg        v
);

    // input registers
    reg [3:0] a_r, b_r;
    reg [2:0] op_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_r  <= 4'd0;
            b_r  <= 4'd0;
            op_r <= 3'd0;
        end else begin
            a_r  <= a;
            b_r  <= b;
            op_r <= op;
        end
    end

    // combinational core
    reg [3:0] y_n;
    reg       c_n, z_n, n_n, v_n;
    reg [4:0] sum;   // 5-bit scratch for ADD/SUB; bit 4 is carry-out / borrow

    always @* begin
        // defaults: no latches
        sum = 5'd0;
        y_n = 4'd0;
        c_n = 1'b0;
        v_n = 1'b0;

        case (op_r)
            // 000 ADD: y = A + B; c = carry-out; v = operands same sign, result differs
            3'b000: begin
                sum = {1'b0, a_r} + {1'b0, b_r};
                y_n = sum[3:0];
                c_n = sum[4];
                v_n = (a_r[3] == b_r[3]) && (y_n[3] != a_r[3]);
            end
            // 001 SUB: y = A - B; c = borrow (bit 4 of the 5-bit difference is 1 iff A < B);
            //          v = operands differ in sign, result sign differs from A
            3'b001: begin
                sum = {1'b0, a_r} - {1'b0, b_r};
                y_n = sum[3:0];
                c_n = sum[4];
                v_n = (a_r[3] != b_r[3]) && (y_n[3] != a_r[3]);
            end
            // 010 AND: y = A & B; c = v = 0
            3'b010: y_n = a_r & b_r;
            // 011 OR: y = A | B; c = v = 0
            3'b011: y_n = a_r | b_r;
            // 100 XOR: y = A ^ B; c = v = 0
            3'b100: y_n = a_r ^ b_r;
            // 101 NOT: y = ~A (B ignored); c = v = 0
            3'b101: y_n = ~a_r;
            // 110 SHL: y = {A[2:0], 0}; c = A[3] (bit shifted out); B ignored; v = 0
            3'b110: begin
                y_n = {a_r[2:0], 1'b0};
                c_n = a_r[3];
            end
            // 111 SHR: logical, y = {0, A[3:1]}; c = A[0] (bit shifted out); B ignored; v = 0
            3'b111: begin
                y_n = {1'b0, a_r[3:1]};
                c_n = a_r[0];
            end
            default: ;
        endcase

        z_n = (y_n == 4'd0);
        n_n = y_n[3];
    end

    // output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'd0;
            c <= 1'b0;
            z <= 1'b0;   // reset value, not a computed flag
            n <= 1'b0;
            v <= 1'b0;
        end else begin
            y <= y_n;
            c <= c_n;
            z <= z_n;
            n <= n_n;
            v <= v_n;
        end
    end

endmodule
