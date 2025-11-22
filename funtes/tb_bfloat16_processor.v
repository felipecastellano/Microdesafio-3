`timescale 1ns / 1ps

module tb_bfloat16_processor_full;

    // === Entradas del DUT ===
    reg clk;
    reg rst;
    reg sck;
    reg mosi;
    reg cs;

    // === Salidas del DUT ===
    wire miso;
    wire [15:0] acc_monitor;
    wire ready;

    // === Instancia del DUT ===
    bfloat16_processor dut (
        .clk(clk),
        .rst(rst),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .acc_monitor(acc_monitor),
        .ready(ready)
    );

    // === Generadores de reloj ===
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    initial sck = 0;
    always #20 sck = ~sck; // Frecuencia SPI más lenta

    // ===============================
    // Bloque de pruebas: un opcode por prueba
    // ===============================
    initial begin
        // --- Archivo VCD ---
        $dumpfile("tb_bfloat16_processor_full.vcd");
        $dumpvars(0, tb_bfloat16_processor_full);

        // Reset inicial
        rst = 1; cs = 1; mosi = 0;
        #50;
        rst = 0;
        #10;

        // ===============================
        // 00: ZERO
        // ===============================
        send_spi_word(16'h0000); 
        #200;

        // ===============================
        // 01: SET_ACC (1.5)
        // ===============================
        send_spi_word(16'h0001); 
        send_spi_word(16'h3FC0); 
        #200;

        // ===============================
        // 02: LOAD_ACC
        // ===============================
        send_spi_word(16'h0002); 
        #200;

        // ===============================
        // 03: ADD2 (1.5 + 2.0)
        // ===============================
        send_spi_word(16'h0003);
        send_spi_word(16'h3FC0);
        send_spi_word(16'h4000);
        #200;

        // ===============================
        // 04: SUB2 (2.0 - 1.5)
        // ===============================
        send_spi_word(16'h0004);
        send_spi_word(16'h4000);
        send_spi_word(16'h3FC0);
        #200;

        // ===============================
        // 05: MPY2 (1.5 * 2.0)
        // ===============================
        send_spi_word(16'h0005);
        send_spi_word(16'h3FC0);
        send_spi_word(16'h4000);
        #200;

        // ===============================
        // 06: DIV2 (2.0 / 1.5)
        // ===============================
        send_spi_word(16'h0006);
        send_spi_word(16'h4000);
        send_spi_word(16'h3FC0);
        #200;

        // ===============================
        // 07: SUM (acumular 0.5)
        // ===============================
        send_spi_word(16'h0007);
        send_spi_word(16'h3F00); // 0.5
        #200;

        // ===============================
        // 08: SUB (restar 0.25 acumulado)
        // ===============================
        send_spi_word(16'h0008);
        send_spi_word(16'h3E80); // 0.25
        #200;

        // ===============================
        // 09: MAC (1.0 * 2.0 -> acumular)
        // ===============================
        send_spi_word(16'h0009);
        send_spi_word(16'h3F80); // 1.0
        send_spi_word(16'h4000); // 2.0
        #200;

        // ===============================
        // 10: MAS (1.5 * 2.0 -> restar acumulador)
        // ===============================
        send_spi_word(16'h000A);
        send_spi_word(16'h3FC0); // 1.5
        send_spi_word(16'h4000); // 2.0
        #200;

        // ===============================
        // FIN DE PRUEBAS
        // ===============================
        #50;
        $finish;
    end

    // ===============================
    // Tarea para enviar palabra SPI (LSB primero)
    // ===============================
    task send_spi_word;
        input [15:0] data;
        integer i;
        begin
            cs = 0;
            for (i = 0; i < 16; i = i + 1) begin
                mosi = data[i];    
                #40;               
            end
            cs = 1;
            #40;
        end
    endtask

endmodule
