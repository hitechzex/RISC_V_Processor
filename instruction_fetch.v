module instruction_fetch(
    input clk,
    input reset,
    input stall,
    output reg [31:0] pc
);
    parameter END_PC = 32'h1C;

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 0;
        // If not stalled and end of program not reached, increment PC to next instruction
        else if (!stall && pc != END_PC)
            pc <= pc + 4;
    end
endmodule
