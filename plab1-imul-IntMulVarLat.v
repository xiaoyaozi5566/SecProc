//=========================================================================
// Integer Multiplier Variable-Latency Implementation
//=========================================================================

`ifndef PLAB1_IMUL_INT_MUL_VAR_LAT_V
`define PLAB1_IMUL_INT_MUL_VAR_LAT_V

`include "plab1-imul-msgs.v"
`include "plab1-imul-CountZeros.v"
`include "plab1-imul-IntMulVarLatDpath.v"
`include "plab1-imul-IntMulVarLatCtrl.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"
`include "vc-assert.v"

//=========================================================================
// Integer Multiplier Variable-Latency Implementation
//=========================================================================

module plab1_imul_IntMulVarLat
(
  input                                         {L} clk,
  input                                         {L} reset,

  input                                         {Domain sd} in_val,
  output                                        {Domain sd} in_rdy,
  input  [`PLAB1_IMUL_MULDIV_REQ_MSG_NBITS-1:0] {Domain sd} in_msg,

  output                                        {Domain sd} out_val,
  input                                         {Domain sd} out_rdy,
  output [31:0]                                 {Domain sd} out_msg,
  input                                         {L} sd
);

  //----------------------------------------------------------------------
  // Unpack Request Message
  //----------------------------------------------------------------------

  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_FUNC_NBITS-1:0] {Domain sd} in_msg_func;
  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_A_NBITS-1:0]    {Domain sd} in_msg_a;
  wire [`PLAB1_IMUL_MULDIV_REQ_MSG_B_NBITS-1:0]    {Domain sd} in_msg_b;

  plab1_imul_MulDivReqMsgUnpack muldiv_req_msg_unpack
  (
    .msg  (in_msg),
    .func (in_msg_func),
    .a    (in_msg_a),
    .b    (in_msg_b),
    .sd   (sd)
  );

  //+++ gen-harness : begin insert +++++++++++++++++++++++++++++++++++++++
  //
  // // Instantiate datapath and control models here and then connect them
  // // together. As a place holder, for now we simply pass input operand
  // // A through to the output, which obviously is not / correct.
  //
  // assign in_rdy  = out_rdy;
  // assign out_val = in_val;
  // assign out_msg = in_msg_a;
  //
  //+++ gen-harness : end insert +++++++++++++++++++++++++++++++++++++++++

  //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++++

  wire {Domain sd} a_mux_sel;
  wire {Domain sd} b_mux_sel;
  wire {Domain sd} add_mux_sel;
  wire {Domain sd} result_mux_sel;
  wire {Domain sd} result_en;
  wire {Domain sd} b_gt_zero;
  wire {Domain sd} b_lsb;

  plab1_imul_IntMulVarLatDpath dpath
  (
   .clk            (clk),
   .reset          (reset),
   .in_msg_a       (in_msg_a),
   .in_msg_b       (in_msg_b),
   .out_msg        (out_msg),
   .a_mux_sel      (a_mux_sel),
   .b_mux_sel      (b_mux_sel),
   .add_mux_sel    (add_mux_sel),
   .result_mux_sel (result_mux_sel),
   .result_en      (result_en),
   .b_gt_zero      (b_gt_zero),
   .b_lsb          (b_lsb),
   .sd             (sd)
  );

  plab1_imul_IntMulVarLatCtrl ctrl
  (
   .clk            (clk),
   .reset          (reset),
   .in_val         (in_val),
   .in_rdy         (in_rdy),
   .out_val        (out_val),
   .out_rdy        (out_rdy),
   .a_mux_sel      (a_mux_sel),
   .b_mux_sel      (b_mux_sel),
   .add_mux_sel    (add_mux_sel),
   .result_mux_sel (result_mux_sel),
   .result_en      (result_en),
   .b_gt_zero      (b_gt_zero),
   .b_lsb          (b_lsb),
   .sd             (sd)
  );

  //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++++

  //----------------------------------------------------------------------
  // Line Tracing
  //----------------------------------------------------------------------

  plab1_imul_MulDivReqMsgTrace#(p_nbits) in_msg_trace
  (
    .clk   (clk),
    .reset (reset),
    .val   (in_val),
    .rdy   (in_rdy),
    .msg   (in_msg),
    .sd    (sd)
  );

  `include "vc-trace-tasks.v"

  reg [`VC_TRACE_NBITS_TO_NCHARS(32)*8-1:0]       str;
  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    in_msg_trace.trace_module( trace );

    vc_trace_str( trace, "(" );

    // Add extra line tracing for internal state here

    //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++

    $sformat( str, "%x", dpath.a_reg_out);
    vc_trace_str( trace, str );
    vc_trace_str( trace, " " );

    $sformat( str, "%x", dpath.b_reg_out);
    vc_trace_str( trace, str );
    vc_trace_str( trace, " " );

    $sformat( str, "%x", dpath.result_reg_out);
    vc_trace_str( trace, str );
    vc_trace_str( trace, " " );

    case ( ctrl.state_reg )
      ctrl.STATE_IDLE: vc_trace_str( trace, "I " );

      ctrl.STATE_CALC: begin
        if ( ctrl.do_add_shift )
          vc_trace_str( trace, "C+" );
        else if ( ctrl.do_shift )
          vc_trace_str( trace, "C " );
        else
          vc_trace_str( trace, "C?" );
      end

      ctrl.STATE_DONE: vc_trace_str( trace, "D " );
      default        : vc_trace_str( trace, "? " );
    endcase

    vc_trace_str( trace, ")" );

    //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++

    $sformat( str, "%x", out_msg );
    vc_trace_str_val_rdy( trace, out_val, out_rdy, str );

  end
  endtask

endmodule

`endif /* PLAB1_IMUL_INT_MUL_VAR_LAT_V */

