//========================================================================
// Verilog Components: Drop Unit
//========================================================================
// Drop unit allows dropping a packet when the drop signal is high. This
// is useful especially in pipelined processor, when a squash should drop
// a late arriving memory response.

`ifndef VC_DROPUNIT_V
`define VC_DROPUNIT_V

module vc_DropUnit
#(
  parameter   p_msg_nbits = 1
)
(
  input                    {L} clk,
  input                    {L} reset,

  // the drop signal will drop the next arriving packet

  input                    {Domain sd} drop,

  input  [p_msg_nbits-1:0] {Domain sd} in_msg,
  input                    {Domain sd} in_val,
  output reg               {Domain sd} in_rdy,

  output [p_msg_nbits-1:0] {Domain sd} out_msg,
  output reg               {Domain sd} out_val,
  input                    {Domain sd} out_rdy,
  input                    {L} sd
);

  localparam c_state_pass = 1'b0;
  localparam c_state_drop = 1'b1;

  reg {Domain sd} state;
  reg {Domain sd} next_state;
  wire {Domain sd} in_go;

  assign in_go = in_rdy && in_val;

  // assign output message same as input message

  assign out_msg = in_msg;

  // next state

  always @(*) begin
    if ( state == c_state_pass ) begin

      // we only go to drop state if there is a drop request and we cannot
      // drop it right away (!in_go)
      if ( drop && !in_go )
        next_state = c_state_drop;
      else
        next_state = c_state_pass;

    end else begin

      // if we are in the drop mode and a message arrives, we can go back
      // to pass state
      if ( in_go )
        next_state = c_state_pass;
      else
        next_state = c_state_drop;

    end
  end

  // state outputs

  always @(*) begin
    if ( state == c_state_pass ) begin

      // we combinationally take care of dropping if the packet is already
      // available
      out_val = in_val && !drop;
      in_rdy  = out_rdy;

    end else begin

      // we just drop the packet
      out_val = 1'b0;
      in_rdy  = 1'b1;

    end
  end

  // state transitions

  always @( posedge clk ) begin

    if ( reset )
      state <= c_state_pass;
    else
      state <= next_state;

  end

endmodule

`endif
