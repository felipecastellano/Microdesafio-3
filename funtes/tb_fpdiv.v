`timescale 1ns / 1ps

module tb_fpdiv;

    // === Entradas del DUT ===
    reg clk;
    reg rst;
    reg en;
    reg [15:0] x1;
    reg [15:0] x2;

    // === Salidas del DUT ===
    wire [15:0] y;
    wire ready;

    // === Instancia del DUT ===
    fpdiv dut (
        .x1(x1),
        .x2(x2),
        .y(y),
        .clk(clk),
        .rst(rst),
        .en(en),
        .ready(ready)
    );

    // === Generador de reloj ===
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    // ===============================
    // Función de conversión bfloat16 a real para ver en GTKWave si se desea
    // ===============================
    function real bfloat16_to_real;
        input [15:0] bf;
        reg sign;
        reg [7:0] exp;
        reg [6:0] mant;
        begin
            sign = bf[15];
            exp  = bf[14:7];
            mant = bf[6:0];
            if (exp == 0) bfloat16_to_real = 0.0;
            else bfloat16_to_real = ((-1.0)**sign) * (1.0 + mant / 128.0) * (2.0**(exp-127));
        end
    endfunction

    // ===============================
    // Bloque de pruebas
    // ===============================
    initial begin
        // Archivo VCD
        $dumpfile("tb_fpdiv.vcd");
        $dumpvars(0, tb_fpdiv);

        // Reset inicial
        rst = 1; en = 0; x1 = 16'h0000; x2 = 16'h0000;
        #20;
        rst = 0;
        #10;

        // ===============================
        // TEST 1: 4.0 / 2.0 = 2.0
        // 4.0 = 0x4080, 2.0 = 0x4000
        // ===============================
        x1 = 16'h4080;
        x2 = 16'h4000;
        en = 1; #10; en = 0;
        wait (ready);
        #20;

        // ===============================
        // TEST 2: (-6.0) / 3.0 = -2.0
        // -6.0 = 0xC0C0, 3.0 = 0x4040
        // ===============================
        x1 = 16'hC0C0;
        x2 = 16'h4040;
        en = 1; #10; en = 0;
        wait (ready);
        #20;

        // ===============================
        // TEST 3: 0.0 / 2.0 = 0.0
        // ===============================
        x1 = 16'h0000;
        x2 = 16'h4000;
        en = 1; #10; en = 0;
        wait (ready);
        #20;

        // ===============================
        // TEST 4: 2.0 / 0.0 -> +infinity
        // ===============================
        x1 = 16'h4000;
        x2 = 16'h0000;
        en = 1; #10; en = 0;
        wait (ready);
        #20;

        // ===============================
        // TEST 5: 0.0 / 0.0 -> NaN
        // ===============================
        x1 = 16'h0000;
        x2 = 16'h0000;
        en = 1; #10; en = 0;
        wait (ready);
        #20;

        // ===============================
        // FIN DE PRUEBAS
        // ===============================
        #50;
        $finish;
    end

endmodule
