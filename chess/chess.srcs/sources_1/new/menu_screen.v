//`timescale 1ns / 1ps

//module menu_screen(
//    input clk,
//    input reset,
//    input [6:0] current_x,
//    input [5:0] current_y,
//    input [2:0] sys_state,
//    input [2:0] seq_progress,
//    input cursor_pos,
//    output reg [15:0] oled_data
//);

//    // Coordinate assignments based on your grid system
    
//    wire [6:0] x = 95 - current_x;
//    wire [5:0] y = 63 - current_y;

//    // Colors (RGB565 format)
//    localparam COLOR_BG     = 16'h0821; // Dark Background
//    localparam COLOR_WHITE  = 16'hFFFF; // White
//    localparam COLOR_GREEN  = 16'h07E0; // Green (Selected)
    
//    // --- Word: CHESS (Placed at Y: 10 to 14) ---
//    wire pixel_CHESS = 
//        // C (Width X: 30-32)
//        ((x == 30 && y >= 10 && y <= 14) || ((y == 10 || y == 14) && x >= 30 && x <= 32)) ||
//        // H (Width X: 34-36)
//        ((x == 34 || x == 36) && y >= 10 && y <= 14) || (y == 12 && x >= 34 && x <= 36) ||
//        // E (Width X: 38-40)
//        ((x == 38) && y >= 10 && y <= 14) || ((y == 10 || y == 12 || y == 14) && x >= 38 && x <= 40) ||
//        // S (Width X: 42-44)
//        ((y == 10 || y == 12 || y == 14) && x >= 42 && x <= 44) || (x == 42 && y >= 10 && y <= 12) || (x == 44 && y >= 12 && y <= 14) ||
//        // S (Width X: 46-48)
//        ((y == 10 || y == 12 || y == 14) && x >= 46 && x <= 48) || (x == 46 && y >= 10 && y <= 12) || (x == 48 && y >= 12 && y <= 14);

//    // --- Word: CLASSIC (Placed at Y: 25 to 29) ---
//    wire pixel_CLASSIC = 
//        // C (Width X: 34-36)
//        ((x == 34 && y >= 25 && y <= 29) || ((y == 25 || y == 29) && x >= 34 && x <= 36)) ||
//        // L (Width X: 38-40)
//        ((x == 38) && y >= 25 && y <= 29) || (y == 29 && x >= 38 && x <= 40) ||
//        // A (Width X: 42-44)
//        ((x == 42 || x == 44) && y >= 25 && y <= 29) || (y == 25 && x >= 42 && x <= 44) || (y == 27 && x >= 42 && x <= 44) ||
//        // S (Width X: 46-48)
//        ((y == 25 || y == 27 || y == 29) && x >= 46 && x <= 48) || (x == 46 && y >= 25 && y <= 27) || (x == 48 && y >= 27 && y <= 29) ||
//        // S (Width X: 50-52)
//        ((y == 25 || y == 27 || y == 29) && x >= 50 && x <= 52) || (x == 50 && y >= 25 && y <= 27) || (x == 52 && y >= 27 && y <= 29) ||
//        // I (Width X: 54-56)
//        ((y == 25 || y == 29) && x >= 54 && x <= 56) || (x == 55 && y >= 25 && y <= 29) ||
//        // C (Width X: 58-60)
//        ((x == 58 && y >= 25 && y <= 29) || ((y == 25 || y == 29) && x >= 58 && x <= 60));

//    // --- Word: BLITZ (Placed at Y: 40 to 44) ---
//    wire pixel_BLITZ = 
//        // B (Width X: 38-40)
//        ((x == 38 || x == 40) && y >= 40 && y <= 44) || ((y == 40 || y == 42 || y == 44) && x >= 38 && x <= 40) ||
//        // L (Width X: 42-44)
//        ((x == 42) && y >= 40 && y <= 44) || (y == 44 && x >= 42 && x <= 44) ||
//        // I (Width X: 46-48)
//        ((y == 40 || y == 44) && x >= 46 && x <= 48) || (x == 47 && y >= 40 && y <= 44) ||
//        // T (Width X: 50-52)
//        (y == 40 && x >= 50 && x <= 52) || (x == 51 && y >= 40 && y <= 44) ||
//        // Z (Width X: 54-56)
//        ((y == 40 || y == 44) && x >= 54 && x <= 56) || (y == 41 && x == 56) || (y == 42 && x == 55) || (y == 43 && x == 54);

//    // Render operations
//    always @(*) begin
//        oled_data = COLOR_BG;
        
