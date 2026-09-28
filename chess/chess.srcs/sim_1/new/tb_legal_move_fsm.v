`timescale 1ns / 1ps

module tb_legal_move_fsm();

    // Inputs to the Module
    reg clk;
    reg start;
    reg [3:0] selected_p;
    reg [5:0] start_tile;
    reg [255:0] board_flat;

    // Outputs from the Module
    wire [63:0] legal_mask;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    legal_move_fsm uut (
        .clk(clk),
        .start(start),
        .selected_p(selected_p),
        .start_tile(start_tile),
        .board_flat(board_flat),
        .legal_mask(legal_mask),
        .done(done)
    );

    // Clock Generation: 100MHz (10ns period)
    always #10 clk = ~clk;

    // Helper Task to Run a Test Case
    task run_test(input [3:0] piece, input [5:0] tile, input [255:0] board);
        begin
            selected_p = piece;
            start_tile = tile;
            board_flat = board;
            @(posedge clk);
            start = 1;   // Pulse Start
            @(posedge clk);
            start = 1;
            
            wait(done);     // Wait for the FSM to finish 64 cycles
            start = 0;
            $display("Test Finished for Piece %d at Tile %d. Mask: %h", piece, tile, legal_mask);
            #20;            // Small gap between tests
        end
    endtask

    initial begin
        // Initialize Signals
        clk = 0;
        start = 0;
        board_flat = 0; // Clear Board
        
        // Setup a Test Board
        // White Rook (Type 4, White 0) = 4'b0100 (4) at (0,0) [Index 0]
        // Black Pawn (Type 1, Black 1) = 4'b1001 (9) at (0,3) [Index 3] (Obstacle)
        // White Piece (Teammate)       = 4'b0010 (2) at (3,0) [Index 24] (Blocking)
        
        board_flat[0*4 +: 4] = 4'd4; // White Rook at 0
        board_flat[3*4 +: 4] = 4'd9; // Black Pawn at 3 (Capture target)
        board_flat[24*4 +: 4] = 4'd2; // White Bishop at 24 (Friend)

        #100; // Wait for Global Reset

        // --- TEST 1: WHITE ROOK ---
        $display("Testing White Rook at index 0...");
        run_test(4'd4, 6'd0, board_flat);

        // --- TEST 2: WHITE KNIGHT ---
        // Move a Knight to center (index 27) and check jumps
        $display("Testing White Knight at index 27...");
        run_test(4'd2, 6'd27, board_flat);

        // --- TEST 3: PAWN ---
        $display("Testing White Pawn at index 8...");
        run_test(4'd1, 6'd8, board_flat);

        $finish;
    end

endmodule