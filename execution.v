module execution(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    input signed [31:0] read_data1, read_data2, imm,
    output reg signed [31:0] result
);
    always @(*) begin
        case (opcode)
            7'b0010011: begin // I-type
                case (funct3)
                    3'b000: result = read_data1 + imm;        // ADDI
                    3'b100: result = read_data1 ^ imm;        // XORI
                    3'b110: result = read_data1 | imm;        // ORI
                    3'b111: result = read_data1 & imm;        // ANDI
                    3'b001: result = read_data1 <<< imm[4:0]; // SLLI
                    3'b101: result = read_data1 >>> imm[4:0]; // SRLI
                    default: result = 32'b0;
                endcase
            end
            7'b0110011: begin // R-type
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: result = read_data1 + read_data2;  // ADD
                    {7'b0100000, 3'b000}: result = read_data1 - read_data2;  // SUB
                    {7'b0000000, 3'b100}: result = read_data1 ^ read_data2;  // XOR
                    {7'b0000000, 3'b110}: result = read_data1 | read_data2;  // OR
                    {7'b0000000, 3'b111}: result = read_data1 & read_data2;  // AND
                    {7'b0000000, 3'b001}: result = read_data1 <<< read_data2[4:0]; // SLL
                    {7'b0000000, 3'b101}: result = read_data1 >>> read_data2[4:0]; // SRL
                    default: result = 32'b0;
                endcase
            end
            7'b0000011, 7'b0100011: begin // LW / SW
                result = read_data1 + imm;
            end
            default: result = 32'b0;
        endcase
    end
endmodule