//        if (pixel_CHESS) begin
//            oled_data = COLOR_WHITE;
//        end
//        else if (pixel_CLASSIC) begin
//            // Highlight green if Classic is the pointed choice (cursor_pos == 0)
//            oled_data = (cursor_pos == 0) ? COLOR_GREEN : COLOR_WHITE;
//        end
//        else if (pixel_BLITZ) begin
//            // Highlight green if Blitz is the pointed choice (cursor_pos == 1)
//            oled_data = (cursor_pos == 1) ? COLOR_GREEN : COLOR_WHITE;
//        end
//    end

//endmodule


`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: menu_screen
// Description: Mode selection page with chessboard background, CHESS title,
//              CLASSIC and BLITZ options.
//////////////////////////////////////////////////////////////////////////////////

module menu_screen(
    input clk,
    input reset,
    input [6:0] current_x,
    input [5:0] current_y,
    input [2:0] sys_state,
    input [2:0] seq_progress,
    input cursor_pos,
    output reg [15:0] oled_data
);

    wire [6:0] x = 95 - current_x;
    wire [5:0] y = 63 - current_y;

    localparam COLOR_WHITE  = 16'hFFFF;
    localparam COLOR_GREEN  = 16'h07E0;
    localparam COLOR_DARK   = 16'h0000;
    localparam COLOR_GREY   = 16'h2104;

    // --- Chessboard background (16x16 tiles) ---
    wire chess_bg = x[4] ^ y[4];

    // --- CHESS title pixels (y:10-14) ---
    wire pixel_CHESS =
        ((x == 30 && y >= 10 && y <= 14) || ((y == 10 || y == 14) && x >= 30 && x <= 32)) ||
        ((x == 34 || x == 36) && y >= 10 && y <= 14) || (y == 12 && x >= 34 && x <= 36) ||
        ((x == 38) && y >= 10 && y <= 14) || ((y == 10 || y == 12 || y == 14) && x >= 38 && x <= 40) ||
        ((y == 10 || y == 12 || y == 14) && x >= 42 && x <= 44) || (x == 42 && y >= 10 && y <= 12) || (x == 44 && y >= 12 && y <= 14) ||
        ((y == 10 || y == 12 || y == 14) && x >= 46 && x <= 48) || (x == 46 && y >= 10 && y <= 12) || (x == 48 && y >= 12 && y <= 14);

    // --- CLASSIC pixels (y:25-29) ---
    wire pixel_CLASSIC =
        ((x == 34 && y >= 25 && y <= 29) || ((y == 25 || y == 29) && x >= 34 && x <= 36)) ||
        ((x == 38) && y >= 25 && y <= 29) || (y == 29 && x >= 38 && x <= 40) ||
        ((x == 42 || x == 44) && y >= 25 && y <= 29) || (y == 25 && x >= 42 && x <= 44) || (y == 27 && x >= 42 && x <= 44) ||
        ((y == 25 || y == 27 || y == 29) && x >= 46 && x <= 48) || (x == 46 && y >= 25 && y <= 27) || (x == 48 && y >= 27 && y <= 29) ||
        ((y == 25 || y == 27 || y == 29) && x >= 50 && x <= 52) || (x == 50 && y >= 25 && y <= 27) || (x == 52 && y >= 27 && y <= 29) ||
        ((y == 25 || y == 29) && x >= 54 && x <= 56) || (x == 55 && y >= 25 && y <= 29) ||
        ((x == 58 && y >= 25 && y <= 29) || ((y == 25 || y == 29) && x >= 58 && x <= 60));

    // --- BLITZ pixels (y:40-44) ---
    wire pixel_BLITZ =
        ((x == 38 || x == 40) && y >= 40 && y <= 44) || ((y == 40 || y == 42 || y == 44) && x >= 38 && x <= 40) ||
        ((x == 42) && y >= 40 && y <= 44) || (y == 44 && x >= 42 && x <= 44) ||
        ((y == 40 || y == 44) && x >= 46 && x <= 48) || (x == 47 && y >= 40 && y <= 44) ||
        (y == 40 && x >= 50 && x <= 52) || (x == 51 && y >= 40 && y <= 44) ||
        ((y == 40 || y == 44) && x >= 54 && x <= 56) || (y == 41 && x == 56) || (y == 42 && x == 55) || (y == 43 && x == 54);

    always @(*) begin
        // Chessboard background (dimmed)
        oled_data = chess_bg ? COLOR_GREY : COLOR_DARK;

        // CHESS title in white
        if (pixel_CHESS)
            oled_data = COLOR_WHITE;

        // CLASSIC option
        else if (pixel_CLASSIC)
            oled_data = (cursor_pos == 0) ? COLOR_GREEN : COLOR_WHITE;

        // BLITZ option
        else if (pixel_BLITZ)
            oled_data = (cursor_pos == 1) ? COLOR_GREEN : COLOR_WHITE;
    end

endmodule

