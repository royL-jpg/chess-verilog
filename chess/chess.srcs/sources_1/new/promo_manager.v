module promo_manager(
    input clk,
    input rst,
    input turn,              // 0 for P1, 1 for P2
    input is_blitz_mode,
    input promo_trigger,     
    input [1:0] raw_btn_sel, 
    output allow_promo_ui,   
    output [1:0] safe_piece_sel, 
    output [1:0] p1_assists_left,
    output [1:0] p2_assists_left
    );

    reg [1:0] p1_promo_count; 
    reg [1:0] p2_promo_count; 
    reg prev_promo_trigger;

    // Check if the player currently moving has any of their 3 chances left
    assign allow_promo_ui = (turn == 0) ? (p1_promo_count < 3) : (p2_promo_count < 3);

    always @(posedge clk) begin
        if (rst) begin
            p1_promo_count <= 0;
            p2_promo_count <= 0;
            prev_promo_trigger <= 0;
        end else begin
            prev_promo_trigger <= promo_trigger;
            
            // Only count when promotion actually ENTERS (stable high)
            if (promo_trigger && !prev_promo_trigger && allow_promo_ui) begin
                // DO NOTHING HERE (just detect entry)
            end
            
            // Count when promotion ENDS (falling edge = confirmed)
            if (!promo_trigger && prev_promo_trigger) begin
                if (turn == 0 && p1_promo_count < 3)
                    p1_promo_count <= p1_promo_count + 1;
                else if (turn == 1 && p2_promo_count < 3)
                    p2_promo_count <= p2_promo_count + 1;
            end
            
            if (p1_promo_count > 3) p1_promo_count <= 3;
            if (p2_promo_count > 3) p2_promo_count <= 3;
        end
    end

    // Add assigns (3 - count = assists remaining):
    assign p1_assists_left = 2'd3 - p1_promo_count;
    assign p2_assists_left = 2'd3 - p2_promo_count;
endmodule