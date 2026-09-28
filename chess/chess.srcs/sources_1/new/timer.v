`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 15:17:08
// Design Name: 
// Module Name: timer
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


//module timer(
//    input clk,
//    input rst,
//    input [2:0] set, // Ignored to remove dependency on switches
//    input turn,
//    output reg [3:0] second1=3,
//    output reg [3:0] second2=0,
//    output reg [3:0] tenth=0,
//    output reg [3:0] hundreth=0
//);
//    wire clk100hz;
//    reg reset_flag = 0;
//    slow_clock #(.MAX_COUNT(500000)) clock1(clk, clk100hz);
//    reg prev_turn = 0;

//    always @(posedge clk100hz, posedge rst) begin
//        if(rst) begin
//           reset_flag <= 1;    
//        end
//        else begin
//            // Stop counting if it hits 00:00 to prevent rolling over to 99:99
//            if (second1 == 0 && second2 == 0 && tenth == 0 && hundreth == 0) begin
//                // Hold at zero
//            end else begin
//                // Normal countdown execution
//                hundreth <= (hundreth > 0) ? hundreth - 1 : 9;
//                tenth <= (hundreth == 0) ? ((tenth > 0) ? tenth - 1 : 9) : tenth;
//                second2 <= (tenth == 0 && hundreth == 0) ? ((second2 > 0) ? second2 - 1 : 9) : second2;                         
//                second1 <= (second2 == 0 && tenth == 0 && hundreth == 0) ? ((second1 > 0) ? second1 - 1 : 9) : second1; 
//            end
            
//            // Hardcoded reset to 30.00s when turn changes or reset is pressed
//            if(turn != prev_turn || reset_flag) begin
//                reset_flag <= 0;
//                hundreth <= 0;
//                tenth <= 0;
//                second2 <= 0; // Ones digit = 0
//                second1 <= 3; // Tens digit = 3
//            end
            
//            prev_turn <= turn;
//        end
//    end
//endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2026 15:17:08
// Design Name: 
// Module Name: timer
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


module timer(input clk,input rst,input [2:0] set,input turn,input game_over,output reg [3:0] second1=3,reg [3:0] second2=0,reg [3:0] tenth=0,reg [3:0] hundreth=0);
    wire clk100hz;
    reg reset_flag = 0;
    reg [2:0] prev_set = 0;
    slow_clock #(.MAX_COUNT(500000)) clock1(clk,clk100hz);
    reg prev_turn = 0;
    always @(posedge clk100hz,posedge rst) begin
        if(rst) begin
           reset_flag <= 1;    
        end
        else begin
            if(~game_over) begin
                if(~set[2]) begin
                    hundreth <= (hundreth>0) ? hundreth - 1 : 9;
                    tenth <= (hundreth == 0) ? (tenth > 0) ? tenth - 1 : 9
                                              : tenth;
                    second2 <= (tenth == 0) ? ((hundreth == 0) ? ((second2 > 0) ? second2 - 1 : 9): second2) : second2;                         
                    second1 <= (second2 == 0) ? ((tenth == 0) ? ((hundreth == 0) ? ((second1 > 0) ? second1 - 1 : 9): second1) : second1) : second1; 
                end  
                if(turn != prev_turn || prev_set != set || reset_flag) begin
                    reset_flag <= 0;
                    prev_set <= set;
                    prev_turn <= turn;
                    hundreth <= set[2] ? 9 : 0;
                    tenth <= set[2] ? 9 : 0;
                    second2 <= set[2] ? 9 :
                               set[1] ? 0 : 
                               set[0] ? 5 : 0;
                    second1 <= set[2] ? 9 :
                               set[1] ? 6 : 
                               set[0] ? 4 : 3;
                end
            end
            else begin
                second1 <= 8;
                second2 <= 8;
                tenth <= 8;
                hundreth <= 8;
            end
        end
    end
endmodule
