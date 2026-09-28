`timescale 1ns / 1ps

module seg7(
    input clk,
    input rst,
    input [2:0] set,
    input turn,
    input game_over,
    output [7:0] seg,
    output [3:0] an,
    output time_up,
    
    // ADDED FOR BLITZ MODE
    input is_blitz,
    input [8:0] p1_time,
    input [8:0] p2_time
);

    reg [1:0] curr_an = 0;
    wire clk_500hz;
    slow_clock #(.MAX_COUNT(100_000)) clk2(clk,clk_500hz);
    
    // -----------------------------------------------------------------------
    // CLASSIC MODE COMPONENTS 
    // -----------------------------------------------------------------------
    wire [3:0] num1 ;
    wire [3:0] num2 ;
    wire [3:0] num3 ;
    wire [3:0] num4 ;
    wire [7:0] segment [3:0];
    
    timer timer1(clk,rst,set,turn,game_over,num1,num2,num3,num4);
    
    decoder_7seg d1(clk,num1,segment[0]);
    decoder_7seg d2(clk,num2,segment[1]);
    decoder_7seg d3(clk,num3,segment[2]);
    decoder_7seg d4(clk,num4,segment[3]);
    
    assign time_up = (num1==0) & (num2 == 0) & (num3 == 0) & (num4 ==0);

    // -----------------------------------------------------------------------
    // BLITZ MODE CALCULATIONS
    // -----------------------------------------------------------------------
    // Determine active time based on turn
    wire [8:0] active_time = turn ? p2_time : p1_time;
    
    // Math to extract Minutes and Seconds (Synthesizes easily for values < 300)
    wire [3:0] b_min   = active_time / 60;
    wire [5:0] rem_sec = active_time % 60;
    wire [3:0] b_sec_t = rem_sec / 10;
    wire [3:0] b_sec_o = rem_sec % 10;
    
    // Decoders for Blitz digits
    wire [7:0] b_seg_min, b_seg_sect, b_seg_seco;
    decoder_7seg db1(clk, b_min,   b_seg_min);
    decoder_7seg db2(clk, b_sec_t, b_seg_sect);
    decoder_7seg db3(clk, b_sec_o, b_seg_seco);
    
    // Flash Logic (<10 seconds warning)
    reg [6:0] flash_cnt = 0;
    always @(posedge clk_500hz) flash_cnt <= flash_cnt + 1;
    wire flash_blank = (active_time < 10) && flash_cnt[6];

    // Custom Characters for Game Over (Active Low: DP G F E D C B A)
    wire [7:0] char_P     = 8'b10001100;
    wire [7:0] char_1     = 8'b11111001;
    wire [7:0] char_2     = 8'b10100100;
    wire [7:0] char_L     = 8'b11000111;
    wire [7:0] char_blank = 8'b11111111;

    // -----------------------------------------------------------------------
    // DISPLAY MULTIPLEXER
    // -----------------------------------------------------------------------
    reg [7:0] seg_r;
    reg [3:0] an_r;
    
    always @(posedge clk_500hz) begin
        if (is_blitz) begin
            // 1. Check if a player lost by time
            if (p1_time == 0 || p2_time == 0) begin
                case(curr_an)
                    0: begin an_r <= 4'b1110; seg_r <= char_L; end
                    1: begin an_r <= 4'b1101; seg_r <= char_blank; end
                    2: begin 
                        an_r <= 4'b1011; 
                        // Show '1' or '2' with the DP turned ON (AND with 0x7F clears DP bit)
                        seg_r <= (p1_time == 0) ? (char_1 & 8'b01111111) : (char_2 & 8'b01111111); 
                    end
                    3: begin an_r <= 4'b0111; seg_r <= char_P; end
                endcase
            end
            // 2. Urgent Flash if < 10 seconds
            else if (flash_blank) begin
                an_r <= 4'b1111;
                seg_r <= char_blank;
            end 
            // 3. Normal Blitz Display:  [Blank] [Min.] [SecT] [SecO]
            else begin
                case(curr_an)
                    0: begin an_r <= 4'b1110; seg_r <= b_seg_seco; end
                    1: begin an_r <= 4'b1101; seg_r <= b_seg_sect; end
                    2: begin an_r <= 4'b1011; seg_r <= b_seg_min & 8'b01111111; end // Adds DP
                    3: begin an_r <= 4'b0111; seg_r <= char_blank; end
                endcase
            end
        end 
        else begin
            // --- ORIGINAL CLASSIC DISPLAY ---
            case(curr_an)
                0: begin an_r <= 4'b1110; seg_r <= segment[3]; end
                1: begin an_r <= 4'b1101; seg_r <= segment[2]; end
                2: begin an_r <= 4'b1011; seg_r <= segment[1]; end
                3: begin an_r <= 4'b0111; seg_r <= segment[0]; end
            endcase
        end
        
        curr_an <= curr_an + 1;
    end
    
    assign seg = seg_r;
    assign an = an_r;

endmodule