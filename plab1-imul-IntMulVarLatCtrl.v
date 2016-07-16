`include "plab1-imul-msgs.v"
`include "plab1-imul-CountZeros.v"
`include "vc-muxes.v"
`include "vc-regs.v"
`include "vc-arithmetic.v"
`include "vc-assert.v"

//========================================================================
// Integer Multiplier Variable-Latency Control
//========================================================================

module plab1_imul_IntMulVarLatCtrl
(
  input      {L} clk,
  input      {L} reset,

   // Dataflow signals

  input      {Domain sd} in_val,
  output reg {Domain sd} in_rdy,
  output reg {Domain sd} out_val,
  input      {Domain sd} out_rdy,

 // Control signals (ctrl->dpath)

  output reg {Domain sd} a_mux_sel,
  output reg {Domain sd} b_mux_sel,
  output reg {Domain sd} add_mux_sel,
  output reg {Domain sd} result_mux_sel,
  output reg {Domain sd} result_en,

   // Control signals (dpath->ctrl)

  input      {Domain sd} b_gt_zero,
  input      {Domain sd} b_lsb,
  input      {L} sd
);

  //----------------------------------------------------------------------
  // State Definitions
  //----------------------------------------------------------------------

  localparam STATE_IDLE = 2'd0;
  localparam STATE_CALC = 2'd1;
  localparam STATE_DONE = 2'd2;

  //----------------------------------------------------------------------
  // State
  //----------------------------------------------------------------------

  always @( posedge clk ) begin
    if ( reset ) begin
      state_reg <= STATE_IDLE;
    end
    else begin
      state_reg <= state_next;
    end
  end

  //----------------------------------------------------------------------
  // State Transitions
  //----------------------------------------------------------------------

  wire {Domain sd} in_go        = in_val  && in_rdy;
  wire {Domain sd} out_go       = out_val && out_rdy;
  wire {Domain sd} is_calc_done = !b_gt_zero;

  reg [1:0] {Domain sd} state_reg;
  reg [1:0] {Domain sd} state_next;

  always @(*) begin

    state_next = state_reg;

    case ( state_reg )

      STATE_IDLE: if ( in_go        ) state_next = STATE_CALC;
      STATE_CALC: if ( is_calc_done ) state_next = STATE_DONE;
      STATE_DONE: if ( out_go       ) state_next = STATE_IDLE;

    endcase

  end

  //----------------------------------------------------------------------
  // State Outputs
  //----------------------------------------------------------------------

  localparam a_x     = 1'dx;
  localparam a_lsh   = 1'd0;
  localparam a_ld    = 1'd1;

  localparam b_x     = 1'dx;
  localparam b_rsh   = 1'd0;
  localparam b_ld    = 1'd1;

  localparam res_x   = 1'dx;
  localparam res_add = 1'd0;
  localparam res_0   = 1'd1;

  localparam add_x   = 1'dx;
  localparam add_add = 1'd0;
  localparam add_res = 1'd1;

  task cs
  (
    input cs_in_rdy,
    input cs_out_val,
    input cs_a_mux_sel,
    input cs_b_mux_sel,
    input cs_add_mux_sel,
    input cs_result_mux_sel,
    input cs_result_en
  );
  begin
    in_rdy         = cs_in_rdy;
    out_val        = cs_out_val;
    a_mux_sel      = cs_a_mux_sel;
    b_mux_sel      = cs_b_mux_sel;
    add_mux_sel    = cs_add_mux_sel;
    result_mux_sel = cs_result_mux_sel;
    result_en      = cs_result_en;
  end
  endtask

  wire {Domain sd} do_add_shift = b_lsb;
  wire {Domain sd} do_shift     = !b_lsb;

  // Set outputs using a control signal "table"

  always @(*) begin

    cs( 0, 0, a_x, b_x, add_x, res_x, 0 );
    case ( state_reg )
      //                                  in  out a mux  b mux  add mux  res mux  res
      //                                  rdy val sel    sel    sel      sel      en
      STATE_IDLE:                     cs( 1,  0,  a_ld,  b_ld,  add_x,   res_0,   1 );
      STATE_CALC: if ( do_shift     ) cs( 0,  0,  a_lsh, b_rsh, add_res, res_add, 1 );
             else if ( do_add_shift ) cs( 0,  0,  a_lsh, b_rsh, add_add, res_add, 1 );
      STATE_DONE:                     cs( 0,  1,  a_x,   b_x,   add_x,   res_x,   0 );

    endcase

  end

  //----------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------

  always @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( in_val    );
      `VC_ASSERT_NOT_X( in_rdy    );
      `VC_ASSERT_NOT_X( out_val   );
      `VC_ASSERT_NOT_X( out_rdy   );
      `VC_ASSERT_NOT_X( result_en );
    end
  end

endmodule