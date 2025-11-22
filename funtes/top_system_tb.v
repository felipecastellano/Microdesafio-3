`timescale 1ns/1ps

module top_system_tb;

    // === Señales del sistema ===
    reg clk, rst;
    reg sck, mosi, cs;
    wire miso;

    // Variable para almacenar el resultado recibido por SPI
    reg [15:0] result;

    // === Instancia del sistema completo ===
    top_system uut (
        .clk(clk),
        .rst(rst),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    // === Generador de reloj del sistema ===
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns de período
    end

    // === Generador de reloj SPI ===
    initial begin
        sck = 0;
        forever #20 sck = ~sck; // 40 ns de período
    end

    // === Tareas SPI ===

    // Enviar un bit (MSB primero)
    task spi_send_bit;
        input reg data;
        begin
            mosi = data;
            @(posedge sck);
        end
    endtask

    // Enviar palabra de 16 bits
    task spi_send_word;
        input [15:0] word;
        integer i;
        begin
            for (i = 15; i >= 0; i = i - 1)
                spi_send_bit(word[i]);
        end
    endtask

    // Recibir palabra de 16 bits
    task spi_receive;
        output [15:0] word;
        integer i;
        reg [15:0] tmp;
        begin
            tmp = 0;
            for (i = 15; i >= 0; i = i - 1) begin
                @(posedge sck);
                tmp[i] = miso;
            end
            word = tmp;
        end
    endtask

    // === Secuencia principal de prueba ===
    initial begin
        $dumpfile("top_system_tb.vcd");
        $dumpvars(0, top_system_tb);

        $display("=== Iniciando prueba TOP SYSTEM (SPI + FPMUL) ===");

        // Reset inicial
        rst = 1; cs = 1; mosi = 0;
        #50;
        rst = 0;
        #20;

        // Activar chip select y enviar x1 y x2
        cs = 0;
        $display("Enviando operandos via SPI (formato IEEE 754 en HEX)...");

        // Ejemplo: 3.0 * 2.0 = 6.0
        // 3.0 = 0x4040  |  2.0 = 0x4000
        spi_send_word(16'h4040);  // x1 = 3.0
        spi_send_word(16'h4000);  // x2 = 2.0

        cs = 1;
        #100;

        // Leer resultado desde SPI
        cs = 0;
        spi_receive(result);
        cs = 1;

        $display("Resultado recibido: y = %h (esperado ≈ 0x40C0 = 6.0)", result);

        $display("=== Fin de simulación ===");
        #100;
        $finish;
    end

endmodule
