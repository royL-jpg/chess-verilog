`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2026 20:13:41
// Design Name: 
// Module Name: history_screen_format
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


module history_screen_format(
    input [12:0] pixel_index,
    input [11:0] w_move_1, w_move_2, w_move_3,
    input [11:0] b_move_1, b_move_2, b_move_3,
    output reg [15:0] oled_data
);
    wire [6:0] xraw = pixel_index % 96;
    wire [5:0] yraw = pixel_index / 96;
    wire [6:0] x = 95 - xraw;
    wire [5:0] y = 63 - yraw;

    // --- Color Palette ---
    localparam COLOR_BG       = 16'h0000; // Black Background
    localparam COLOR_W_TXT    = 16'hFFFF; // White Text
    localparam COLOR_B_TXT    = 16'h07FF; // Cyan Text for Black (shows up well on OLED)
    localparam COLOR_DIVIDER  = 16'h8410; // Gray Line

    // --- Screen Layout ---
    wire is_white_col = (x < 48);
    wire [6:0] base_x = is_white_col ? 7'd2 : 7'd50;
    
    // Determine which row we are drawing based on Y
    reg [5:0] base_y;
    reg [11:0] current_move;
    always @(*) begin
        if (y < 21) begin
            base_y = 6;
            current_move = is_white_col ? w_move_1 : b_move_1;
        end else if (y < 42) begin
            base_y = 26;
            current_move = is_white_col ? w_move_2 : b_move_2;
        end else begin
            base_y = 46;
            current_move = is_white_col ? w_move_3 : b_move_3;
        end
    end

    // --- Coordinate Decoder ---
    wire [2:0] from_rank = current_move[11:9];
    wire [2:0] from_file = current_move[8:6];
    wire [2:0] to_rank   = current_move[5:3];
    wire [2:0] to_file   = current_move[2:0];

    // --- Font Hardware Dictionary (3x5 scale) ---
    function [0:0] get_pixel;
        input [4:0] char;
        input [2:0] px;
        input [2:0] py;
        reg [14:0] bmp;
        begin
            case (char)
                5'd0: bmp = 15'b010_101_111_101_101; // A
                5'd1: bmp = 15'b110_101_110_101_110; // B
                5'd2: bmp = 15'b011_100_100_100_011; // C
                5'd3: bmp = 15'b110_101_101_101_110; // D
                5'd4: bmp = 15'b111_100_110_100_111; // E
                5'd5: bmp = 15'b111_100_110_100_100; // F
                5'd6: bmp = 15'b011_100_101_101_011; // G
                5'd7: bmp = 15'b101_101_111_101_101; // H
                5'd8: bmp = 15'b010_110_010_010_111; // 1
                5'd9: bmp = 15'b110_001_010_100_111; // 2
                5'd10: bmp= 15'b110_001_011_001_110; // 3
                5'd11: bmp= 15'b101_101_111_001_001; // 4
                5'd12: bmp= 15'b111_100_110_001_110; // 5
                5'd13: bmp= 15'b011_100_111_101_011; // 6
                5'd14: bmp= 15'b111_001_010_100_100; // 7
                5'd15: bmp= 15'b011_101_010_101_011; // 8
                5'd16: bmp= 15'b000_000_111_000_000; // -
                5'd17: bmp= 15'b100_010_001_010_100; // >
                default: bmp = 15'b0;
            endcase
            get_pixel = bmp[14 - (py * 3 + px)];
        end
    endfunction

    // --- Render Logic ---
    wire [6:0] dx = x - base_x;
    wire [5:0] dy = y - base_y;
    
    // Scale up by 2 (6x10 pixels per character, 8px advance)
    wire [2:0] char_idx = dx / 8; 
    wire [2:0] px = (dx % 8) / 2;
    wire [2:0] py = dy / 2;

    reg [4:0] active_char;
    always @(*) begin
        case (char_idx)
            0: active_char = from_file;                // File (A-H)
            1: active_char = 8 + (7 - from_rank);      // Rank (1-8)
            2: active_char = 16;                       // '-'
            3: active_char = 17;                       // '>'
            4: active_char = to_file;                  // File (A-H)
            5: active_char = 8 + (7 - to_rank);        // Rank (1-8)
            default: active_char = 31; // Empty
        endcase
    end

    always @(*) begin
        if (x == 48) begin
            oled_data = COLOR_DIVIDER; // Draw center line
        end else if (current_move != 0 && dx < 48 && px < 3 && dy < 10) begin
            if (get_pixel(active_char, px, py))
                oled_data = is_white_col ? COLOR_W_TXT : COLOR_B_TXT;
            else
                oled_data = COLOR_BG;
        end else begin
            oled_data = COLOR_BG;
        end
    end
endmodule
