//========================================================================
// plab4-net-RingNetBase
//========================================================================

`ifndef PLAB4_NET_RING_NET_BASE
`define PLAB4_NET_RING_NET_BASE

`include "vc-net-msgs.v"
`include "vc-param-utils.v"
`include "vc-queues.v"
`include "plab4-net-RouterBase.v"

// macros to calculate previous and next router ids

`define PREV(i_)  ( ( i_ + c_num_ports - 1 ) % c_num_ports )
`define NEXT(i_)  i_

module plab4_net_RingNetBase_4
#(
  parameter p_payload_nbits  = 32,
  parameter p_opaque_nbits   = 3,
  parameter p_srcdest_nbits  = 2,
  
  parameter c_num_ports = 4,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits,

  parameter c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s),

  parameter m = c_net_msg_nbits
)
(
  input {L} clk,
  input {L} reset,

  input          {Domain in_sd_0} in_val_0,
  output         {Domain in_sd_0} in_rdy_0,
  input  [m-1:0] {Domain in_sd_0} in_msg_0,
  input          {L} in_sd_0,

  output         {Domain cur_sd} out_val_0,
  input          {Domain cur_sd} out_rdy_0,
  output [m-1:0] {Domain cur_sd} out_msg_0,
  
  input          {Domain in_sd_1} in_val_1,
  output         {Domain in_sd_1} in_rdy_1,
  input  [m-1:0] {Domain in_sd_1} in_msg_1,
  input          {L} in_sd_1,

  output         {Domain cur_sd} out_val_1,
  input          {Domain cur_sd} out_rdy_1,
  output [m-1:0] {Domain cur_sd} out_msg_1,
  
  input          {Domain in_sd_2} in_val_2,
  output         {Domain in_sd_2} in_rdy_2,
  input  [m-1:0] {Domain in_sd_2} in_msg_2,
  input          {L} in_sd_2,

  output         {Domain cur_sd} out_val_2,
  input          {Domain cur_sd} out_rdy_2,
  output [m-1:0] {Domain cur_sd} out_msg_2,
  
  input          {Domain in_sd_3} in_val_3,
  output         {Domain in_sd_3} in_rdy_3,
  input  [m-1:0] {Domain in_sd_3} in_msg_3,
  input          {L} in_sd_3,
  
  output         {Domain cur_sd} out_val_3,
  input          {Domain cur_sd} out_rdy_3,
  output [m-1:0] {Domain cur_sd} out_msg_3,
  
  input          {L} cur_sd
);

  // // current security domain of the router
  // reg                          {L} cur_sd;
  //
  // always @ (posedge clk) begin
  //     cur_sd <= ~cur_sd;
  // end
  //----------------------------------------------------------------------
  // Router-router connection wires
  //----------------------------------------------------------------------

  // forward (increasing router id) wires

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} forw_out_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} forw_out_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] {Domain cur_sd} forw_out_msg;

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} forw_in_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} forw_in_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] {Domain cur_sd} forw_in_msg;

  // backward (decreasing router id) wires

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} backw_out_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} backw_out_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] {Domain cur_sd} backw_out_msg;

  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} backw_in_val;
  wire [`VC_PORT_PICK_NBITS(1,c_num_ports)-1:0] {Domain cur_sd} backw_in_rdy;
  wire [`VC_PORT_PICK_NBITS(m,c_num_ports)-1:0] {Domain cur_sd} backw_in_msg;

  //----------------------------------------------------------------------
  // Router generation
  //----------------------------------------------------------------------

  genvar i;

  plab4_net_RouterBase
  #(
    .p_payload_nbits  (p_payload_nbits),
    .p_opaque_nbits   (p_opaque_nbits),
    .p_srcdest_nbits  (p_srcdest_nbits),

    .p_router_id      (0),
    .p_num_routers    (c_num_ports)
  )
  router_0
  (
    .clk      (clk),
    .reset    (reset),

    .in0_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,`PREV(0))]),
    .in0_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,`PREV(0))]),
    .in0_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,`PREV(0))]),

    .in1_val  (in_val_0),
    .in1_rdy  (in_rdy_0),
    .in1_msg  (in_msg_0),
    .in1_sd   (in_sd_0),

    .in2_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,`NEXT(0))]),
    .in2_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(0))]),
    .in2_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,`NEXT(0))]),

    .out0_val (backw_out_val[`VC_PORT_PICK_FIELD(1,`PREV(0))]),
    .out0_rdy (backw_out_rdy[`VC_PORT_PICK_FIELD(1,`PREV(0))]),
    .out0_msg (backw_out_msg[`VC_PORT_PICK_FIELD(m,`PREV(0))]),

    .out1_val (out_val_0),
    .out1_rdy (out_rdy_0),
    .out1_msg (out_msg_0),

    .out2_val (forw_out_val[`VC_PORT_PICK_FIELD(1,`NEXT(0))]),
    .out2_rdy (forw_out_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(0))]),
    .out2_msg (forw_out_msg[`VC_PORT_PICK_FIELD(m,`NEXT(0))]),
    .cur_sd   (cur_sd)
  );

  plab4_net_RouterBase
  #(
    .p_payload_nbits  (p_payload_nbits),
    .p_opaque_nbits   (p_opaque_nbits),
    .p_srcdest_nbits  (p_srcdest_nbits),

    .p_router_id      (1),
    .p_num_routers    (c_num_ports)
  )
  router_1
  (
    .clk      (clk),
    .reset    (reset),

    .in0_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,`PREV(1))]),
    .in0_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,`PREV(1))]),
    .in0_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,`PREV(1))]),

    .in1_val  (in_val_1),
    .in1_rdy  (in_rdy_1),
    .in1_msg  (in_msg_1),
    .in1_sd   (in_sd_1),

    .in2_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,`NEXT(1))]),
    .in2_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(1))]),
    .in2_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,`NEXT(1))]),

    .out0_val (backw_out_val[`VC_PORT_PICK_FIELD(1,`PREV(1))]),
    .out0_rdy (backw_out_rdy[`VC_PORT_PICK_FIELD(1,`PREV(1))]),
    .out0_msg (backw_out_msg[`VC_PORT_PICK_FIELD(m,`PREV(1))]),

    .out1_val (out_val_1),
    .out1_rdy (out_rdy_1),
    .out1_msg (out_msg_1),

    .out2_val (forw_out_val[`VC_PORT_PICK_FIELD(1,`NEXT(1))]),
    .out2_rdy (forw_out_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(1))]),
    .out2_msg (forw_out_msg[`VC_PORT_PICK_FIELD(m,`NEXT(1))]),
    .cur_sd   (cur_sd)
  );

  plab4_net_RouterBase
  #(
    .p_payload_nbits  (p_payload_nbits),
    .p_opaque_nbits   (p_opaque_nbits),
    .p_srcdest_nbits  (p_srcdest_nbits),

    .p_router_id      (2),
    .p_num_routers    (c_num_ports)
  )
  router_2
  (
    .clk      (clk),
    .reset    (reset),

    .in0_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,`PREV(2))]),
    .in0_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,`PREV(2))]),
    .in0_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,`PREV(2))]),

    .in1_val  (in_val_2),
    .in1_rdy  (in_rdy_2),
    .in1_msg  (in_msg_2),
    .in1_sd   (in_sd_2),

    .in2_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,`NEXT(2))]),
    .in2_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(2))]),
    .in2_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,`NEXT(2))]),

    .out0_val (backw_out_val[`VC_PORT_PICK_FIELD(1,`PREV(2))]),
    .out0_rdy (backw_out_rdy[`VC_PORT_PICK_FIELD(1,`PREV(2))]),
    .out0_msg (backw_out_msg[`VC_PORT_PICK_FIELD(m,`PREV(2))]),

    .out1_val (out_val_2),
    .out1_rdy (out_rdy_2),
    .out1_msg (out_msg_2),

    .out2_val (forw_out_val[`VC_PORT_PICK_FIELD(1,`NEXT(2))]),
    .out2_rdy (forw_out_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(2))]),
    .out2_msg (forw_out_msg[`VC_PORT_PICK_FIELD(m,`NEXT(2))]),
    .cur_sd   (cur_sd)
  );

  plab4_net_RouterBase
  #(
    .p_payload_nbits  (p_payload_nbits),
    .p_opaque_nbits   (p_opaque_nbits),
    .p_srcdest_nbits  (p_srcdest_nbits),

    .p_router_id      (3),
    .p_num_routers    (c_num_ports)
  )
  router_3
  (
    .clk      (clk),
    .reset    (reset),

    .in0_val  (forw_in_val[`VC_PORT_PICK_FIELD(1,`PREV(3))]),
    .in0_rdy  (forw_in_rdy[`VC_PORT_PICK_FIELD(1,`PREV(3))]),
    .in0_msg  (forw_in_msg[`VC_PORT_PICK_FIELD(m,`PREV(3))]),

    .in1_val  (in_val_3),
    .in1_rdy  (in_rdy_3),
    .in1_msg  (in_msg_3),
    .in1_sd   (in_sd_3),

    .in2_val  (backw_in_val[`VC_PORT_PICK_FIELD(1,`NEXT(3))]),
    .in2_rdy  (backw_in_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(3))]),
    .in2_msg  (backw_in_msg[`VC_PORT_PICK_FIELD(m,`NEXT(3))]),

    .out0_val (backw_out_val[`VC_PORT_PICK_FIELD(1,`PREV(3))]),
    .out0_rdy (backw_out_rdy[`VC_PORT_PICK_FIELD(1,`PREV(3))]),
    .out0_msg (backw_out_msg[`VC_PORT_PICK_FIELD(m,`PREV(3))]),

    .out1_val (out_val_3),
    .out1_rdy (out_rdy_3),
    .out1_msg (out_msg_3),

    .out2_val (forw_out_val[`VC_PORT_PICK_FIELD(1,`NEXT(3))]),
    .out2_rdy (forw_out_rdy[`VC_PORT_PICK_FIELD(1,`NEXT(3))]),
    .out2_msg (forw_out_msg[`VC_PORT_PICK_FIELD(m,`NEXT(3))]),
    .cur_sd   (cur_sd)
  );

  //   end
  // endgenerate

  //----------------------------------------------------------------------
  // Channel generation
  //----------------------------------------------------------------------

  generate
    for ( i = 0; i < c_num_ports; i = i + 1 ) begin: CHANNEL

      assign forw_in_val[`VC_PORT_PICK_FIELD(1,i)] = forw_out_val[`VC_PORT_PICK_FIELD(1,i)];
      assign forw_in_rdy[`VC_PORT_PICK_FIELD(1,i)] = forw_out_rdy[`VC_PORT_PICK_FIELD(1,i)];
      assign forw_in_msg[`VC_PORT_PICK_FIELD(m,i)] = forw_out_msg[`VC_PORT_PICK_FIELD(m,i)];

      assign backw_in_val[`VC_PORT_PICK_FIELD(1,i)] = backw_out_val[`VC_PORT_PICK_FIELD(1,i)];
      assign backw_in_rdy[`VC_PORT_PICK_FIELD(1,i)] = backw_out_rdy[`VC_PORT_PICK_FIELD(1,i)];
      assign backw_in_msg[`VC_PORT_PICK_FIELD(m,i)] = backw_out_msg[`VC_PORT_PICK_FIELD(m,i)];

    end
  endgenerate

endmodule

`endif /* PLAB4_NET_RING_NET_BASE */
