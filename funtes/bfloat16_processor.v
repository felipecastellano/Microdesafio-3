`timescale 1ns / 1ps

module bfloat16_processor (
    input clk,
    input rst,
    // Interfaz SPI
    input sck,        // Reloj SPI
    input mosi,       // Datos del master hacia el esclavo
    output reg miso,  // Datos del esclavo hacia el master
    input cs,         // Chip select (activo bajo)
    // Salidas opcionales para depuración
    output reg [15:0] acc_monitor, // Permite monitorear el acumulador
    output reg ready               // Señal de listo
);

// ---------------------------
// Registros internos
// ---------------------------
reg [15:0] acc;               // Acumulador interno
reg [15:0] instruction_reg;   // Registro de instrucción recibida
reg [15:0] operand1_reg;      // Primer operando
reg [15:0] operand2_reg;      // Segundo operando
reg [15:0] result_reg;        // Registro de resultado

// ---------------------------
// Señales de control
// ---------------------------
reg [3:0] state;              // Estado de la máquina de estados
reg [3:0] current_opcode;     // Código de instrucción actual

// ---------------------------
// Interfaz SPI
// ---------------------------
reg [15:0] spi_shift_in;      // Registro de desplazamiento para entrada SPI
reg [15:0] spi_shift_out;     // Registro de desplazamiento para salida SPI
reg [4:0] spi_bit_counter;    // Contador de bits recibidos
reg spi_transfer_active;      // Indica si hay transferencia activa
reg last_cs;                  // Guarda el valor previo de CS para detectar flancos

// ---------------------------
// Operaciones de punto flotante simplificadas
// ---------------------------
wire [15:0] add_result;       // Resultado de suma
wire [15:0] mul_result;       // Resultado de multiplicación
wire [15:0] div_result;       // Resultado de división

// ---------------------------
// Inicialización de registros
// ---------------------------
initial begin
    acc = 16'b0;
    instruction_reg = 16'b0;
    operand1_reg = 16'b0;
    operand2_reg = 16'b0;
    result_reg = 16'b0;
    state = 0;
    current_opcode = 0;
    spi_shift_in = 16'b0;
    spi_shift_out = 16'b0;
    spi_bit_counter = 0;
    spi_transfer_active = 0;
    last_cs = 1;
    miso = 0;
    acc_monitor = 16'b0;
    ready = 0;
end

// ---------------------------
// Operaciones matemáticas simplificadas
// NOTA: solo funcionalidad de prueba, no IEEE 754 exacto
// ---------------------------
assign add_result = operand1_reg + operand2_reg; // Suma simplificada

assign mul_result = {operand1_reg[15] ^ operand2_reg[15],  // Signo
                     operand1_reg[14:7] + operand2_reg[14:7] - 8'd15, // Exponente
                     (operand1_reg[6:0] * operand2_reg[6:0]) >> 7};   // Mantisa

assign div_result = {operand1_reg[15] ^ operand2_reg[15],  // Signo
                     operand1_reg[14:7] - operand2_reg[14:7] + 8'd15, // Exponente
                     (operand1_reg[6:0] << 7) / operand2_reg[6:0]};   // Mantisa

// ---------------------------
// Procesamiento de entrada SPI
// ---------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset de registros SPI y estado
        spi_shift_in <= 16'b0;
        spi_bit_counter <= 0;
        spi_transfer_active <= 0;
        last_cs <= 1;
        state <= 0;
        ready <= 0;
    end else begin
        last_cs <= cs;               // Guardar estado anterior de CS
        ready <= (state == 0);       // Listo si está esperando instrucción
        
        // Detectar flanco descendente de CS: inicio de transferencia
        if (last_cs && !cs) begin
            spi_transfer_active <= 1;
            spi_bit_counter <= 0;
            spi_shift_in <= 16'b0;
        end
        
        // Detectar flanco ascendente de CS: fin de transferencia
        if (!last_cs && cs) begin
            spi_transfer_active <= 0;
            if (spi_bit_counter == 16) begin
                // Palabra completa recibida
                case (state)
                    0: begin // Esperando instrucción
                        instruction_reg <= {spi_shift_in[0], spi_shift_in[1], spi_shift_in[2], spi_shift_in[3],
                                           spi_shift_in[4], spi_shift_in[5], spi_shift_in[6], spi_shift_in[7],
                                           spi_shift_in[8], spi_shift_in[9], spi_shift_in[10], spi_shift_in[11],
                                           spi_shift_in[12], spi_shift_in[13], spi_shift_in[14], spi_shift_in[15]};
                        current_opcode <= spi_shift_in[3:0]; // Tomar 4 LSB como opcode
                        state <= 1; // Pasar a recibir primer operando
                    end
                    1: begin // Esperando primer operando
                        operand1_reg <= {spi_shift_in[0], spi_shift_in[1], spi_shift_in[2], spi_shift_in[3],
                                        spi_shift_in[4], spi_shift_in[5], spi_shift_in[6], spi_shift_in[7],
                                        spi_shift_in[8], spi_shift_in[9], spi_shift_in[10], spi_shift_in[11],
                                        spi_shift_in[12], spi_shift_in[13], spi_shift_in[14], spi_shift_in[15]};
                        // Para operaciones que requieren dos operandos
                        if (current_opcode >= 3 && current_opcode <= 6) begin
                            state <= 2; // Esperar segundo operando
                        end else begin
                            state <= 3; // Ejecutar operación
                        end
                    end
                    2: begin // Esperando segundo operando
                        operand2_reg <= {spi_shift_in[0], spi_shift_in[1], spi_shift_in[2], spi_shift_in[3],
                                        spi_shift_in[4], spi_shift_in[5], spi_shift_in[6], spi_shift_in[7],
                                        spi_shift_in[8], spi_shift_in[9], spi_shift_in[10], spi_shift_in[11],
                                        spi_shift_in[12], spi_shift_in[13], spi_shift_in[14], spi_shift_in[15]};
                        state <= 3; // Ejecutar operación
                    end
                    default: state <= 0;
                endcase
            end
        end
        
        // Desplazar datos de entrada en flanco de subida de SCK
        if (!cs && sck && spi_transfer_active) begin
            spi_shift_in <= {mosi, spi_shift_in[15:1]}; // LSB primero
            spi_bit_counter <= spi_bit_counter + 1;
        end
        
        // ---------------------------
        // Ejecución de la operación
        // ---------------------------
        case (state)
            3: begin
                case (current_opcode)
                    0: begin // ZERO: limpiar acumulador
                        acc <= 16'b0;
                        result_reg <= 16'b0;
                        state <= 0;
                    end
                    1: begin // SET_ACC: cargar acumulador
                        acc <= operand1_reg;
                        result_reg <= operand1_reg;
                        state <= 0;
                    end
                    2: begin // LOAD_ACC: devolver acumulador
                        result_reg <= acc;
                        state <= 0;
                    end
                    3: begin // ADD2: suma simple
                        result_reg <= add_result;
                        state <= 0;
                    end
                    4: begin // SUB2: resta simplificada
                        result_reg <= add_result;
                        state <= 0;
                    end
                    5: begin // MPY2: multiplicación
                        result_reg <= mul_result;
                        state <= 0;
                    end
                    6: begin // DIV2: división
                        result_reg <= div_result;
                        state <= 0;
                    end
                    7: begin // SUM: acumular suma
                        acc <= add_result;
                        result_reg <= add_result;
                        state <= 1; // Esperar siguiente operando
                    end
                    8: begin // SUB: acumular resta
                        acc <= add_result;
                        result_reg <= add_result;
                        state <= 1;
                    end
                    9: begin // MAC: multiplicar y acumular
                        acc <= mul_result + acc;
                        result_reg <= acc;
                        state <= 1;
                    end
                    10: begin // MAS: multiplicar y restar del acumulador
                        acc <= acc - mul_result;
                        result_reg <= acc;
                        state <= 1;
                    end
                    default: begin
                        state <= 0;
                    end
                endcase
            end
        endcase
    end
end

// ---------------------------
// Salida SPI
// ---------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        spi_shift_out <= 16'b0;
        miso <= 0;
    end else begin
        // Preparar datos de salida LSB primero
        if (!cs && state == 0) begin
            spi_shift_out <= {result_reg[0], result_reg[1], result_reg[2], result_reg[3],
                             result_reg[4], result_reg[5], result_reg[6], result_reg[7],
                             result_reg[8], result_reg[9], result_reg[10], result_reg[11],
                             result_reg[12], result_reg[13], result_reg[14], result_reg[15]};
        end
        
        // Desplazar datos de salida en flanco de bajada de SCK
        if (!cs && !sck && spi_transfer_active) begin
            miso <= spi_shift_out[0];
            spi_shift_out <= {1'b0, spi_shift_out[15:1]};
        end
    end
end

// ---------------------------
// Monitoreo del acumulador
// ---------------------------
always @(posedge clk) begin
    acc_monitor <= acc; // Actualiza salida para depuración
end

endmodule
