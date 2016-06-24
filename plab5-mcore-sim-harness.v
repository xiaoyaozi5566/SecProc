//=========================================================================
// Processor Simulator Harness
//=========================================================================
// This harness is meant to be instantiated for a specific implementation
// of the multiplier using the special IMPL macro like this:
//
//  `define PLAB5_MCORE_IMPL     plab5_mcore_Impl
//  `define PLAB5_MCORE_IMPL_STR "plab5-mcore-Impl"
//
//  `include "plab5-mcore-Impl.v"
//  `include "plab5-mcore-sim-harness.v"
//

`include "pisa-inst.v"
`include "plab5-mcore-ProcCacheNetAlt.v"
`include "vc-mem-msgs.v"

//------------------------------------------------------------------------
// Simulation driver
//------------------------------------------------------------------------

module top;

  // Local parameters

  localparam c_req_msg_nbits  = `VC_MEM_REQ_MSG_NBITS(8,32,128);
  localparam c_resp_msg_nbits = `VC_MEM_RESP_MSG_NBITS(8,128);
  localparam c_opaque_nbits   = 8;
  localparam c_data_nbits     = 128;  // size of mem message data in bits
  localparam c_addr_nbits     = 32;   // size of mem message address in bits
  
  wire        clk;
  wire        reset;
  
  wire [31:0] proc0_from_mngr_msg;
  wire        proc0_from_mngr_val;
  wire        proc0_from_mngr_rdy;
  
  wire [31:0] proc0_to_mngr_msg;
  wire        proc0_to_mngr_val;
  wire        proc0_to_mngr_rdy;

  wire  [c_req_msg_nbits-1:0]  memreq0_msg;
  wire                         memreq0_val;
  wire                         memreq0_rdy;

  wire  [c_resp_msg_nbits-1:0] memresp0_msg;
  wire                         memresp0_val;
  wire                         memresp0_rdy;

  wire  [c_req_msg_nbits-1:0]  memreq1_msg;
  wire                         memreq1_val;
  wire                         memreq1_rdy;

  wire  [c_resp_msg_nbits-1:0] memresp1_msg;
  wire                         memresp1_val;
  wire                         memresp1_rdy;

  wire                         stats_en;
  
  plab5_mcore_ProcCacheNetAlt proc_cache_net
  (
    .clk           (clk),
    .reset         (reset),

    .memreq0_val   (memreq0_val),
    .memreq0_rdy   (memreq0_rdy),
    .memreq0_msg   (memreq0_msg),

    .memresp0_val  (memresp0_val),
    .memresp0_rdy  (memresp0_rdy),
    .memresp0_msg  (memresp0_msg),

    .memreq1_val   (memreq1_val),
    .memreq1_rdy   (memreq1_rdy),
    .memreq1_msg   (memreq1_msg),

    .memresp1_val  (memresp1_val),
    .memresp1_rdy  (memresp1_rdy),
    .memresp1_msg  (memresp1_msg),

    .proc0_from_mngr_msg (proc0_from_mngr_msg),
    .proc0_from_mngr_val (proc0_from_mngr_val),
    .proc0_from_mngr_rdy (proc0_from_mngr_rdy),

    .proc0_to_mngr_msg   (proc0_to_mngr_msg),
    .proc0_to_mngr_val   (proc0_to_mngr_val),
    .proc0_to_mngr_rdy   (proc0_to_mngr_rdy),

    .stats_en            (stats_en)
  );

endmodule


