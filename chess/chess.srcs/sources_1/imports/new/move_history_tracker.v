`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2026 20:11:28
// Design Name: 
// Module Name: move_history_tracker
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


module move_history_tracker(
    input clk,
    input rst,
    input board_change_en,
    input [3:0] board_change_contents, // To know if we are placing a piece
    input [5:0] sel_tile,              // Where we picked it up
    input [5:0] to_tile,               // Where we put it down
    input turn,
    output reg [11:0] w_move_1, w_move_2, w_move_3,
    output reg [11:0] b_move_1, b_move_2, b_move_3
);
    reg last_turn;
    reg [5:0] latched_from, latched_to;
    reg move_ready;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_move_1 <= 0; w_move_2 <= 0; w_move_3 <= 0;
            b_move_1 <= 0; b_move_2 <= 0; b_move_3 <= 0;
            last_turn <= turn;
            move_ready <= 0;
        end else begin
            // 1. Latch the coordinates ONLY when we place a valid piece
            // (Ignoring the cycle where the old tile is overwritten with 0)
            if (board_change_en && board_change_contents[2:0] != 3'b000) begin
                latched_from <= sel_tile;
                latched_to <= to_tile;
                move_ready <= 1;
            end

            // 2. Push to history ONLY when the turn officially changes
            if (turn != last_turn) begin
                if (move_ready) begin
                    if (last_turn == 0) begin // White just finished
                        w_move_3 <= w_move_2;
                        w_move_2 <= w_move_1;
                        w_move_1 <= {latched_from, latched_to};
                    end else begin            // Black just finished
                        b_move_3 <= b_move_2;
                        b_move_2 <= b_move_1;
                        b_move_1 <= {latched_from, latched_to};
                    end
                    move_ready <= 0; // Reset ready flag
                end
                last_turn <= turn;
            end
        end
    end
endmodule