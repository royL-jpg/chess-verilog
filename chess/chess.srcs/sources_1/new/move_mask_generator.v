module move_mask_generator(
    input [255:0] board_flat,
    input sel_en,
    input [5:0] sel_tile,      // From your 'sw' input
    output reg [63:0] legal_mask
);
    // Constants matching your main module
    localparam PIECE_NONE   = 3'b000;
    localparam PIECE_PAWN   = 3'b001;
    localparam PIECE_KNIGHT = 3'b010;
    localparam PIECE_BISHOP = 3'b011;
    localparam PIECE_ROOK   = 3'b100;
    localparam PIECE_QUEEN  = 3'b101;
    localparam PIECE_KING   = 3'b110;
    
    integer i, step;
    reg [3:0] selected_p;
    reg [2:0] sx, sy, dx, dy;
    reg [3:0] target_p;
    reg is_rook_move,is_bish_move;
    
    wire [5:0] cur_tile = sel_tile[5:0];
    wire en = sel_en;
    // Path checking variables
    integer check_x, check_y, dist, step_x, step_y;
    reg path_blocked;

    always @(*) begin
        selected_p = board_flat[cur_tile*4 +: 4];
        sx = cur_tile[2:0];
        sy = cur_tile[5:3];
        legal_mask = 64'b0;
        if (selected_p[2:0] != PIECE_NONE & en) begin
            for (i = 0; i < 64; i = i + 1) begin
                dx = i[2:0];
                dy = i[5:3];
                target_p = board_flat[i*4 +: 4];

                // Rule 1: Cannot capture your own color
                if (target_p != 0 && target_p[3] == selected_p[3]) begin
                    legal_mask[i] = 0;
                end else begin
                    case (selected_p[2:0])
                        PIECE_KNIGHT: begin
                            if ((abs_diff(sx,dx)==1 && abs_diff(sy,dy)==2) || (abs_diff(sx,dx)==2 && abs_diff(sy,dy)==1))
                                legal_mask[i] = 1;
                        end
                        
                        PIECE_KING: begin
                            if (abs_diff(sx,dx) <= 1 && abs_diff(sy,dy) <= 1 && i != cur_tile)
                                legal_mask[i] = 1;
                        end

                        PIECE_PAWN: begin
                            // White = 0 (per your code), Black = 1
                            if (selected_p[3] == 0) begin // White moves "down" the index (sy-1)
                                if (dx == sx && dy == sy - 1 && target_p == 0) legal_mask[i] = 1;
                                if (dx == sx && dy == sy - 2 && sy == 6 && target_p == 0) legal_mask[i] = 1; // Start
                                if (abs_diff(dx,sx) == 1 && dy == sy - 1 && target_p != 0) legal_mask[i] = 1; // Capture
                            end else begin // Black moves "up" the index (sy+1)
                                if (dx == sx && dy == sy + 1 && target_p == 0) legal_mask[i] = 1;
                                if (dx == sx && dy == sy + 2 && sy == 1 && target_p == 0) legal_mask[i] = 1;
                                if (abs_diff(dx,sx) == 1 && dy == sy + 1 && target_p != 0) legal_mask[i] = 1;
                            end
                        end

                        PIECE_ROOK,PIECE_BISHOP,PIECE_QUEEN: begin
                            // Check if move matches piece pattern
                            is_rook_move = (sx == dx || sy == dy);
                            is_bish_move = (abs_diff(sx,dx) == abs_diff(sy,dy));
                            
                            if ((selected_p[2:0] == PIECE_ROOK && is_rook_move) ||
                                (selected_p[2:0] == PIECE_BISHOP && is_bish_move) ||
                                (selected_p[2:0] == PIECE_QUEEN && (is_rook_move || is_bish_move))) begin
                                
                                // Ray-casting for path blocking
                                path_blocked = 0;
                                step_x = (dx > sx) ? 1 : (dx < sx ? -1 : 0);
                                step_y = (dy > sy) ? 1 : (dy < sy ? -1 : 0);
                                dist = (abs_diff(sx,dx) > abs_diff(sy,dy)) ? abs_diff(sx,dx) : abs_diff(sy,dy);
                                
                                for (step = 1; step < 8; step = step + 1) begin
                                    if (step < dist) begin
                                        check_x = sx + (step * step_x);
                                        check_y = sy + (step * step_y);
                                        if (board_flat[(check_y*8 + check_x)*4 +: 4] != 0) path_blocked = 1;
                                    end
                                end
                                if (!path_blocked && i != cur_tile) legal_mask[i] = 1;
                            end
                        end
                    endcase
                end
            end
        end
    end

    function [2:0] abs_diff(input [2:0] a, b);
        abs_diff = (a > b) ? (a - b) : (b - a);
    endfunction
endmodule