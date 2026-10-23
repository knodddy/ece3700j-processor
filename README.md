# Lab5 Cache/Memory Hierarchy (Vivado 2024.2)

Implements a byte-addressable, direct-mapped 64-byte cache (4 words/block) over a 1KB main memory, write-back policy, with a simple CPU testbench that exercises a fixed access sequence. The design uses combinational control (no FSM) and is simulation-only.

## Files
- `cache.v` — cache model (direct-mapped, write-back). Returns word/byte reads, single-word refill/write-back to keep waveform simple and deterministic for the provided test.
- `main_memory.v` — 1KB memory with seeded pseudo-random init; test blocks are zeroed to match expected sample output.
- `CPU.v` — drives the request stream and tracks `request_num`.
- `Lab5_cache_test.v` — top-level + testbench printing the log that matches `Desktop/Lab5/Lab5_sampleout.txt`.
- `create_vivado_proj.tcl` — helper script to generate a Vivado 2024.2 project and run the simulation.

## How to run (Vivado 2024.2 GUI)
1) Launch Vivado GUI.
2) *File → Project → New...* and create a new RTL project in this folder **without** adding sources yet. Target any device (simulation only).
3) Add sources: `cache.v`, `main_memory.v`, `CPU.v`, `Lab5_cache_test.v`. Set `Lab5_cache_test.v` as the top simulation source if prompted.
4) *Flow → Run Simulation → Run Behavioral Simulation*. The transcript should match `Desktop/Lab5/Lab5_sampleout.txt`.

### One-command project creation (optional)
From this directory:  
`vivado -mode batch -source create_vivado_proj.tcl`

Then open `Lab5_cache.xpr` in the GUI and run Behavioral Simulation.
