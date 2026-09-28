//`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////////
//// Module Name: instruction_box
//// Description: Renders the LOCKED menu with a dimmed chessboard background,
////              a "CHESS" title, and a blinking "Unlock" prompt.
////              Corrected for 180-degree physical inversion on Port JA.
////////////////////////////////////////////////////////////////////////////////////

//module instruction_box(
//    input [6:0] x_ja,           // Raw X-coordinate from OLED controller (0-95)
//    input [5:0] y_ja,           // Raw Y-coordinate from OLED controller (0-63)
//    input [2:0] state,          // Progress from TaskB (0 to 5)
//    input pulse_1hz,            // Slow clock signal for blinking text
//    output reg [15:0] pixel_color
//    );

//    // --- HARDWARE CORRECTION: 180-degree flip for JA Port ---
//    // This transforms the raw controller coordinates so the image appears 
//    // upright on a physically upside-down screen.
//    wire [6:0] x = 7'd95 - x_ja;
//    wire [5:0] y = 6'd63 - y_ja;

//    // Colors (RGB565 format)
//    localparam YELLOW = 16'hFFE0;
//    localparam WHITE  = 16'hFFFF;
//    localparam BLACK  = 16'h0000;
//    localparam GREY   = 16'h2104; // Very dim grey for background squares

//    always @(*) begin
//        // 1. BACKGROUND: Dimmed Chessboard Pattern
//        // Logic: XOR the 4th bits of X and Y to create 16x16 pixel squares.
//        if ((x[4] ^ y[4])) 
//            pixel_color = GREY; 
//        else 
//            pixel_color = BLACK;

//        // 2. TITLE: "CHESS" (Static Yellow Box)
//        // Positioned in the upper-middle of the flipped coordinate space.
//        if (y >= 15 && y <= 25 && x >= 30 && x <= 65) begin
//            pixel_color = YELLOW;
//        end

//        // 3. PROMPT: "Unlock to Start" (Blinking White Box)
//        // Logic: Only renders when pulse_1hz is HIGH.
//        if (y >= 35 && y <= 43 && x >= 15 && x <= 80) begin
//            if (pulse_1hz) begin 
//                pixel_color = WHITE;
//            end
//            // Note: If pulse_1hz is LOW, it falls back to the grey/black background.
//        end
        
//        // 4. PROGRESS DOTS: Visual feedback for the TaskB password sequence
//        // Dots appear horizontally across the bottom as 'state' increases.
//        if (y >= 50 && y <= 52) begin
//            // Dot 1: Appears after Center button (State 1)
//            if (x >= 35 && x <= 37 && state >= 1) pixel_color = YELLOW; 
//            // Dot 2: Appears after Left button (State 2)
//            if (x >= 43 && x <= 45 && state >= 2) pixel_color = YELLOW; 
//            // Dot 3: Appears after Right button (State 3)
//            if (x >= 51 && x <= 53 && state >= 4) pixel_color = YELLOW; 
//            // Dot 4: Appears after Up button (State 4)
//            if (x >= 59 && x <= 61 && state >= 4) pixel_color = YELLOW; 
//        end
//    end
//endmodule




