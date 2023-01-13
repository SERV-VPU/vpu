/* Vector register
 *
 * University of Southampton Grouo Design Project - Group 41
 *
 * controbuter: Ren Chen rc7g18@soton.ac.uk / chenren76@hotmail.com
 *
 * no sure what the liscen is, please ask the university or Olof. XD
 *
 * This is the register file for vector processor unit
 *
 *
*/

module vector_registers 
#(
    parameter WIDTH = 32,
    parameter VLEN = 128
)(
    input  wire             i_clk,
    input  wire             i_rst,
    input  wire [WIDTH-1:0] i_ALU_result,
    input  wire            i_update_vreg,
    input  wire            i_update_mask,
    input  wire [VLEN/8-1:0]     i_Vreg_write_flag,
    input  wire [$clog2(WIDTH)-1:0] i_Vregs_input_adr,

    input  wire [$clog2(WIDTH)-1:0]       i_Vregs_output_addr[1:0],
    
    output wire [VLEN-1:0]    o_vector_registers_outputs [1:0],
    output wire [VLEN-1:0] o_masks_output
);

    reg [VLEN-1:0]  vregs [WIDTH-1:0]; //the first vreg is used for mask

    assign o_vector_registers_outputs[0] = vregs[i_Vregs_output_addr[0]];
    assign o_vector_registers_outputs[1] = vregs[i_Vregs_output_addr[1]];

    assign o_masks_output = vregs[0];
    wire[79:0] debug_v1 = vregs[1][79:0];

genvar i;
generate
for(i=0; i<(VLEN/8); i=i+1) begin
    always@(posedge i_clk)
        if(i_Vreg_write_flag[i]) begin
            if(i_update_mask & ~|i_Vregs_input_adr)
                vregs[0][8*(i+1)-1:8*i] <= i_ALU_result[((i%4)+1)*8-1 : (i%4)*8];
            else if(i_update_vreg & |i_Vregs_input_adr)
                    vregs[i_Vregs_input_adr][8*(i+1)-1:8*i] <= i_ALU_result[((i%4)+1)*8-1 : (i%4)*8];
        end
end
endgenerate

endmodule
