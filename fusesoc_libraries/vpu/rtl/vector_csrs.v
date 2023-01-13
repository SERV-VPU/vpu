module vector_csrs
#(
    parameter WIDTH = 32,
    parameter VLEN = 256
) (
    input  wire             i_clk,
    input  wire             i_rst,
    input  wire [WIDTH-1:0] i_vxsat,
    input  wire [WIDTH-1:0] i_vxrm,
    input  wire [WIDTH-1:0] i_vcsr,
    input  wire [WIDTH-1:0] i_vl,
    input  wire [7:0]       i_vtype_zimm,
    input  wire             i_update_vl,
    input  wire             i_or_vpu_vs1,
    input  wire             i_or_vpu_vd,
    output reg  [WIDTH-1:0] o_vlenb,
    output wire [2:0]       o_vsew,
    output wire [2:0]       o_vlmul,
    output wire             o_vta,
    output wire             o_vma,
    output wire             o_vill,
    output wire [WIDTH-1:0] o_vl
);

    reg [WIDTH-1:0] vstart;
    reg [WIDTH-1:0] vxsat;
    reg [WIDTH-1:0] vxrm;
    reg [WIDTH-1:0] vcsr;
    reg [WIDTH-1:0] vl;
    reg [WIDTH-1:0] vtype;
    reg [WIDTH-1:0] vlenb;

    assign o_vsew = vtype[5:3];
    assign o_vlmul = 3'd0; //vtype[2:0];
    assign o_vta = vtype[6];
    assign o_vma = vtype[7];
    assign o_vill = vtype[WIDTH-1];
    assign o_vlenb = 32'd32;
    assign o_vl = (i_update_vl ? next_vl : vl); //tmp for now, stick with 32 bits
    wire [31:0] next_vl;
    
    assign next_vl = i_or_vpu_vs1 ? i_vl : (i_or_vpu_vd ? 32'd8 : 32'd7);
    
    always @(posedge i_clk) begin
        if(i_update_vl) begin
            vl <= next_vl;
            if(|i_vtype_zimm[2:0])
                vtype <= {1'b1, {31{1'b0}}};
            else
                vtype[7:0] <= i_vtype_zimm;
        end
    end
    
endmodule
