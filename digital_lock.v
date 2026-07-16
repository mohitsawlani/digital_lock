// ============================================================
//  DIGITAL LOCK — based directly on PDF Listings 8.9 to 8.14
//  All names match the textbook exactly.
//  Password sequence: SW[0] -> SW[1] -> SW[2] -> SW[3]
// ============================================================


// ---- Listing 8.9: D Flip-Flop ----
// Stores 1 bit. Updates on every rising clock edge.
module dff(output reg q, input d, clk);
  always @(posedge clk) q <= d;
endmodule


// ---- Listing 8.10: Edge Detector ----
// Problem: one button press lasts many clock cycles.
// This converts it into exactly 1-cycle pulse.
//
//  edge_in --[DFF0]-- q0 --[DFF1]-- q1
//  detected = q0 & ~q1  (fires for 1 cycle on falling edge)
module edgedet(input edge_in, output detected, input clock);
  wire q0, q1;
  dff dff0(.q(q0), .d(edge_in), .clk(clock));
  dff dff1(.q(q1), .d(q0),      .clk(clock));
  assign detected = q0 & ~q1;   // fixed from PDF (figure shows ~q1)
endmodule


// ---- Listing 8.11: Timer ----
// Counts 300 clock pulses = 30 seconds at 10 Hz.
// Used for auto-lock after unlocking.
module Timer(input Clock, Start, output Timeout);
  localparam NUMCLKS = 300;
  reg [8:0] q;
  always @(posedge Clock) begin
    if (!Start || (q == NUMCLKS))
      q <= 9'b0;        // reset if disabled or done
    else
      q <= q + 1;
  end
  assign Timeout = (q == NUMCLKS);
endmodule


// ---- Listing 8.12: 7-Segment Display Decoder ----
// Displays:  L = Locked   U = Unlocked   A = Alarm
module segdisp(input locked, alarm,
               output SA, SB, SC, SD, SE, SF, SG);
  reg [6:0] seg;
  always @(locked or alarm) begin
    if      (alarm  == 0) seg = 7'b0001000;  // 'A' - alarm
    else if (locked == 0) seg = 7'b1000001;  // 'U' - unlocked
    else                  seg = 7'b1110001;  // 'L' - locked
  end
  assign {SA, SB, SC, SD, SE, SF, SG} = seg;
endmodule


// ---- Listing 8.13: Lock FSM ----
// Heart of the system. Moore FSM with 6 states.
//
// codesw = 1 means correct key was pressed this cycle
// anysw  = 1 means ANY key was pressed this cycle
//
//  Both 1  --> correct key  --> advance to next state
//  Only anysw --> wrong key --> go to ALARM (stuck!)
//  Neither    --> no key    --> stay in current state
module lockfsm(input clock, reset, codesw, anysw,
               output reg [1:0] selsw,
               output locked, alarm, entimer,
               input timeout);

  // State names (same as PDF)
  localparam s0     = 3'b000,   // Locked - waiting for key 1
             s1     = 3'b001,   // Got key 1, waiting for key 2
             s2     = 3'b010,   // Got key 2, waiting for key 3
             s3     = 3'b011,   // Got key 3, waiting for key 4
             wrong  = 3'b100,   // ALARM - wrong key pressed
             unlock = 3'b101;   // UNLOCKED

  reg [2:0] lockstate;

  // Sequential block: decides what state to go to next
  always @(posedge clock or posedge reset) begin
    if (reset == 1'b1)
      lockstate <= s0;
    else
      case (lockstate)
        s0: if (anysw & codesw) lockstate <= s1;
            else if (anysw)     lockstate <= wrong;
            else                lockstate <= s0;

        s1: if (anysw & codesw) lockstate <= s2;
            else if (anysw)     lockstate <= wrong;
            else                lockstate <= s1;

        s2: if (anysw & codesw) lockstate <= s3;
            else if (anysw)     lockstate <= wrong;
            else                lockstate <= s2;

        s3: if (anysw & codesw) lockstate <= unlock;  // All 4 correct!
            else if (anysw)     lockstate <= wrong;
            else                lockstate <= s3;

        wrong:  lockstate <= wrong;          // Stuck - only reset exits
        unlock: if (timeout) lockstate <= s0; // Auto-lock after 30s
                else         lockstate <= unlock;
        default: lockstate <= 3'bx;
      endcase
  end

  // Combinational block: selsw tells the mux which switch to check
  always @(lockstate) begin
    case (lockstate)
      s0:      selsw = 0;
      s1:      selsw = 1;
      s2:      selsw = 2;
      s3:      selsw = 3;
      wrong:   selsw = 0;
      unlock:  selsw = 0;
      default: selsw = 2'bx;
    endcase
  end

  // Output signals (Moore: depend only on current state)
  assign locked  = (lockstate == unlock) ? 0 : 1;
  assign alarm   = (lockstate == wrong)  ? 0 : 1;  // active-low!
  assign entimer = (lockstate == unlock) ? 1 : 0;

endmodule


// ---- Listing 8.14: Top-Level comblock ----
// Wires everything together. Mux and AND gate are inline assigns.
module comblock(input clock, clear,
                input [7:0] switches,
                output alarm, locked,
                output SA, SB, SC, SD, SE, SF, SG);

  wire mux_out, anysw, codesw, allsw, entimer, timeout;
  wire [1:0] selsw;

  // 4-to-1 mux: picks the "expected" switch at each step
  // Password is SW[0]->SW[1]->SW[2]->SW[3] (hardwired)
  assign mux_out = selsw == 0 ? switches[0] :
                  (selsw == 1 ? switches[1] :
                  (selsw == 2 ? switches[2] :
                                switches[3]));

  // AND of all 8 switches: goes LOW if any switch is pressed
  assign allsw = &switches;

  edgedet det1(.edge_in(mux_out), .detected(codesw), .clock(clock));
  edgedet det2(.edge_in(allsw),   .detected(anysw),  .clock(clock));

  Timer t1(.Clock(clock), .Start(entimer), .Timeout(timeout));

  lockfsm controller(.clock(clock),   .reset(clear),
                     .codesw(codesw), .anysw(anysw),
                     .selsw(selsw),   .locked(locked),
                     .alarm(alarm),   .entimer(entimer),
                     .timeout(timeout));

  segdisp sg1(.locked(locked), .alarm(alarm),
              .SA(SA), .SB(SB), .SC(SC), .SD(SD),
              .SE(SE), .SF(SF), .SG(SG));

endmodule
