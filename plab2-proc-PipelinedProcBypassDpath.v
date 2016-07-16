//=========================================================================
// 5-Stage Bypass Pipelined Processor Datapath
//=========================================================================

`ifndef PLAB2_PROC_PIPELINED_PROC_BYPASS_DPATH_V
`define PLAB2_PROC_PIPELINED_PROC_BYPASS_DPATH_V

`include "plab2-proc-dpath-components.v"
`include "vc-arithmetic.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "pisa-inst.v"
`include "plab1-imul-msgs.v"
`include "plab1-imul-IntMulVarLat.v"

module plab2_proc_PipelinedProcBypassDpath
#(
  parameter p_num_cores = 1,
  parameter p_core_id   = 0
)
(
  input {L} clk,
  input {L} reset,

  // Instruction Memory Port

  output [31:0] {Domain sd} imemreq_msg_addr,
  input  [31:0] {Domain sd} imemresp_msg_data,

  // Data Memory Port

  output [31:0] {Domain sd} dmemreq_msg_addr,
  output [31:0] {Domain sd} dmemreq_msg_data,
  input  [31:0] {Domain sd} dmemresp_msg_data,

  // mngr communication ports

  input  [31:0] {Domain sd} from_mngr_data,
  output [31:0] {Domain sd} to_mngr_data,

  // imul unit ports

  input         {Domain sd} mul_req_val_D,
  output        {Domain sd} mul_req_rdy_D,

  output        {Domain sd} mul_resp_val_X,
  input         {Domain sd} mul_resp_rdy_X,

  // control signals (ctrl->dpath)

  input [1:0]   {Domain sd} pc_sel_F,
  input         {Domain sd} reg_en_F,
  input         {Domain sd} reg_en_D,
  input         {Domain sd} reg_en_X,
  input         {Domain sd} reg_en_M,
  input         {Domain sd} reg_en_W,
  input [1:0]   {Domain sd} op0_sel_D,
  input [2:0]   {Domain sd} op1_sel_D,
  input [1:0]   {Domain sd} op0_byp_sel_D,
  input [1:0]   {Domain sd} op1_byp_sel_D,
  input [1:0]   {Domain sd} mfc_sel_D,
  input [3:0]   {Domain sd} alu_fn_X,
  input         {Domain sd} ex_result_sel_X,
  input         {Domain sd} wb_result_sel_M,
  input [4:0]   {Domain sd} rf_waddr_W,
  input         {Domain sd} rf_wen_W,
  input         {Domain sd} stats_en_wen_W,

  // status signals (dpath->ctrl)

  output [31:0] {Domain sd} inst_D,
  output        {Domain sd} br_cond_zero_X,
  output        {Domain sd} br_cond_neg_X,
  output        {Domain sd} br_cond_eq_X,

  // stats_en output

  output        {Domain sd} stats_en,
  input         {L} sd
);

  localparam c_reset_vector = 32'h1000;
  localparam c_reset_inst   = 32'h00000000;

  //--------------------------------------------------------------------
  // F stage
  //--------------------------------------------------------------------

  wire [31:0] {Domain sd} pc_F;
  wire [31:0] {Domain sd} pc_next_F;
  wire [31:0] {Domain sd} pc_plus4_F;
  wire [31:0] {Domain sd} pc_plus4_next_F;
  wire [31:0] {Domain sd} br_target_X;
  wire [31:0] {Domain sd} j_target_D;
  wire [31:0] {Domain sd} jr_target_D;

  vc_EnResetReg #(32, c_reset_vector) pc_plus4_reg_F
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_F),
    .d      (pc_plus4_next_F),
    .q      (pc_plus4_F),
    .sd     (sd)
  );

  vc_Incrementer #(32, 4) pc_incr_F
  (
    .in   (pc_next_F),
    .out  (pc_plus4_next_F),
    .sd   (sd)
  );

  vc_Mux4 #(32) pc_sel_mux_F
  (
    .in0  (pc_plus4_F),
    .in1  (br_target_X),
    .in2  (j_target_D),
    .in3  (jr_target_D),
    .sel  (pc_sel_F),
    .out  (pc_next_F),
    .sd   (sd)
  );

  assign imemreq_msg_addr = pc_next_F;

  // note: we don't need pc_F except to draw the line tracing

  vc_EnResetReg #(32) pc_reg_F
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_F),
    .d      (pc_next_F),
    .q      (pc_F),
    .sd     (sd)
  );

  //--------------------------------------------------------------------
  // D stage
  //--------------------------------------------------------------------

  wire  [31:0] {Domain sd} pc_plus4_D;
  wire  [31:0] {Domain sd} inst_D;
  wire   [4:0] {Domain sd} inst_rs_D;
  wire   [4:0] {Domain sd} inst_rt_D;
  wire   [4:0] {Domain sd} inst_rd_D;
  wire   [4:0] {Domain sd} inst_shamt_D;
  wire  [31:0] {Domain sd} inst_shamt_zext_D;
  wire  [15:0] {Domain sd} inst_imm_D;
  wire  [31:0] {Domain sd} inst_imm_sext_D;
  wire  [31:0] {Domain sd} inst_imm_zext_D;
  wire  [25:0] {Domain sd} inst_target_D;
  wire  [31:0] {Domain sd} rf_wdata_W;

  vc_EnResetReg #(32) pc_plus4_reg_D
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_D),
    .d      (pc_plus4_F),
    .q      (pc_plus4_D),
    .sd     (sd)
  );

  vc_EnResetReg #(32, c_reset_inst) inst_D_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_D),
    .d      (imemresp_msg_data),
    .q      (inst_D),
    .sd     (sd)
  );

  wire   [`PISA_INST_OPCODE_NBITS-1:0] {Domain sd} opcode_D;
  wire   [`PISA_INST_FUNC_NBITS-1:0]   {Domain sd} func_D;
  
  pisa_InstUnpack inst_unpack
  (
    .inst     (inst_D),
    .opcode   (opcode_D),
    .rs       (inst_rs_D),
    .rt       (inst_rt_D),
    .rd       (inst_rd_D),
    .shamt    (inst_shamt_D),
    .func     (func_D),
    .imm      (inst_imm_D),
    .target   (inst_target_D),
    .sd       (sd)
  );

  wire [ 4:0] {Domain sd} rf_raddr0_D = inst_rs_D;
  wire [31:0] {Domain sd} rf_rdata0_D;
  wire [ 4:0] {Domain sd} rf_raddr1_D = inst_rt_D;
  wire [31:0] {Domain sd} rf_rdata1_D;

  plab2_proc_Regfile rfile
  (
    .clk         (clk),
    .reset       (reset),
    .read_addr0  (rf_raddr0_D),
    .read_data0  (rf_rdata0_D),
    .read_addr1  (rf_raddr1_D),
    .read_data1  (rf_rdata1_D),
    .write_en    (rf_wen_W),
    .write_addr  (rf_waddr_W),
    .write_data  (rf_wdata_W),
    .sd          (sd)
  );

  wire [31:0] {Domain sd} op0_D;
  wire [31:0] {Domain sd} op1_D;

  vc_ZeroExtender #(5, 32) shamt_zext_D
  (
    .in   (inst_shamt_D),
    .out  (inst_shamt_zext_D),
    .sd   (sd)
  );

  wire [31:0] {Domain sd} op0_byp_out_D;
  wire [31:0] {Domain sd} byp_data_X;
  wire [31:0] {Domain sd} byp_data_M;
  wire [31:0] {Domain sd} byp_data_W;

  vc_Mux4 #(32) op0_byp_mux_D
  (
    .in0  (rf_rdata0_D),
    .in1  (byp_data_X),
    .in2  (byp_data_M),
    .in3  (byp_data_W),
    .sel  (op0_byp_sel_D),
    .out  (op0_byp_out_D),
    .sd   (sd)
  );

  vc_Mux3 #(32) op0_sel_mux_D
  (
    .in0  (op0_byp_out_D),
    .in1  (inst_shamt_zext_D),
    .in2  (32'd16),
    .sel  (op0_sel_D),
    .out  (op0_D),
    .sd   (sd)
  );

  assign jr_target_D = op0_byp_out_D;

  vc_SignExtender #(16, 32) imm_sext_D
  (
    .in   (inst_imm_D),
    .out  (inst_imm_sext_D),
    .sd   (sd)
  );

  vc_ZeroExtender #(16, 32) imm_zext_D
  (
    .in   (inst_imm_D),
    .out  (inst_imm_zext_D),
    .sd   (sd)
  );

  wire [31:0] {Domain sd} op1_byp_out_D;
  wire [31:0] {Domain sd} op1_byp_data_X;
  wire [31:0] {Domain sd} op1_byp_data_M;
  wire [31:0] {Domain sd} op1_byp_data_W;

  vc_Mux4 #(32) op1_byp_mux_D
  (
    .in0  (rf_rdata1_D),
    .in1  (byp_data_X),
    .in2  (byp_data_M),
    .in3  (byp_data_W),
    .sel  (op1_byp_sel_D),
    .out  (op1_byp_out_D),
    .sd   (sd)
  );

  wire [31:0] {Domain sd} mfc_data_D;

  vc_Mux5 #(32) op1_sel_mux_D
  (
    .in0  (op1_byp_out_D),
    .in1  (inst_imm_sext_D),
    .in2  (inst_imm_zext_D),
    .in3  (pc_plus4_D),
    .in4  (mfc_data_D),
    .sel  (op1_sel_D),
    .out  (op1_D),
    .sd   (sd)
  );

  vc_Mux3 #(32) mfc_sel_mux_D
  (
    .in0  (from_mngr_data),
    .in1  (p_num_cores),
    .in2  (p_core_id),
    .sel  (mfc_sel_D),
    .out  (mfc_data_D),
    .sd   (sd)
  );

  wire [31:0] {Domain sd} br_target_D;

  plab2_proc_BrTarget br_target_calc_D
  (
    .pc_plus4  (pc_plus4_D),
    .imm_sext  (inst_imm_sext_D),
    .br_target (br_target_D),
    .sd        (sd)
  );

  plab2_proc_JTarget j_target_calc_D
  (
    .pc_plus4   (pc_plus4_D),
    .imm_target (inst_target_D),
    .j_target   (j_target_D),
    .sd        (sd)
  );

  wire [31:0] {Domain sd} dmem_write_data_D;

  assign dmem_write_data_D = op1_byp_out_D;

  // the multiply unit

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_NBITS-1:0] {Domain sd} mul_req_msg_D;
  wire [31:0]                                 {Domain sd} mul_resp_msg_X;

  plab1_imul_IntMulVarLat imul
  (
    .clk      (clk),
    .reset    (reset),

    .in_val   (mul_req_val_D),
    .in_rdy   (mul_req_rdy_D),
    .in_msg   (mul_req_msg_D),

    .out_val  (mul_resp_val_X),
    .out_rdy  (mul_resp_rdy_X),
    .out_msg  (mul_resp_msg_X),
    .sd       (sd)
  );

  plab1_imul_MulDivReqMsgPack mul_req_msg_pack
  (
    .func   (`PLAB1_IMUL_MULDIV_REQ_MSG_FUNC_MUL),
    .a      (op0_D),
    .b      (op1_D),

    .msg    (mul_req_msg_D),
    .sd     (sd)
  );

  //--------------------------------------------------------------------
  // X stage
  //--------------------------------------------------------------------

  wire [31:0] {Domain sd} op0_X;
  wire [31:0] {Domain sd} op1_X;

  vc_EnResetReg #(32, 0) op0_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (op0_D),
    .q      (op0_X)
  );

  vc_EnResetReg #(32, 0) op1_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (op1_D),
    .q      (op1_X)
  );


  vc_EnResetReg #(32, 0) br_target_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (br_target_D),
    .q      (br_target_X)
  );


  vc_EqComparator #(32) br_cond_eq_comp_X
  (
    .in0  (op0_X),
    .in1  (op1_X),
    .out  (br_cond_eq_X),
    .sd   (sd)
  );

  vc_ZeroComparator #(32) br_cond_zero_comp_X
  (
    .in   (op0_X),
    .out  (br_cond_zero_X),
    .sd   (sd)
  );

  vc_EqComparator #(1) br_cond_neg_comp_X
  (
    .in0  (op0_X[31]),
    .in1  (1'b1),
    .out  (br_cond_neg_X),
    .sd   (sd)
  );

  wire [31:0] {Domain sd} alu_result_X;
  wire [31:0] {Domain sd} ex_result_X;

  plab2_proc_Alu alu
  (
    .in0  (op0_X),
    .in1  (op1_X),
    .fn   (alu_fn_X),
    .out  (alu_result_X)
  );

  vc_Mux2 #(32) ex_result_sel_mux_X
  (
    .in0    (alu_result_X),
    .in1    (mul_resp_msg_X),
    .sel    (ex_result_sel_X),
    .out    (ex_result_X)
  );

  wire [31:0] {Domain sd} dmem_write_data_X;

  // this is the bypassing data from x
  assign byp_data_X = ex_result_X;

  vc_EnResetReg #(32, 0) dmem_write_data_reg_X
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_X),
    .d      (dmem_write_data_D),
    .q      (dmem_write_data_X)
  );

  assign dmemreq_msg_addr = alu_result_X;
  assign dmemreq_msg_data = dmem_write_data_X;

  //--------------------------------------------------------------------
  // M stage
  //--------------------------------------------------------------------

  wire [31:0] {Domain sd} ex_result_M;

  vc_EnResetReg #(32, 0) ex_result_reg_M
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_M),
    .d      (ex_result_X),
    .q      (ex_result_M)
  );

  wire [31:0] {Domain sd} dmem_result_M;
  wire [31:0] {Domain sd} wb_result_M;

  assign dmem_result_M = dmemresp_msg_data;

  vc_Mux2 #(32) wb_result_sel_mux_M
  (
    .in0    (ex_result_M),
    .in1    (dmem_result_M),
    .sel    (wb_result_sel_M),
    .out    (wb_result_M)
  );

  // this is the bypassing data from m
  assign byp_data_M = wb_result_M;

  //--------------------------------------------------------------------
  // W stage
  //--------------------------------------------------------------------

  wire [31:0] {Domain sd} wb_result_W;

  vc_EnResetReg #(32, 0) wb_result_reg_W
  (
    .clk    (clk),
    .reset  (reset),
    .en     (reg_en_W),
    .d      (wb_result_M),
    .q      (wb_result_W)
  );

  assign to_mngr_data = wb_result_W;

  // this is the bypassing data from m
  assign byp_data_W = wb_result_W;

  assign rf_wdata_W = wb_result_W;

  // stats output

  // note the stats en is full 32-bit here but the outside port is one
  // bit.
  wire [31:0] {Domain sd} stats_en_W;

  assign stats_en = | stats_en_W;

  vc_EnResetReg #(32, 0) stats_en_reg_W
  (
    .clk    (clk),
    .reset  (reset),
    .en     (stats_en_wen_W),
    .d      (wb_result_W),
    .q      (stats_en_W)
  );

endmodule

`endif

