//========================================================================
// Verilog Components: Crossbars
//========================================================================

`ifndef VC_CROSSBARS_V
`define VC_CROSSBARS_V

`include "vc-muxes.v"

//------------------------------------------------------------------------
// 2 input, 2 output crossbar
//------------------------------------------------------------------------

module vc_Crossbar2
#(
  parameter p_nbits = 32
)
(
  input  [p_nbits-1:0]   {Domain sd} in0,
  input  [p_nbits-1:0]   {Domain sd} in1,

  input                  {Domain sd} sel0,
  input                  {Domain sd} sel1,

  output [p_nbits-1:0]   {Domain sd} out0,
  output [p_nbits-1:0]   {Domain sd} out1,
  input                  {L} sd
);

  vc_Mux2#(p_nbits) out0_mux
  (
    .in0 (in0),
    .in1 (in1),
    .sel (sel0),
    .out (out0),
    .sd  (sd)
  );

  vc_Mux2#(p_nbits) out1_mux
  (
    .in0 (in0),
    .in1 (in1),
    .sel (sel1),
    .out (out1),
    .sd  (sd)
  );

endmodule

//------------------------------------------------------------------------
// 3 input, 3 output crossbar
//------------------------------------------------------------------------

module vc_Crossbar3
#(
  parameter p_nbits = 32
)
(
  input  [p_nbits-1:0]   {Domain cur_sd} in0,
  input  [p_nbits-1:0]   {Domain cur_sd} in1,
  input  [p_nbits-1:0]   {Domain cur_sd} in2,

  input  [1:0]           {Domain cur_sd} sel0,
  input  [1:0]           {Domain cur_sd} sel1,
  input  [1:0]           {Domain cur_sd} sel2,

  output [p_nbits-1:0]   {Domain cur_sd} out0,
  output [p_nbits-1:0]   {Domain cur_sd} out1,
  output [p_nbits-1:0]   {Domain cur_sd} out2,
  input                  {L} cur_sd
);

  vc_Mux3#(p_nbits) out0_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .sel (sel0),
    .out (out0),
    .sd  (cur_sd)
  );

  vc_Mux3#(p_nbits) out1_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .sel (sel1),
    .out (out1),
    .sd  (cur_sd)
  );

  vc_Mux3#(p_nbits) out2_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .sel (sel2),
    .out (out2),
    .sd  (cur_sd)
  );

endmodule

//------------------------------------------------------------------------
// 4 input, 4 output crossbar
//------------------------------------------------------------------------

module vc_Crossbar4
#(
  parameter p_nbits = 32
)
(
  input  [p_nbits-1:0]   {Domain sd} in0,
  input  [p_nbits-1:0]   {Domain sd} in1,
  input  [p_nbits-1:0]   {Domain sd} in2,
  input  [p_nbits-1:0]   {Domain sd} in3,

  input  [1:0]           {Domain sd} sel0,
  input  [1:0]           {Domain sd} sel1,
  input  [1:0]           {Domain sd} sel2,
  input  [1:0]           {Domain sd} sel3,

  output [p_nbits-1:0]   {Domain sd} out0,
  output [p_nbits-1:0]   {Domain sd} out1,
  output [p_nbits-1:0]   {Domain sd} out2,
  output [p_nbits-1:0]   {Domain sd} out3,
  input                  {L} sd
);

  vc_Mux4#(p_nbits) out0_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .in3 (in3),
    .sel (sel0),
    .out (out0),
    .sd  (sd)
  );

  vc_Mux4#(p_nbits) out1_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .in3 (in3),
    .sel (sel1),
    .out (out1),
    .sd  (sd)
  );

  vc_Mux4#(p_nbits) out2_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .in3 (in3),
    .sel (sel2),
    .out (out2),
    .sd  (sd)
  );

  vc_Mux4#(p_nbits) out3_mux
  (
    .in0 (in0),
    .in1 (in1),
    .in2 (in2),
    .in3 (in3),
    .sel (sel3),
    .out (out3),
    .sd  (sd)
  );

endmodule

`endif /* VC_CROSSBARS_V */
