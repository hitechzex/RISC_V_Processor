module register_file(
    input clk,
    input reset,
    input [4:0] rs1, rs2, rd,
    input reg_write,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] regs[0:31];
    
	// Registers read
    assign read_data1 = regs[rs1];
    assign read_data2 = regs[rs2];

	integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
		// Registers write
        end else if (reg_write && rd != 0) begin
            regs[rd] <= write_data;
        end
    end
endmodule
