module instruction_memory(
    input clk,
    input reset,
    input [31:0] addr,
    output reg [31:0] instr
);
    reg [31:0] mem [0:15];
    reg [31:0] addr_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            instr <= 32'b0;
		// Each instruction is 32 bits (1 word), so use addr[31:2] for word indexing
        else
            instr <= mem[addr[31:2]];
    end

    // Expose for testbench access
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1)
            mem[i] = 32'b0;
    end
endmodule
