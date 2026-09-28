`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.03.2026 13:43:09
// Design Name: 
// Module Name: cursor
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


module cursor(input rst,clk,turn,btnL,btnR,btnU,btnD,[1:0] sys_state,output [5:0] cur_addr);
    //7th bit for sel_addr to indicate sel enable
    reg [5:0] cur [1:0];
    initial begin
        cur[0] = 60;
        cur[1] = 4;
    end
    wire btnL_trigger,btnR_trigger,btnU_trigger,btnD_trigger,btnC_trigger;
    debounce_btn b1(clk,btnL,btnL_trigger);
    debounce_btn b2(clk,btnR,btnR_trigger);
    debounce_btn b3(clk,btnU,btnU_trigger);
    debounce_btn b4(clk,btnD,btnD_trigger);
    always @(posedge clk,posedge rst) begin
        if(rst) begin
            cur[0] <= 60;
            cur[1] <= 4;
        end
        else begin
            if(sys_state > 2'b01) begin
                if(btnL_trigger) begin
                    cur[turn] <= (cur[turn][2:0] > 0) ? cur[turn] - 1 : cur[turn];
                end
                else if (btnR_trigger) begin
                    cur[turn] <= (cur[turn][2:0] < 7) ? cur[turn] + 1 : cur[turn];
                end
                else if(btnU_trigger) begin
                    cur[turn] <= (cur[turn][5:3] > 0) ? cur[turn] - 8 : cur[turn];
                end
                else if(btnD_trigger) begin
                    cur[turn] <= (cur[turn][5:3] < 7) ? cur[turn] + 8 : cur[turn];
                end
            end
        end
    end
    assign cur_addr = turn ? cur[1] : cur[0];
endmodule
