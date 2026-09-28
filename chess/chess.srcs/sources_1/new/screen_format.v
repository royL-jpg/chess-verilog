

`timescale 1ns / 1ps

module screen_format(BOARD,sel_en,sel_tile,cur_tile,legal_moves,x,y,check,turn,game_over,oled_data,
white_pawn_lost,
white_knight_lost,
white_bishop_lost,
white_rook_lost,
white_queen_lost,
black_pawn_lost,
black_knight_lost,
black_bishop_lost,
black_rook_lost,
black_queen_lost);
    input [255:0] BOARD;
    input sel_en;
    input [5:0] sel_tile;
    input [5:0] cur_tile;
    input [63:0] legal_moves;
    input [6:0] x;
    input [5:0] y;
    input check;
    input turn;
    input game_over;
    output reg [15:0] oled_data;
    input [3:0] white_pawn_lost;
    input [3:0] white_knight_lost;
    input [3:0] white_bishop_lost;
    input [3:0] white_rook_lost;
    input [3:0] white_queen_lost;
    input [3:0] black_pawn_lost;
    input [3:0] black_knight_lost;
    input [3:0] black_bishop_lost;
    input [3:0] black_rook_lost;
    input [3:0] black_queen_lost;
    
    wire [3:0] board [63:0];
    wire [3:0] x_local;
    wire [2:0] y_local;
    wire [3:0] x_col;
    wire [2:0] y_row;  
    assign x_col = x[6:3];
    assign y_row = y[5:3];
    
    // Scoreboard area definitions
    wire board_area = (x < 64);
    
    wire [6:0] score_x = x - 7'd64;   // 0..31
    wire entry_col = score_x[4];      // 0 = left column, 1 = right column
    wire [3:0] entry_x = score_x[3:0]; // 0..15 inside one entry
    
    wire [2:0] bot_row = y_row - 3'd5;
    wire [5:0] score_local_tile = y_local * 8 + entry_x[2:0];
    
    reg [2:0] score_piece_type;
    reg [3:0] score_count;
    reg score_piece_pixel;
    reg [15:0] score_piece_color;
    wire [2:0] num_x = entry_x - 8;
    wire [5:0] num_tile = y_local * 8 + num_x;
    reg num_pixel;
    reg score_enable;
    
    assign x_local = x[2:0];
    assign y_local = y[2:0];
    
    genvar i;
    generate for (i=0; i<64; i=i+1) begin: REWIRE_BOARD
        assign board[i] = BOARD[i*4+3 : i*4];
    end
    endgenerate
    
    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT = 3'b010;
    localparam PIECE_BISHOP = 3'b011;
    localparam PIECE_ROOK   = 3'b100;
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;
    
    localparam COLOR_WHITE  = 0;
    localparam COLOR_BLACK  = 1;
    
    // ARTWORK
    localparam [0:63] pawnArt  = {
        8'b00000000,
        8'b00000000,
        8'b00000000,
        8'b00000000,
        8'b00011000,
        8'b00111100,
        8'b01111110,
        8'b01111110
    };
    
    localparam [0:63] bishopArt  = {
        8'b00000000,
        8'b00011000,
        8'b00111100,
        8'b00111100,
        8'b00011000,
        8'b00011000,
        8'b00111100,
        8'b11100111
    };
    
    localparam [0:63] knightArt = { 
        8'b00011000,
        8'b01111100,
        8'b11111110,
        8'b11101111,
        8'b00000111,
        8'b00011111,
        8'b00111111,
        8'b01111110
    };
    
    localparam [0:63] queenArt = { 
        8'b00000000,
        8'b01010101,
        8'b01010101,
        8'b01010101,
        8'b01010101,
        8'b01111111,
        8'b01111111,
        8'b01111111
    };
    
    localparam [0:63] kingArt = { 
        8'b00011000,
        8'b01111110,
        8'b00011000,
        8'b00011000,
        8'b00111100,
        8'b01111110,
        8'b01111110,
        8'b00111100
    };
    
    localparam [0:63] rookArt  = { 
        8'b00000000,
        8'b01011010,
        8'b01111110,
        8'b00111100,
        8'b00011000,
        8'b00011000,
        8'b00111100,
        8'b01111110
    };
    
    localparam [0:63] zero = {
        8'b00111100,
        8'b01100110,
        8'b01101110,
        8'b01110110,
        8'b01100110,
        8'b01100110,
        8'b00111100,
        8'b00000000
    };
    
    localparam [0:63] one = {
        8'b00011000,
        8'b00111000,
        8'b00011000,
        8'b00011000,
        8'b00011000,
        8'b00011000,
        8'b00111100,
        8'b00000000
    };
    
    localparam [0:63] two = {
        8'b00111100,
        8'b01100110,
        8'b00000110,
        8'b00001100,
        8'b00011000,
        8'b00110000,
        8'b01111110,
        8'b00000000
    };
    
    localparam [0:63] three = {
        8'b00111100,
        8'b01100110,
        8'b00000110,
        8'b00011100,
        8'b00000110,
        8'b01100110,
        8'b00111100,
        8'b00000000
    };
    
    localparam [0:63] four = {
        8'b00001100,
        8'b00011100,
        8'b00101100,
        8'b01001100,
        8'b01111110,
        8'b00001100,
        8'b00011110,
        8'b00000000
    };
    
    localparam [0:63] five = {
        8'b01111110,
        8'b01100000,
        8'b01111100,
        8'b00000110,
        8'b00000110,
        8'b01100110,
        8'b00111100,
        8'b00000000
    };
    
    localparam [0:63] six = {
        8'b00111100,
        8'b01100110,
        8'b01100000,
        8'b01111100,
        8'b01100110,
        8'b01100110,
        8'b00111100,
        8'b00000000
    };
    
    localparam [0:63] seven = {
        8'b01111110,
        8'b01100110,
        8'b00000110,
        8'b00001100,
        8'b00011000,
        8'b00011000,
        8'b00011000,
        8'b00000000
    };
    
    localparam [0:63] eight = {
        8'b00111100,
        8'b01100110,
        8'b01100110,
        8'b00111100,
        8'b01100110,
        8'b01100110,
        8'b00111100,
        8'b00000000
    };
   
    localparam RGB_OUTSIDE = 0;   // outside the drawn board
    localparam RGB_DARK_SQ = 16'h0;   // color of the dark squares
    localparam RGB_LIGHT_SQ = 16'hFFFF; // color of the light squares
    localparam RGB_BLACK_PIECE = 16'hF800; // color of the black player's pieces
    localparam RGB_WHITE_PIECE = 16'h07C0; // color of the white player's pieces
    localparam RGB_CURSOR = 16'hFE80; // color of the squares' outline that shows the cursor
    localparam RGB_SELECTED = 16'h001F; // color of the outline showing which piece is selected 
    localparam RGB_LEGAL = 16'h0500; // A dark green for legal move tiles
    localparam RGB_CHECK = 16'hFD20; // Orange
    
    wire dark_square = y_row[0] ^ x_col[0];
    wire [5:0] tile = y_row*8 + x_col; 
    wire [5:0] local_tile = y_local*8 + x_local; 
    reg [15:0] base_sq_color;
    reg piece_pixel;

//    // --- GAME OVER pixel art wires ---
//    wire [3:0] go_kx = (x >= 40 && x <= 55) ? ((x - 7'd40) >> 1) : 4'd0;
//    wire [2:0] go_ky = (y >= 20 && y <= 35) ? ((y - 6'd20) >> 1) : 3'd0;
//    wire [5:0] go_kt = go_ky * 6'd8 + {2'b00, go_kx};
//    wire go_king_pixel = (x >= 7'd40 && x <= 7'd55 && y >= 6'd20 && y <= 6'd35) && kingArt[go_kt];

//    wire go_W  = (y>=44&&y<=48) && (((x==30||x==32)&&y<=47) || (x==31&&y==48));
//    wire go_I  = ((x==35&&y>=44&&y<=48) || ((y==44||y==48)&&x>=34&&x<=36));
//    wire go_N  = (y>=44&&y<=48) && ((x==37||x==39) || (x==38&&y==44));
//    wire go_S  = (y>=44&&y<=48) && (
//                   (x==41&&(y==44||y==45||y==46)) ||
//                   (x==42&&(y==44||y==46||y==48)) ||
//                   (x==43&&(y==44||y==46||y==47||y==48)));
//    wire go_EX = (x==46) && ((y>=44&&y<=46) || y==48);
//    wire go_wins_pixel = go_W | go_I | go_N | go_S | go_EX;

//    wire go_label_W = (!turn) && (y>=13&&y<=17) && (
//                        ((x==44||x==50)&&y<=16) ||
//                        (x==47&&y==17) ||
//                        ((x==46||x==48)&&y==16));
//    wire go_label_B = (turn) && (y>=13&&y<=17) && (
//                        (x==44) ||
//                        (x==45&&(y==13||y==15||y==17)) ||
//                        (x==46&&(y==14||y==16)));
//    wire go_label_pixel = go_label_W | go_label_B;
    // =========================================================================
    // GAME OVER OVERLAY WIRES (Synthesizable Block Graphics)
    // =========================================================================
    
    // 1. King Art (Moved slightly up to make room for huge text: y = 10 to 26)
    wire in_go_king_box  = (x >= 40 && x < 56) && (y >= 10 && y < 26);
    wire [2:0] go_king_x = (x - 40) >> 1;
    wire [2:0] go_king_y = (y - 10) >> 1;
    wire go_king_pixel   = kingArt[{go_king_y, go_king_x}];

    // 2. Background Graphics (8x8 Checkerboard + Border)
    wire go_checker = x[3] ^ y[3]; 
    wire go_border  = (x < 2 || x > 93 || y < 2 || y > 61);

    // 3. Massive Arcade Letters for "P1 WIN" and "P2 WIN" (Height: 20 pixels)
    // Letter P (x: 6 to 18)
    wire go_P = ((x>=6 && x<=9) && (y>=35 && y<=55)) || 
                ((x>=10 && x<=18) && (y>=35 && y<=38 || y>=43 && y<=46)) || 
                ((x>=15 && x<=18) && (y>=39 && y<=42));
                
    // Letter 1 (x: 22 to 34)
    wire go_1 = ((x>=26 && x<=29) && (y>=35 && y<=55)) || 
                ((x>=22 && x<=33) && (y>=52 && y<=55)) || 
                ((x>=22 && x<=25) && (y>=35 && y<=38));
                
    // Letter 2 (x: 22 to 34)
    wire go_2 = ((x>=22 && x<=34) && (y>=35 && y<=38 || y>=43 && y<=46 || y>=52 && y<=55)) || 
                ((x>=31 && x<=34) && (y>=39 && y<=42)) || 
                ((x>=22 && x<=25) && (y>=47 && y<=51));
                
    // Letter W (x: 42 to 58)
    wire go_W = ((x>=42 && x<=45) && (y>=35 && y<=55)) || 
                ((x>=55 && x<=58) && (y>=35 && y<=55)) || 
                ((x>=48 && x<=52) && (y>=46 && y<=55));
                
    // Letter I (x: 64 to 67)
    wire go_I = ((x>=64 && x<=67) && (y>=35 && y<=55));
    
    // Letter N (x: 74 to 88)
    wire go_N = ((x>=74 && x<=77) && (y>=35 && y<=55)) || 
                ((x>=85 && x<=88) && (y>=35 && y<=55)) || 
                ((x>=78 && x<=80) && (y>=40 && y<=46)) || 
                ((x>=81 && x<=84) && (y>=47 && y<=53));
    
    
    
    always @(*) begin
        score_enable = 0;
        piece_pixel = 0;
        base_sq_color = RGB_OUTSIDE;
        oled_data = RGB_OUTSIDE;
        num_pixel = 0;
        score_piece_pixel = 0;
        score_piece_type = PIECE_NONE;
        score_count = 0;
        score_piece_color = RGB_OUTSIDE;
        
        if(game_over == 0) begin
            if (board_area) begin
                if (legal_moves[tile] && sel_en) begin
                    base_sq_color = RGB_LEGAL; // Highlight square if it's a legal move
                end else if(check && board[tile][2:0] == PIECE_KING && board[tile][3] == turn) begin
                    base_sq_color = RGB_CHECK;
                end
                else begin
                    base_sq_color = dark_square ? RGB_DARK_SQ : RGB_LIGHT_SQ;
                end
                case(board[tile][2:0])
                    PIECE_PAWN:   piece_pixel = pawnArt[local_tile];
                    PIECE_KNIGHT: piece_pixel = knightArt[local_tile];
                    PIECE_BISHOP: piece_pixel = bishopArt[local_tile];
                    PIECE_ROOK:   piece_pixel = rookArt[local_tile];
                    PIECE_QUEEN:  piece_pixel = queenArt[local_tile];
                    PIECE_KING:   piece_pixel = kingArt[local_tile];
                    default:      piece_pixel = 0;
                endcase
        
                // --- 3. Final Color Assembly ---
                if (x_col < 8) begin
                    if (piece_pixel) begin
                        // Draw the piece color
                        oled_data = (board[tile][3] == COLOR_BLACK) ? RGB_BLACK_PIECE : RGB_WHITE_PIECE;
                    end else begin
                        // Draw the background square color
                        oled_data = base_sq_color;
                    end
        
                    // --- 4. Cursor Overlay (Border) ---
                    if (x_local == 0 || y_local == 0 || x_local == 7 || y_local == 7) begin
                        if (sel_en && sel_tile[5:0] == tile) begin
                            oled_data = RGB_SELECTED;
                        end
                        else if (cur_tile[5:0] == tile) begin
                            oled_data = RGB_CURSOR;
                        end
                    end
                end
            end
            else begin
                // scoreboard background
                oled_data = 16'h2104;
    
                // TOP RIGHT: black has eaten white pieces
                if (y_row <= 2) begin
                    score_piece_color = RGB_WHITE_PIECE;
                
                    case ({y_row, entry_col})
                        4'b0000: begin score_enable = 1; score_piece_type = PIECE_PAWN;   score_count = white_pawn_lost;   end
                        4'b0001: begin score_enable = 1; score_piece_type = PIECE_ROOK;   score_count = white_rook_lost;   end
                        4'b0010: begin score_enable = 1; score_piece_type = PIECE_KNIGHT; score_count = white_knight_lost; end
                        4'b0011: begin score_enable = 1; score_piece_type = PIECE_BISHOP; score_count = white_bishop_lost; end
                        4'b0100: begin score_enable = 1; score_piece_type = PIECE_QUEEN;  score_count = white_queen_lost;  end
                        default: begin
                            score_enable = 0;
                            score_piece_type = PIECE_NONE;
                            score_count = 0;
                        end
                    endcase
                end
    
                // BOTTOM RIGHT: white has eaten black pieces
                else if (y_row >= 5) begin
                    score_piece_color = RGB_BLACK_PIECE;
                
                    case ({bot_row, entry_col})
                        4'b0000: begin score_enable = 1; score_piece_type = PIECE_PAWN;   score_count = black_pawn_lost;   end
                        4'b0001: begin score_enable = 1; score_piece_type = PIECE_ROOK;   score_count = black_rook_lost;   end
                        4'b0010: begin score_enable = 1; score_piece_type = PIECE_KNIGHT; score_count = black_knight_lost; end
                        4'b0011: begin score_enable = 1; score_piece_type = PIECE_BISHOP; score_count = black_bishop_lost; end
                        4'b0100: begin score_enable = 1; score_piece_type = PIECE_QUEEN;  score_count = black_queen_lost;  end
                        default: begin
                            score_enable = 0;
                            score_piece_type = PIECE_NONE;
                            score_count = 0;
                        end
                    endcase
                end
    
                // LEFT HALF OF ENTRY: piece icon
                if (entry_x < 8) begin
                    if (score_enable) begin
                        case (score_piece_type)
                            PIECE_PAWN:   score_piece_pixel = pawnArt[score_local_tile];
                            PIECE_KNIGHT: score_piece_pixel = knightArt[score_local_tile];
                            PIECE_BISHOP: score_piece_pixel = bishopArt[score_local_tile];
                            PIECE_ROOK:   score_piece_pixel = rookArt[score_local_tile];
                            PIECE_QUEEN:  score_piece_pixel = queenArt[score_local_tile];
                            default:      score_piece_pixel = 0;
                        endcase
                
                        if (score_piece_pixel && score_enable)
                            oled_data = score_piece_color;
                    end
                end
    
                // RIGHT HALF OF ENTRY: number bitmap
                else begin
                    if (score_enable) begin
                        case (score_count)
                            4'd0: num_pixel = zero[num_tile];
                            4'd1: num_pixel = one[num_tile];
                            4'd2: num_pixel = two[num_tile];
                            4'd3: num_pixel = three[num_tile];
                            4'd4: num_pixel = four[num_tile];
                            4'd5: num_pixel = five[num_tile];
                            4'd6: num_pixel = six[num_tile];
                            4'd7: num_pixel = seven[num_tile];
                            4'd8: num_pixel = eight[num_tile];
                            default: num_pixel = 0;
                        endcase
                
                        if (num_pixel && score_enable)
                            oled_data = score_piece_color;
                    end
                end
                
                // Turn Indicator (dead space between lists)
                if(y_row > 2 && y_row < 5 && x_col > 8 && x_col < 11) begin
                    oled_data = turn ? RGB_BLACK_PIECE : RGB_WHITE_PIECE;
                end
            end
        end
        else begin
            // GAME OVER SCREEN 
            // 1. Draw Background (Border -> Checkerboard -> Black)
            if (go_border)
                oled_data = 16'hFFFF; // White Border
            else if (go_checker)
                oled_data = 16'h2104; // Matte Grey Tile
            else
                oled_data = 16'h0000; // Black Tile

            // 2. Draw King icon (Kept your exact color logic implementation)
            if (in_go_king_box && go_king_pixel)
                oled_data = turn ? RGB_BLACK_PIECE : RGB_WHITE_PIECE;

            // 3. Draw Huge "P1 WIN" or "P2 WIN" based on the turn
            // If turn is 1 (P2), show "2". If turn is 0 (P1), show "1".
            if (go_P || go_W || go_I || go_N || (turn ? go_2 : go_1))
                oled_data = turn ? RGB_BLACK_PIECE : RGB_WHITE_PIECE;

        end
    end

endmodule