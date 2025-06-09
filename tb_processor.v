module tb_processor();
  reg clk;
  reg reset;
  wire done;
  
  integer i; 

  // DUT instantiation
  processor #(.END_PC(32'h1C)) dut (.clk(clk), .reset(reset), .done(done));
  
  // Reference Models
  reg signed [31:0] ref_regs [0:31];
  reg signed [31:0] ref_data_mem  [0:15];
  reg signed [31:0] ref_instr_mem [0:15];

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Dumpfile
  initial begin
    $dumpfile("processor.vcd");
    $dumpvars(0, dut);

    for (i = 0; i < 16; i = i + 1) begin
      $dumpvars(0, tb_processor.dut.IM.mem[i]);
      $dumpvars(0, tb_processor.dut.DM.mem[i]);
    end
    for (i = 0; i < 32; i = i + 1) begin
      $dumpvars(0, tb_processor.dut.RF.regs[i]);
    end
	
  end

  // Load instructions and update reference
  task load_instruction_memory_and_reference;
    integer i;
    begin  

      ref_instr_mem[0] = 32'b000000001010_00010_000_00101_0010011; // ADDI x5, x2, 10
      ref_instr_mem[1] = 32'b000000000101_00010_000_00110_0010011; // ADDI x6, x2, 5
      ref_instr_mem[2] = 32'b000000000001_00111_001_00011_0010011; // SLLI x3, x7, 1
      ref_instr_mem[3] = 32'b0000000_00101_00000_010_00100_0100011; // SW x5, 4(x0)
      ref_instr_mem[4] = 32'b0000000_00100_00000_010_00110_0000011; // LW x6, 4(x0)
	  ref_instr_mem[5] = 32'b010000000010_00001_000_00100_0110011; // SUB x4, x1, x2
      ref_instr_mem[6] = 32'b000000000100_00011_100_00101_0110011; // XOR x5, x3, x4
      ref_instr_mem[7] = 32'b000000001111_00110_111_00111_0010011; // ANDI x7, x6, 0xF
	  
	  for (i = 8; i < 16; i = i + 1)
        ref_instr_mem[i] = 0;
	  
      for (i = 0; i < 16; i = i + 1)
        dut.IM.mem[i] = ref_instr_mem[i];

    end
  endtask

  // Load register file and update reference
  task load_register_file_and_reference;
    integer i;
    begin
      for (i = 1; i < 32; i = i + 1) begin
        ref_regs[i] = i * 10;
        dut.RF.regs[i] = ref_regs[i];
      end
      ref_regs[0] = 0;
      dut.RF.regs[0] = 0;
    end
  endtask

  // Load data memory and update reference
  task load_data_memory_and_reference;
    integer i;
    begin
      for (i = 0; i < 16; i = i + 1) begin
        ref_data_mem[i] = i * 100;
        dut.DM.mem[i] = ref_data_mem[i];
      end
    end
  endtask

  // Monitor and update reference model
  task monitor_and_update_reference;
    reg [31:0] instr;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] imm;
    reg [31:0] val1, val2;
    begin
      instr = dut.ID.instr;
      opcode = instr[6:0];
      rd = instr[11:7];
      funct3 = instr[14:12];
      rs1 = instr[19:15];
      rs2 = instr[24:20];
      funct7 = instr[31:25];
      val1 = ref_regs[rs1];
      val2 = ref_regs[rs2];

      // Immediate generation
      if (opcode == 7'b0010011 || opcode == 7'b0000011)
        imm = {{20{instr[31]}}, instr[31:20]};
      else if (opcode == 7'b0100011)
        imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      else
        imm = 32'b0;

      // Register writes
      if (dut.reg_write && rd != 0) begin
        case (opcode)
          7'b0010011: begin
            case (funct3)
              3'b000: ref_regs[rd] = val1 + imm;
              3'b100: ref_regs[rd] = val1 ^ imm;
              3'b110: ref_regs[rd] = val1 | imm;
              3'b111: ref_regs[rd] = val1 & imm;
              3'b001: ref_regs[rd] = val1 << imm[4:0];
              3'b101: ref_regs[rd] = val1 >> imm[4:0];
            endcase
          end
          7'b0110011: begin
            case ({funct7, funct3})
              {7'b0000000, 3'b000}: ref_regs[rd] = val1 + val2;
              {7'b0100000, 3'b000}: ref_regs[rd] = val1 - val2;
              {7'b0000000, 3'b100}: ref_regs[rd] = val1 ^ val2;
              {7'b0000000, 3'b110}: ref_regs[rd] = val1 | val2;
              {7'b0000000, 3'b111}: ref_regs[rd] = val1 & val2;
              {7'b0000000, 3'b001}: ref_regs[rd] = val1 << val2[4:0];
              {7'b0000000, 3'b101}: ref_regs[rd] = val1 >> val2[4:0];
            endcase
          end
          7'b0000011: ref_regs[rd] = ref_data_mem[(val1 + imm) >> 2]; // LW
        endcase
      end

      // Memory write
      if (dut.mem_write)
        ref_data_mem[(val1 + imm) >> 2] = val2;
    end
  endtask

  // Compare register/memory data against reference model
  task verify_all;
    integer j;
    integer errors;
    begin
      errors = 0;

      $display("Verifying Register File...");
      for (j = 0; j < 32; j = j + 1) begin
        if ($signed(dut.RF.regs[j]) !== ref_regs[j]) begin
          $display("Mismatch in reg[%0d]: expected=%0d, got=%0d", j, ref_regs[j], $signed(dut.RF.regs[j]));
          errors = errors + 1;
        end else begin
          $display("Match in reg[%0d]: expected=%0d, got=%0d", j, ref_regs[j], $signed(dut.RF.regs[j]));
        end
      end

      $display("Verifying Data Memory...");
      for (j = 0; j < 16; j = j + 1) begin
        if (dut.DM.mem[j] !== ref_data_mem[j]) begin
          $display("Mismatch in data_mem[%0d]: expected=%0d, got=%0d", j, ref_data_mem[j], $signed(dut.DM.mem[j]));
          errors = errors + 1;
        end else begin
          $display("Match in data_mem[%0d]: expected=%0d, got=%0d", j, ref_data_mem[j], $signed(dut.DM.mem[j]));
        end
      end

      $display("Verifying Instruction Memory...");
      for (j = 0; j < 16; j = j + 1) begin
        if (dut.IM.mem[j] !== ref_instr_mem[j]) begin
          $display("Mismatch in instr_mem[%0d]: expected=%b, got=%b", j, ref_instr_mem[j], dut.IM.mem[j]);
          errors = errors + 1;
        end else begin
          $display("Match in instr_mem[%0d]: expected=%b, got=%b", j, ref_instr_mem[j], dut.IM.mem[j]);
        end
      end

      if (errors == 0)
        $display("All models match. SUCCESS!");
      else
        $display("Total errors: %0d", errors);
    end
  endtask

  // Main simulation block
  initial begin
    reset = 1;
	#10 reset = 0;

    // Load all memories/registers before releasing reset
    load_instruction_memory_and_reference();
    load_register_file_and_reference();
    load_data_memory_and_reference();
	// Wait for 'done' signal signaling end of program execution
    @(posedge done);
    #100;
    verify_all();
    $finish;
  end

  // Live reference model updater
  always @(posedge clk) begin
    monitor_and_update_reference();
  end
endmodule
