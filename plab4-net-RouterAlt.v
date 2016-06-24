//========================================================================
// Alternative Router
//========================================================================

`ifndef PLAB4_NET_ROUTER_ALT_V
`define PLAB4_NET_ROUTER_ALT_V

`include "vc-crossbars.v"
`include "vc-queues.v"
`include "vc-mem-msgs.v"
`include "plab4-net-RouterInputCtrl.v"
`include "plab4-net-RouterAdaptiveInputTerminalCtrl.v"
`include "plab4-net-RouterOutputCtrl.v"

module plab4_net_RouterAlt
#(
  parameter p_payload_nbits  = 32,
  parameter p_opaque_nbits   = 3,
  parameter p_srcdest_nbits  = 3,

  parameter p_router_id      = 0,
  parameter p_num_routers    = 8,

  parameter p_num_free_nbits = 2,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits,

  parameter c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s)
)
(
  input                        clk,
  input                        reset,

  input                        in0_val,
  output                       in0_rdy,
  input  [c_net_msg_nbits-1:0] in0_msg,

  input                        in1_val,
  output                       in1_rdy,
  input  [c_net_msg_nbits-1:0] in1_msg,

  input                        in2_val,
  output                       in2_rdy,
  input  [c_net_msg_nbits-1:0] in2_msg,

  output                       out0_val,
  input                        out0_rdy,
  output [c_net_msg_nbits-1:0] out0_msg,

  output                       out1_val,
  input                        out1_rdy,
  output [c_net_msg_nbits-1:0] out1_msg,

  output                       out2_val,
  input                        out2_rdy,
  output [c_net_msg_nbits-1:0] out2_msg,

  input [p_num_free_nbits-1:0] num_free_prev,
  input [p_num_free_nbits-1:0] num_free_next
);

  //----------------------------------------------------------------------
  // Input queues
  //----------------------------------------------------------------------

  wire                       in0_deq_val;
  wire                       in0_deq_rdy;
  wire [c_net_msg_nbits-1:0] in0_deq_msg;
  wire [2:0]                 num_free0;

  wire                       in1_deq_val;
  wire                       in1_deq_rdy;
  wire [c_net_msg_nbits-1:0] in1_deq_msg;

  wire                       in2_deq_val;
  wire                       in2_deq_rdy;
  wire [c_net_msg_nbits-1:0] in2_deq_msg;
  wire [2:0]                 num_free2;

  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in0_queue
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in0_val),
    .enq_rdy            (in0_rdy),
    .enq_msg            (in0_msg),

    .deq_val            (in0_deq_val),
    .deq_rdy            (in0_deq_rdy),
    .deq_msg            (in0_deq_msg),

    .num_free_entries   (num_free0)
  );

  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in1_queue
  (
    .clk        (clk),
    .reset      (reset),

    .enq_val    (in1_val),
    .enq_rdy    (in1_rdy),
    .enq_msg    (in1_msg),

    .deq_val    (in1_deq_val),
    .deq_rdy    (in1_deq_rdy),
    .deq_msg    (in1_deq_msg)
  );

  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in2_queue
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in2_val),
    .enq_rdy            (in2_rdy),
    .enq_msg            (in2_msg),

    .deq_val            (in2_deq_val),
    .deq_rdy            (in2_deq_rdy),
    .deq_msg            (in2_deq_msg),

    .num_free_entries   (num_free2)
  );

  //----------------------------------------------------------------------
  // Crossbar
  //----------------------------------------------------------------------

  wire [1:0] xbar_sel0;
  wire [1:0] xbar_sel1;
  wire [1:0] xbar_sel2;

  vc_Crossbar3
  #(
    .p_nbits    (c_net_msg_nbits)
  )
  xbar
  (
    .in0        (in0_deq_msg),
    .in1        (in1_deq_msg),
    .in2        (in2_deq_msg),

    .sel0       (xbar_sel0),
    .sel1       (xbar_sel1),
    .sel2       (xbar_sel2),

    .out0       (out0_msg),
    .out1       (out1_msg),
    .out2       (out2_msg)
  );

  //----------------------------------------------------------------------
  // Input controls
  //----------------------------------------------------------------------

  wire [2:0] in0_reqs;
  wire [2:0] in1_reqs;
  wire [2:0] in2_reqs;

  wire [2:0] in0_grants;
  wire [2:0] in1_grants;
  wire [2:0] in2_grants;

  wire [2:0] out0_reqs;
  wire [2:0] out1_reqs;
  wire [2:0] out2_reqs;

  wire [2:0] out0_grants;
  wire [2:0] out1_grants;
  wire [2:0] out2_grants;

  wire [s-1:0] dest0;
  wire [s-1:0] dest1;
  wire [s-1:0] dest2;

  assign out0_reqs  = { in2_reqs[0], in1_reqs[0], in0_reqs[0] };
  assign out1_reqs  = { in2_reqs[1], in1_reqs[1], in0_reqs[1] };
  assign out2_reqs  = { in2_reqs[2], in1_reqs[2], in0_reqs[2] };

  assign in0_grants = { out2_grants[0], out1_grants[0], out0_grants[0] };
  assign in1_grants = { out2_grants[1], out1_grants[1], out0_grants[1] };
  assign in2_grants = { out2_grants[2], out1_grants[2], out0_grants[2] };

  assign dest0 = in0_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];
  assign dest1 = in1_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];
  assign dest2 = in2_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];

  plab4_net_RouterInputCtrl
  #(
    .p_router_id    (p_router_id),
    .p_num_routers  (p_num_routers),
    .p_default_reqs (3'b100)
  )
  in0_ctrl
  (
    .dest   (dest0),

    .in_val (in0_deq_val),
    .in_rdy (in0_deq_rdy),

    .reqs   (in0_reqs),
    .grants (in0_grants)
  );

  plab4_net_RouterAdaptiveInputTerminalCtrl
  #(
    .p_router_id           (p_router_id),
    .p_num_routers         (p_num_routers),
    .p_num_free_nbits      (3),
    .p_num_free_chan_nbits (2)
  )
  in1_ctrl
  (
    .dest      (dest1),

    .in_val    (in1_deq_val),
    .in_rdy    (in1_deq_rdy),

    .num_free0 (num_free0),
    .num_free2 (num_free2),

    .num_free_chan0 (num_free_prev),
    .num_free_chan2 (num_free_next),

    .reqs      (in1_reqs),
    .grants    (in1_grants)
  );

  plab4_net_RouterInputCtrl
  #(
    .p_router_id    (p_router_id),
    .p_num_routers  (p_num_routers),
    .p_default_reqs (3'b001)
  )
  in2_ctrl
  (
    .dest   (dest2),

    .in_val (in2_deq_val),
    .in_rdy (in2_deq_rdy),

    .reqs   (in2_reqs),
    .grants (in2_grants)
  );

  //----------------------------------------------------------------------
  // Output controls
  //----------------------------------------------------------------------

  plab4_net_RouterOutputCtrl out0_ctrl
  (
    .clk      (clk),
    .reset    (reset),

    .reqs     (out0_reqs),
    .grants   (out0_grants),

    .out_val  (out0_val),
    .out_rdy  (out0_rdy),
    .xbar_sel (xbar_sel0)
  );

  plab4_net_RouterOutputCtrl out1_ctrl
  (
    .clk      (clk),
    .reset    (reset),

    .reqs     (out1_reqs),
    .grants   (out1_grants),

    .out_val  (out1_val),
    .out_rdy  (out1_rdy),
    .xbar_sel (xbar_sel1)
  );

  plab4_net_RouterOutputCtrl out2_ctrl
  (
    .clk      (clk),
    .reset    (reset),

    .reqs     (out2_reqs),
    .grants   (out2_grants),

    .out_val  (out2_val),
    .out_rdy  (out2_rdy),
    .xbar_sel (xbar_sel2)
  );

  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------

  `include "vc-trace-tasks.v"

  reg [2*8-1:0] in0_str;
  reg [4*8-1:0] in1_str;
  reg [2*8-1:0] in2_str;

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( in0_str, "%x",
              in0_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );
    $sformat( in1_str, "%x>%x",
              in1_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)],
              in1_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)] );
    $sformat( in2_str, "%x",
              in2_deq_msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)] );

    vc_trace_str( trace, "(" );
    vc_trace_str_val_rdy( trace, in0_deq_val, in0_deq_rdy, in0_str );
    vc_trace_str( trace, "|" );
    vc_trace_str_val_rdy( trace, in1_deq_val, in1_deq_rdy, in1_str );
    vc_trace_str( trace, "|" );
    vc_trace_str_val_rdy( trace, in2_deq_val, in2_deq_rdy, in2_str );
    vc_trace_str( trace, ")" );
  end
  endtask

endmodule
`endif /* PLAB4_NET_ROUTER_ALT_V */
