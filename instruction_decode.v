module instruction_decode(
    input        clk,
    input        reset,
    input [31:0] instr,
    input [4:0]  ex_rd,
    input        ex_reg_write,
    output reg [6:0]  opcode,
    output reg [4:0]  rd,
    output reg [4:0]  rs1,
    output reg [4:0]  rs2,
    output reg [2:0]  funct3,
    output reg [6:0]  funct7,
    output reg [31:0] imm,
    output reg        stall
);

  always @(posedge clk or posedge reset) begin
    if (reset)
      stall <= 0;
    // Stall only if current rs1 or rs2 depends on ex_rd
    else if (ex_reg_write && ex_rd != 0 && (rs1 == ex_rd || rs2 == ex_rd))
      stall <= 1;
    else
      stall <= 0;
  end

  always @(*) begin
    opcode  = instr[6:0];
    rd      = instr[11:7];
    funct3  = instr[14:12];
    rs1     = instr[19:15];
    rs2     = instr[24:20];
    funct7  = instr[31:25];

    case (instr[6:0])
      7'b0010011: imm = {{20{instr[31]}}, instr[31:20]}; // I-type
      7'b0000011: imm = {{20{instr[31]}}, instr[31:20]}; // LW
      7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // SW
      7'b0110011: imm = 32'b0; // R-type
      default:    imm = 32'b0;
    endcase
  end

endmodule
