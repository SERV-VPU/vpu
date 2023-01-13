module vector_32_bit_alignment_decoder#(
    parameter VLEN = 256
)(
    input wire [31:0] i_ALU_R,
    input wire [2:0]  i_width,
    output reg [$clog2(VLEN/32)-1:0] o_address,
    output reg o_last_index,
    output reg last_sub_index
);
always @(i_ALU_R[3:0] or i_width) begin
    case(i_width)
        3'b000: begin
            o_address = i_ALU_R[$clog2(VLEN/32)+1:2];  // 8 bits
            last_sub_index = &i_ALU_R[1:0];
        end
        3'b101: begin
            o_address = i_ALU_R[$clog2(VLEN/32):1];  //16 bits
            last_sub_index = i_ALU_R[0];
        end
        3'b110: begin
            o_address = i_ALU_R[$clog2(VLEN/32)-1:0];     //32 bits
            last_sub_index = 1'b1;
        end
        default: begin
            o_address = i_ALU_R[$clog2(VLEN/32)+1:2];  // default to 8 bits
            last_sub_index = &i_ALU_R[1:0];
        end
    endcase
    o_last_index = last_sub_index & (&o_address);
end
endmodule