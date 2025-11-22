`timescale 1ns/1ps
module bfloat16_spi_acc(
    input clk,
    input rst,
    // SPI interface
    input mosi,
    input sclk,
    input cs_n,
    output miso,
    output ready
);

    // ============================================
    // SPI registers
    // ============================================
    reg [15:0] spi_data_in;
    reg [15:0] spi_data_out;
    reg spi_ready;

    wire spi_done;

    // SPI Slave simple (serial to parallel 16 bits)
    spi_slave_16 spi0(
        .clk(clk),
        .rst(rst),
        .cs_n(cs_n),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .data_out(spi_data_in),
        .done(spi_done)
    );

    // ============================================
    // Instruction decode
    // ============================================
    reg [3:0] instr;
    reg [15:0] operand_a, operand_b;
    reg [15:0] ACC;

    // FP16 result wires
    wire [15:0] sum_res, mul_res, div_res;
    wire sum_ready, mul_ready, div_ready;

    // Temporary registers for operation
    reg op_start;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr <= 0;
            ACC <= 16'd0;
            operand_a <= 16'd0;
            operand_b <= 16'd0;
            op_start <= 1'b0;
            spi_data_out <= 16'd0;
            spi_ready <= 1'b0;
        end else if (spi_done) begin
            // Primer palabra recibida = instrucción
            instr <= spi_data_in[3:0]; // asumimos solo 4 LSBs para instrucción
            // En caso de instrucciones con operandos, esperar siguiente palabra
            op_start <= 1'b1;
        end
    end

    // ============================================
    // Operand latching (simplificado)
    // ============================================
    always @(posedge clk) begin
        if (op_start && (instr==4'd1 || instr==4'd3 || instr==4'd4 || instr==4'd5 || instr==4'd6)) begin
            operand_a <= spi_data_in; // asumir siguiente palabra = operando A
            operand_b <= spi_data_in; // siguiente palabra = operando B
            op_start <= 1'b0;
        end
    end

    // ============================================
    // FP16 modules instantiation
    // ============================================
    fp16sum_res_pipe sum0(
        .x1(operand_a),
        .x2(operand_b),
        .clk(clk),
        .rst(rst),
        .add_sub(1'b0), // 0=sum, 1=sub
        .en(op_start),
        .ready(sum_ready),
        .y(sum_res)
    );

    fpmul mul0(
        .x1(operand_a),
        .x2(operand_b),
        .clk(clk),
        .rst(rst),
        .en(op_start),
        .ready(mul_ready),
        .y(mul_res)
    );

    fpdiv div0(
        .x1(operand_a),
        .x2(operand_b),
        .clk(clk),
        .rst(rst),
        .en(op_start),
        .ready(div_ready),
        .y(div_res)
    );

    // ============================================
    // Execute instruction
    // ============================================
    always @(posedge clk) begin
        if (sum_ready || mul_ready || div_ready) begin
            case(instr)
                4'd0: ACC <= 16'd0;                 // ZERO
                4'd1: ACC <= operand_a;             // SET_ACC
                4'd2: spi_data_out <= ACC;          // LOAD_ACC
                4'd3: spi_data_out <= sum_res;      // ADD2
                4'd4: spi_data_out <= sum_res;      // SUB2 (usando add_sub=1)
                4'd5: spi_data_out <= mul_res;      // MPY2
                4'd6: spi_data_out <= div_res;      // DIV2
                4'd7: ACC <= sum_res;               // SUM
                4'd8: ACC <= sum_res;               // SUB
                4'd9: ACC <= mul_res + ACC;         // MAC
                4'd10: ACC <= ACC - mul_res;        // MAS
                default: ACC <= ACC;
            endcase
            spi_ready <= 1'b1;
        end else begin
            spi_ready <= 1'b0;
        end
    end

    assign ready = spi_ready;

endmodule
