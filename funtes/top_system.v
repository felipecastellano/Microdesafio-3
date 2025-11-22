module top_system(
    input clk, rst,
    input sck, mosi, cs,
    output miso
);

    wire [15:0] x1, x2, y;
    wire en, ready;

    fpmul fpmul_inst (
        .x1(x1),
        .x2(x2),
        .y(y),
        .clk(clk),
        .rst(rst),
        .en(en),
        .ready(ready)
    );

    spi_fpmul_slave spi_slave_inst (
        .clk(clk),
        .rst(rst),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs),
        .x1(x1),
        .x2(x2),
        .y(y),
        .en(en),
        .ready(ready)
    );

endmodule
