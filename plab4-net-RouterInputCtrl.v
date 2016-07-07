//========================================================================
// Router Input Ctrl
//========================================================================

`ifndef PLAB4_NET_ROUTER_INPUT_CTRL_V
`define PLAB4_NET_ROUTER_INPUT_CTRL_V


module plab4_net_RouterInputCtrl
#(
  parameter p_router_id   = 0,
  parameter p_num_routers = 8,

  //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++++

  // indicates the reqs signal to pass through a message
  parameter p_default_reqs = 3'b001,

  //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++++

  // parameter not meant to be set outside this module

  parameter c_dest_nbits = $clog2( p_num_routers )

)
(
  input  [c_dest_nbits-1:0] {Domain cur_sd} dest,

  input                     {Domain cur_sd} in_val,
  output                    {Domain cur_sd} in_rdy,

  output [2:0]              {Domain cur_sd} reqs,
  input  [2:0]              {Domain cur_sd} grants,
  input                     {L} cur_sd
);

  //+++ gen-harness : begin insert +++++++++++++++++++++++++++++++++++++++
// 
//   // add logic here
// 
//   assign in_rdy = 0;
//   assign reqs = 0;
// 
  //+++ gen-harness : end insert +++++++++++++++++++++++++++++++++++++++++

  //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++++

  //----------------------------------------------------------------------
  // Combinational logic
  //----------------------------------------------------------------------

  // rdy is just a reductive OR of the AND of reqs and grants

  assign in_rdy = | (reqs & grants);

  reg [2:0] reqs;

  always @(*) begin
    if (in_val) begin

      // if the packet is for this port, redirect it to the terminal
      if ( dest == p_router_id )
        reqs = 3'b010;

      // otherwise, we just pass through it
      else
        reqs = p_default_reqs;

    end else begin
      // if !val, we don't request any output ports
      reqs = 3'b000;
    end
  end

  //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++++

endmodule

`endif  /* PLAB4_NET_ROUTER_INPUT_CTRL_V */
