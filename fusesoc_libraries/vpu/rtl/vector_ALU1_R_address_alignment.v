module vector_ALU0_1_address_alignment(
    input wire [2:0] i_width,
    input wire [1:0] i_address,
    input wire [31:0] i_ALU_1,
    output reg [31:0] o_address
);

always @(i_width[1:0] or i_address or i_ALU_1)
    case(i_width[1:0])
        2'b00:  case(i_address)
                    2'b00: o_address = {24'd0, i_ALU_1[7:0]};
                    2'b01: o_address = {24'd0, i_ALU_1[15:8]};
                    2'b10: o_address = {24'd0, i_ALU_1[23:16]};
                    2'b11: o_address = {24'd0, i_ALU_1[31:24]};
                endcase
        2'b01:  case(i_address[0])
                    1'b0: o_address = {16'd0, i_ALU_1[15:0]};
                    1'b1: o_address = {16'd0, i_ALU_1[31:16]};
                endcase
        2'b10:  o_address = i_ALU_1;
        default: o_address = i_ALU_1;
    endcase

endmodule