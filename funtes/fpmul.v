// Half-precision (16-bit) floating point multiplier
module fpmul(
    input [15:0] x1,
    input [15:0] x2,
    output [15:0] y,
    input clk,
    input rst,
    input en,
    output ready
    );

// Internal wires/signals declaration    
wire [15:0] reg_a_out,reg_b_out,reg_p_out;
wire p_s;
wire [7:0] p_exp;
wire [7:0] exp_grs;
wire [7:0] p_mant;
wire [10:0] mant_grs;
wire [7:0] adder_out,sub_out;
wire [15:0] mult_out;
wire [15:0] result;
wire [54:0] seg_reg0_out;
wire end1,end2,end3;



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


// Sign of result
assign p_s=reg_a_out[15] ^ reg_b_out[15];

// Adder of exponents
assign adder_out=reg_a_out[14:7]+reg_b_out[14:7];

// Multiplier of mantissas
assign mult_out=$unsigned({1'b1,reg_a_out[6:0]})*$unsigned({1'b1,reg_b_out[6:0]});

// Bias subtractor
assign sub_out=adder_out-8'd127;


// Pipeline register
myreg  #(.N(55)) seg_reg0 (
 .d({p_s,reg_a_out[14:0],reg_b_out[14:0],sub_out,mult_out}),
 .q(seg_reg0_out),
 .clk(clk),
 .en(end1),
 .rst(rst)
);



// Exponent normalizer according to mantissa product
assign exp_grs= (seg_reg0_out[15]==1)?seg_reg0_out[23:16]+8'd1 : seg_reg0_out[23:16];   

// Mantissa normalizer
assign mant_grs=(seg_reg0_out[15]==1)?seg_reg0_out[15:5] : seg_reg0_out[14:4];

// Product rounder using GRS bits    
rounder rounder0 (
    .mant_i(mant_grs),
    .exp_i(exp_grs),
    .mant_o(p_mant),
    .exp_o(p_exp)
    );

// Assign result  
assign result = (seg_reg0_out[53:39]==0) ? {seg_reg0_out[54],15'd0}: // x1 is zero -> result is zero
                (seg_reg0_out[38:24]==0) ? {seg_reg0_out[54],15'd0} : // x2 is zero -> result is zero  
                {seg_reg0_out[54],p_exp,p_mant[6:0]};  // No special case, default result.

// Output register
myreg  #(.N(16)) yreg (
 .d(result),
 .q(reg_p_out),
 .clk(clk),
 .en(end2),
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
.d(end1),
 .q(end2),
 .clk(clk),
 .en(1),
 .rst(rst)
);

myreg #(.N(1)) reg3en(
.d(end2),
 .q(end3),
 .clk(clk),
 .en(1),
 .rst(rst)
);


// Connect register output to module output
assign y=reg_p_out;
assign ready=end3;

endmodule
