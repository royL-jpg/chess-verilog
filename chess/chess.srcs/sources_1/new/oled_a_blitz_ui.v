`timescale 1ns / 1ps

// Renders the side panel, turn indicator, and shrinking timer bars
module oled_a_blitz_ui(
    input [6:0] x_ja, 
    input [5:0] y_ja,
    input [8:0] p1_time,
    input [8:0] p2_time,
    input turn_p2,
    input sw15_promo_active,   // sw[15] active on a pawn with assists left
    input promotion_pending,   // timer paused - waiting btnC confirm
    input [1:0] p1_assists_left,
    input [1:0] p2_assists_left,
    input flash_bit,           // ~1.5Hz from main for blinking
    output reg [15:0] pixel_color
    );

    // Coordinate Inversion for JA Port (180 deg flip)
    wire [6:0] x = 7'd95 - x_ja;
    wire [5:0] y = 6'd63 - y_ja;

    // Max width is 64 pixels. Math: Width = (Time / 300) * 64.
//    wire [6:0] p1_bar_w = (p1_time * 109) >> 9;
//    wire [6:0] p2_bar_w = (p2_time * 109) >> 9;

    // Bar width: time/30 * 64px. Approx: (time*137)>>6, capped at 64
    wire [13:0] p1_prod = p1_time * 14'd137;
    wire [13:0] p2_prod = p2_time * 14'd137;
    wire [6:0] p1_bar_w = (p1_prod[13:6] >= 7'd64) ? 7'd64 : p1_prod[13:6];
    wire [6:0] p2_bar_w = (p2_prod[13:6] >= 7'd64) ? 7'd64 : p2_prod[13:6];

    // Colors (RGB565)
    localparam COLOR_GREEN  = 16'h07E0;
    localparam COLOR_ORANGE = 16'hFD20;
    localparam COLOR_GREY   = 16'h4208;
    localparam COLOR_BG     = 16'h0821;
    localparam COLOR_YELLOW = 16'hFFE0;
    localparam COLOR_WHITE  = 16'hFFFF;
    localparam COLOR_RED    = 16'hF800;

    // Assist dots: P1 left side (green), P2 right side (orange)
    wire p1_dot1 = (y>=38 && y<=42 && x>=8  && x<=12) && (p1_assists_left >= 1);
    wire p1_dot2 = (y>=38 && y<=42 && x>=16 && x<=20) && (p1_assists_left >= 2);
    wire p1_dot3 = (y>=38 && y<=42 && x>=24 && x<=28) && (p1_assists_left >= 3);
    wire p1_dot1g = (y>=38 && y<=42 && x>=8  && x<=12) && (p1_assists_left < 1);
    wire p1_dot2g = (y>=38 && y<=42 && x>=16 && x<=20) && (p1_assists_left < 2);
    wire p1_dot3g = (y>=38 && y<=42 && x>=24 && x<=28) && (p1_assists_left < 3);

    wire p2_dot1 = (y>=38 && y<=42 && x>=66 && x<=70) && (p2_assists_left >= 1);
    wire p2_dot2 = (y>=38 && y<=42 && x>=74 && x<=78) && (p2_assists_left >= 2);
    wire p2_dot3 = (y>=38 && y<=42 && x>=82 && x<=86) && (p2_assists_left >= 3);
    wire p2_dot1g = (y>=38 && y<=42 && x>=66 && x<=70) && (p2_assists_left < 1);
    wire p2_dot2g = (y>=38 && y<=42 && x>=74 && x<=78) && (p2_assists_left < 2);
    wire p2_dot3g = (y>=38 && y<=42 && x>=82 && x<=86) && (p2_assists_left < 3);

    // SW15 center indicator (yellow when active, grey otherwise)
    wire sw15_zone = (y>=38 && y<=42 && x>=36 && x<=58);

    // "PRESS C" pixel art at Y:50-54, X:24-53
    wire px_P  = (y>=50&&y<=54) && ((x==24) || ((x==25||x==26)&&(y==50||y==52)) || (x==27&&(y==50||y==51||y==52)));
    wire px_R  = (y>=50&&y<=54) && ((x==29) || ((x==30||x==31)&&(y==50||y==52)) || (x==32&&(y==50||y==51||y==52||y==54)) || (x==31&&y==53));
    wire px_E  = (y>=50&&y<=54) && ((x==34) || ((x==35||x==36||x==37)&&(y==50||y==54)) || ((x==35||x==36)&&y==52));
    wire px_S1 = (y>=50&&y<=54) && (((x==40||x==41||x==42)&&y==50) || (x==39&&y==51) || ((x==40||x==41)&&y==52) || (x==42&&y==53) || ((x==39||x==40||x==41)&&y==54));
    wire px_S2 = (y>=50&&y<=54) && (((x==45||x==46||x==47)&&y==50) || (x==44&&y==51) || ((x==45||x==46)&&y==52) || (x==47&&y==53) || ((x==44||x==45||x==46)&&y==54));
    wire px_C  = (y>=50&&y<=54) && (((x==51||x==52||x==53)&&(y==50||y==54)) || (x==50&&(y==51||y==52||y==53)));
    wire text_press_c = px_P|px_R|px_E|px_S1|px_S2|px_C;

    // "PRESS C" banner background Y:47-57
    wire press_c_banner = (y>=47 && y<=57 && x>=20 && x<=60);
    // Double border effect (issue 2: double confirmness)
    wire press_c_border = ((y==47||y==57) && x>=20 && x<=60) ||
                          ((y==48||y==56) && x>=20 && x<=60) ||
                          ((x==20||x==60) && y>=47 && y<=57) ||
                          ((x==21||x==59) && y>=47 && y<=57);

    always @(*) begin
        pixel_color = COLOR_BG; 

        // P1 Timer Bar (Green, Top) -> Y: 20 to 25, X: 10 to 74
        if (y >= 20 && y <= 25 && x >= 10 && x < 74) begin
            if (x - 10 < p1_bar_w) pixel_color = COLOR_GREEN;
            else pixel_color = COLOR_GREY;
        end
        // P2 Timer Bar (Orange, Bottom) -> Y: 30 to 35, X: 10 to 74
        else if (y >= 30 && y <= 35 && x >= 10 && x < 74) begin
            if (x - 10 < p2_bar_w) pixel_color = COLOR_ORANGE;
            else pixel_color = COLOR_GREY;
        end
        // Turn Indicator Box -> Y: 5 to 15, X: 10 to 25
        else if (y >= 5 && y <= 15 && x >= 10 && x <= 25) begin
            pixel_color = turn_p2 ? COLOR_ORANGE : COLOR_GREEN;
        end
        
        
        //Assist dots row 
        else if (p1_dot1 || p1_dot2 || p1_dot3) pixel_color = COLOR_GREEN;
        else if (p1_dot1g || p1_dot2g || p1_dot3g) pixel_color = COLOR_GREY;
        else if (p2_dot1 || p2_dot2 || p2_dot3) pixel_color = COLOR_ORANGE;
        else if (p2_dot1g || p2_dot2g || p2_dot3g) pixel_color = COLOR_GREY;

        // SW15 center indicator 
        else if (sw15_zone) begin
            pixel_color = sw15_promo_active ? COLOR_YELLOW : COLOR_GREY;
        end

        // "PRESS C" confirmation banner (promotion_pending) 
        if (promotion_pending) begin
            if (press_c_border)
                pixel_color = COLOR_WHITE;
            else if (press_c_banner)
                pixel_color = flash_bit ? COLOR_YELLOW : COLOR_RED;
            if (press_c_banner && text_press_c)
                pixel_color = COLOR_WHITE;
        end        
    end
endmodule