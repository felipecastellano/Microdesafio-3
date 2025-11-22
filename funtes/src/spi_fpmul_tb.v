`timescale 1ns/1ps

module spi_fpmul_tb;

    // === Entradas del sistema ===
    reg clk;
    reg rst;
    reg en;
    reg [15:0] x1;
    reg [15:0] x2;

    // === Salidas ===
    wire [15:0] y;
    wire ready;

    // === Instancia del módulo a probar ===
    fpmul uut (
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
        forever #5 clk = ~clk;  // periodo de 10 ns
    end

    // === Secuencia de prueba ===
    initial begin
        $dumpfile("spi_fpmul_tb.vcd");
        $dumpvars(0, spi_fpmul_tb);

        $display("=== INICIO DE PRUEBAS: FPMUL (Floating Point Multiplier) ===");

        // Reset inicial
        rst = 1; en = 0; x1 = 16'h0000; x2 = 16'h0000;
        #20;
        rst = 0;
        #10;

        // === PRUEBA 1: 3.0 * 2.0 = 6.0 ===
        // 3.0 = 0x4040, 2.0 = 0x4000
        x1 = 16'h4040;
        x2 = 16'h4000;
        en = 1; #10; en = 0;
        wait (ready);
        $display("t=%0t | TEST1: x1=0x%h (3.0) x2=0x%h (2.0) -> y=0x%h (≈6.0)", $time, x1, x2, y);

        // === PRUEBA 2: (-2.0) * 2.0 = -4.0 ===
        // -2.0 = 0xC000, 2.0 = 0x4000
        x1 = 16'hC000;
        x2 = 16'h4000;
        en = 1; #10; en = 0;
        wait (ready);
        $display("t=%0t | TEST2: x1=0x%h (-2.0) x2=0x%h (2.0) -> y=0x%h (≈-4.0)", $time, x1, x2, y);

        // === PRUEBA 3: 0.0 * 2.0 = 0.0 ===
        // 0.0 = 0x0000, 2.0 = 0x4000
        x1 = 16'h0000;
        x2 = 16'h4000;
        en = 1; #10; en = 0;
        wait (ready);
        $display("t=%0t | TEST3: x1=0x%h (0.0) x2=0x%h (2.0) -> y=0x%h (≈0.0)", $time, x1, x2, y);

        // === PRUEBA 4: 640 * 32 ≈ 20480 ===
        // 640 ≈ 0x48A0, 32 ≈ 0x4200
        x1 = 16'h48A0;
        x2 = 16'h4200;
        en = 1; #10; en = 0;
        wait (ready);
        $display("t=%0t | TEST4: x1=0x%h (640) x2=0x%h (32) -> y=0x%h (≈20480)", $time, x1, x2, y);

        // === FIN DE PRUEBAS ===
        $display("=== FIN DE PRUEBAS ===");
        #50;
        $finish;
    end

endmodule
