`default_nettype none
module servant(
 input wire  wb_clk,
 input wire  wb_rst,
 output wire q);

   parameter memfile = "VPU_test.hex";
   parameter memsize = 8192;
   parameter reset_strategy = "MINI";
   parameter sim = 0;
   parameter with_csr = 1;
   parameter [0:0] compress = 0;
   parameter [0:0] align = 0;

   wire 	timer_irq;

   wire [31:0] 	wb_ibus_adr;
   wire 	wb_ibus_cyc;
   wire [31:0] 	wb_ibus_rdt;
   wire 	wb_ibus_ack;

   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   wire [31:0] 	wb_dbus_rdt;
   wire 	wb_dbus_ack;

   wire [31:0] 	wb_dmem_adr;
   wire [31:0] 	wb_dmem_dat;
   wire [3:0] 	wb_dmem_sel;
   wire 	wb_dmem_we;
   wire 	wb_dmem_cyc;
   wire [31:0] 	wb_dmem_rdt;
   wire 	wb_dmem_ack;

   wire [31:0] 	wb_mem_adr;
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire [3:0] 	vpu_sel;
   wire 	wb_mem_we;
   wire 	wb_mem_cyc;
   wire [31:0] 	wb_mem_rdt;
   wire 	wb_mem_ack;

   wire 	wb_gpio_dat;
   wire 	wb_gpio_we;
   wire 	wb_gpio_cyc;
   wire 	wb_gpio_rdt;

   wire [31:0] 	wb_timer_dat;
   wire 	wb_timer_we;
   wire 	wb_timer_cyc;
   wire [31:0] 	wb_timer_rdt;

   wire [31:0] mdu_rs1;
   wire [31:0] mdu_rs2;
   wire [ 2:0] mdu_op;
   wire        mdu_valid;
   wire [31:0] mdu_rd;
   wire        mdu_ready;
   wire [31:0] vpu_rd;
   wire        vpu_ready;
   wire [31:0] ext_rd = ({32{mdu_ready}} & mdu_rd) | ({32{vpu_ready}} & vpu_rd);
   wire        ext_ready = mdu_ready | vpu_ready;
   wire [1:0]  mdu_op;
   wire [5:0]  vpu_funct6;

   wire        vpu_valid;
   wire [2:0]  vpu_op;
   wire [$clog2(memsize)-1:0] wb_vpu_adr;
   wire [31:0] wb_vpu_dat;
   wire        vpu_cyc_rd;
   wire        vpu_cyc_wr;
   wire [4:0]  vpu_vd;
   wire [4:0]  vpu_vs1;
   wire [4:0]  vpu_vs2;
   wire        vpu_vm;
   wire [1:0]  vpu_mop;
   wire        vpu_stage_req;

   servant_arbiter arbiter
     (.i_wb_cpu_dbus_adr (wb_dmem_adr),
      .i_wb_cpu_dbus_dat (wb_dmem_dat),
      .i_wb_cpu_dbus_sel (wb_dmem_sel),
      .i_wb_cpu_dbus_we  (wb_dmem_we ),
      .i_wb_cpu_dbus_cyc (wb_dmem_cyc),
      .o_wb_cpu_dbus_rdt (wb_dmem_rdt),
      .o_wb_cpu_dbus_ack (wb_dmem_ack),

      .i_wb_cpu_ibus_adr (wb_ibus_adr),
      .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
      .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
      .o_wb_cpu_ibus_ack (wb_ibus_ack),

      .o_wb_cpu_adr (wb_mem_adr),
      .o_wb_cpu_dat (wb_mem_dat),
      .o_wb_cpu_sel (wb_mem_sel),
      .o_wb_cpu_we  (wb_mem_we ),
      .o_wb_cpu_cyc (wb_mem_cyc),
      .i_wb_cpu_rdt (wb_mem_rdt),
      .i_wb_cpu_ack (wb_mem_ack));

   servant_mux #(sim) servant_mux
     (
      .i_clk (wb_clk),
      .i_rst (wb_rst & (reset_strategy != "NONE")),
      .i_wb_cpu_adr (wb_dbus_adr),
      .i_wb_cpu_dat (wb_dbus_dat),
      .i_wb_cpu_sel (wb_dbus_sel),
      .i_wb_cpu_we  (wb_dbus_we),
      .i_wb_cpu_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_dbus_rdt),
      .o_wb_cpu_ack (wb_dbus_ack),

      .o_wb_mem_adr (wb_dmem_adr),
      .o_wb_mem_dat (wb_dmem_dat),
      .o_wb_mem_sel (wb_dmem_sel),
      .o_wb_mem_we  (wb_dmem_we),
      .o_wb_mem_cyc (wb_dmem_cyc),
      .i_wb_mem_rdt (wb_dmem_rdt),

      .o_wb_gpio_dat (wb_gpio_dat),
      .o_wb_gpio_we  (wb_gpio_we),
      .o_wb_gpio_cyc (wb_gpio_cyc),
      .i_wb_gpio_rdt (wb_gpio_rdt),

      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt));

   servant_ram
     #(.memfile (memfile),
       .depth (memsize),
  `ifdef VPU
       .VPU(1),
  `endif 
       .RESET_STRATEGY (reset_strategy))
   ram
     (// Wishbone interface
      .i_wb_clk (wb_clk),
      .i_wb_rst (wb_rst),
      .i_wb_adr (wb_mem_adr[$clog2(memsize)-1:2]),
      .i_wb_cyc (wb_mem_cyc),
      .i_wb_we  (wb_mem_we) ,
      .i_wb_sel (wb_mem_sel),
      .i_vpu_sel (vpu_sel),
      .i_wb_dat (wb_mem_dat),
      .o_wb_rdt (wb_mem_rdt),
      .o_wb_ack (wb_mem_ack),
      .i_vpu_request_rd(vpu_cyc_rd),
      .i_vpu_request_wr(vpu_cyc_wr),
      .i_vpu_adr(wb_vpu_adr[$clog2(memsize)-1:2]),
      .i_vpu_dat(wb_vpu_dat)
      );

   generate
      if (|with_csr) begin
	 servant_timer
	   #(.RESET_STRATEGY (reset_strategy),
	     .WIDTH (32))
	 timer
	   (.i_clk    (wb_clk),
	    .i_rst    (wb_rst),
	    .o_irq    (timer_irq),
	    .i_wb_cyc (wb_timer_cyc),
	    .i_wb_we  (wb_timer_we) ,
	    .i_wb_dat (wb_timer_dat),
	    .o_wb_dat (wb_timer_rdt));
      end else begin
	 assign wb_timer_rdt = 32'd0;
	 assign timer_irq = 1'b0;
      end
   endgenerate

   servant_gpio gpio
     (.i_wb_clk (wb_clk),
      .i_wb_dat (wb_gpio_dat),
      .i_wb_we  (wb_gpio_we),
      .i_wb_cyc (wb_gpio_cyc),
      .o_wb_rdt (wb_gpio_rdt),
      .o_gpio   (q));

   serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .RESET_STRATEGY (reset_strategy),
  `ifdef MDU
       .MDU(1),
  `endif 
  `ifdef VPU
       .VPU(1),
  `endif 
       .WITH_CSR (with_csr),
       .COMPRESSED(compress),
       .ALIGN(align))
   cpu
     (
      .clk      (wb_clk),
      .i_rst    (wb_rst),
      .i_timer_irq  (timer_irq),
`ifdef RISCV_FORMAL
      .rvfi_valid     (),
      .rvfi_order     (),
      .rvfi_insn      (),
      .rvfi_trap      (),
      .rvfi_halt      (),
      .rvfi_intr      (),
      .rvfi_mode      (),
      .rvfi_ixl       (),
      .rvfi_rs1_addr  (),
      .rvfi_rs2_addr  (),
      .rvfi_rs1_rdata (),
      .rvfi_rs2_rdata (),
      .rvfi_rd_addr   (),
      .rvfi_rd_wdata  (),
      .rvfi_pc_rdata  (),
      .rvfi_pc_wdata  (),
      .rvfi_mem_addr  (),
      .rvfi_mem_rmask (),
      .rvfi_mem_wmask (),
      .rvfi_mem_rdata (),
      .rvfi_mem_wdata (),
