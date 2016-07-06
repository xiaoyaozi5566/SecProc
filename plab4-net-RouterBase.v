//========================================================================
// plab4-net-RouterBase
//========================================================================

`ifndef PLAB4_NET_ROUTER_BASE_V
`define PLAB4_NET_ROUTER_BASE_V

`include "vc-crossbars.v"
`include "vc-queues.v"
`include "vc-mem-msgs.v"
`include "vc-net-msgs.v"
`include "vc-muxes.v"
`include "plab4-net-RouterInputCtrl.v"
`include "plab4-net-RouterInputTerminalCtrl.v"
`include "plab4-net-RouterOutputCtrl.v"

module plab4_net_RouterBase
#(
  parameter p_payload_nbits  = 32,
  parameter p_opaque_nbits   = 3,
  parameter p_srcdest_nbits  = 3,

  parameter p_router_id      = 0,
  parameter p_num_routers    = 8,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits,

  parameter c_net_msg_nbits = `VC_NET_MSG_NBITS(p,o,s)
)
(
  input                        clk,
  input                        reset,

  input                        {Domain in0_sd} in0_val,
  output                       {Domain in0_sd} in0_rdy,
  input  [c_net_msg_nbits-1:0] {L} in0_msg,
  // current security domain of west input
  input                        {L} in0_sd,

  input                        {Domain in1_sd} in1_val,
  output                       {Domain in1_sd} in1_rdy,
  input  [c_net_msg_nbits-1:0] {L} in1_msg,
  // current security domain of terminal input
  input                        {L} in1_sd,

  input                        {Domain in2_sd} in2_val,
  output                       {Domain in2_sd} in2_rdy,
  input  [c_net_msg_nbits-1:0] {L} in2_msg,
  // current security domain of east input
  input                        {L} in2_sd,

  output                       {Domain out0_sd} out0_val,
  input                        {Domain out0_sd} out0_rdy,
  output [c_net_msg_nbits-1:0] {L} out0_msg,
  // current security domain of west output
  output                       {L} out0_sd,

  output                       {Domain out1_sd} out1_val,
  input                        {Domain out1_sd} out1_rdy,
  output [c_net_msg_nbits-1:0] {L} out1_msg,
  // current security domain of termianl output
  output                       {L} out1_sd,

  output                       {Domain out2_sd} out2_val,
  input                        {Domain out2_sd} out2_rdy,
  output [c_net_msg_nbits-1:0] {L} out2_msg,
  // current security domain of east output
  output                       {L} out2_sd

);

  // current security domain of the router
  reg                          {L} cur_sd;
  
  always @ (posedge clk) begin
      cur_sd <= ~cur_sd;
  end
  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  // enqueue signals
  wire                       {D0} in0_val_d0;
  wire                       {D0} in0_rdy_d0;
  wire [c_net_msg_nbits-1:0] {L} in0_msg_d0;
  wire                       {D1} in0_val_d1;
  wire                       {D1} in0_rdy_d1;
  wire [c_net_msg_nbits-1:0] {L} in0_msg_d1;

  wire                       {D0} in2_val_d0;
  wire                       {D0} in2_rdy_d0;
  wire [c_net_msg_nbits-1:0] {L} in2_msg_d0;
  wire                       {D1} in2_val_d1;
  wire                       {D1} in2_rdy_d1;
  wire [c_net_msg_nbits-1:0] {L} in2_msg_d1;
  
  // dequeue signals
  wire                       {D0} in0_deq_val_d0;
  wire                       {D0} in0_deq_rdy_d0;
  wire [c_net_msg_nbits-1:0] {L} in0_deq_msg_d0;
  wire                       {D1} in0_deq_val_d1;
  wire                       {D1} in0_deq_rdy_d1;
  wire [c_net_msg_nbits-1:0] {L} in0_deq_msg_d1;

  wire                       {Domain in1_sd} in1_deq_val;
  wire                       {Domain in1_sd} in1_deq_rdy;
  wire [c_net_msg_nbits-1:0] {L} in1_deq_msg;

  wire                       {D0} in2_deq_val_d0;
  wire                       {D0} in2_deq_rdy_d0;
  wire [c_net_msg_nbits-1:0] {L} in2_deq_msg_d0;
  wire                       {D1} in2_deq_val_d1;
  wire                       {D1} in2_deq_rdy_d1;
  wire [c_net_msg_nbits-1:0] {L} in2_deq_msg_d1;

  //+++ gen-harness : begin insert +++++++++++++++++++++++++++++++++++++++
// 
//   // instantiate input queues, crossbar and control modules here
// 
//   // the following is a placeholder, delete
// 
//   assign in0_rdy = 0;
//   assign in1_rdy = 0;
//   assign in2_rdy = 0;
// 
//   assign out0_val = 0;
//   assign out1_val = 0;
//   assign out2_val = 0;
// 
//   assign out0_msg = 0;
//   assign out1_msg = 0;
//   assign out2_msg = 0;
// 
  //+++ gen-harness : end insert +++++++++++++++++++++++++++++++++++++++++

  //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++++

  //----------------------------------------------------------------------
  // Input queues
  //----------------------------------------------------------------------

  wire [2:0]                 {D0} num_free_west_d0;
  wire [2:0]                 {D1} num_free_west_d1;

  wire [2:0]                 {D0} num_free_east_d0;
  wire [2:0]                 {D1} num_free_east_d1;
  
  assign in0_msg_d0 = in0_msg;
  assign in0_msg_d1 = in0_msg;
  // assign in0_val_d0 = in0_val ? (in0_sd ? 0 : 1) : 0;
  assign in0_val_d0 = (in0_sd == 1) ? 0 : in0_val;
  assign in0_val_d1 = (in0_sd == 1) ? in0_val : 0;
  // FIX
  assign in0_deq_rdy_d0 = (cur_sd == 1) ? 0 : in0_deq_rdy;
  assign in0_deq_rdy_d1 = (cur_sd == 1) ? in0_deq_rdy : 0;
  
  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in0_queue_d0
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in0_val_d0),
    .enq_rdy            (in0_rdy_d0),
    .enq_msg            (in0_msg_d0),

    .deq_val            (in0_deq_val_d0),
    .deq_rdy            (in0_deq_rdy_d0),
    .deq_msg            (in0_deq_msg_d0),

    .num_free_entries   (num_free_west_d0)
  );
  
  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in0_queue_d1
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in0_val_d1),
    .enq_rdy            (in0_rdy_d1),
    .enq_msg            (in0_msg_d1),

    .deq_val            (in0_deq_val_d1),
    .deq_rdy            (in0_deq_rdy_d1),
    .deq_msg            (in0_deq_msg_d1),

    .num_free_entries   (num_free_west_d1)
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

  assign in2_msg_d0 = in2_msg;
  assign in2_msg_d1 = in2_msg;
  assign in2_val_d0 = (in2_sd == 1) ? 0 : in2_val;
  assign in2_val_d1 = (in2_sd == 1) ? in2_val : 0;
  // FIX
  assign in2_deq_rdy_d0 = (cur_sd == 1) ? 0 : in2_deq_rdy;
  assign in2_deq_rdy_d1 = (cur_sd == 1) ? in2_deq_rdy : 0;
  
  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in2_queue_d0
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in2_val_d0),
    .enq_rdy            (in2_rdy_d0),
    .enq_msg            (in2_msg_d0),

    .deq_val            (in2_deq_val_d0),
    .deq_rdy            (in2_deq_rdy_d0),
    .deq_msg            (in2_deq_msg_d0),

    .num_free_entries   (num_free_east_d0)
  );
  
  vc_Queue
  #(
    .p_type       (`VC_QUEUE_NORMAL),
    .p_msg_nbits  (c_net_msg_nbits),
    .p_num_msgs   (4)
  )
  in2_queue_d1
  (
    .clk                (clk),
    .reset              (reset),

    .enq_val            (in2_val_d1),
    .enq_rdy            (in2_rdy_d1),
    .enq_msg            (in2_msg_d1),

    .deq_val            (in2_deq_val_d1),
    .deq_rdy            (in2_deq_rdy_d1),
    .deq_msg            (in2_deq_msg_d1),

    .num_free_entries   (num_free_east_d1)
  );

  //----------------------------------------------------------------------
  // Input queue mux
  //----------------------------------------------------------------------
  
  wire                       {Domain cur_sd} in0_deq_val;
  wire                       {Domain cur_sd} in0_deq_rdy;
  wire [c_net_msg_nbits-1:0] {Domain cur_sd} in0_deq_msg;
  wire [2:0]                 {Domain cur_sd} num_free_west;

  wire                       {Domain cur_sd} in2_deq_val;
  wire                       {Domain cur_sd} in2_deq_rdy;
  wire [c_net_msg_nbits-1:0] {Domain cur_sd} in2_deq_msg;
  wire [2:0]                 {Domain cur_sd} num_free_east;
  
  vc_Mux2
  #(
  	.p_nbits		(c_net_msg_nbits)
  )
  in0_deq_msg_mux
  (
  	.in0			(in0_deq_msg_d0),
  	.in1			(in0_deq_msg_d1),
  	.sel			(cur_sd),
  	.out			(in0_deq_msg)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(1)
  )
  in0_deq_val_mux
  (
  	.in0			(in0_deq_val_d0),
  	.in1			(in0_deq_val_d1),
  	.sel			(cur_sd),
  	.out			(in0_deq_val)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(1)
  )
  in0_rdy_mux
  (
  	.in0			(in0_rdy_d0),
  	.in1			(in0_rdy_d1),
    // FIX
  	.sel			(cur_sd),
  	.out			(in0_rdy)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(3)
  )
  in0_deq_free_mux
  (
  	.in0			(num_free_west_d0),
  	.in1			(num_free_west_d1),
  	.sel			(cur_sd),
  	.out			(num_free_west)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(c_net_msg_nbits)
  )
  in2_deq_msg_mux
  (
  	.in0			(in2_deq_msg_d0),
  	.in1			(in2_deq_msg_d1),
  	.sel			(cur_sd),
  	.out			(in2_deq_msg)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(1)
  )
  in2_deq_val_mux
  (
  	.in0			(in2_deq_val_d0),
  	.in1			(in2_deq_val_d1),
  	.sel			(cur_sd),
  	.out			(in2_deq_val)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(1)
  )
  in2_rdy_mux
  (
  	.in0			(in2_rdy_d0),
  	.in1			(in2_rdy_d1),
  	.sel			(cur_sd),
  	.out			(in2_rdy)
  );
  
  vc_Mux2
  #(
  	.p_nbits		(3)
  )
  in2_deq_free_mux
  (
  	.in0			(num_free_east_d0),
  	.in1			(num_free_east_d1),
  	.sel			(cur_sd),
  	.out			(num_free_east)
  );
  
  //----------------------------------------------------------------------
  // Crossbar
  //----------------------------------------------------------------------

  wire [1:0] {Domain cur_sd} xbar_sel0;
  wire [1:0] {Domain cur_sd} xbar_sel1;
  wire [1:0] {Domain cur_sd} xbar_sel2;

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

  wire [2:0] {Domain cur_sd} in0_reqs;
  wire [2:0] {Domain cur_sd} in1_reqs;
  wire [2:0] {Domain cur_sd} in2_reqs;

  wire [2:0] {Domain cur_sd} in0_grants;
  wire [2:0] {Domain cur_sd} in1_grants;
  wire [2:0] {Domain cur_sd} in2_grants;

  wire [2:0] {Domain cur_sd} out0_reqs;
  wire [2:0] {Domain cur_sd} out1_reqs;
  wire [2:0] {Domain cur_sd} out2_reqs;

  wire [2:0] {Domain cur_sd} out0_grants;
  wire [2:0] {Domain cur_sd} out1_grants;
  wire [2:0] {Domain cur_sd} out2_grants;

  wire [s-1:0] {Domain cur_sd} dest0;
  wire [s-1:0] {Domain cur_sd} dest1;
  wire [s-1:0] {Domain cur_sd} dest2;

  assign out0_reqs  = { in2_reqs[0], in1_reqs[0], in0_reqs[0] };
  assign out1_reqs  = { in2_reqs[1], in1_reqs[1], in0_reqs[1] };
  assign out2_reqs  = { in2_reqs[2], in1_reqs[2], in0_reqs[2] };

  assign in0_grants = { out2_grants[0], out1_grants[0], out0_grants[0] };
  assign in1_grants = { out2_grants[1], out1_grants[1], out0_grants[1] };
  assign in2_grants = { out2_grants[2], out1_grants[2], out0_grants[2] };

  assign dest0 = in0_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];
  assign dest1 = in1_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];
  assign dest2 = in2_deq_msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];

  // Note: to prevent livelocking, the route computation is only done at
  // the terminal input controls, and the other input controls simply pass
  // the message through

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

  // Note: the following is the implementation w/o deadlock prevention
  //
  // plab4_net_RouterInputCtrl
  // #(
  //   .p_router_id    (p_router_id),
  //   .p_num_routers  (p_num_routers)
  // )
  // in1_ctrl
  // (
  //   .dest   (dest1),

  //   .in_val (in1_deq_val),
  //   .in_rdy (in1_deq_rdy),

  //   .reqs   (in1_reqs),
  //   .grants (in1_grants)
  // );

  plab4_net_RouterInputTerminalCtrl
  #(
    .p_router_id      (p_router_id),
    .p_num_routers    (p_num_routers),
    .p_num_free_nbits (3)
  )
  in1_ctrl
  (
    .dest          (dest1),

    .in_val        (in1_deq_val),
    .in_rdy        (in1_deq_rdy),

    .num_free_west (num_free_west),
    .num_free_east (num_free_east),

    .reqs          (in1_reqs),
    .grants        (in1_grants)
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
  
  assign out0_sd = cur_sd;

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
  
  assign out1_sd = cur_sd;

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
  
  assign out2_sd = cur_sd;

  //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++++

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
`endif /* PLAB4_NET_ROUTER_BASE_V */
