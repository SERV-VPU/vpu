module vector_mask_decoder#(
    parameter VLEN = 256
)(
 input wire [VLEN-1:0] i_mask,
 input wire            i_first_fault,
 input wire            i_mask_skip,
 output reg            o_fault_occur,
 output reg [3:0] o_UpdateBits,
 input wire [2:0] i_element_width,
 input wire [$clog2(VLEN)-1:0] i_address,
 output reg o_ALU2_16,
 output reg o_ALU2_8

);

reg [$clog2(VLEN)-1:0] effective_address = i_address;
reg [3:0] effective_UpdateBits_1;
reg [31:0] effective_UpdateBits_0;

    always @(effective_UpdateBits_0 or effective_address[3:2] or i_mask_skip or i_mask[15:0]) begin
        if(i_mask_skip) effective_UpdateBits_1 = 4'b1111;
        else
            case(effective_address[4:2])
                3'b000: effective_UpdateBits_1 = i_mask[3:0];
                3'b001: effective_UpdateBits_1 = i_mask[7:4];
                3'b010: effective_UpdateBits_1 = i_mask[11:8];
                3'b011: effective_UpdateBits_1 = i_mask[15:12];
                3'b100: effective_UpdateBits_1 = i_mask[19:16];
                3'b101: effective_UpdateBits_1 = i_mask[23:20];
                3'b110: effective_UpdateBits_1 = i_mask[27:24];
                3'b111: effective_UpdateBits_1 = i_mask[31:28];
                default: effective_UpdateBits_1 = i_mask[3:0];
            endcase
    end
    
always @(effective_UpdateBits_1 or effective_address[1:0] or i_element_width or i_first_fault) begin
    o_ALU2_16 = 1'b0;
    o_ALU2_8 = 1'b0;
    case (i_element_width) 
        3'b000:  begin
                    if(i_first_fault) begin
                        case(effective_address[1:0])
                            2'b00:o_UpdateBits = {3'd0, effective_UpdateBits_1[0]};
                            2'b01:o_UpdateBits = {2'd0, &effective_UpdateBits_1[1:0], 1'b0};
                            2'b10:o_UpdateBits = {1'd0, &effective_UpdateBits_1[2:0], 2'b0};
                            2'b11:o_UpdateBits = {&effective_UpdateBits_1[3:0], 3'b0};
                        endcase
                    end
                    else begin
                        case(effective_address[1:0])
                            2'b00:o_UpdateBits = {3'd0, effective_UpdateBits_1[0]};
                            2'b01:o_UpdateBits = {2'd0, effective_UpdateBits_1[1], 1'b0};
                            2'b10:o_UpdateBits = {1'd0,effective_UpdateBits_1[2], 2'b0};
                            2'b11:o_UpdateBits = {effective_UpdateBits_1[3], 3'b0};
                        endcase
                    end
                    o_ALU2_8 = 1'b1;
                end
        3'b101: begin
            if(i_first_fault) begin
                case (effective_address[0])
                    1'b0: o_UpdateBits = {2'd0, {2{effective_UpdateBits_1[0]}}};
                    1'b1: o_UpdateBits = {{2{effective_UpdateBits_1[1]&effective_UpdateBits_1[0]}}, 2'd0};
                endcase
            end
            else begin
                case (effective_address[0])
                    1'b0: o_UpdateBits = {2'd0, {2{effective_UpdateBits_1[0]}}};
                    1'b1: o_UpdateBits = {{2{effective_UpdateBits_1[1]}}, 2'd0};
                endcase
            end
            o_ALU2_16 = 1'b1;
        end
        3'b110: begin
            case (effective_address[1:0])
                2'b00: o_UpdateBits = {4{effective_UpdateBits_1[0]}};
                2'b01: o_UpdateBits = {4{effective_UpdateBits_1[1]}};
                2'b10: o_UpdateBits = {4{effective_UpdateBits_1[2]}};
                2'b11: o_UpdateBits = {4{effective_UpdateBits_1[3]}};
            endcase
        end
        default: begin
            o_UpdateBits = effective_UpdateBits_1;
        end

    endcase
    o_fault_occur = i_first_fault&(~|o_UpdateBits);
end

endmodule
