`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.03.2026 07:08:28
// Design Name: 
// Module Name: legal_move_fsm
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

module legal_move_fsm(
    input rst,
    input clk,
    input start,               // Pulse this when a piece is selected
    input [3:0] selected_p,    // The piece type/color
    input [5:0] start_tile,    // sx, sy combined
    input [255:0] board_flat,  // The board state
    input white_king_moved,
    input black_king_moved,
    input white_rook_left_moved,
    input white_rook_right_moved,
    input black_rook_left_moved,
    input black_rook_right_moved,
    output reg [63:0] legal_mask,
    output reg done,
    output reg check
);
    reg [5:0] current_tile;
    reg [2:0] state=0;
    
    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT = 3'b010;
    localparam PIECE_BISHOP = 3'b011;
    localparam PIECE_ROOK   = 3'b100;
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;
    // Internal signals for the current tile being checked
    wire [2:0] sx = start_tile[2:0];
    wire [2:0] sy = start_tile[5:3];
    wire [2:0] dx = current_tile[2:0];
    wire [2:0] dy = current_tile[5:3];
    reg [3:0] target_p;
    reg is_rook_move,is_bish_move;
    reg move_possible;
    // Logic for the sliding piece ray-cast (only 1 set of hardware now!)
    reg path_blocked;
    integer step;
    integer temp_x, temp_y, dist, step_x, step_y;
    // ... (logic for step_x, step_y, dist based on sx,sy and dx,dy) ...
    
    localparam IDLE = 0,CLEAR_CHECK = 1 ,CHECKING = 2, FINISH = 3;
    function [2:0] abs_diff(input [2:0] a, b);
        abs_diff = (a > b) ? (a - b) : (b - a);
    endfunction
    always @(posedge clk,posedge rst) begin
        if(rst) begin
            state <= 0;
            current_tile <= 0;
            done <= 0;
            check <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        legal_mask <= 64'b0;
                        current_tile <= 0;
                        state <= CLEAR_CHECK;
                    end
                end
                CLEAR_CHECK: begin
                    check <= 0;
                    state <= CHECKING;
                end
                CHECKING: begin
                    // 1. Initial Reset for this specific tile
                    move_possible = 0;
                    path_blocked = 0; // Use = so it's immediate
                    target_p = board_flat[current_tile*4 +: 4];                  
                    // Default to illegal until proven otherwise
                    // Rule 1: Cannot capture your own color
                    if (target_p != 0 && target_p[3] == selected_p[3]) begin
                        move_possible = 0;
                    end
                    else begin  
                        case (selected_p[2:0])
                            PIECE_KNIGHT: begin
                                if ((abs_diff(sx,dx)==1 && abs_diff(sy,dy)==2) || (abs_diff(sx,dx)==2 && abs_diff(sy,dy)==1))
                                    move_possible = 1;
                            end
                            
                            PIECE_KING: begin
                                if (abs_diff(sx,dx) <= 1 && abs_diff(sy,dy) <= 1 && current_tile != start_tile) move_possible = 1;
                                if (selected_p[3] == 0 && start_tile == 6'b111_100) begin
                                        // White king-side: e1 -> g1
                                        if (current_tile == 6'b111_110 &&
                                            !white_king_moved &&
                                            !white_rook_right_moved &&
                                            board_flat[(6'b111_101)*4 +: 4] == 0 &&
                                            board_flat[(6'b111_110)*4 +: 4] == 0 &&
                                            board_flat[(6'b111_111)*4 +: 4] == 4'b0_100)
                                            move_possible = 1;
                                
                                        // White queen-side: e1 -> c1
                                        if (current_tile == 6'b111_010 &&
                                            !white_king_moved &&
                                            !white_rook_left_moved &&
                                            board_flat[(6'b111_001)*4 +: 4] == 0 &&
                                            board_flat[(6'b111_010)*4 +: 4] == 0 &&
                                            board_flat[(6'b111_011)*4 +: 4] == 0 &&
                                            board_flat[(6'b111_000)*4 +: 4] == 4'b0_100)
                                            move_possible = 1;
                                    end
                                
                                    // Black castling
                                    if (selected_p[3] == 1 && start_tile == 6'b000_100) begin
                                        // Black king-side: e8 -> g8
                                        if (current_tile == 6'b000_110 &&
                                            !black_king_moved &&
                                            !black_rook_right_moved &&
                                            board_flat[(6'b000_101)*4 +: 4] == 0 &&
                                            board_flat[(6'b000_110)*4 +: 4] == 0 &&
                                            board_flat[(6'b000_111)*4 +: 4] == 4'b1_100)
                                            move_possible = 1;
                                
                                        // Black queen-side: e8 -> c8
                                        if (current_tile == 6'b000_010 &&
                                            !black_king_moved &&
                                            !black_rook_left_moved &&
                                            board_flat[(6'b000_001)*4 +: 4] == 0 &&
                                            board_flat[(6'b000_010)*4 +: 4] == 0 &&
                                            board_flat[(6'b000_011)*4 +: 4] == 0 &&
                                            board_flat[(6'b000_000)*4 +: 4] == 4'b1_100)
                                            move_possible = 1;
                                    end
                            end
                
                            PIECE_PAWN: begin
                                // Note: Using = here ensures conditions are checked correctly
                                if (selected_p[3] == 0) begin // White
                                    if (dx == sx && dy == sy - 1 && target_p == 0) move_possible = 1;
                                    else if (dx == sx && dy == sy - 2 && sy == 6 && target_p == 0 && board_flat[(40+sx)*4 +: 4] == 0) move_possible = 1;
                                    else if (abs_diff(dx,sx) == 1 && dy == sy - 1 && target_p != 0) move_possible = 1;
                                end else begin // Black
                                    if (dx == sx && dy == sy + 1 && target_p == 0) move_possible = 1;
                                    else if (dx == sx && dy == sy + 2 && sy == 1 && target_p == 0 && board_flat[(16+sx)*4 +: 4] == 0) move_possible = 1;
                                    else if (abs_diff(dx,sx) == 1 && dy == sy + 1 && target_p != 0) move_possible = 1;
                                end
                            end
                
                            PIECE_ROOK, PIECE_BISHOP, PIECE_QUEEN: begin
                                is_rook_move = (sx == dx || sy == dy);
                                is_bish_move = (abs_diff(sx,dx) == abs_diff(sy,dy));
                                
                                if ((selected_p[2:0] == PIECE_ROOK && is_rook_move) ||
                                    (selected_p[2:0] == PIECE_BISHOP && is_bish_move) ||
                                    (selected_p[2:0] == PIECE_QUEEN && (is_rook_move || is_bish_move))) begin
                                    
                                    // RAY-CASTING (Use blocking = for immediate loop logic)
                                    step_x = (dx > sx) ? 1 : (dx < sx ? -1 : 0);
                                    step_y = (dy > sy) ? 1 : (dy < sy ? -1 : 0);
                                    dist = (abs_diff(sx,dx) > abs_diff(sy,dy)) ? abs_diff(sx,dx) : abs_diff(sy,dy);
                                    
                                    for (step = 1; step < 8; step = step + 1) begin
                                        if (step < dist) begin
                                            // We calculate temp coords using blocking assignments
                                            temp_x = sx + (step * step_x);
                                            temp_y = sy + (step * step_y);
                                            if (board_flat[(temp_y*8 + temp_x)*4 +: 4] != 0) 
                                                path_blocked = 1; 
                                        end
                                    end
                                    
                                    if (!path_blocked && current_tile != start_tile) 
                                        move_possible = 1 ;
                                end
                            end
                        endcase
                    end
                    if (current_tile != start_tile) begin
                        if(move_possible & target_p[3] != selected_p[3] & target_p[2:0]==PIECE_KING) check <= 1;
                        legal_mask[current_tile] <= move_possible;
                    end
                
                    // Move to next tile logic
                    if (current_tile == 63) begin
                        state <= FINISH;
                    end else begin
                        current_tile <= current_tile + 1;
                    end
                end
                    
    
                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule