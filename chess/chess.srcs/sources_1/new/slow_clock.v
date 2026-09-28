`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2026 14:43:03
// Design Name: 
// Module Name: slow_clock
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


module slow_clock #(parameter MAX_COUNT = 50_000_000)(input clk,output reg slow_clk = 0);
    reg [31:0] count = 0;

    always @(posedge clk) begin
        count <= (count == MAX_COUNT - 1 ) ? 0 : count + 1;
        slow_clk <= (count == 0) ? ~slow_clk : slow_clk;
    end
endmodule
