`timescale 1ns / 1ps

module blitz_timer(
    input  clk,
    input  reset,
    input  enable,           
    input  switch_player,    // Tied to `turn` (0 = P1, 1 = P2)
    input  paused,           
    input  move_done,        
    output reg [8:0] p1_time,
    output reg [8:0] p2_time,
    output reg time_expired
);
    // Updated for 30s start and 3s increment
    parameter CLK_FREQ   = 100_000_000;
    parameter START_TIME = 9'd30;     
    parameter INCREMENT  = 9'd3;      

    reg [26:0] clk_counter;
    reg        prev_move_done;
    reg        prev_turn;

    wire move_done_edge = move_done && !prev_move_done;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            p1_time      <= START_TIME;
            p2_time      <= START_TIME;
            clk_counter  <= 0;
            time_expired <= 0;
            prev_turn    <= switch_player;
        end else begin
            prev_move_done <= move_done;

            // Detect ANY turn change to reset the 1-second window
            if (switch_player != prev_turn) begin
                clk_counter <= 0;
                prev_turn <= switch_player;
            end

            // +3s Fischer Increment
            if (move_done_edge) begin
                if (switch_player == 1) // If it's now P2's turn, P1 just finished
                    p1_time <= (p1_time + INCREMENT > 9'd30) ? 9'd30 : p1_time + INCREMENT;
                else
                    p2_time <= (p2_time + INCREMENT > 9'd30) ? 9'd30 : p2_time + INCREMENT;
            end

            // Countdown Logic (Uses 'switch_player' directly as the active player flag)
            else if (enable && !paused && !time_expired) begin
                if (clk_counter >= CLK_FREQ - 1) begin
                    clk_counter <= 0;
                    
                    if (switch_player == 0) begin
                        if (p1_time > 1) begin
                            p1_time <= p1_time - 1;
                        end else begin
                            p1_time <= 0;
                            time_expired <= 1;
                        end
                    end else begin
                        if (p2_time > 1) begin
                            p2_time <= p2_time - 1;
                        end else begin
                            p2_time <= 0;
                            time_expired <= 1;
                        end
                    end
                    
                    
                    
                end else begin
                    clk_counter <= clk_counter + 1;
                end
            end
        end
    end
endmodule
