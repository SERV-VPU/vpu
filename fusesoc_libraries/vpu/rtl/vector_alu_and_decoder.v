module vector_alu_and_decoder
#(
    parameter WIDTH = 32
) (
    input wire [WIDTH-1:0] input1,
    input wire [WIDTH-1:0] input2,
    input wire             i_16bits,
    input wire             i_8bits,
    input wire [3:0]       i_masks,
    output wire [WIDTH-1:0] masked_result,
    output wire extented_result,
    output wire o_is_sat,
    input wire [5:0] i_funct6
);

reg [WIDTH-1:0] result;
wire [WIDTH-1:0] result_buffer;
wire [3:0] overflow;
wire [3:0] saturation;

wire [3:0] msb_result_buffer;
wire [3:0] msb_input1;
wire [3:0] msb_signed_input2;
wire [3:0] e_carry;

wire [WIDTH/4-1:0] signed_input2_0, signed_input2_1, signed_input2_2, signed_input2_3;
wire carry7, carry15, carry23;

reg calculate_code;

//Determines the MSB at different element sizes
//Seperate module?
assign msb_result_buffer[0] = i_8bits ? result_buffer[7] : i_16bits ? result_buffer[15] : result_buffer[31];
assign msb_result_buffer[1] = i_8bits | i_16bits ? result_buffer[15] : result_buffer[31];
assign msb_result_buffer[2] = i_8bits ? result_buffer[23] : result_buffer[31];
assign msb_result_buffer[3] = result_buffer[31];

assign msb_input1[0] = i_8bits ? input1[7] : i_16bits ? input1[15] : input1[31];
assign msb_input1[1] = i_8bits | i_16bits ? input1[15] : input1[31];
assign msb_input1[2] = i_8bits ? input1[23] : input1[31];
assign msb_input1[3] = input1[31];

assign msb_signed_input2[0] = i_8bits ? signed_input2_0[7] : i_16bits ? signed_input2_1[7] : signed_input2_3[7];
assign msb_signed_input2[1] = i_8bits | i_16bits ? signed_input2_1[7] : signed_input2_3[7];
assign msb_signed_input2[2] = i_8bits ? signed_input2_2[7] : signed_input2_3[7];
assign msb_signed_input2[3] = signed_input2_3[7];

assign e_carry[0] = i_8bits ? carry7 : i_16bits ? carry15 : extented_result;
assign e_carry[1] = i_8bits | i_16bits ? carry15 : extented_result;
assign e_carry[2] = i_8bits ? carry23 : extented_result;
assign e_carry[3] = extented_result;

//Overflow detection depending on signed or unsigned operation (i_funct[0])
//Overflow in signed operation is determined by change of sign; unsigned is determined by carryout bit
assign overflow[0] = i_funct6[0] ? (~msb_input1[0] & ~msb_signed_input2[0] & msb_result_buffer[0])|(msb_input1[0] & msb_signed_input2[0] & ~msb_result_buffer[0]) : e_carry[0];
assign overflow[1] = i_funct6[0] ? (~msb_input1[1] & ~msb_signed_input2[1] & msb_result_buffer[1])|(msb_input1[1] & msb_signed_input2[1] & ~msb_result_buffer[1]) : e_carry[1];
assign overflow[2] = i_funct6[0] ? (~msb_input1[2] & ~msb_signed_input2[2] & msb_result_buffer[2])|(msb_input1[2] & msb_signed_input2[2] & ~msb_result_buffer[2]) : e_carry[2];
assign overflow[3] = i_funct6[0] ? (~msb_input1[3] & ~msb_signed_input2[3] & msb_result_buffer[3])|(msb_input1[3] & msb_signed_input2[3] & ~msb_result_buffer[3]) : e_carry[3];

assign o_is_sat = ~(|overflow);

//Determine if saturation value is max(1) or min(0)
//Saturation value for unsigned overflow is determined by the operation, addu is max value; subu is min value
//Saturation value for signed overflow is determined by sign if result, positive is min value; negative is max value
assign saturation[0] = i_funct6[0] ? msb_result_buffer[0] : ~i_funct6[1];
assign saturation[1] = i_funct6[0] ? msb_result_buffer[1] : ~i_funct6[1];
assign saturation[2] = i_funct6[0] ? msb_result_buffer[2] : ~i_funct6[1];
assign saturation[3] = i_funct6[0] ? msb_result_buffer[3] : ~i_funct6[1];

assign signed_input2_0 = calculate_code ? (~input2[7:0]) : input2[7:0];
assign signed_input2_1 = calculate_code ? (~input2[15:8]) : input2[15:8];
assign signed_input2_2 = calculate_code ? (~input2[23:16]) : input2[23:16];
assign signed_input2_3 = calculate_code ? (~input2[31:24]) : input2[31:24];

