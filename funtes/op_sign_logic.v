`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2024 15:23:07
// Design Name: 
// Module Name: op_sign_logic
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


module op_sign_logic(
     input [10:0] mantisa_a,
     input [10:0] mantisa_b,
     output reg [11:0] mantisa_r,
     output reg sign_r,
     output reg op_r,
     input add_sub,
     input s_a,
     input s_b

    );
   
   
wire sel;
wire [11:0] sub_r1,sub_r2,add_r1;

assign add_r1={1'b0,mantisa_a} + {1'b0,mantisa_b};
assign sub_r1={1'b0,mantisa_a} - {1'b0,mantisa_b};
assign sub_r2={1'b0,mantisa_b} - {1'b0,mantisa_a};


assign sel = (mantisa_a> mantisa_b)?1:0;
    

always @(*) begin
    case (add_sub) 
        0: begin // suma
            case ({s_a, s_b})
                2'b00: begin // Ambos son positivos
                    sign_r = s_a;
                    mantisa_r = add_r1;
                    op_r=1'b0;
                end
                2'b01: begin // A positivo, B negativo
                    if (sel) begin
                        mantisa_r = sub_r1;
                        sign_r = s_a;
                        op_r=1'b1;
                    end else begin
                        mantisa_r = sub_r2;
                        sign_r = s_b;
                        op_r=1'b1;
                    end
                end
                2'b10: begin // A negativo, B positivo
                    if (sel) begin
                        mantisa_r =sub_r1;
                        sign_r = s_a;
                        op_r=1'b1;
                    end else begin
                        mantisa_r = sub_r2;
                        sign_r = s_b;
                        op_r=1'b1;
                    end
                end
                2'b11: begin // Ambos son negativos
                    mantisa_r = add_r1;
                    op_r=1'b0;
                    sign_r = s_a;
                end
            endcase
        end
        
        default: begin // resta
            case ({s_a, s_b})
                2'b00: begin // Ambos son positivos
                    if (sel) begin
                         mantisa_r =sub_r1;
                        sign_r = s_a;
                        op_r=1'b1;
                    end else begin
                        mantisa_r =sub_r2;
                        sign_r = ~s_b;
                        op_r=1'b1;
                    end
                end
                2'b01: begin // A positivo, B negativo
                   mantisa_r =add_r1;
                    sign_r = s_a;
                    op_r=1'b0;
                end
                2'b10: begin // A negativo, B positivo
                    
                        mantisa_r =add_r1;
                        sign_r = s_a;
                        op_r=1'b0;
                    
                        
                    
                end
                2'b11: begin // Ambos son negativos
                    if (sel) begin
                        mantisa_r =sub_r1;
                        sign_r = s_a;
                        op_r=1'b1;
                    end else begin
                        mantisa_r = sub_r2;
                        sign_r = ~s_b;
                        op_r=1'b1;
                    end
                end
            endcase
        end
    endcase
end

endmodule
