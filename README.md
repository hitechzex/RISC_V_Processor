RISC-V Processor in Verilog
===========================

Overview
--------
This project implements a 5-stage pipelined RISC-V processor in Verilog, supporting a simplified RV32I instruction set. It handles R-type, I-type, LW, and SW instructions. Data hazards are resolved via a stall mechanism that detects RAW (Read After Write) conflicts to ensure correct pipeline execution.

Modules
-------

1. instruction_fetch.v
   - Fetches 32-bit instructions from instruction memory using the Program Counter (PC).
   - Supports PC incrementing logic and conditional PC hold in case of pipeline stall.
   - Operates on word-aligned instruction addresses using `PC[31:2]`.

2. instruction_decode.v
   - Decodes instruction into fields: `opcode`, `rd`, `rs1`, `rs2`, `funct3`, `funct7`, and immediate `imm`.
   - Implements hazard detection logic: stalls the pipeline when a source register depends on a result still in the execution stage or memory stage (register or memory-based RAW hazard).

3. execution.v
   - Executes arithmetic and logical operations using a simple ALU.
   - Instruction type and control fields (opcode, funct3, funct7) determine operation.

4. data_memory.v
   - Models data memory with 16 words of 32-bit entries.
   - Simulates data persistence used in real systems for saving temporary or long-term variables.

5. instruction_memory.v
   - Contains the full instruction set of the program.
   - Modeled as a ROM-like structure for word-aligned instruction access.
   - Initialized through the testbench to represent program logic.

6. register_file.v
   - Implements 32 general-purpose registers.
   - Registers are used to store intermediate results from logic and arithmetic operations and to temporarily hold values that may override or substitute data memory contents during instruction execution.

7. processor.v
   - Top-level module integrating all pipeline stages.
   - Propagates control and data signals between stages.
   - Handles global stall signal to pause PC and pipeline flow during hazards.

8. tb_processor.v
   - Provides simulation environment and stimuli for validation.
   - Initializes instruction and data memory and drives the clock/reset signals.
   - Includes a reference model for registers and data memory, and performs cycle-accurate comparisons post-simulation.
   - Generates detailed match/mismatch logs and reports final test status.

Simulation Screenshot
---------------------
[Simulation Waveform]https://github.com/hitechzex/RISC_V_Processor/blob/main/simulation_screenshot.png

