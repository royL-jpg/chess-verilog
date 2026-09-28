`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2026 01:20:25
// Design Name: 
// Module Name: scoreboard
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


module scoreboard(
input clk,
input rst,
input capturing,
input [3:0] captured_piece,

output reg [3:0] white_pawn_lost = 0,
output reg [3:0] white_knight_lost = 0,
output reg [3:0] white_bishop_lost = 0,
output reg [3:0] white_rook_lost = 0,
output reg [3:0] white_queen_lost = 0,

output reg [3:0] black_pawn_lost = 0,
output reg [3:0] black_knight_lost = 0,
output reg [3:0] black_bishop_lost = 0,
output reg [3:0] black_rook_lost = 0,
output reg [3:0] black_queen_lost = 0
    );
//game_logic track_piece(track.captured_piece,capturing.capturing);

always @(posedge clk, posedge rst) begin
    if(rst) begin
        white_pawn_lost <= 0;
        white_knight_lost <= 0;
        white_bishop_lost <= 0;
        white_rook_lost <= 0;
        white_queen_lost <= 0;
        
        black_pawn_lost <= 0;
        black_knight_lost <= 0;
        black_bishop_lost <= 0;
        black_rook_lost <= 0;
        black_queen_lost <= 0; 
    end
    else if(capturing) begin
        if (captured_piece ==4'b0_001)begin // white pawn
            white_pawn_lost <= white_pawn_lost + 1;
        end
        if (captured_piece ==4'b0_010)begin // white knight
            white_knight_lost <= white_knight_lost + 1;
        end
        if (captured_piece ==4'b0_011)begin // white bishop
            white_bishop_lost <= white_bishop_lost + 1;
        end
        if (captured_piece ==4'b0_100)begin // white rook
            white_rook_lost <= white_rook_lost + 1;
        end
        if (captured_piece ==4'b0_101)begin // white queen
            white_queen_lost <= white_queen_lost + 1;
        end
        if (captured_piece ==4'b1_001)begin // black pawn
            black_pawn_lost <= black_pawn_lost + 1;
        end
        if (captured_piece ==4'b1_010)begin // black knight
            black_knight_lost <= black_knight_lost + 1;
        end
        if (captured_piece ==4'b1_011)begin // black bishop
            black_bishop_lost <= black_bishop_lost + 1;
        end
        if (captured_piece ==4'b1_100)begin // black rook
            black_rook_lost <= black_rook_lost + 1;
        end
        if (captured_piece ==4'b1_101)begin // black queen
            black_queen_lost <= black_queen_lost + 1;
        end
    end 
end

endmodule
