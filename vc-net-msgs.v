//========================================================================
// vc-net-msgs : Network Messages
//========================================================================
// Payload field width (payload_nbits), opaque filed width (opaque_nbits)
// source and destination field widths (p_srcdest_nbits) are adjustable
// via parameterized macro definitions.
//
// Example message format for payload_nbits = 32, srcdest_nbits = 3,
// opaque_nbits = 4
//
// 41   39 38  36 35    32 31                            0
// +------+------+--------+-------------------------------+
// | dest | src  | opaque | payload                       |
// +------+------+--------+-------------------------------+
//

`ifndef VC_NET_MSGS_V
`define VC_NET_MSGS_V

//-------------------------------------------------------------------------
// Message defines
//-------------------------------------------------------------------------

// Size of message

`define VC_NET_MSG_NBITS(p_,o_,s_)       p_ + o_ + ( 2 * s_ )

// Payload field

`define VC_NET_MSG_PAYLOAD_NBITS(p_,o_,s_)  p_

`define VC_NET_MSG_PAYLOAD_MSB(p_,o_,s_)                                \
  ( `VC_NET_MSG_PAYLOAD_NBITS(p_,o_,s_) - 1 )

`define VC_NET_MSG_PAYLOAD_FIELD(p_,o_,s_)                              \
  ( `VC_NET_MSG_PAYLOAD_MSB(p_,o_,s_) ) : 0

// Opaque field

`define VC_NET_MSG_OPAQUE_NBITS(p_,o_,s_) o_

`define VC_NET_MSG_OPAQUE_MSB(p_,o_,s_)                                 \
  ( `VC_NET_MSG_PAYLOAD_MSB(p_,o_,s_) +                                 \
  `VC_NET_MSG_OPAQUE_NBITS(p_,o_,s_) )

`define VC_NET_MSG_OPAQUE_FIELD(p_,o_,s_)                               \
  ( `VC_NET_MSG_OPAQUE_MSB(p_,o_,s_) ) :                                \
  ( `VC_NET_MSG_PAYLOAD_MSB(p_,o_,s_) + 1 )

// Source field

`define VC_NET_MSG_SRC_NBITS(p_,o_,s_) s_

`define VC_NET_MSG_SRC_MSB(p_,o_,s_)                                    \
  ( `VC_NET_MSG_OPAQUE_MSB(p_,o_,s_) + `VC_NET_MSG_SRC_NBITS(p_,o_,s_) )

`define VC_NET_MSG_SRC_FIELD(p_,o_,s_)                                  \
  ( `VC_NET_MSG_SRC_MSB(p_,o_,s_) ) :                                   \
  ( `VC_NET_MSG_OPAQUE_MSB(p_,o_,s_) + 1 )

// Destination field

`define VC_NET_MSG_DEST_NBITS(p_,o_,s_) s_

`define VC_NET_MSG_DEST_MSB(p_,o_,s_)                                   \
  ( `VC_NET_MSG_SRC_MSB(p_,o_,s_) + `VC_NET_MSG_DEST_NBITS(p_,o_,s_) )

`define VC_NET_MSG_DEST_FIELD(p_,o_,s_)                                 \
  ( `VC_NET_MSG_DEST_MSB(p_,o_,s_) ) :                                  \
  ( `VC_NET_MSG_SRC_MSB(p_,o_,s_) + 1 )

//-------------------------------------------------------------------------
// Pack network message
//-------------------------------------------------------------------------

module vc_NetMsgPack
#(
  parameter p_payload_nbits = 32,
  parameter p_opaque_nbits  = 4,
  parameter p_srcdest_nbits = 3,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits
)
(
  // Input message

  input [`VC_NET_MSG_DEST_NBITS(p,o,s)-1:0]    {Domain sd} dest,
  input [`VC_NET_MSG_SRC_NBITS(p,o,s)-1:0]     {Domain sd} src,
  input [`VC_NET_MSG_OPAQUE_NBITS(p,o,s)-1:0]  {Domain sd} opaque,
  input [`VC_NET_MSG_PAYLOAD_NBITS(p,o,s)-1:0] {Domain sd} payload,

  // Output msg

  output [`VC_NET_MSG_NBITS(p,o,s)-1:0]        {Domain sd} msg,
  input                                        {L} sd
);

  assign msg[`VC_NET_MSG_DEST_FIELD(p,o,s)]    = dest;
  assign msg[`VC_NET_MSG_SRC_FIELD(p,o,s)]     = src;
  assign msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)]  = opaque;
  assign msg[`VC_NET_MSG_PAYLOAD_FIELD(p,o,s)] = payload;

endmodule

//-------------------------------------------------------------------------
// Unpack network message
//-------------------------------------------------------------------------

module vc_NetMsgUnpack
#(
  parameter p_payload_nbits = 32,
  parameter p_opaque_nbits  = 4,
  parameter p_srcdest_nbits = 3,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits
)
(
  // Input message

  input  [`VC_NET_MSG_NBITS(p,o,s)-1:0] {Domain sd} msg,

  // Output message

  output [`VC_NET_MSG_DEST_NBITS(p,o,s)-1:0]    {Domain sd} dest,
  output [`VC_NET_MSG_SRC_NBITS(p,o,s)-1:0]     {Domain sd} src,
  output [`VC_NET_MSG_OPAQUE_NBITS(p,o,s)-1:0]  {Domain sd} opaque,
  output [`VC_NET_MSG_PAYLOAD_NBITS(p,o,s)-1:0] {Domain sd} payload,
  input                                         {L} sd
);

  assign dest    = msg[`VC_NET_MSG_DEST_FIELD(p,o,s)];
  assign src     = msg[`VC_NET_MSG_SRC_FIELD(p,o,s)];
  assign opaque  = msg[`VC_NET_MSG_OPAQUE_FIELD(p,o,s)];
  assign payload = msg[`VC_NET_MSG_PAYLOAD_FIELD(p,o,s)];

