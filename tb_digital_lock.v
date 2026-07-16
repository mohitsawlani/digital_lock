// ============================================================
//  TESTBENCH — based on PDF Listing 8.15 (test_comblock)
//  Tests: correct password, auto-lock timeout, wrong password
// ============================================================
`timescale 1ms / 1ms

module test_comblock();

  reg clock, clear;
  reg [7:0] switches;
  wire alarm, locked;
  wire SA, SB, SC, SD, SE, SF, SG;

  // Instantiate the top-level lock (named UUT like in the PDF)
  comblock UUT(
    .clock(clock), .clear(clear),
    .switches(switches),
    .alarm(alarm), .locked(locked),
    .SA(SA), .SB(SB), .SC(SC), .SD(SD),
    .SE(SE), .SF(SF), .SG(SG)
  );

  // 10 Hz clock (period = 100ms, half-period = 50ms)
  initial begin
    clock = 1'b0;
    forever #50 clock = ~clock;
  end

  initial begin
    // --- Setup ---
    clear     = 1'b1;
    switches  = 8'b11111111;   // all buttons released (active-low)
    repeat(3) @(negedge clock);
    clear = 1'b0;
    repeat(3) @(negedge clock);

    // -------------------------------------------------------
    // TEST 1: Correct password -> should UNLOCK
    // Sequence: SW[0] SW[1] SW[2] SW[3]
    // -------------------------------------------------------
    $display("--- Correct password ---");

    switches[0] = 1'b0; repeat(2) @(negedge clock);   // press SW0
    switches[0] = 1'b1; repeat(3) @(negedge clock);   // release

    switches[1] = 1'b0; repeat(2) @(negedge clock);   // press SW1
    switches[1] = 1'b1; repeat(3) @(negedge clock);

    switches[2] = 1'b0; repeat(2) @(negedge clock);   // press SW2
    switches[2] = 1'b1; repeat(3) @(negedge clock);

    switches[3] = 1'b0; repeat(2) @(negedge clock);   // press SW3
    switches[3] = 1'b1; repeat(3) @(negedge clock);

    // locked=0 means UNLOCKED, alarm=1 means no alarm
    $display("locked=%b alarm=%b (expect: 0 1)", locked, alarm);

    // -------------------------------------------------------
    // TEST 2: Wait for auto-lock (300 clocks = 30s)
    // -------------------------------------------------------
    $display("--- Waiting for auto-lock... ---");
    repeat(400) @(negedge clock);
    $display("locked=%b (expect: 1 = re-locked)", locked);

    // -------------------------------------------------------
    // TEST 3: Wrong password -> ALARM
    // Press SW[0] correct, then SW[5] wrong
    // -------------------------------------------------------
    $display("--- Wrong password ---");
    clear = 1'b1; repeat(4) @(negedge clock);
    clear = 1'b0; repeat(3) @(negedge clock);

    switches[0] = 1'b0; repeat(2) @(negedge clock);   // correct
    switches[0] = 1'b1; repeat(3) @(negedge clock);

    switches[5] = 1'b0; repeat(2) @(negedge clock);   // WRONG!
    switches[5] = 1'b1; repeat(3) @(negedge clock);

    // alarm=0 means ALARM IS ON (active-low)
    $display("locked=%b alarm=%b (expect: 1 0 = alarm!)", locked, alarm);

    repeat(4) @(negedge clock);
    clear = 1'b1;
    repeat(4) @(negedge clock);
    $stop;
  end

endmodule
