`timescale 1ns / 1ps

// bfloat16 pipelined adder/subtractor

module fp16sum_res_pipe(
    input [15:0] x1,
    input [15:0] x2,
    input clk,
    input rst,
    input add_sub,
    input en,
    output ready,
    output [15:0] y
    );

// Internal signals   
wire [15:0] reg_x1_out,reg_x2_out,result;
wire reg_add_sub_out;
wire [7:0] as_exp,exp_r,exp_r1,exp_r2;
wire [7:0] mantisa_r1,mantisa_r2,mantisa_r;
wire [10:0] mant_x1,mant_x2;
wire [11:0] mantisa_r0;
wire sign_r,op_r;
wire end1,end2,end3,end4;

wire [32:0] seg_reg0_out;
wire [21:0] seg_reg1_out;


// Input registers
myreg  #(.N(16)) x1reg (
 .d(x1),
 .q(reg_x1_out),
 .clk(clk),
 .en(en),
 .rst(rst)
);

myreg  #(.N(16)) x2reg (
 .d(x2),
 .q(reg_x2_out),
 .clk(clk),
 .en(en),
 .rst(rst)
);

myreg  #(.N(1)) reg_add_sub (
 .d(add_sub),
 .q(reg_add_sub_out),
 .clk(clk),
 .en(en),
 .rst(rst)
);

// Exponent computation and input significand preprocessing
exp_mant_logic exp_mant_logic0(
    .a(reg_x1_out),
    .b(reg_x2_out),
    .as_exp(as_exp),
    .mantisa_a(mant_x1),
    .mantisa_b(mant_x2)
);

// First pipeline register
myreg #(.N(33)) seg_reg0(
 .d({reg_x1_out[15],reg_x2_out[15],reg_add_sub_out,as_exp,mant_x1,mant_x2}),
 .q(seg_reg0_out),
 .clk(clk),
 .en(end1),
 .rst(rst)
);

// Compute result sign and result significand
op_sign_logic op_sign_logic0(
     .mantisa_a(seg_reg0_out[21:11]),
     .mantisa_b(seg_reg0_out[10:0]),
     .mantisa_r(mantisa_r0),
     .sign_r(sign_r),
     .op_r(op_r),
     .add_sub(seg_reg0_out[30]),
     .s_a(seg_reg0_out[32]),
     .s_b(seg_reg0_out[31])      
    );
    
// Second pipeline register
myreg #(.N(22)) seg_reg1(
 .d({op_r,sign_r,mantisa_r0,seg_reg0_out[29:22]}),
 .q(seg_reg1_out),
 .clk(clk),
 .en(end2),
 .rst(rst)
);  
    
  
// Leading zero normalization for subtraction
 leading_zero_norm leading_zero_norm0(
    .mantisa(seg_reg1_out[18:8]),
    .exp(seg_reg1_out[7:0]),
    .mantisa_r(mantisa_r1),
    .exp_r(exp_r1)
    );
    
// Mantissa normalization for addition
add_renorm add_renorm0(       
       .mantisa(seg_reg1_out[19:8]),
       .exp(seg_reg1_out[7:0]),
       .mantisa_r(mantisa_r2),
       .exp_r(exp_r2) 
    );
    
 assign mantisa_r=seg_reg1_out[21]?mantisa_r1:mantisa_r2;
 assign exp_r=seg_reg1_out[21]?exp_r1:exp_r2;

 assign result = (mantisa_r==0)?16'd0:{seg_reg1_out[20],exp_r,mantisa_r[6:0]};

// Output register
myreg  #(.N(16)) yreg (
 .d(result),
 .q(y),
 .clk(clk),
 .en(end3),
 .rst(rst)
);


// Pipeline registers for enable
myreg #(.N(1)) reg1en(
.d(en),
 .q(end1),
 .clk(clk),
 .en(1'b1),
 .rst(rst)
);

myreg #(.N(1)) reg2en(
.d(end1),
 .q(end2),
 .clk(clk),
 .en(1'b1),
 .rst(rst)
);

myreg #(.N(1)) reg3en(
.d(end2),
 .q(end3),
 .clk(clk),
 .en(1'b1),
 .rst(rst)
);

myreg #(.N(1)) reg4en(
.d(end3),
 .q(end4),
 .clk(clk),
 .en(1'b1),
 .rst(rst)
);

 
    
 assign ready=end4;   
    
    
 endmodule