endmodule

//------------------------------------------------------------------------
// Trace message
//------------------------------------------------------------------------

module vc_NetMsgTrace
#(
  parameter p_payload_nbits = 32,
  parameter p_opaque_nbits  = 4,
  parameter p_srcdest_nbits = 3,

  // Shorter names, not to be set from outside the module
  parameter p = p_payload_nbits,
  parameter o = p_opaque_nbits,
  parameter s = p_srcdest_nbits
)
(
  input                                 {L} clk,
  input                                 {L} reset,
  input                                 {Domain sd} val,
  input                                 {Domain sd} rdy,
  input  [`VC_NET_MSG_NBITS(p,o,s)-1:0] {Domain sd} msg,
  input                                 {L} sd
);

  // Extract fields

  wire [`VC_NET_MSG_DEST_FIELD(p,o,s)]    {Domain sd} dest;
  wire [`VC_NET_MSG_SRC_FIELD(p,o,s)]     {Domain sd} src;
  wire [`VC_NET_MSG_OPAQUE_FIELD(p,o,s)]  {Domain sd} opaque;
  wire [`VC_NET_MSG_PAYLOAD_FIELD(p,o,s)] {Domain sd} payload;

  vc_NetMsgUnpack#(p,o,s) net_msg_unpack
  (
    .msg     (msg),
    .dest    (dest),
    .src     (src),
    .opaque  (opaque),
    .payload (payload),
    .sd      (sd)
  );

  // Line tracing

  `include "vc-trace-tasks.v"

  reg [vc_trace_nbits-1:0] str;
  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( str, "%x>%x:%x", src, dest, opaque );

    // Trace with val/rdy signals

    vc_trace_str_val_rdy( trace, val, rdy, str );

  end
  endtask

endmodule

`endif /* VC_NET_MSGS_V */
