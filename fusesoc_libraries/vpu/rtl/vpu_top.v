
/* Vector Processor Unit
 *
 * University of Southampton Grouo Design Project - Group 41
 *
 * controbuter: Ren Chen rc7g18@soton.ac.uk / chenren76@hotmail.com
 *
 * no sure what the liscen is, please ask the university or Olof. XD
 *
 * This is top level of the VPU, it connect the ALU and register modules and connect them base on the signals feeded
 *
 *
*/

module vpu_top
#(
  parameter WIDTH = 32,
  parameter depth = 256,
  parameter VLEN = 256,
  parameter aw    = $clog2(depth)
)(
  input  wire              i_clk,
  input  wire              i_rst,
  input  wire              i_load_fp_op,
  input  wire              i_vector_op,
  input  wire              i_store_fp_op,
  input  wire              i_vpu_valid,
  input  wire [2:0]        i_width,   //funct3
  input  wire [5:0]        i_funct6,
  input  wire [WIDTH-1:0]  i_vpu_rs1,
  input  wire [WIDTH-1:0]  i_vpu_rs2,
  input  wire [$clog2(WIDTH)-1:0]       i_vpu_vd,
  input  wire [$clog2(WIDTH)-1:0]       i_vpu_vs1,
  input  wire [$clog2(WIDTH)-1:0]       i_vpu_vs2,
  input  wire [WIDTH-1:0]  i_vpu_mem_dat,
  input  wire [1:0]        i_mop,
  output wire [aw-1:0]     o_external_mem_adr,
  output reg               o_vpu_mem_request,
  output reg               o_vpu_mem_wr_request,
  output wire [31:0]       o_vpu_mem_dat,
  output wire [3:0]        o_vpu_mem_sel,
  output reg               o_vpu_rdy,
  output wire [WIDTH-1:0]  o_vpu_config_dat,
  input wire               i_vm,
  output reg               o_vpu_stage_req
);

reg [2:0] state_reg, next_state_reg;

localparam no_op = 3'd0,
           prepare_vector_load_store = 3'd1,
           Vector_load = 3'd2,
           Vector_store = 3'd3,
           Vector_arithmetic_init = 3'd4,
           Vector_arithmetic_loop = 3'd5,
           Vector_config = 3'd6;

reg [VLEN/8-1:0] Vreg_write_flag;

wire [WIDTH-1:0] ALU0_R, ALU1_R, ALU2_R, shifted_mem_dat;

reg [WIDTH-1:0] ALU0_1, ALU0_2, ALU1_1, ALU1_2, ALU2_1, ALU2_2, previous_ALU0_R, previous_ALU1_R;

reg [5:0] funct6;

reg [WIDTH-1:0] next_ALU0_1, next_ALU0_2, next_ALU1_1, next_ALU1_2, next_ALU2_1, next_ALU2_2, stride_address, ALU1_R_mid;

reg [WIDTH-1:0] new_vxsat, new_vxrm, new_vcsr, csr_vl, csr_vlenb, new_vlenb, vpu_rs1, vpu_rs2;

wire [2:0] vtype_vsew, vtype_vlmul;

wire [$clog2(WIDTH)-1:0] vpu_v1, vpu_v2;

wire vtype_vta, vtype_vma, vtype_vill;

wire ALU0_e, ALU1_e, ALU2_e;

reg ALU0_op, ALU1_op, ALU2_op;

reg next_ALU0_op, next_ALU1_op, next_ALU2_op, update_vpu_inputs, stride_ALU0_1, unit_stride_8_bits, unit_stride_ALU0_2,
arithmetic_sat, rs2_stride_ALU0_2, index_stride_ALU0_2, no_op_state;

wire [VLEN-1:0] V1, V2, V3_Updated;

wire [VLEN-1:0] mask;

wire mask_skip = (i_vm | unit_stride_mask_load_store) & (|state_reg);//i_vm;

wire ALU1_cnt = ~|(ALU1_R^csr_vl);

wire unit_stride_load_store = ~|i_vpu_vs2;

wire unit_stride_whole_register_load_store = i_vpu_vs2 == 5'd8;

