module debounce_btn(input clk, btn, output reg btn_trigger);
    reg [2:0] curr_state = 0;
    integer debounce_count = 0;
    
    // Constants for 100MHz clock
    localparam INITIAL_LOCKOUT = 20_000_000; // 200ms
    localparam REPEAT_DELAY    = 60_000_000; // 0.6 second
    localparam HELD_DELAY    = 20_000_000; // 0.2 second
    localparam RELEASE_WINDOW  = 2_000_000;  // 20ms

    always @(posedge clk) begin
        btn_trigger <= 0; // Default pulse state
        
        case (curr_state)
            0: begin // IDLE
                if (btn) begin
                    btn_trigger <= 1;
                    debounce_count <= INITIAL_LOCKOUT;
                    curr_state <= 1;
                end
            end
            
            1: begin // INITIAL DEBOUNCE LOCKOUT
                if (debounce_count > 0) begin
                    debounce_count <= debounce_count - 1;
                end else begin
                    debounce_count <= REPEAT_DELAY; // Prepare the 1s repeat timer
                    curr_state <= 2;
                end
            end
            
            2: begin // HOLD & AUTO-REPEAT
                if (!btn) begin
                    // Button released, go to release debounce
                    debounce_count <= RELEASE_WINDOW;
                    curr_state <= 3;
                end else if (debounce_count > 0) begin
                    debounce_count <= debounce_count - 1;
                end else begin
                    // Timer reached 1s and button is still pressed
                    btn_trigger <= 1;
                    debounce_count <= HELD_DELAY; // Reset repeat timer
                end
            end
            
            3: begin // RELEASE DEBOUNCE
                if (btn) begin
                    // It was a bounce, go back to holding state
                    debounce_count <= 1000;
                    curr_state <= 2; 
                end else if (debounce_count > 0) begin
                    debounce_count <= debounce_count - 1;
                end else begin
                    curr_state <= 0; 
                end
            end
            
            default: curr_state <= 0;
        endcase
    end
endmodule