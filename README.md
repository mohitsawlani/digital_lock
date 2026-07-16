# Digital Lock — FSM-Based Combination Lock (Verilog)

A 4-digit combination lock in Verilog, simulated in Vivado. Enter the right switch sequence and it unlocks (with a 30-second auto re-lock timer); enter a wrong one and it locks into an alarm state until reset.

Built this to actually learn Verilog hands-on — coming from C++, the biggest shift was realizing everything here runs in parallel, not top to bottom.

## How it works

Six modules, all on one clock:
- **dff** — basic D flip-flop
- **edgedet** — two `dff`s chained to turn a messy button press into a clean 1-cycle pulse
- **lockfsm** — Moore FSM (`s0, s1, s2, s3, unlock, wrong`) that reads the pulses and decides what to do
- **Timer** — 300-cycle counter, auto re-locks 30s after unlock
- **segdisp** — 7-segment display: `L` (locked), `U` (unlocked), `A` (alarm)
- **comblock** — top module wiring it all together

Wrong key at any point → `wrong` state → alarm stays latched until hardware reset.

## Files

- `digital_lock.v` — all six modules
- `tb_digital_lock.v` — testbench, runs correct password / auto-lock wait / wrong password

## Running it

1. Add both files to a Vivado project, set `comblock` as top, `test_comblock` as sim top.
2. Run Behavioral Simulation.
3. Watch `clock`, `clear`, `switches[7:0]`, `alarm`, `locked`, `SA`–`SG` in the waveform viewer.

## Simulation results

- Correct sequence → `locked` drops LOW a couple cycles after the last key (edge detector delay).
- ~30s later → auto re-locks, exactly as the 300-cycle timer predicts.
- Wrong key → `alarm` drops LOW and stays there until a `clear` pulse.


