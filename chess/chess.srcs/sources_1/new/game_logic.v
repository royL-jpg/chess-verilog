
`timescale 1ns / 1ps

module game_logic(
    rst,
    sys_state,
    clk,
    btnC,
    btnL, btnR, btnU, btnD,     
    board_flat,
    time_up,
    legal_tile,
    state,
    cur_tile,
    sel_en,
    sel_tile,
    board_change_en,
    board_change_addr,
    board_change_contents,
    check_out,
    turn,
    game_over,
    track,
    capturing,
    promotion_pending,          
    promo_selection,            
    is_blitz,                   
    white_king_moved,
    black_king_moved,
    white_rook_left_moved,
    white_rook_right_moved,
    black_rook_left_moved,
    black_rook_right_moved,
    blitz_sw15_promo,
    blitz_rand_sel
    );

    input  rst;
    input [1:0] sys_state;
    input  clk;
    input  btnC, btnL, btnR, btnU, btnD;
    input  [255:0] board_flat;   
    input blitz_sw15_promo;
    input [1:0] blitz_rand_sel;
    input  time_up;
    input  is_blitz;
    output [63:0] legal_tile;
    output reg [2:0]  state;
    input  [5:0]  cur_tile;
    output reg    sel_en;
    output reg [5:0]  sel_tile;
    output reg    board_change_en;
    output reg [5:0]  board_change_addr;
    output reg [3:0]  board_change_contents;
    output reg    check_out;
    output reg    turn           = 0;
    output reg    game_over      = 0;
    output reg [3:0] track       = 4'b0000;
    output reg    capturing      = 1'b0;
    output reg    promotion_pending = 0;   
    output reg [1:0] promo_selection = 0;                      
    output reg    white_king_moved        = 0;
    output reg    black_king_moved        = 0;
    output reg    white_rook_left_moved   = 0;
    output reg    white_rook_right_moved  = 0;
    output reg    black_rook_left_moved   = 0;
    output reg    black_rook_right_moved  = 0;

    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT   = 3'b010; 
    localparam PIECE_BISHOP = 3'b011; 
    localparam PIECE_ROOK = 3'b100; 
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;


    wire btnC_trig, btnL_trig, btnR_trig, btnU_trig, btnD_trig;
    debounce_btn bC(clk, btnC, btnC_trig);
    debounce_btn bL(clk, btnL, btnL_trig);
    debounce_btn bR(clk, btnR, btnR_trig);
    debounce_btn bU(clk, btnU, btnU_trig);
    debounce_btn bD(clk, btnD, btnD_trig);

    reg castle_pending;
    reg [5:0] castle_rook_from;
    reg [5:0] castle_rook_to;

    reg [1:0] white_blitz_count; // added: tracks 3 tries for white
    reg [1:0] black_blitz_count; // added: tracks 3 tries for black
    
    // added: helper wire to check if current player has charges remaining
    wire has_blitz_charge = (turn == 0) ? (white_blitz_count < 3) : (black_blitz_count < 3);    
    
    reg btn_handled; 


    wire [63:0] legal_tile;        
    reg  start;
    wire done;
    reg  [3:0] selected_p;         
    wire check_flag;

    legal_move_fsm legal_fsm(
        .rst(rst),
        .clk(clk),
        .start(start),
        .selected_p(selected_p),
        .start_tile(sel_tile),
        .board_flat(board_flat),   
        .white_king_moved(white_king_moved),
        .black_king_moved(black_king_moved),
        .white_rook_left_moved(white_rook_left_moved),
        .white_rook_right_moved(white_rook_right_moved),
        .black_rook_left_moved(black_rook_left_moved),
        .black_rook_right_moved(black_rook_right_moved),
        .legal_mask(legal_tile),
        .done(done),
        .check(check_flag)
    );


    localparam WAIT      = 3'b000;
    localparam MOVE      = 3'b001;
    localparam ERASE     = 3'b010;
    localparam CHECK     = 3'b011;
    localparam PASS      = 3'b100;
    localparam ROOKPLACE  = 3'b101;
    localparam ROOKERASE  = 3'b110;
    localparam PROMOTE    = 3'b111; 

    wire [3:0] cur_piece  = board_flat[cur_tile*4  +: 4];
    wire [3:0] sel_piece  = board_flat[sel_tile*4  +: 4];

    reg loser; //added  0 = P1 lost, 1 = P2 lost
    reg time_upf;
    wire real_timeup = time_up & ~time_upf;

    // -----------------------------------------------------------------------
    // Main FSM
    // -----------------------------------------------------------------------
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state                 <= WAIT;
            sel_en                <= 0;
            sel_tile              <= 0;
            board_change_en       <= 0;
            board_change_addr     <= 0;
            board_change_contents <= 0;
            check_out             <= 0;
            turn                  <= 0;
            game_over             <= 0;
            time_upf              <= 0;
            promotion_pending     <= 0;
            promo_selection       <= 0;
            btn_handled           <= 0;
            white_king_moved        <= 0;
            black_king_moved        <= 0;
            white_rook_left_moved   <= 0;
            white_rook_right_moved  <= 0;
            black_rook_left_moved   <= 0;
            black_rook_right_moved  <= 0;
        end
        else begin
            if(~game_over) begin
                time_upf  <= time_up;
                capturing <= 0;
                
                // Release the safety lock when user lets go of the button
                if (!btnC_trig) btn_handled <= 0; 
    
                case (state)
                    // --------------------------------------------------------
                    // WAIT
                    // --------------------------------------------------------
                    WAIT : begin
                        if (!promotion_pending && btnC_trig && !btn_handled) begin //added
                            if (cur_piece[3] == turn && cur_piece[2:0] != PIECE_NONE) begin
                                sel_tile   <= cur_tile;
                                selected_p <= cur_piece;   
                                sel_en     <= 1;
                                start      <= 1;
                                btn_handled <= 1; 
                            end
                        end
                        if (done) begin
                            start <= 0;
                            state <= MOVE;
                        end
//                        if (real_timeup) state <= PASS;
                        if(is_blitz) begin
                            if (real_timeup && !game_over) begin
                                game_over <= 1;
                                loser <= turn; // whoever's clock was running loses
                                turn <= ~turn; //Flip turn to the winner!
                            end
                        end
                        else if(real_timeup) state <= PASS;

                    end
    
                    // --------------------------------------------------------
                    // MOVE
                    // --------------------------------------------------------
                    MOVE : begin
                        if (!promotion_pending && btnC_trig && !btn_handled) begin //added
                            if (legal_tile[cur_tile]) begin
                                
                                btn_handled <= 1; // Lock trigger
                                if (sel_tile == 6'b111_000) white_rook_left_moved  <= 1;
                                if (sel_tile == 6'b111_111) white_rook_right_moved <= 1;
                                if (sel_tile == 6'b000_000) black_rook_left_moved  <= 1;
                                if (sel_tile == 6'b000_111) black_rook_right_moved <= 1;
                                if (sel_tile == 6'b111_100) white_king_moved        <= 1;
                                if (sel_tile == 6'b000_100) black_king_moved        <= 1;
    
                                if (cur_piece[2:0] == PIECE_KING) game_over <= 1;
                                // Blitz Mode Rule: Capturing the opponent's Queen is a win condition
                                if (is_blitz && cur_piece[2:0] == PIECE_QUEEN) begin
                                    game_over <= 1;
                                end
                                // ======================================
    
                                // ---------- castling destination ----------
                                castle_pending <= 0;
                                if (sel_tile == 6'b111_100 && cur_tile == 6'b111_110) begin
                                    castle_pending   <= 1;
                                    castle_rook_from <= 6'b111_111;
                                    castle_rook_to   <= 6'b111_101;
                                end else if (sel_tile == 6'b111_100 && cur_tile == 6'b111_010) begin
                                    castle_pending   <= 1;
                                    castle_rook_from <= 6'b111_000;
                                    castle_rook_to   <= 6'b111_011;
                                end else if (sel_tile == 6'b000_100 && cur_tile == 6'b000_110) begin
                                    castle_pending   <= 1;
                                    castle_rook_from <= 6'b000_111;
                                    castle_rook_to   <= 6'b000_101;
                                end else if (sel_tile == 6'b000_100 && cur_tile == 6'b000_010) begin
                                    castle_pending   <= 1;
                                    castle_rook_from <= 6'b000_000;
                                    castle_rook_to   <= 6'b000_011;
                                end
    
                                if (cur_piece[2:0] != PIECE_NONE) begin
                                    track     <= cur_piece;
                                    capturing <= 1;
                                end else begin
                                    capturing <= 0;
                                end
    
                                board_change_addr <= cur_tile;
    
                                // ---- PAWN PROMOTION FLAG ----
                                if (selected_p[2:0] == PIECE_PAWN) begin
                                    // 1. Check for SW15 + is_blitz + charges remaining
                                    if (is_blitz && blitz_sw15_promo && has_blitz_charge) begin
                                        promotion_pending <= 1;
                                    end 
                                    // 2. Classic promotion (at the ends of the board)
                                    else if ((selected_p[3] == 1'b0 && cur_tile[5:3] == 3'b000) ||
                                             (selected_p[3] == 1'b1 && cur_tile[5:3] == 3'b111)) begin
                                        promotion_pending <= 1;
                                        promo_selection   <= 2'b00; // Reset UI cursor to default
                                    end 
                                    // 3. Just a normal pawn move
                                    else begin
                                        promotion_pending <= 0;
                                    end
                                end 
                                // 4. Not a pawn
                                else begin
                                    promotion_pending <= 0;
                                end
        
                                board_change_contents <= selected_p;
                                board_change_en <= 1;
                                state           <= ERASE;
                            end
                            
                            else begin
                                state  <= WAIT;
                                sel_en <= 0;
                            end
                        end
//                        if (real_timeup) state <= PASS; 
                        if(is_blitz) begin
                            if (real_timeup && !game_over) begin
                                game_over <= 1;
                                loser <= turn;  // whoever's clock was running loses
                                turn <= ~turn; //Flip turn to the winner!
                            end
                        end
                        else if(real_timeup) begin
                            state <= PASS;
                        end

                    end
    
                    ROOKPLACE : begin
                        board_change_en       <= 1;
                        board_change_addr     <= castle_rook_to;
                        board_change_contents <= board_flat[castle_rook_from*4 +: 4];
                        state                 <= ROOKERASE;
                    end
    
                    ROOKERASE : begin
                        board_change_en       <= 1;
                        board_change_addr     <= castle_rook_from;
                        board_change_contents <= 0;
                        castle_pending        <= 0;
                        start                 <= 1;
                        state                 <= CHECK;
                    end
    
                    ERASE : begin
                        board_change_en       <= 1;
                        board_change_addr     <= sel_tile;
                        board_change_contents <= 0;
                        sel_tile              <= cur_tile; 
    
                        if (castle_pending)
                            state <= ROOKPLACE;
                        else begin
                            start <= 1;
                            state <= CHECK;
                        end
                    end
    
                    CHECK : begin
                        start <= 0;
                        if (done) begin
                            check_out <= check_flag;
                            if (promotion_pending)
                                state <= PROMOTE; 
                            else
                                state <= PASS;
                        end
                    end
    
                    // --------------------------------------------------------
                    // PROMOTE 
                    // --------------------------------------------------------
                    PROMOTE : begin
                    // --- 1. GLOBAL TIMEOUT CHECK ---
                    // Handles what happens if the clock hits zero while choosing a piece
                    if (time_up) begin
                        if (is_blitz) begin
                            // Blitz Timeout: Player loses instantly
                            game_over <= 1;
                            loser <= turn;
                        end else begin
                            // Classic Timeout: Auto-promote to current cursor and force turn swap
                            board_change_en <= 1;
                            board_change_addr <= sel_tile;
                            case (promo_selection)
                                2'b00: board_change_contents <= {selected_p[3], PIECE_QUEEN};
                                2'b01: board_change_contents <= {selected_p[3], PIECE_ROOK};
                                2'b10: board_change_contents <= {selected_p[3], PIECE_BISHOP};
                                2'b11: board_change_contents <= {selected_p[3], PIECE_KNIGHT};
                            endcase
                            promotion_pending <= 0;
                            state <= PASS;
                        end
                    end
                    
                    // --- 2. BLITZ MODE PROMOTION ---
                    else if (is_blitz) begin
                        if (blitz_sw15_promo && has_blitz_charge) begin
                            // Blitz Feature: SW15 Random Promotion
                            if (btnC_trig && !btn_handled) begin
                                btn_handled <= 1;
                                board_change_en   <= 1;
                                board_change_addr <= sel_tile;
                                case (blitz_rand_sel)
                                    2'b01:   board_change_contents <= {selected_p[3], PIECE_ROOK};
                                    2'b10:   board_change_contents <= {selected_p[3], PIECE_BISHOP};
                                    2'b11:   board_change_contents <= {selected_p[3], PIECE_KNIGHT};
                                    default: board_change_contents <= {selected_p[3], PIECE_KNIGHT};
                                endcase
                                
                                // Increment charge
                                if (turn == 0) white_blitz_count <= white_blitz_count + 1;
                                else           black_blitz_count <= black_blitz_count + 1;

                                promotion_pending <= 0;
                                state <= PASS;
                            end else begin
                                board_change_en <= 0;
                            end
                        end else begin
                            // Blitz Default: Normal Back-Rank Promotion (if SW15 is OFF or charges empty)
                            if (btnL_trig) promo_selection[0] <= 1'b0; 
                            else if (btnR_trig) promo_selection[0] <= 1'b1; 
                            else if (btnU_trig) promo_selection[1] <= 1'b0; 
                            else if (btnD_trig) promo_selection[1] <= 1'b1; 
        
                            else if (btnC_trig && !btn_handled) begin
                                btn_handled <= 1; 
                                board_change_en <= 1;
                                board_change_addr <= sel_tile; 
                                case (promo_selection)
                                    2'b00: board_change_contents <= {selected_p[3], PIECE_QUEEN};   
                                    2'b01: board_change_contents <= {selected_p[3], PIECE_ROOK};    
                                    2'b10: board_change_contents <= {selected_p[3], PIECE_BISHOP};  
                                    2'b11: board_change_contents <= {selected_p[3], PIECE_KNIGHT};  
                                endcase
                                promotion_pending <= 0;
                                state <= PASS;
                            end else begin
                                board_change_en <= 0;
                            end
                        end
                    end
                    
                    // --- 3. CLASSIC MODE PROMOTION ---
                    else begin
                        // Classic Mode: Manual DPAD Promotion Only
                        if (btnL_trig) promo_selection[0] <= 1'b0; 
                        else if (btnR_trig) promo_selection[0] <= 1'b1; 
                        else if (btnU_trig) promo_selection[1] <= 1'b0; 
                        else if (btnD_trig) promo_selection[1] <= 1'b1; 
    
                        else if (btnC_trig && !btn_handled) begin
                            btn_handled <= 1; 
                            board_change_en <= 1;
                            board_change_addr <= sel_tile; 
                            case (promo_selection)
                                2'b00: board_change_contents <= {selected_p[3], PIECE_QUEEN};   
                                2'b01: board_change_contents <= {selected_p[3], PIECE_ROOK};    
                                2'b10: board_change_contents <= {selected_p[3], PIECE_BISHOP};  
                                2'b11: board_change_contents <= {selected_p[3], PIECE_KNIGHT};  
                            endcase
                            promotion_pending <= 0;
                            state <= PASS;
                        end else begin
                            board_change_en <= 0;
                        end
                    end
                end
    
                    // --------------------------------------------------------
                    // PASS
                    // --------------------------------------------------------
                    PASS : begin
                    if (!game_over)//added
                        turn              <= ~turn;
                        sel_en            <= 0;
                        board_change_en   <= 0;
                        promotion_pending <= 0;   
                        state             <= WAIT;
                    end
                    default: state <= WAIT;
                endcase
            end
        end
    end

endmodule