`endif

      .o_ibus_adr   (wb_ibus_adr),
      .o_ibus_cyc   (wb_ibus_cyc),
      .i_ibus_rdt   (wb_ibus_rdt),
      .i_ibus_ack   (wb_ibus_ack),

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_dbus_rdt),
      .i_dbus_ack   (wb_dbus_ack),
      
      //Extension
      .o_ext_rs1    (mdu_rs1),
      .o_ext_rs2    (mdu_rs2),
      .o_ext_funct3 (mdu_op),
      .o_ext_funct6 (vpu_funct6),
      .i_ext_rd     (ext_rd),
      .i_ext_ready  (ext_ready),
      .o_vpu_vm     (vpu_vm),
      .o_vpu_mop    (vpu_mop),
      //MDU
      .o_mdu_valid  (mdu_valid),
      //VPU
      .o_vpu_valid  (vpu_valid),
      .o_vector_op  (vpu_op[0]),
      .o_load_fp_op (vpu_op[1]),
      .o_store_fp_op (vpu_op[2]),
      .o_vpu_vd     (vpu_vd),
      .o_vpu_vs1    (vpu_vs1),
      .o_vpu_vs2    (vpu_vs2),
      .i_vpu_stage_req(vpu_stage_req));

`ifdef MDU
    mdu_top mdu_serv
    (
     .i_clk(wb_clk),
     .i_rst(wb_rst),
     .i_mdu_rs1(mdu_rs1),
     .i_mdu_rs2(mdu_rs2),
     .i_mdu_op(mdu_op),
     .i_mdu_valid(mdu_valid),
     .o_mdu_ready(mdu_ready),
     .o_mdu_rd(mdu_rd));