assign {carry7, result_buffer[7:0]} =  input1[7:0] + signed_input2_0 + {7'd0,{calculate_code}};

assign {carry15, result_buffer[15:8]} =  input1[15:8] + signed_input2_1 + {7'd0,{(i_8bits ? calculate_code : carry7)}};

assign {carry23, result_buffer[23:16]} = input1[23:16] + signed_input2_2 + {7'd0,{((i_16bits | i_8bits) ? calculate_code : carry15)}};

assign {extented_result, result_buffer[31:24]} =  input1[31:24] + signed_input2_3 + {7'd0,{(i_8bits ? calculate_code : carry23)}};

always @(*)
begin
    case (i_funct6[3:2])
    2'b00: begin //Add and substract functions
        assign calculate_code = i_funct6[1];
        //Is saturation
        if(i_funct6[5]) begin
            result[0] = overflow[0] ? ( saturation[0] ? 1'b1 : i_funct6[0] ) : result_buffer[0];
            result[6:1] = overflow[0] ? ( saturation[0] ? 6'b111_111 : 6'b0 ) : result_buffer[6:1];
            result[7] = overflow[0] ? (i_8bits ? (saturation[0] ? ~i_funct6[0]:i_funct6[0]) : saturation[0] ) : result_buffer[7];

            result[8] = overflow[1] ? ( i_8bits ? (saturation[1] ? 1'b1 : i_funct6[0]) : saturation[1] ) : result_buffer[8];
            result[14:9] = overflow[1] ? ( saturation[1] ? 6'b111_111 : 6'b0 ) : result_buffer[14:9];
            result[15] = overflow[1] ? (i_8bits|i_16bits ? (saturation[1] ? ~i_funct6[0]:i_funct6[0]) : saturation[1] ) : result_buffer[15];

            result[16] = overflow[2] ? ( i_8bits | i_16bits ? (saturation[2] ? 1'b1 : i_funct6[0]) : saturation[2] ) : result_buffer[16];
            result[22:17] = overflow[2] ? ( saturation[2] ? 6'b111_111 : 6'b0 ) : result_buffer[22:17];
            result[23] = overflow[2] ? (i_8bits ? (saturation[2] ? ~i_funct6[0]:i_funct6[0]) : saturation[2] ) : result_buffer[23];

            result[24] = overflow[3] ? ( i_8bits ? (saturation[3] ? 1'b1 : i_funct6[0]) : saturation[3] ) : result_buffer[24];
            result[30:25] = overflow[3] ? ( saturation[3] ? 6'b111_111 : 6'b0 ) : result_buffer[30:25];
            result[31] = overflow[3] ? (saturation[3] ? ~i_funct6[0] : i_funct6[0] ) : result_buffer[31];
        end
        else result = result_buffer;
    end

    2'b01: begin //Max or min
        assign calculate_code = 1;
        //Signed(1) or unsigned(0)
        if(i_funct6[0]) begin
            //Signed min(0) and max(1)
            result[7 :0 ] = msb_result_buffer[0] ^ overflow[0] ^ i_funct6[1] ? input1[7:0] : input2[7:0];
            result[15:8 ] = msb_result_buffer[1] ^ overflow[1] ^ i_funct6[1] ? input1[15:8] : input2[15:8];
            result[23:16] = msb_result_buffer[2] ^ overflow[2] ^ i_funct6[1] ? input1[23:16] : input2[23:16];
            result[31:24] = msb_result_buffer[3] ^ overflow[3] ^ i_funct6[1] ? input1[31:24] : input2[31:24];
        end
        else begin
            //Unsigned min and max
            if(i_8bits) begin
                result[7:0] = (input1[7:0] > input2[7:0]) ^ i_funct6[1] ? input2[7:0] : input1[7:0];
                result[15:8] = (input1[15:8] > input2[15:8]) ^ i_funct6[1] ? input2[15:8] : input1[15:8];
                result[23:16] = (input1[23:16] > input2[23:16]) ^ i_funct6[1] ? input2[23:16] : input1[23:16];
                result[31:24] = (input1[31:24] > input2[31:24]) ^ i_funct6[1] ? input2[31:24] : input1[31:24];
            end
            else if(i_16bits) begin
                result[15:0] = (input1[15:0] > input2[15:0]) ^ i_funct6[1] ? input2[15:0] : input1[15:0];
                result[31:16] = (input1[31:16] > input2[31:16]) ^ i_funct6[1] ? input2[31:16] : input1[31:16];
            end
            else begin
                result = (input1 > input2) ^ i_funct6[1] ? input2 : input1;
            end
        end
    end

    2'b10: begin
        assign calculate_code = 1;
        //Bitwise operators
        case (i_funct6[1:0])
            2'b01:   result = input1 & input2;
            2'b10:   result = input1 | input2;
            2'b11:   result = input1 ^ input2;
            default: result = input1 & input2;
        endcase
    end

    default: begin
        assign calculate_code = 1;
        result = result_buffer;
    end
    endcase
end

    // Masking result   
    assign masked_result[7:0] = i_masks[0] ? result[7:0] : 8'd0;
    assign masked_result[15:8] = i_masks[1] ? result[15:8] : 8'd0;
    assign masked_result[23:16] = i_masks[2] ? result[23:16] : 8'd0;
    assign masked_result[31:24] = i_masks[3] ? result[31:24] : 8'd0;

endmodule
