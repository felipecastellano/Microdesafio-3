`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2024 18:09:18
// Design Name: 
// Module Name: add_renorm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module add_renorm(
       input [11:0] mantisa,
       input [7:0] exp,
       output [7:0] mantisa_r,
       output [7:0] exp_r 
    );
    
    
    wire [10:0] mant_i; 
    wire [7:0] exp_i;

   
   //mantisa normalizada desplazamiento derecha
   assign mant_i = mantisa[11] ? mantisa[11:1] : mantisa[10:0];
   assign exp_i = mantisa[11] ? exp + 1 : exp;
   
   // Redondea el resultado de la suma    
rounder rounder0 (
    .mant_i(mant_i),
    .exp_i(exp_i),
    .mant_o(mantisa_r),
    .exp_o(exp_r)

    );
   
    
endmodule