`else
    assign mdu_ready = 1'b0;
    assign mdu_rd = 32'b0;
`endif
`ifdef VPU
    vpu_top #(
      `ifdef VLEN_128
        .VLEN(128),
      `endif
      .depth(memsize)
      
    )
    vpu_serv
    (
     .i_clk(wb_clk),
     .i_rst(wb_rst),
     .i_load_fp_op(vpu_op[1]),
     .i_vector_op(vpu_op[0]),
     .i_store_fp_op(vpu_op[2]),
     .i_width(mdu_op),
     .i_funct6(vpu_funct6),
     .i_vpu_rs1(mdu_rs1),
     .i_vpu_rs2(mdu_rs2),
     .i_vpu_vd(vpu_vd),
     .i_vpu_valid(vpu_valid),
     .i_vpu_mem_dat(wb_mem_rdt),
     .i_vm(vpu_vm),
     .i_mop(vpu_mop),
     .o_external_mem_adr(wb_vpu_adr[$clog2(memsize)-1:0]),
     .o_vpu_mem_request(vpu_cyc_rd),
     .o_vpu_mem_wr_request(vpu_cyc_wr),
     .i_vpu_vs1    (vpu_vs1),
     .i_vpu_vs2    (vpu_vs2),
     .o_vpu_mem_dat(wb_vpu_dat),
     .o_vpu_mem_sel(vpu_sel),
     .o_vpu_rdy(vpu_ready),
     .o_vpu_config_dat(vpu_rd),
     .o_vpu_stage_req(vpu_stage_req));
`else
    assign wb_vpu_dat = 32'd0;
    assign vpu_sel = 4'd0;
    assign vpu_ready = 1'd0;
    assign vpu_rd = 32'd0;
    assign vpu_cyc_wr = 1'd0;
    assign vpu_cyc_rd = 1'd0;
    assign wb_vpu_adr = {($clog2(memsize)){1'd0}};
    assign vpu_stage_req = 1'b0;
`endif
endmodule
