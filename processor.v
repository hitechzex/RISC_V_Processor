module processor #(parameter END_PC = 32'h1C)(
  input clk,
  input reset,
  output reg done
);
  // Wires for inter-module communication
    wire [31:0] instr;
    wire [6:0]  opcode;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] imm;
    wire [31:0] pc;
    wire [31:0] reg1, reg2;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] write_back_data;
    wire reg_write;
    wire mem_read, mem_write;
    wire stall;

    // Pipeline register to hold previous instruction’s destination register
    reg [4:0]  ex_rd;
    reg        ex_reg_write;

    instruction_fetch IF (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .pc(pc)
    );

    instruction_memory IM (
        .clk(clk),
        .reset(reset),
        .addr(pc),
        .instr(instr)
    );

    instruction_decode ID (
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .ex_rd(ex_rd),
        .ex_reg_write(ex_reg_write),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7),
        .imm(imm),
        .stall(stall)
    );

    register_file RF (
        .clk(clk),
        .reset(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_write(reg_write),
        .write_data(write_back_data),
        .read_data1(reg1),
        .read_data2(reg2)
    );

    execution EX (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .read_data1(reg1),
        .read_data2(reg2),
        .imm(imm),
        .result(alu_result)
    );

    assign mem_read  = (opcode == 7'b0000011); // LW
    assign mem_write = (opcode == 7'b0100011); // SW

    data_memory DM (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(alu_result),
        .write_data(reg2),
        .read_data(mem_read_data)
    );

    assign reg_write = (opcode == 7'b0110011 || opcode == 7'b0010011 || opcode == 7'b0000011);
    assign write_back_data = (opcode == 7'b0000011) ? mem_read_data : alu_result;

	// Stores destination register index and write flag for hazard detection (stalling logic)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_rd <= 0;
            ex_reg_write <= 0;
        end else begin
            ex_rd <= rd;
            ex_reg_write <= reg_write;
        end
    end

  // Done signal logic
  always @(posedge clk or posedge reset) begin
    if (reset)
      done <= 0;
	// Reached to the end of instruction memory region
    else if (pc == END_PC)
      done <= 1;
  end
endmodule