module spi_fpmul_slave (
    input wire clk,       // Reloj del sistema (más rápido que SCK)
    input wire rst,       // Reset global
    // Interfaz SPI
    input wire sck,       // SPI clock
    input wire mosi,      // Master Out Slave In
    output reg miso,      // Master In Slave Out
    input wire cs,        // Chip select (activo en bajo)
    // Conexión al módulo fpmul
    output reg [15:0] x1,
    output reg [15:0] x2,
    input wire [15:0] y,
    output reg en,
    input wire ready
);

    // Estados
    localparam IDLE       = 3'd0;
    localparam RECV_X1    = 3'd1;
    localparam RECV_X2    = 3'd2;
    localparam WAIT_READY = 3'd3;
    localparam SEND_Y     = 3'd4;

    reg [2:0] state = IDLE;
    reg [5:0] bit_cnt = 0;    // Contador de bits (0–31)
    reg [31:0] data_in = 0;   // Datos recibidos del maestro
    reg [15:0] data_out = 0;  // Datos a enviar al maestro
    reg sck_dly;

    // Detectar flancos de SCK
    wire sck_rising = (sck && !sck_dly);
    wire sck_falling = (!sck && sck_dly);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sck_dly <= 0;
        end else begin
            sck_dly <= sck;
        end
    end

    // Máquina de estados principal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
            data_in <= 0;
            data_out <= 0;
            x1 <= 0;
            x2 <= 0;
            en <= 0;
            miso <= 0;
            state <= IDLE;
        end else begin
            en <= 0; // solo un pulso cuando se cargan operandos

            case (state)

                IDLE: begin
                    if (!cs) begin
                        bit_cnt <= 0;
                        state <= RECV_X1;
                    end
                end

                RECV_X1: begin
                    if (!cs && sck_rising) begin
                        data_in <= {data_in[30:0], mosi};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 15) begin
                            x1 <= {data_in[14:0], mosi};
                            bit_cnt <= 0;
                            state <= RECV_X2;
                        end
                    end
                end

                RECV_X2: begin
                    if (!cs && sck_rising) begin
                        data_in <= {data_in[30:0], mosi};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 15) begin
                            x2 <= {data_in[14:0], mosi};
                            en <= 1;               // inicia cálculo
                            state <= WAIT_READY;
                            bit_cnt <= 0;
                        end
                    end
                end

                WAIT_READY: begin
                    if (ready) begin
                        data_out <= y;
                        state <= SEND_Y;
                    end
                end

                SEND_Y: begin
                    if (!cs && sck_falling) begin
                        miso <= data_out[15 - bit_cnt];
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 15) begin
                            bit_cnt <= 0;
                            state <= IDLE;
                        end
                    end
                end

            endcase
        end
    end

endmodule
