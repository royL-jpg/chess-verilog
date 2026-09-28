`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2026 13:12:35
// Design Name: 
// Module Name: debounce_sw
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debounce_sw(input clk,btn,output reg btn_trigger);
    reg [2:0] curr_state;
    integer debounce_count = 0;
    always @(posedge clk) begin
        btn_trigger <= 0; // Default to 0, only pulses for 1 cycle
        case (curr_state)
            0: begin // Idle: Waiting for a press
                if (btn) begin
                    btn_trigger <= 1;        // Trigger color change immediately
                    curr_state <= 1;
                    debounce_count <= 20_000_000; // 200ms at 100MHz
                end
            end          
            1: begin // Press Lockout: Ignore everything for 200ms
                if (debounce_count > 0) begin
                    debounce_count <= debounce_count - 1;
                end else begin
                    curr_state <= 2; // Time's up, move to check for release
                end
            end 
            2: begin // Wait for the user to physically let go of the button
                if (!btn) begin
                    curr_state <= 3;
                    debounce_count <= 2_000_000; // 20ms release debounce window
                end
            end
            3: begin // Release Debounce: Ensure the release is clean and stable
                if (btn) begin
                    // Button bounced back to 1! It wasn't a clean release.
                    curr_state <= 2; 
                end else if (debounce_count > 0) begin
                    debounce_count <= debounce_count - 1;
                end else begin
                    // Button stayed at 0 for the whole 20ms. Clean release.
                    curr_state <= 0; 
                end
            end
        endcase
    end
endmodule
