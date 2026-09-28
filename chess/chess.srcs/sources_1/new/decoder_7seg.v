`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 14:49:26
// Design Name: 
// Module Name: decoder_7seg
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


module decoder_7seg(
input clk, input [3:0] D, output reg [7:0] seg

    );
 always @ (posedge clk)
 begin
 case(D)
  0:seg <= 8'b11000000;
  1:seg <= 8'b11111001;
  2:seg <= 8'b10100100;
  3:seg <= 8'b10110000;
  4:seg <= 8'b10011001;
  5:seg <= 8'b10010010;
  6:seg <= 8'b10000010;
  7:seg <= 8'b11111000;
  8:seg <= 8'b10000000;
  9:seg <= 8'b10010000;
  default:seg <= 8'b11111111;
  endcase
  end
  
endmodule
