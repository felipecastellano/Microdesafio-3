`timescale 1ns / 1ps

module spi_receiver(
    input wire clk,       // Reloj del sistema
    input wire rst,       // Reset sincrónico
    input wire mosi,      // Datos entrantes del maestro
    input wire sclk,      // Reloj SPI
    input wire cs,        // Chip select activo en bajo
    output reg [15:0] instruction,  // Instrucción recibida
    output reg valid     // Señal que indica que la instrucción está lista
);

    reg [3:0] bit_count;      // Contador de bits recibidos
    reg [15:0] shift_reg;     // Registro de desplazamiento

    always @(posedge sclk or posedge rst) begin
        if (rst) begin
            shift_reg <= 16'b0;
            bit_count <= 0;
            instruction <= 16'b0;
            valid <= 0;
        end else if (~cs) begin
            // Se recibe bit por bit, LSB primero
            shift_reg <= {mosi, shift_reg[15:1]};
            bit_count <= bit_count + 1;

            if (bit_count == 15) begin
                instruction <= shift_reg;
                valid <= 1;  // La instrucción completa está lista
                bit_count <= 0; // Reinicia para la siguiente instrucción
            end else begin
                valid <= 0;
            end
        end else begin
            bit_count <= 0;
            valid <= 0;
        end
    end

endmodule
