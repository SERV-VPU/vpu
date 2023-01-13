/* Vector Processor Unit
 *
 * University of Southampton Grouo Design Project - Group 41
 *
 * controbuter: Ren Chen rc7g18@soton.ac.uk / chenren76@hotmail.com
 *
 * no sure what the liscen is, please ask the university or Olof. XD
 *
 * This is the ALU for the vector register unit, it only support +/- operations
 *
 *
*/

module vector_ALU
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
    input wire calculate_code
);

wire [WIDTH-1:0] result;

wire [WIDTH/4-1:0] signed_input2_0, signed_input2_1, signed_input2_2, signed_input2_3;
wire carry7, carry15, carry23;

assign signed_input2_0 = calculate_code ? (~input2[7:0]) : input2[7:0];
assign {carry7, result[7:0]} =  input1[7:0] + signed_input2_0 + {7'd0,{calculate_code}};

assign signed_input2_1 = calculate_code ? (~input2[15:8]) : input2[15:8];
assign {carry15, result[15:8]} =  input1[15:8] + signed_input2_1 + {7'd0,{(i_8bits ? calculate_code : carry7)}};

assign signed_input2_2 = calculate_code ? (~input2[23:16]) : input2[23:16];
assign {carry23, result[23:16]} = input1[23:16] + signed_input2_2 + {7'd0,{((i_16bits | i_8bits) ? calculate_code : carry15)}};

assign signed_input2_3 = calculate_code ? (~input2[31:24]) : input2[31:24];
assign {extented_result, result[31:24]} =  input1[31:24] + signed_input2_3 + {7'd0,{(i_8bits ? calculate_code : carry23)}};

assign masked_result[7:0] = i_masks[0] ? result[7:0] : 8'd0;
assign masked_result[15:8] = i_masks[1] ? result[15:8] : 8'd0;
assign masked_result[23:16] = i_masks[2] ? result[23:16] : 8'd0;
assign masked_result[31:24] = i_masks[3] ? result[31:24] : 8'd0;

endmodule
