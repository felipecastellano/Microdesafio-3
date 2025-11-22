// Half-precision (16-bit) floating point multiplier
module fpdiv(
    input [15:0] x1,
    input [15:0] x2,
    output [15:0] y,
    input clk,
    input rst,
    input en,
    output ready
    );

// Internal wires/signals declaration    
wire [15:0] reg_a_out,reg_b_out,reg_q_out;
wire q_s;
reg [7:0] q_exp;
reg [10:0] q_mant;
wire [7:0] adder_out,sub_out;
wire [11:0] div_out;
wire [15:0] result;
wire end1,end2,done;
wire [7:0]exp_r,mantisa_r;

// Input registers
myreg  #(.N(16)) x1reg (
 .d(x1),
 .q(reg_a_out),
 .clk(clk),
 .en(en),
 .rst(rst)
);

myreg  #(.N(16)) x2reg (
 .d(x2),
 .q(reg_b_out),
 .clk(clk),
 .en(en),
 .rst(rst)
);

// Sign
assign q_s=reg_a_out[15] ^ reg_b_out[15];

// Subtractor of exponents
assign sub_out=reg_a_out[14:7]-reg_b_out[14:7];

// Adder of bias
assign adder_out=sub_out+8'd127;

// Divider of mantissas
fractional_divider #(.N(12)) divider0
                          (.clk(clk),               // Global clock signal
                            .rst(rst),              // Global reset signal
                            .start(end1),            // To start division
                            .dividend({1'b1,reg_a_out[6:0],4'b0000}), // Dividend of the form 1.xxxxxxxx..xx
                            .divisor({1'b1,reg_b_out[6:0],4'b0000}),  // Divisor of the form 1.yyyyyyyy..yy
                            .quotient(div_out),
                            .done(done));



// Exponent and mantissa normalizer
always @(*) begin
if(div_out[11]==1) 
    begin
    q_exp<=adder_out;
    q_mant<=div_out[11:1];
    end 
else 
    begin
    q_exp<=adder_out-8'd1;
    q_mant<=div_out[10:0];
    end
end

// Rounder
rounder rounder0 (
    .mant_i(q_mant),
    .exp_i(q_exp),
    .mant_o(mantisa_r),
    .exp_o(exp_r)

    );


// Assign result  according to first special cases 
assign result = ((reg_a_out[14:0]==0)&&(reg_b_out[14:0]!=0)) ? {q_s,15'd0} : // x1 is zero x2 is not zero -> result is zero
                ((reg_a_out[14:0]!=0)&&(reg_b_out[14:0]==0)) ? {q_s,8'd255,7'd0} : // x1 is not zero x2 is zero -> result is +-infinity   
                ((reg_a_out[14:0]==0)&&(reg_b_out[14:0]==0)) ? 16'b1111111111111111 : // x1 is zero x2 is zero -> result is NaN                                
                {q_s,exp_r,mantisa_r[6:0]};  // No special case, default result.

// Output register
myreg  #(.N(16)) yreg (
 .d(result),
 .q(reg_q_out),
 .clk(clk),
 .en(done),
 .rst(rst)
);

// Registers for enable
myreg #(.N(1)) reg1en(
.d(en),
 .q(end1),
 .clk(clk),
 .en(1),
 .rst(rst)
);

myreg #(.N(1)) reg2en(
.d(done),
 .q(end2),
 .clk(clk),
 .en(1),
 .rst(rst)
);


// Connect register output to module output
assign y=reg_q_out;
assign ready=end2;


endmodule
