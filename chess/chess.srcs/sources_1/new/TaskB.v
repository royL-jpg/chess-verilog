//`timescale 1ns / 1ps

//module TaskB(
//    input CLOCK,                // 100MHz clock
//    input btnc, btnl, btnr, btnu, btnd, // Debounced hardware buttons
//    output reg [6:0] seg,       // 7-segment segments
//    output reg [3:0] an,        // 7-segment anodes
//    output reg UNLOCK = 0,      // Signal to main.v to switch screens
//    output [2:0] state_out      // Connects to instruction_box for UI progress
//    );
    
//    reg [2:0] state = 0; 
//    assign state_out = state;
    
//    // --- Edge Detection Logic ---
//    // Prevents the "skipping" issue by detecting the moment a button is pressed.
//    reg btnc_p, btnl_p, btnr_p, btnu_p, btnd_p;
//    wire pulse_c = btnc && !btnc_p;
//    wire pulse_l = btnl && !btnl_p;
//    wire pulse_r = btnr && !btnr_p;
//    wire pulse_u = btnu && !btnu_p;
//    wire pulse_d = btnd && !btnd_p;
//    wire any_p   = pulse_c | pulse_l | pulse_r | pulse_u | pulse_d;

//    always @ (posedge CLOCK) begin
//        btnc_p <= btnc; btnl_p <= btnl; btnr_p <= btnr;
//        btnu_p <= btnu; btnd_p <= btnd;

//        case(state)
//            // STEP 0: IDLE
//            0: begin 
//                an <= 4'b1110; seg <= 7'b0100111; // Display 'c'
//                UNLOCK <= 0;
//                if (any_p) state <= pulse_c ? 1 : 0; 
//            end
//            // STEP 1: LEFT
//            1: begin 
//                an <= 4'b1110; seg <= 7'b1110001; // Display 'L'
//                if (any_p) state <= pulse_l ? 2 : 0; 
//            end 
//            // STEP 2: RIGHT
//            2: begin 
//                an <= 4'b1101; seg <= 7'b1111010; // Display 'r'
//                if (any_p) state <= pulse_r ? 3 : 0; 
//            end 
//            // STEP 3: UP
//            3: begin 
//                an <= 4'b1011; seg <= 7'b1000001; // Display 'U'
//                if (any_p) state <= pulse_u ? 4 : 0; 
//            end 
//            // STEP 4: DOWN
//            4: begin 
//                an <= 4'b0111; seg <= 7'b1000010; // Display 'd'
//                if (any_p) state <= pulse_d ? 5 : 0; 
//            end 
//            // STEP 5: UNLOCKED
//            5: begin 
//                UNLOCK <= 1;
//                an <= 4'b1111; // Turn off 7-segment display to save power/focus on OLED
//            end
//            default: state <= 0;
//        endcase
//    end
//endmodule




`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: TaskB
// Description: Single-button unlock - press btnC once to unlock.
//              LRUD password sequence removed.
//////////////////////////////////////////////////////////////////////////////////

module TaskB(
    input CLOCK,
    input btnc, btnl, btnr, btnu, btnd,
    output reg [6:0] seg,
    output reg [3:0] an,
    output reg UNLOCK = 0,
    output [2:0] state_out
    );

    reg [2:0] state = 0;
    assign state_out = state;

    reg btnc_p;
    wire pulse_c = btnc && !btnc_p;

    always @ (posedge CLOCK) begin
        btnc_p <= btnc;

        case (state)
            // IDLE: display 'C' on 7-seg, wait for center press
            0: begin
                an     <= 4'b1110;
                seg    <= 7'b0100111; // 'c'
                UNLOCK <= 0;
                if (pulse_c) state <= 1;
            end
            // UNLOCKED
            1: begin
                UNLOCK <= 1;
                an     <= 4'b1111;   // blank 7-seg
                seg    <= 7'b1111111;
            end
            default: state <= 0;
        endcase
    end
endmodule