wire unit_stride_mask_load_store = i_vpu_vs2 == 5'd11;

wire unit_stride_first_fault_load = i_vpu_vs2 == 5'd16;

reg update_vector_regs, update_vl, update_vector_masks;

wire ALU2_16byte, ALU2_8byte, first_fault_occur, V1_last_index, V2_last_index, V3_last_index, V1_last_sub_index, V2_last_sub_index, V3_last_sub_index;

wire [3:0] ALU2_mask;

wire [$clog2(VLEN/32)-1:0] ALU1_R_decoded_address_V1, ALU1_R_decoded_address_V2, ALU1_R_decoded_address_V3;

reg [$clog2(VLEN/32)-1:0] previous_ALU1_R_decoded_address_V3;

wire [31:0] ALU0_2_mid;

vector_ALU ALU0(              //Address only
  .input1   (ALU0_1),
  .input2   (ALU0_2_mid),
  .calculate_code (ALU0_op),
  .extented_result (ALU0_e),
  .masked_result   (ALU0_R),
  .i_16bits(1'b0),
  .i_8bits(1'b0),
  .i_masks(4'b1111)
);

vector_ALU ALU1(              //remaining size only
  .input1   (ALU1_1),
  .input2   (ALU1_2),
  .calculate_code (ALU1_op),
  .extented_result (ALU1_e),
  .masked_result   (ALU1_R),
  .i_16bits(1'b0),
  .i_8bits(1'b0),
  .i_masks(4'b1111)
);

vector_alu_and_decoder ALU2(              //ALUs for calculation
  .input1   (ALU2_1),
  .input2   (ALU2_2),
  .extented_result (ALU2_e),
  .masked_result   (ALU2_R),
  .i_16bits(ALU2_16byte),
  .i_8bits(ALU2_8byte),
  .i_masks(4'b1111),
  .i_funct6(funct6),
  .o_is_sat(arithmetic_sat)
);

vector_registers#(
  .VLEN(VLEN),
  .WIDTH(WIDTH))
  register(
  .i_clk (i_clk),
  .i_rst (i_rst),
  .i_ALU_result(updated_data),
  .i_update_vreg (update_vector_regs),
  .i_update_mask (update_vector_masks),
  .i_Vregs_input_adr (i_vpu_vd),
  .i_Vregs_output_addr ( '{vpu_v1, vpu_v2} ),
  .o_vector_registers_outputs ('{V1, V2}),
  .o_masks_output(mask),
  .i_Vreg_write_flag(Vreg_write_flag)
);

vector_csrs csrs(
  .i_clk (i_clk),
  .i_rst (i_rst),
  .i_vtype_zimm({i_mop, i_vm, i_vpu_vs2}),
  .i_vxsat(new_vxsat),
  .i_vxrm(new_vxrm),
  .i_vcsr(new_vcsr),
  .i_vl(vpu_rs1),
  .i_update_vl(update_vl),
  .i_or_vpu_vs1(or_vs1),
  .i_or_vpu_vd(or_vd),
  .o_vsew(vtype_vsew),
  .o_vlmul(vtype_vlmul),
  .o_vta(vtype_vta),
  .o_vma(vtype_vma),
  .o_vill(vtype_vill),
  .o_vl(csr_vl),
  .o_vlenb(csr_vlenb)
);

vector_mem_if memory_interface(     //shift the data for alignment
  .mem_inputs(i_vpu_mem_dat),
  .o_mem_outputs(shifted_mem_dat),
  .shift_offset(previous_ALU0_R[1:0]),
  .i_width(i_width),
  .i_Vreg_shift(previous_ALU1_R[1:0])
);

vector_mask_decoder #(
  .VLEN(VLEN))
  mask_decoder(
  .i_mask(mask),
  .i_element_width(i_vector_op ? vtype_vsew : i_width),
  .i_address(previous_ALU1_R[$clog2(VLEN)-1:0]),
  .i_mask_skip(mask_skip),
  .o_UpdateBits(ALU2_mask),
  .o_ALU2_16(ALU2_16byte),
  .o_ALU2_8(ALU2_8byte),
  .i_first_fault(unit_stride_first_fault_load),
  .o_fault_occur(first_fault_occur)
);

vector_32_bit_alignment_decoder #(.VLEN(VLEN)) ALU0_R_decoder_V1(
  .i_ALU_R (ALU1_R),
  .i_width (vtype_vsew),
  .o_address (ALU1_R_decoded_address_V1),
  .o_last_index(V1_last_index),
  .last_sub_index(V1_last_sub_index)
);

vector_32_bit_alignment_decoder #(.VLEN(VLEN)) ALU0_R_decoder_V2(
  .i_ALU_R (ALU1_R_mid),
  .i_width (i_store_fp_op? i_width : vtype_vsew),
  .o_address (ALU1_R_decoded_address_V2),
  .o_last_index(V2_last_index),
  .last_sub_index(V2_last_sub_index)
);

vector_32_bit_alignment_decoder #(.VLEN(VLEN)) ALU0_R_decoder_V3(
  .i_ALU_R (ALU1_R),
  .i_width (i_vector_op? vtype_vsew : i_width),
  .o_address (ALU1_R_decoded_address_V3),
  .o_last_index(V3_last_index),
  .last_sub_index(V3_last_sub_index)
);

vector_ALU0_1_address_alignment ALU1_R_alignment(
  .i_width(vtype_vsew),
  .i_address(ALU1_R[1:0]),
  .i_ALU_1(loaded_data_V2),
  .o_address(stride_address)
);

wire [31:0] co_external_mem_adr = i_load_fp_op ? ALU0_R: previous_ALU0_R;

assign o_external_mem_adr = co_external_mem_adr[aw-1:0];

assign vpu_v1 = i_vpu_vs1;

assign vpu_v2 = (update_vector_regs | i_vector_op) ? i_vpu_vs2 : (o_vpu_mem_wr_request ? i_vpu_vd : 5'b0 );

assign o_vpu_mem_dat = loaded_data_V2;

assign o_vpu_mem_sel = ALU2_mask;

assign o_vpu_config_dat = csr_vl;

assign ALU0_2_mid = index_stride_ALU0_2 ? stride_address : ALU0_2;

wire or_vs1 = | i_vpu_vs1;

wire or_vd = | i_vpu_vd;

wire [WIDTH-1:0] updated_data = o_vpu_mem_request ? shifted_mem_dat : ALU2_R;

reg [WIDTH-1:0] loaded_data_V1, loaded_data_V2, next_ALU2_1_mid;

reg [$clog2(VLEN/32)-1:0] V1_address, V2_address, V3_address;

assign ALU1_R_mid = i_store_fp_op ? previous_ALU1_R : ALU1_R;


`ifdef VLEN_128
    always@(V1_address or V1 or V2 or V2_address or V3_address or ALU2_mask) begin     //DeMUX for loading V1 and V2 for ALUs
      case (V1_address[$clog2(VLEN/32)-1:0])
        2'b000: begin
          loaded_data_V1 = V1[31:0];
        end
        2'b001: begin
          loaded_data_V1 = V1[63:32];
        end
        2'b010: begin
          loaded_data_V1 = V1[95:64];
        end
        2'b011: begin
          loaded_data_V1 = V1[127:96];
        end
        default: begin
          loaded_data_V1 = V1[31:0];
        end
      endcase

      case (V2_address[$clog2(VLEN/32)-1:0])
        2'b00: begin
          loaded_data_V2 = V2[31:0];
        end
        2'b01: begin
          loaded_data_V2 = V2[63:32];
        end
        2'b10: begin
          loaded_data_V2 = V2[95:64];
        end
        2'b11: begin
          loaded_data_V2 = V2[127:96];
        end
        default: begin
          loaded_data_V2 = V2[31:0];
        end
      endcase

        Vreg_write_flag = {(VLEN/8){1'b0}};

        case (V3_address[$clog2(VLEN/32)-1:0])
        3'b000: begin
          Vreg_write_flag[3:0] = ALU2_mask;
        end
        3'b001: begin
          Vreg_write_flag[7:4] = ALU2_mask;
        end
        3'b010: begin
          Vreg_write_flag[11:8] = ALU2_mask;
        end
        3'b011: begin
          Vreg_write_flag[15:12] = ALU2_mask;
        end
        3'b100: begin
          Vreg_write_flag[19:16] = ALU2_mask;
        end
        3'b101: begin
          Vreg_write_flag[23:20] = ALU2_mask;
        end
        3'b110: begin
          Vreg_write_flag[27:24] = ALU2_mask;
        end
        3'b111: begin
          Vreg_write_flag[31:28] = ALU2_mask;
        end
        default: begin
          Vreg_write_flag[3:0] = ALU2_mask;
        end
      endcase
    end
`else 
    always@(V1_address or V1 or V2 or V2_address or V3_address or ALU2_mask) begin     //DeMUX for loading V1 and V2 for ALUs
      case (V1_address[$clog2(VLEN/32)-1:0])
        3'b000: begin
          loaded_data_V1 = V1[31:0];
        end
        3'b001: begin
          loaded_data_V1 = V1[63:32];
        end
        3'b010: begin
          loaded_data_V1 = V1[95:64];
        end
        3'b011: begin
          loaded_data_V1 = V1[127:96];
        end
        3'b100: begin
          loaded_data_V1 = V1[159:128];
        end
        3'b101: begin
          loaded_data_V1 = V1[191:160];
        end
        3'b110: begin
          loaded_data_V1 = V1[223:192];
        end
        3'b111: begin
          loaded_data_V1 = V1[255:224];
        end
        default: begin
          loaded_data_V1 = V1[31:0];
        end
      endcase

      case (V2_address[$clog2(VLEN/32)-1:0])
       3'b000: begin
          loaded_data_V2 = V2[31:0];
        end
        3'b001: begin
          loaded_data_V2 = V2[63:32];
        end
        3'b010: begin
          loaded_data_V2 = V2[95:64];
        end
        3'b011: begin
          loaded_data_V2 = V2[127:96];
        end
        3'b100: begin
          loaded_data_V2 = V2[159:128];
        end
        3'b101: begin
          loaded_data_V2 = V2[191:160];
        end
        3'b110: begin
          loaded_data_V2 = V2[223:192];
        end
        3'b111: begin
          loaded_data_V2 = V2[255:224];
        end
        default: begin
          loaded_data_V2 = V2[31:0];
        end
      endcase

        Vreg_write_flag = {(VLEN/8){1'b0}};

        case (V3_address[$clog2(VLEN/32)-1:0])
        3'b000: begin
          Vreg_write_flag[3:0] = ALU2_mask;
        end
        3'b001: begin
          Vreg_write_flag[7:4] = ALU2_mask;
        end
        3'b010: begin
          Vreg_write_flag[11:8] = ALU2_mask;
        end
        3'b011: begin
          Vreg_write_flag[15:12] = ALU2_mask;
        end
        3'b100: begin
          Vreg_write_flag[19:16] = ALU2_mask;
        end
        3'b101: begin
          Vreg_write_flag[23:20] = ALU2_mask;
        end
        3'b110: begin
          Vreg_write_flag[27:24] = ALU2_mask;
        end
        3'b111: begin
          Vreg_write_flag[31:28] = ALU2_mask;
        end
        default: begin
          Vreg_write_flag[3:0] = ALU2_mask;
        end
      endcase
    end
`endif
always @(stride_ALU0_1 or ALU0_R or i_vpu_rs1) begin
  if (stride_ALU0_1)
    next_ALU0_1 = ALU0_R;
  else
    next_ALU0_1 = i_vpu_rs1;
end

always @(unit_stride_8_bits or unit_stride_ALU0_2 or rs2_stride_ALU0_2 or index_stride_ALU0_2 or i_width or vpu_rs2 or stride_address) begin
  if (unit_stride_8_bits)
    next_ALU0_2 = 32'd1;
  else if(unit_stride_ALU0_2)
    case(i_width)
      3'b000: next_ALU0_2 = 32'd1;
      3'b101: next_ALU0_2 = 32'd2;
      3'b110: next_ALU0_2 = 32'd4;
      default:next_ALU0_2 = 32'd1;
    endcase
  else if (rs2_stride_ALU0_2)
    next_ALU0_2 = vpu_rs2;
  else if (index_stride_ALU0_2)
    next_ALU0_2 = stride_address;
  else
    next_ALU0_2 = 32'd0;
end

always @(no_op_state or ALU1_R) begin
  if (!no_op_state) begin
    next_ALU1_2 = 32'd1;
    next_ALU1_1 = ALU1_R;
  end
  else begin
    next_ALU1_2 = 32'd0;
    next_ALU1_1 = 32'd0;
  end
end

always @(i_width or loaded_data_V1 or vpu_rs1 or i_vpu_vs2) begin
  
  case(i_width)
    3'b000: begin
      //Data from vector register
      next_ALU2_1 = loaded_data_V1;
    end
    3'b011: begin
      //Data from immediate value
      next_ALU2_1[7:0] = {3'd0, i_vpu_vs2};
      next_ALU2_1[15:8] = ALU2_8byte ? {3'd0, i_vpu_vs2} : 8'b0;
      next_ALU2_1[23:16] = ALU2_8byte | ALU2_16byte ? {3'd0, i_vpu_vs2} : 8'b0;
      next_ALU2_1[31:24] = ALU2_8byte ? {3'd0, i_vpu_vs2} : 8'b0;
    end
    3'b100: begin
      //Data from general register
      next_ALU2_1[7:0] = i_vpu_rs1[7:0];
      next_ALU2_1[15:8] = ALU2_8byte ? i_vpu_rs1[7:0] : i_vpu_rs1[15:8];
      next_ALU2_1[23:16] = ALU2_8byte | ALU2_16byte ? i_vpu_rs1[7:0] : i_vpu_rs1[7:0];
      next_ALU2_1[31:24] = ALU2_8byte ? i_vpu_rs1[7:0] : ALU2_16byte ? i_vpu_rs1[15:8] : i_vpu_rs1[31:24];
    end
    default: next_ALU2_1 = loaded_data_V1;
  endcase
end

assign next_ALU2_2 = loaded_data_V2;

assign V1_address = ALU1_R_decoded_address_V1;
assign V2_address = ALU1_R_decoded_address_V2;
assign V3_address = previous_ALU1_R_decoded_address_V3;

always@(state_reg or i_load_fp_op or i_store_fp_op or i_vpu_valid or i_vector_op or i_width or i_mop or unit_stride_load_store or unit_stride_mask_load_store or V3_last_index or first_fault_occur or ALU1_cnt) begin

  o_vpu_mem_request = 1'b0;
  next_ALU0_op = 1'b0;
  next_ALU1_op = 1'b0;
  next_ALU2_op = 1'b0;
  update_vector_regs = 1'b0;
  update_vpu_inputs = 1'b0;
  stride_ALU0_1 = 1'b0;
  unit_stride_ALU0_2 = 1'b0;
  rs2_stride_ALU0_2 = 1'b0;
  index_stride_ALU0_2 = 1'b0;
  unit_stride_8_bits = 1'b0;
  no_op_state = 1'b0;
  o_vpu_rdy = 1'b0;
  update_vl = 1'b0;
  o_vpu_stage_req = 1'b0;
  o_vpu_mem_wr_request = 1'b0;

  case(state_reg)

    no_op: begin
      if(i_vpu_valid) begin
        if(i_load_fp_op | i_store_fp_op) begin
          next_state_reg = prepare_vector_load_store;
        end
        else if (i_vector_op & (&i_width)) begin
          next_state_reg = Vector_config;
        end
        else if (i_vector_op) begin
          next_state_reg = Vector_arithmetic_init;
        end
      end
      else 
        next_state_reg = no_op;
        update_vpu_inputs = 1'b1;
        no_op_state = 1'b1;
    end

    prepare_vector_load_store: begin
      if (i_mop[0]) begin   // indexed, need to set V2's source
        index_stride_ALU0_2 = 1'b1;
        update_vector_regs = 1'b1;
      end
      else if (i_mop[1] & !i_mop[0]) begin
        // stride_ALU0_1 = 1'b1;
        rs2_stride_ALU0_2 = 1'b1;
      end
      else if (unit_stride_mask_load_store) // EEW = 8 for mask loading
        unit_stride_8_bits = 1'b1;
      else begin
        // stride_ALU0_1 = 1'b1;
        unit_stride_ALU0_2 = 1'b1;
      end

      if(i_load_fp_op) begin
        o_vpu_mem_request = 1'b1;
        next_state_reg = Vector_load;
      end else if (i_store_fp_op)begin
        next_state_reg = Vector_store;
      end
    end

    Vector_load: begin
      if (i_mop[0]) begin //index
        index_stride_ALU0_2 = 1'b1;
      end
      else if (i_mop[1] & !i_mop[0]) begin   // mop = 2'b10  stride
        stride_ALU0_1 = 1'b1;
        rs2_stride_ALU0_2 = 1'b1;
      end
      else begin
        stride_ALU0_1 = 1'b1;
        unit_stride_ALU0_2 = 1'b1;
      end
      update_vector_regs = 1'b1;
      o_vpu_mem_request = 1'b1;

      if((ALU1_cnt & (unit_stride_load_store | unit_stride_mask_load_store | index_stride_ALU0_2 | rs2_stride_ALU0_2)) | (unit_stride_first_fault_load & first_fault_occur) |
       (V3_last_index & unit_stride_whole_register_load_store)) begin
          next_state_reg = no_op;
          o_vpu_rdy = 1'b1;
      end
    end

    Vector_store: begin
      if (i_mop[0]) begin //index
        index_stride_ALU0_2 = 1'b1;
      end
      else if (i_mop[1] & !i_mop[0]) begin   // mop = 2'b10  stride
        stride_ALU0_1 = 1'b1;
        rs2_stride_ALU0_2 = 1'b1;
      end
      else begin
        stride_ALU0_1 = 1'b1;
          if (unit_stride_mask_load_store) begin// EEW = 8 for mask loading
            unit_stride_8_bits = 1'b1;
            update_vector_masks = 1'b1;
          end
          else
            unit_stride_ALU0_2 = 1'b1;
      end
      o_vpu_mem_wr_request = 1'b1;

      if((ALU1_cnt & (unit_stride_ALU0_2 | unit_stride_load_store | unit_stride_mask_load_store | rs2_stride_ALU0_2)) |
       (V3_last_index & unit_stride_whole_register_load_store)) begin
          next_state_reg = no_op;
          o_vpu_rdy = 1'b1;
      end
      
    end

    Vector_arithmetic_init: begin
      next_state_reg = Vector_arithmetic_loop;
    end

    Vector_arithmetic_loop: begin
      update_vector_regs = 1'b1;
      if(ALU1_cnt) begin
        next_state_reg = no_op;
        o_vpu_rdy = 1'b1;
      end
      else
        next_state_reg = Vector_arithmetic_loop;
    end

    Vector_config: begin
      update_vl = 1'b1;
      o_vpu_rdy = 1'b1;
      next_state_reg = no_op;
    end
    default: next_state_reg = no_op;

  endcase

end


always @(posedge i_clk) begin   //update next_state
    ALU0_1 <= next_ALU0_1;
    ALU0_2 <= next_ALU0_2;
    ALU0_op<= next_ALU0_op;
    ALU1_1 <= next_ALU1_1;
    ALU1_2 <= next_ALU1_2;
    ALU1_op<= next_ALU1_op;
    ALU2_1 <= next_ALU2_1;
    ALU2_2 <= next_ALU2_2;
    ALU2_op<= next_ALU2_op;
    state_reg <= next_state_reg;
    previous_ALU0_R <= ALU0_R;
    previous_ALU1_R <= ALU1_R;
    previous_ALU1_R_decoded_address_V3 <= ALU1_R_decoded_address_V3;
    if (update_vpu_inputs) begin
      vpu_rs1 <= i_vpu_rs1;
      vpu_rs2 <= i_vpu_rs2;
    end
    funct6 <= i_funct6;
end


endmodule
