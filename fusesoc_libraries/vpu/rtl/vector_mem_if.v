module vector_mem_if #(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] mem_inputs,
    input wire [1:0]       shift_offset,
    input wire [2:0]       i_width,
    input wire [1:0]       i_Vreg_shift,
    output reg [WIDTH-1:0] o_mem_outputs
);

reg [1:0]       Vreg_shift;
always @(i_Vreg_shift or i_width) begin
    case(i_width)
        3'b000:  begin
                    Vreg_shift = i_Vreg_shift;
                end
        3'b110:  begin
                    Vreg_shift = i_Vreg_shift << 2;
                end
        3'b101:  begin
                    Vreg_shift = i_Vreg_shift << 1;
                end
        default: begin
                    Vreg_shift = i_Vreg_shift;
                end
    endcase
end

wire [1:0] error = shift_offset - Vreg_shift;

always @(mem_inputs or error) begin
    case(error)
        2'b00:  begin
                    o_mem_outputs = mem_inputs;
                end
        2'b11:  begin
                    o_mem_outputs[31:24] = mem_inputs[7:0];
                    o_mem_outputs[23:0] = mem_inputs[31:8];
                end
        2'b10:  begin
                    o_mem_outputs[31:16] = mem_inputs[15:0];
                    o_mem_outputs[15:0] = mem_inputs[31:16];
                end
        2'b01:  begin
                    o_mem_outputs[31:8] = mem_inputs[23:0];
                    o_mem_outputs[7:0] = mem_inputs[31:24];
                end
    endcase
end


endmodule
