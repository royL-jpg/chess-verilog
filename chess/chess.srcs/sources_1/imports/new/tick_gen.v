`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.03.2026 14:34:04
// Design Name: 
// Module Name: tick_gen
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


module tick_gen #(parameter MAX_COUNT = 50_000_000)(clk,en);
    input clk;
    output en;
    
    integer count = 0;
    always @(posedge clk) begin
        count <= count + 1;
        if(count == MAX_COUNT) begin
            count <= 0;
        end
    end
    
    assign en = (count == MAX_COUNT) ? 1 : 0;
endmodule
