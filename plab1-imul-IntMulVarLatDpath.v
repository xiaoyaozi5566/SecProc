`include "plab1-imul-msgs.v"
`include "plab1-imul-CountZeros.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"
`include "vc-assert.v"

//========================================================================
// Integer Multiplier Variable-Latency Datapath
//========================================================================

module plab1_imul_IntMulVarLatDpath
(
  input                                          {L} clk,
  input                                          {L} reset,

  // Data signals

  input [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0] {Domain sd} in_msg_a,
  input [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0] {Domain sd} in_msg_b,
  output [31:0]                                  {Domain sd} out_msg,

  // Control signals (ctrl->dpath)

  input                                          {Domain sd} a_mux_sel,
  input                                          {Domain sd} b_mux_sel,
  input                                          {Domain sd} add_mux_sel,
  input                                          {Domain sd} result_mux_sel,
  input                                          {Domain sd} result_en,

  // Control signals (dpath->ctrl)

  output                                         {Domain sd} b_gt_zero,
  output                                         {Domain sd} b_lsb,
  input                                          {L} sd
);

  // B mux

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]  {Domain sd} right_shift_1_out;
  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]  {Domain sd} b_mux_out;

  vc_Mux2#(`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS) b_mux
  (
   .sel (b_mux_sel),
   .in0 (right_shift_1_out),
   .in1 (in_msg_b),
   .out (b_mux_out),
   .sd  (sd)
  );

  // B register

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]  {Domain sd} b_reg_out;

  vc_Reg#(`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS) b_reg
  (
   .clk (clk),
   .d   (b_mux_out),
   .q   (b_reg_out),
   .sd  (sd)
  );

  // > 0 Comparator

  vc_GtComparator#(32) b_gt_zero_comparator
  (
   .in0 (right_shift_1_out),
   .in1 (0),
   .out (b_gt_zero),
   .sd  (sd)
  );

  // CountZeros

  wire [3:0] {Domain sd} count_zeros_out;

  plab1_imul_CountZeros count_zeros
  (
   .to_be_counted (b_reg_out[7:0]),
   .count (count_zeros_out),
   .sd    (sd)
  );

  // Variable right shift

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]  {Domain sd} right_shift_out;

  vc_RightLogicalShifter#(`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS,4) right_shift
  (
   .in    (b_reg_out),
   .shamt (count_zeros_out),
   .out   (right_shift_out),
   .sd    (sd)
  );

  assign b_lsb = right_shift_out[0];

  // Right shift 1

  vc_RightLogicalShifter#(`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS,1) right_shift_1
  (
   .in    (right_shift_out),
   .shamt (1'b1),
   .out   (right_shift_1_out),
   .sd    (sd)
  );

  // A mux

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} left_shift_1_out;
  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} a_mux_out;

  vc_Mux2#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS) a_mux
  (
   .sel (a_mux_sel),
   .in0 (left_shift_1_out),
   .in1 (in_msg_a),
   .out (a_mux_out),
   .sd  (sd)
  );

  // A register

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} a_reg_out;

  vc_Reg#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS) a_reg
  (
   .clk (clk),
   .d   (a_mux_out),
   .q   (a_reg_out),
   .sd  (sd)
  );

  // Variable left shift

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]  {Domain sd} left_shift_out;

  vc_LeftLogicalShifter#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS,4) left_shift
  (
   .in    (a_reg_out),
   .shamt (count_zeros_out),
   .out   (left_shift_out),
   .sd    (sd)
  );

  // Left shift 1

  vc_LeftLogicalShifter#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS,1) left_shift_1
  (
   .in    (left_shift_out),
   .shamt (1'b1),
   .out   (left_shift_1_out),
   .sd    (sd)
  );

  // Result mux

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} add_mux_out;
  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} result_mux_out;

  vc_Mux2#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS) result_mux
  (
   .sel (result_mux_sel),
   .in0 (add_mux_out),
   .in1 (0),
   .out (result_mux_out),
   .sd  (sd)
  );

  // Result register

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} result_reg_out;

  vc_EnReg#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS) result_reg
  (
   .clk   (clk),
   .d     (result_mux_out),
   .q     (result_reg_out),
   .reset (reset),
   .en    (result_en),
   .sd    (sd)
  );

  // Adder

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]  {Domain sd} adder_out;

  vc_SimpleAdder#(`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS) adder
  (
   .in0 (left_shift_out),
   .in1 (result_reg_out),
   .out (adder_out),
   .sd  (sd)
  );

  // Add mux

  vc_Mux2#(`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS) add_mux
  (
   .sel (add_mux_sel),
   .in0 (adder_out),
   .in1 (result_reg_out),
   .out (add_mux_out),
   .sd  (sd)
  );

  // out_msg

  assign out_msg = result_reg_out;

endmodule