`timescale 1ns / 1ps

module instruction_box 
    #(parameter INVERT = 1)
    (input [6:0] x_ja,
    input [5:0] y_ja,
    input [2:0] state,
    input pulse_1hz,
    output reg [15:0] pixel_color
    );

    wire [6:0] x = INVERT ? (7'd95 - x_ja) : x_ja;
    wire [5:0] y = INVERT ? (6'd63 - y_ja) : y_ja;

    localparam YELLOW = 16'hFFE0;
    localparam WHITE  = 16'hFFFF;
    localparam BLACK  = 16'h0000;
    localparam GREY   = 16'h2104;

    // CHESS pixel-art title (y:6-10, x:25-43 using menu_screen style)
    wire pixel_CHESS =
        ((x == 25 && y >= 6 && y <= 10) || ((y == 6 || y == 10) && x >= 25 && x <= 27)) ||
        ((x == 29 || x == 31) && y >= 6 && y <= 10) || (y == 8 && x >= 29 && x <= 31) ||
        ((x == 33) && y >= 6 && y <= 10) || ((y == 6 || y == 8 || y == 10) && x >= 33 && x <= 35) ||
        ((y == 6 || y == 8 || y == 10) && x >= 37 && x <= 39) || (x == 37 && y >= 6 && y <= 8) || (x == 39 && y >= 8 && y <= 10) ||
        ((y == 6 || y == 8 || y == 10) && x >= 41 && x <= 43) || (x == 41 && y >= 6 && y <= 8) || (x == 43 && y >= 8 && y <= 10);

    // White frame border -- ALWAYS VISIBLE (y:22-52, x:4-91, 1px)
    wire frame_border =
        ((y == 22 || y == 52) && x >= 4 && x <= 91) ||
        ((x == 4  || x == 91) && y >= 22 && y <= 52);

    // LINE 1: "PRESS BTNC"  (y:28-32)
    wire px_P  = (y>=28&&y<=32) && ((x==20) || (x==21&&(y==28||y==30)) || (x==22&&y==29));
    wire px_R  = (y>=28&&y<=32) && ((x==24) || (x==25&&(y==28||y==30)) || (x==26&&(y==29||y==31||y==32)));
    wire px_E  = (y>=28&&y<=32) && ((x==28) || (x==29&&(y==28||y==30||y==32)) || (x==30&&(y==28||y==32)));
    wire px_S1 = (y>=28&&y<=32) && ((x==32&&(y==28||y==29||y==30)) || (x==33&&(y==28||y==30||y==32)) || (x==34&&(y==28||y==30||y==31||y==32)));
    wire px_S2 = (y>=28&&y<=32) && ((x==36&&(y==28||y==29||y==30)) || (x==37&&(y==28||y==30||y==32)) || (x==38&&(y==28||y==30||y==31||y==32)));
    wire px_B  = (y>=28&&y<=32) && ((x==42) || (x==43&&(y==28||y==30||y==32)) || (x==44&&(y==29||y==31)));
    wire px_T1 = (y>=28&&y<=32) && ((y==28&&x>=46&&x<=48) || (x==47));
    wire px_N1 = (y>=28&&y<=32) && ((x==50||x==52) || (x==51&&y==28));
    wire px_C1 = (y>=28&&y<=32) && ((x==54&&y>=29&&y<=31) || (x==55&&(y==28||y==32)) || (x==56&&(y==28||y==32)));

    // LINE 2: "TO UNLOCK!"  (y:39-43)
    wire px_T2   = (y>=39&&y<=43) && ((y==39&&x>=24&&x<=26) || (x==25));
    wire px_O1   = (y>=39&&y<=43) && ((x==28||x==30) || (x==29&&(y==39||y==43)));
    wire px_U    = (y>=39&&y<=43) && ((x==34||x==36) || (x==35&&y==43));
    wire px_N2   = (y>=39&&y<=43) && ((x==38||x==40) || (x==39&&y==39));
    wire px_L    = (y>=39&&y<=43) && ((x==42) || (y==43&&x>=42&&x<=44));
    wire px_O2   = (y>=39&&y<=43) && ((x==46||x==48) || (x==47&&(y==39||y==43)));
    wire px_C2   = (y>=39&&y<=43) && ((x==50&&y>=40&&y<=42) || (x==51&&(y==39||y==43)) || (x==52&&(y==39||y==43)));
    wire px_K    = (y>=39&&y<=43) && ((x==54) || (x==55&&y==41) || (x==56&&(y==39||y==40||y==42||y==43)));
    wire px_EXCL = (x==59) && ((y>=39&&y<=41) || y==43);

    wire pixel_text = px_P|px_R|px_E|px_S1|px_S2|px_B|px_T1|px_N1|px_C1|
                      px_T2|px_O1|px_U|px_N2|px_L|px_O2|px_C2|px_K|px_EXCL;

    always @(*) begin
        // 1. Dimmed chessboard background
        pixel_color = (x[4] ^ y[4]) ? GREY : BLACK;

        // 2. CHESS title yellow background
        if (y >= 4 && y <= 12 && x >= 23 && x <= 57)
            pixel_color = YELLOW;

        // 3. CHESS pixel-art letters in black on yellow
        if (pixel_CHESS)
            pixel_color = BLACK;

        // 4. White frame border -- ALWAYS ON
        if (frame_border)
            pixel_color = WHITE;

        // 5. Pulsing text (1 Hz)
        if (pixel_text && pulse_1hz)
            pixel_color = WHITE;

        // 6. Progress dot (single dot for center-only unlock)
        if (y >= 47 && y <= 49 && x >= 45 && x <= 47 && state >= 1)
            pixel_color = YELLOW;
    end
endmodule
