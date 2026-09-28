
`timescale 1ns / 1ps
module main(clk, sw,sw15, btnL, btnR, btnD, btnU, btnC, seg, an, JB, JA, led);

    input        clk;
    input  [3:0] sw;
    input sw15;
    input        btnL, btnR, btnU, btnD, btnC;
    output [7:0] seg;
    output [3:0] an;
    output [7:0] JA;          // OLED A (Left)  - move-history display + promotion mux
    output [7:0] JB;          // OLED B (Right) - gameplay board display
    output [15:0] led;

    // Reset (sw[0])
    wire rst;
    debounce_sw sw1(clk, sw[0], rst);

    // ====================================================================
    // INLINE DEBOUNCER (10ms sampling at 100MHz)
    // Guarantees clean button signals without needing an external file
    // ====================================================================
    reg [19:0] db_count = 0;
    reg clean_btnC, clean_btnU, clean_btnD, clean_btnL, clean_btnR;

    always @(posedge clk) begin
        if (rst) begin
            db_count <= 0;
            clean_btnC <= 0; clean_btnU <= 0; clean_btnD <= 0; 
            clean_btnL <= 0; clean_btnR <= 0;
        end else begin
            db_count <= db_count + 1;
            // 10ms sampling period (assuming 100MHz clock)
            if (db_count == 20'd1_000_000) begin
                clean_btnC <= btnC;
                clean_btnU <= btnU;
                clean_btnD <= btnD;
                clean_btnL <= btnL;
                clean_btnR <= btnR;
                db_count <= 0;
            end
        end
    end

    // Edge Detection strictly on the CLEANED signals
    reg btnC_prev, btnU_prev, btnD_prev, btnL_prev, btnR_prev;
    always @(posedge clk) begin
        btnC_prev <= clean_btnC;
        btnU_prev <= clean_btnU;
        btnD_prev <= clean_btnD;
        btnL_prev <= clean_btnL;
        btnR_prev <= clean_btnR;
    end
    
    wire btnC_edge = clean_btnC && !btnC_prev;
    wire btnU_edge = clean_btnU && !btnU_prev;
    wire btnD_edge = clean_btnD && !btnD_prev;
    wire btnL_edge = clean_btnL && !btnL_prev;
    wire btnR_edge = clean_btnR && !btnR_prev;
    
    
    assign led[15] = sw15; // LED 15 instantly turns on when SW15 is flipped!
    assign led[14:4] = 11'b0; // Keep the unused LEDs turned off
    
    
    // TOP-LEVEL FSM (LOCKED -> MENU -> GAME MODE)
    localparam SYS_LOCKED  = 2'b00;
    localparam SYS_MENU    = 2'b01;
    localparam SYS_CLASSIC = 2'b10;
    localparam SYS_BLITZ   = 2'b11;
    
    reg [1:0] sys_state = SYS_LOCKED;
    reg menu_cursor = 1'b0; // 0 = Classic, 1 = Blitz
    
    // Wires for the Task B password system
    wire [2:0] current_lock_state;
    wire lock_unlocked;

    always @(posedge clk) begin
        if (rst) begin
            sys_state <= SYS_LOCKED;
            menu_cursor <= 0;
        end else begin
            case (sys_state)
                SYS_LOCKED: begin
                    // State machine hands tracking over to TaskB. 
                    // Once unlocked, move to menu.
                    if (lock_unlocked) begin
                        sys_state <= SYS_MENU;
                    end
                end
                SYS_MENU: begin
                    if (btnU_edge || btnD_edge) menu_cursor <= ~menu_cursor;
                    if (btnC_edge) begin
                        sys_state <= (menu_cursor == 0) ? SYS_CLASSIC : SYS_BLITZ;
                    end
                end
                SYS_CLASSIC, SYS_BLITZ: begin
                // Stay here until the reset switch resets back to locked or menu
                end
            endcase
        end
    end

    wire is_blitz   = (sys_state == SYS_BLITZ);
    wire rst_game   = rst || (sys_state == SYS_MENU) || (sys_state == SYS_LOCKED);

    // --- Original OLED Clocks and Coordinates ---
    wire frame_begin;
    wire [12:0] pixel_index;     
    
    wire frame_begin_2;
    wire [12:0] pixel_index_2;   

    wire [6:0] x_ja = pixel_index % 96;
    wire [5:0] y_ja = pixel_index / 96;

    wire [6:0] x_jb = pixel_index_2 % 96;
    wire [5:0] y_jb = pixel_index_2 / 96;

    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT = 3'b010;
    localparam PIECE_BISHOP = 3'b011;
    localparam PIECE_ROOK   = 3'b100;
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;
    localparam COLOR_WHITE  = 1'b0;
    localparam COLOR_BLACK  = 1'b1;
    
    // Board
    wire turn;
    wire game_over;
    reg  [3:0] board[63:0];
    wire [255:0] passable_board;

    genvar i;
    generate for (i = 0; i < 64; i = i + 1) begin: BOARD
        assign passable_board[i*4+3 : i*4] = board[i];
    end endgenerate

    wire [63:0] legal_moves;
    wire        board_change_en;
    wire [5:0]  board_change_addr;
    wire [3:0]  board_change_contents;
    wire [5:0]  cur_addr;
    wire        sel_en;
    wire [5:0]  sel_addr;
    wire [3:0] track;
    wire        capturing;
    wire [3:0] white_pawn_lost, white_knight_lost, white_bishop_lost,
               white_rook_lost, white_queen_lost;
    wire [3:0] black_pawn_lost, black_knight_lost, black_bishop_lost,
               black_rook_lost, black_queen_lost;

    wire clk6p25m;
    slow_clock #(.MAX_COUNT(8)) clk1(clk, clk6p25m);

    initial begin
        reset_board();
    end

    task reset_board;
    begin
        board[6'b111_000] <= {COLOR_WHITE, PIECE_ROOK};
        board[6'b111_001] <= {COLOR_WHITE, PIECE_KNIGHT};
        board[6'b111_010] <= {COLOR_WHITE, PIECE_BISHOP};
        board[6'b111_011] <= {COLOR_WHITE, PIECE_QUEEN};
        board[6'b111_100] <= {COLOR_WHITE, PIECE_KING};
        board[6'b111_101] <= {COLOR_WHITE, PIECE_BISHOP};
        board[6'b111_110] <= {COLOR_WHITE, PIECE_KNIGHT};
        board[6'b111_111] <= {COLOR_WHITE, PIECE_ROOK};

        board[6'b110_000] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_001] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_010] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_011] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_100] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_101] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_110] <= {COLOR_WHITE, PIECE_PAWN};
        board[6'b110_111] <= {COLOR_WHITE, PIECE_PAWN};

        board[6'b101_000] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_001] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_010] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_011] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_100] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_101] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_110] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b101_111] <= {COLOR_WHITE, PIECE_NONE};

        board[6'b100_000] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_001] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_010] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_011] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_100] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_101] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_110] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b100_111] <= {COLOR_WHITE, PIECE_NONE};

        board[6'b011_000] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_001] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_010] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_011] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_100] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_101] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_110] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b011_111] <= {COLOR_WHITE, PIECE_NONE};

        board[6'b010_000] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_001] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_010] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_011] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_100] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_101] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_110] <= {COLOR_WHITE, PIECE_NONE};
        board[6'b010_111] <= {COLOR_WHITE, PIECE_NONE};

        board[6'b001_000] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_001] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_010] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_011] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_100] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_101] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_110] <= {COLOR_BLACK, PIECE_PAWN};
        board[6'b001_111] <= {COLOR_BLACK, PIECE_PAWN};

        board[6'b000_000] <= {COLOR_BLACK, PIECE_ROOK};
        board[6'b000_001] <= {COLOR_BLACK, PIECE_KNIGHT};
        board[6'b000_010] <= {COLOR_BLACK, PIECE_BISHOP};
        board[6'b000_011] <= {COLOR_BLACK, PIECE_QUEEN};
        board[6'b000_100] <= {COLOR_BLACK, PIECE_KING};
        board[6'b000_101] <= {COLOR_BLACK, PIECE_BISHOP};
        board[6'b000_110] <= {COLOR_BLACK, PIECE_KNIGHT};
        board[6'b000_111] <= {COLOR_BLACK, PIECE_ROOK};
    end
    endtask

    wire [15:0] oled_gameplay_data;

    screen_format module0(
        .BOARD(passable_board), .cur_tile(cur_addr), .sel_en(sel_en), .sel_tile(sel_addr),
        .legal_moves(legal_moves), .x(x_jb), .y(y_jb), .check(led[3]), .turn(turn),
        .game_over(game_over), .white_pawn_lost(white_pawn_lost), .white_knight_lost(white_knight_lost),
        .white_bishop_lost(white_bishop_lost), .white_rook_lost(white_rook_lost), .white_queen_lost(white_queen_lost),
        .black_pawn_lost(black_pawn_lost), .black_knight_lost(black_knight_lost), .black_bishop_lost(black_bishop_lost),
        .black_rook_lost(black_rook_lost), .black_queen_lost(black_queen_lost), .oled_data(oled_gameplay_data)
    );

    wire [15:0] oled_history_data;
    wire [11:0] wm1, wm2, wm3;
    wire [11:0] bm1, bm2, bm3;

    move_history_tracker tracker_inst(
        .clk(clk), .rst(rst), .board_change_en(board_change_en), .board_change_contents(board_change_contents),
        .sel_tile(sel_addr), .to_tile(board_change_addr), .turn(turn),
        .w_move_1(wm1), .w_move_2(wm2), .w_move_3(wm3), .b_move_1(bm1), .b_move_2(bm2), .b_move_3(bm3)
    );

    history_screen_format formatter_2(
        .pixel_index(pixel_index), .w_move_1(wm1), .w_move_2(wm2), .w_move_3(wm3),
        .b_move_1(bm1), .b_move_2(bm2), .b_move_3(bm3), .oled_data(oled_history_data)
    );

    // PROMOTION MENU PIXEL GENERATOR 
    wire [1:0] safe_promo_sel;
    wire promotion_pending;
    wire [1:0] promo_selection; 
    
    // --- Coordinate Inversion (Physical Orientation Setup) ---
    wire [6:0] x_promo = 7'd95 - x_ja;   
    wire [5:0] y_promo = 6'd63 - y_ja;   
    
    // Artwork (8x8 bitmaps) for the 4 promotion choices
    localparam [0:63] promo_queenArt = {
        8'b00000000, 8'b01010101, 8'b01010101, 8'b01010101,
        8'b01010101, 8'b01111111, 8'b01111111, 8'b01111111
    };
    localparam [0:63] promo_rookArt = {
        8'b00000000, 8'b01011010, 8'b01111110, 8'b00111100,
        8'b00011000, 8'b00011000, 8'b00111100, 8'b01111110
    };
    localparam [0:63] promo_bishopArt = {
        8'b00000000, 8'b00011000, 8'b00111100, 8'b00111100,
        8'b00011000, 8'b00011000, 8'b00111100, 8'b11100111
    };
    localparam [0:63] promo_knightArt = {
        8'b00011000, 8'b01111100, 8'b11111110, 8'b11101111,
        8'b00000111, 8'b00011111, 8'b00111111, 8'b01111110
    };
    
    wire        promo_col  = (x_promo >= 7'd48);
    wire        promo_row  = (y_promo >= 6'd32);
    wire [1:0] promo_cell = {promo_row, promo_col};  // matches promo_selection encoding
    wire        is_sel     = (promo_cell == promo_selection);
    
    wire [5:0] cell_x = promo_col ? (x_promo - 7'd48) : x_promo[5:0]; // 0..47
    wire [4:0] cell_y = promo_row ? (y_promo - 6'd32) : y_promo[4:0]; // 0..31
    wire promo_border = is_sel &&
                        ((cell_x < 6'd2) | (cell_x >= 6'd46) |
                         (cell_y < 5'd2) | (cell_y >= 5'd30));
    
    // Grid divider: 2px lines separating the four cells 
    wire promo_divider = (x_promo == 7'd47) | (x_promo == 7'd48) |
                         (y_promo == 6'd31) | (y_promo == 6'd32);
    
    // 2x Scaled Sprite (8x8 -> 16x16) centered in each 48x32 cell 
    wire in_spr_x   = (cell_x >= 6'd16) && (cell_x < 6'd32);
    wire in_spr_y   = (cell_y >= 5'd8)  && (cell_y < 5'd24);
    wire in_sprite  = in_spr_x && in_spr_y;
    
    wire [2:0] spr_xi  = (cell_x - 6'd16) >> 1;   // 0..7
    wire [2:0] spr_yi  = (cell_y - 5'd8)  >> 1;   // 0..7
    wire [5:0] spr_idx = {spr_yi, spr_xi};
    
    reg promo_piece_bit;
    always @(*) begin
        promo_piece_bit = 1'b0;
        if (in_sprite) begin
            case (promo_cell)
                2'b00: promo_piece_bit = promo_queenArt[spr_idx];
                2'b01: promo_piece_bit = promo_rookArt[spr_idx];
                2'b10: promo_piece_bit = promo_bishopArt[spr_idx];
                2'b11: promo_piece_bit = promo_knightArt[spr_idx];
            endcase
        end
    end
    
    //Colors 
    wire [15:0] promo_piece_color  = ~turn ? 16'h07C0 : 16'hF800;
    wire [15:0] promo_sel_bg       = 16'h001F;  // Blue
    wire [15:0] promo_unsel_bg     = 16'h1082;  // Dark
    wire [15:0] promo_border_color = 16'hFFFF;  // White
    wire [15:0] promo_divider_col  = 16'h4208;  // Gray
    
    //  Final Pixel Assembler
    wire [15:0] promo_pixel =
        promo_border                    ? promo_border_color :
        promo_divider                   ? promo_divider_col  :
        (in_sprite & promo_piece_bit)   ? promo_piece_color  :
        is_sel                          ? promo_sel_bg       :
                                          promo_unsel_bg;
    

  // --- PROMOTION & ASSIST LOGIC ---
// 1. Identify the piece currently at the cursor
    wire [3:0] selected_piece = board[cur_addr];
    wire piece_is_pawn = (selected_piece[2:0] == PIECE_PAWN);

    wire allow_promo;
    wire [8:0] p1_time, p2_time;
    wire [1:0] p1_assists_left, p2_assists_left;
    wire manual_promo_trigger = is_blitz && sw15 && piece_is_pawn;

    wire blitz_sw15_promo = is_blitz && manual_promo_trigger && allow_promo;
    // Free-running counter for random piece in blitz SW15 promo (Rook/Bishop/Knight)
    reg [1:0] blitz_rand_cnt;
    always @(posedge clk) blitz_rand_cnt <= blitz_rand_cnt + 1;
    
    wire [1:0] blitz_rand_sel = (blitz_rand_cnt == 2'b00) ? 2'b01 : blitz_rand_cnt;
    
    
    wire blitz_timeout;
    // move_done_pulse: fires for one cycle when turn changes (move committed)
    reg prev_turn_blitz;
    wire move_done_pulse = (turn != prev_turn_blitz) && is_blitz;
    always @(posedge clk) prev_turn_blitz <= turn;

    promo_manager promo_limit_inst(
        .clk(clk),
        .rst(rst_game),
        .turn(turn),                     // Added: pass 0 for P1, 1 for P2
        .is_blitz_mode(is_blitz),
        .promo_trigger(promotion_pending),       // Triggered by end-rank OR SW15
        .raw_btn_sel(promo_selection),   
        .allow_promo_ui(allow_promo),   
        .safe_piece_sel(safe_promo_sel),
        .p1_assists_left(p1_assists_left),
        .p2_assists_left(p2_assists_left) 
    );


    blitz_timer timer_inst(
        .clk(clk),
        .reset(rst_game),
        .enable(is_blitz),
        .switch_player(turn),
        .paused(promotion_pending),
        .move_done(move_done_pulse),
        .p1_time(p1_time),
        .p2_time(p2_time),
        .time_expired(blitz_timeout)
    );


    // ====================================================================
    // PULSE GENERATOR & INSTRUCTION OVERLAY
    // ====================================================================
    reg [24:0] pulse_cnt = 0;
    always @(posedge clk) pulse_cnt <= pulse_cnt + 1;
    wire ui_pulse = pulse_cnt[24]; // Approx 1.5Hz clock for flashing

    wire [15:0] blitz_oled_pixel;
    oled_a_blitz_ui side_panel_inst(
            .x_ja(x_ja), .y_ja(y_ja),
            .p1_time(p1_time), .p2_time(p2_time),
            .turn_p2(turn),
            .sw15_promo_active(blitz_sw15_promo),
            .promotion_pending(promotion_pending),
            .p1_assists_left(p1_assists_left),
            .p2_assists_left(p2_assists_left),
            .flash_bit(ui_pulse),
            .pixel_color(blitz_oled_pixel)
        );

    
    // Sub-wires to prevent multiple drivers on physical outputs
    wire [7:0] taskb_seg;
    wire [3:0] taskb_an;

    // Instantiate Task B
    TaskB lock_ctrl(
        .CLOCK(clk),
        .btnc(btnC_edge), 
        .btnl(btnL_edge), 
        .btnr(btnR_edge), 
        .btnu(btnU_edge), 
        .btnd(btnD_edge),
        .seg(taskb_seg), 
        .an(taskb_an),
        .UNLOCK(lock_unlocked),
        .state_out(current_lock_state) 
    );
    wire [15:0] inst_pixel_ja; // For the Left OLED
    wire [15:0] inst_pixel_jb; // For the Right OLED
    instruction_box #(.INVERT(1)) draw_inst_ja (
        .x_ja(x_ja),           
        .y_ja(y_ja),
        .state(current_lock_state), 
        .pulse_1hz(ui_pulse),
        .pixel_color(inst_pixel_ja) // Connect to JA wire
    );
    
    // Instance for Port JB (No Inversion)
    instruction_box #(.INVERT(0)) draw_inst_jb (
        .x_ja(x_jb),           
        .y_ja(y_jb),
        .state(current_lock_state), 
        .pulse_1hz(ui_pulse),
        .pixel_color(inst_pixel_jb) // Connect to JB wire
    );
    
    wire [15:0] menu_pixel_out;
    menu_screen menu_inst(
        .clk(clk),
        .reset(rst),
        .current_x(x_ja),
        .current_y(y_ja),
        .sys_state({1'b0, sys_state}), 
        .seq_progress(current_lock_state), // Handed sequence status over to TaskB
        .cursor_pos(menu_cursor),
        .oled_data(menu_pixel_out)
    );

    
    // OLED B (Right) Multiplexer: ONLY show instructions when locked. Solid black in menu.
    wire [15:0] final_oled_jb_pixel = 
        (sys_state == SYS_LOCKED) ? inst_pixel_jb :
        (sys_state == SYS_MENU)   ? 16'h0000   : 
        oled_gameplay_data;

    wire [15:0] final_oled_ja_pixel = 
    (sys_state == SYS_LOCKED) ? inst_pixel_ja : 
    (sys_state == SYS_MENU)   ? menu_pixel_out : 
    (promotion_pending && !blitz_sw15_promo) ? promo_pixel : 
    (is_blitz) ? blitz_oled_pixel : oled_history_data;

    // Oled_Displays driven by the multiplexed signals
    Oled_Display oled1(
        .clk(clk6p25m), .reset(1'b0), .frame_begin(frame_begin), .pixel_index(pixel_index),
        .pixel_data(final_oled_ja_pixel), .cs(JA[0]), .sdin(JA[1]), .sclk(JA[3]), .d_cn(JA[4]), 
        .resn(JA[5]), .vccen(JA[6]), .pmoden(JA[7])
    );

    Oled_Display oled2(
        .clk(clk6p25m), .reset(1'b0), .frame_begin(frame_begin_2), .pixel_index(pixel_index_2),
        .pixel_data(final_oled_jb_pixel), .cs(JB[0]), .sdin(JB[1]), .sclk(JB[3]), .d_cn(JB[4]), 
        .resn(JB[5]), .vccen(JB[6]), .pmoden(JB[7])
    );

    // Scoreboard, Cursor, Timer
    scoreboard sb(
        .clk(clk), .rst(rst), .capturing(capturing), .captured_piece(track),
        .white_pawn_lost(white_pawn_lost), .white_knight_lost(white_knight_lost),
        .white_bishop_lost(white_bishop_lost), .white_rook_lost(white_rook_lost), .white_queen_lost(white_queen_lost),
        .black_pawn_lost(black_pawn_lost), .black_knight_lost(black_knight_lost), .black_bishop_lost(black_bishop_lost),
        .black_rook_lost(black_rook_lost), .black_queen_lost(black_queen_lost)
    );
    
    
    // Note: passing the clean (debounced) buttons to the rest of the game logic
//    cursor cursor_controller(rst, clk, turn, clean_btnL, clean_btnR, clean_btnU, clean_btnD,sys_state, cur_addr);
    // -----------------------------------------------------------------------
    // CURSOR CONTROL (Masked during promotion in blitz)
    // -----------------------------------------------------------------------
    wire cursor_btnL = clean_btnL & !promotion_pending;
    wire cursor_btnR = clean_btnR & !promotion_pending;
    wire cursor_btnU = clean_btnU & !promotion_pending;
    wire cursor_btnD = clean_btnD & !promotion_pending;

    // Note: passing the masked buttons so the board cursor freezes during promotion
    cursor cursor_controller(
        .rst(rst), .clk(clk), .turn(turn), 
        .btnL(cursor_btnL), .btnR(cursor_btnR), .btnU(cursor_btnU), .btnD(cursor_btnD),
        .sys_state(sys_state), .cur_addr(cur_addr)
    );

    wire time_up;
    wire [7:0] game_seg;
    wire [3:0] game_an;

    seg7 seven_seg_module(
        .clk(clk), .rst(rst_game),.set(sw[3:1]), 
        .turn(turn),.game_over(game_over), .seg(game_seg), .an(game_an), .time_up(time_up),
        .is_blitz(is_blitz),.p1_time(p1_time),.p2_time(p2_time));
    
    // 7-SEGMENT 
    // Reverses bit mapping to fix physical constraints file inversion
    wire [7:0] corrected_taskb_seg = {
        taskb_seg[0], taskb_seg[1], taskb_seg[2], taskb_seg[3], 
        taskb_seg[4], taskb_seg[5], taskb_seg[6], taskb_seg[7]
    };

    assign seg = (sys_state == SYS_LOCKED) ? taskb_seg : game_seg;
    assign an  = (sys_state == SYS_LOCKED) ? taskb_an : game_an;

    wire white_king_moved;
    wire black_king_moved;
    wire white_rook_left_moved;
    wire white_rook_right_moved;
    wire black_rook_left_moved;
    wire black_rook_right_moved;
    
    wire safe_classic_timeout = (sw[3:1] == 3'b000) ? 1'b0 : time_up;
    game_logic logic_module(
        .rst(rst_game),.sys_state(sys_state), .clk(clk), 
        .btnC(clean_btnC), .btnL(clean_btnL), .btnR(clean_btnR), .btnU(clean_btnU), .btnD(clean_btnD),
        .board_flat(passable_board), .time_up(is_blitz ? blitz_timeout : time_up), 
        .legal_tile(legal_moves), .state(led[2:0]), .cur_tile(cur_addr), .sel_en(sel_en), .sel_tile(sel_addr),
        .board_change_en(board_change_en), .board_change_addr(board_change_addr), .board_change_contents(board_change_contents),
        .check_out(led[3]), .turn(turn), .game_over(game_over), .track(track), .capturing(capturing),
        .promotion_pending(promotion_pending),.promo_selection(promo_selection),.is_blitz(is_blitz),.white_king_moved(white_king_moved),
        .black_king_moved(black_king_moved),.white_rook_left_moved(white_rook_left_moved),.white_rook_right_moved(white_rook_right_moved),
        .black_rook_left_moved(black_rook_left_moved),.black_rook_right_moved(black_rook_right_moved), 
        .blitz_sw15_promo(blitz_sw15_promo),.blitz_rand_sel(blitz_rand_sel)
    );

    always @(posedge clk, posedge rst_game) begin
        if (rst_game)
            reset_board();
        else if (board_change_en)
            board[board_change_addr] <= board_change_contents;
    end

endmodule