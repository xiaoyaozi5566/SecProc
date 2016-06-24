//========================================================================
// 1-Core Processor-Cache-Network
//========================================================================

`ifndef PLAB5_MCORE_PROC_CACHE_NET_ALT_V
`define PLAB5_MCORE_PROC_CACHE_NET_ALT_V
`define PLAB4_NET_NUM_PORTS_4

`include "vc-mem-msgs.v"
`include "plab2-proc-PipelinedProcBypass.v"
`include "plab3-mem-BlockingCacheAlt.v"
`include "plab5-mcore-MemNet.v"

module plab5_mcore_ProcCacheNetAlt
#(
  parameter p_icache_nbytes = 256,
  parameter p_dcache_nbytes = 256,

  parameter p_num_cores     = 4,

  // local params not meant to be set from outside

  parameter c_opaque_nbits  = 8,
  parameter c_addr_nbits    = 32,
  parameter c_data_nbits    = 32,
  parameter c_cacheline_nbits = 128,

  parameter o = c_opaque_nbits,
  parameter a = c_addr_nbits,
  parameter d = c_data_nbits,
  parameter l = c_cacheline_nbits,

  parameter c_memreq_nbits  = `VC_MEM_REQ_MSG_NBITS(o,a,l),
  parameter c_memresp_nbits = `VC_MEM_RESP_MSG_NBITS(o,l)
)
(
  input clk,
  input reset,

  // proc0 manager ports

  input  [31:0] proc0_from_mngr_msg,
  input         proc0_from_mngr_val,
  output        proc0_from_mngr_rdy,

  output [31:0] proc0_to_mngr_msg,
  output        proc0_to_mngr_val,
  input         proc0_to_mngr_rdy,

  output  [c_memreq_nbits-1:0] memreq0_msg,
  output                       memreq0_val,
  input                        memreq0_rdy,

  input  [c_memresp_nbits-1:0] memresp0_msg,
  input                        memresp0_val,
  output                       memresp0_rdy,

  output  [c_memreq_nbits-1:0] memreq1_msg,
  output                       memreq1_val,
  input                        memreq1_rdy,

  input  [c_memresp_nbits-1:0] memresp1_msg,
  input                        memresp1_val,
  output                       memresp1_rdy,

  output                       stats_en
);

  //+++ gen-harness : begin insert ++++++++++++++++++++++++++++++++++++++
// 
//   // placeholder assignments, add processor-cache-net composition here
// 
//   assign proc0_from_mngr_rdy = 0;
//   assign proc0_to_mngr_msg   = 0;
//   assign proc0_to_mngr_val   = 0;
// 
//   assign memreq0_msg  = 0;
//   assign memreq0_val  = 0;
//   assign memresp0_rdy = 0;
// 
//   assign memreq1_msg  = 0;
//   assign memreq1_val  = 0;
//   assign memresp1_rdy = 0;
// 
//   assign stats_en     = 0;
// 
  //+++ gen-harness : end insert +++++++++++++++++++++++++++++++++++++++++

  //+++ gen-harness : begin cut ++++++++++++++++++++++++++++++++++++++++++

  // short name for refill data size and network source size

  localparam rd = c_cacheline_nbits;

  // memory message sizes

  localparam c_proc_req_nbits    = `VC_MEM_REQ_MSG_NBITS(o,a,d);
  localparam c_proc_resp_nbits   = `VC_MEM_RESP_MSG_NBITS(o,d);

  localparam c_mem_req_nbits     = `VC_MEM_REQ_MSG_NBITS(o,a,rd);
  localparam c_mem_resp_nbits    = `VC_MEM_RESP_MSG_NBITS(o,rd);

  // short names for the memory message sizes

  localparam prq = c_proc_req_nbits;
  localparam prs = c_proc_resp_nbits;

  localparam mrq = c_mem_req_nbits;
  localparam mrs = c_mem_resp_nbits;

  // declare network wires

  wire [`VC_PORT_PICK_NBITS(prq,p_num_cores)-1:0] dcache_net_req_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_req_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_req_in_rdy;

  wire [`VC_PORT_PICK_NBITS(prq,p_num_cores)-1:0] dcache_net_req_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_req_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_req_out_rdy;

  wire [`VC_PORT_PICK_NBITS(prs,p_num_cores)-1:0] dcache_net_resp_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_resp_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_resp_in_rdy;

  wire [`VC_PORT_PICK_NBITS(prs,p_num_cores)-1:0] dcache_net_resp_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_resp_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_net_resp_out_rdy;

  wire [`VC_PORT_PICK_NBITS(mrq,p_num_cores)-1:0] dcache_refill_net_req_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_req_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_req_in_rdy;

  wire [`VC_PORT_PICK_NBITS(mrq,p_num_cores)-1:0] dcache_refill_net_req_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_req_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_req_out_rdy;

  wire [`VC_PORT_PICK_NBITS(mrs,p_num_cores)-1:0] dcache_refill_net_resp_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_resp_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_resp_in_rdy;

  wire [`VC_PORT_PICK_NBITS(mrs,p_num_cores)-1:0] dcache_refill_net_resp_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_resp_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] dcache_refill_net_resp_out_rdy;

  wire [`VC_PORT_PICK_NBITS(mrq,p_num_cores)-1:0] icache_refill_net_req_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_req_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_req_in_rdy;

  wire [`VC_PORT_PICK_NBITS(mrq,p_num_cores)-1:0] icache_refill_net_req_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_req_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_req_out_rdy;

  wire [`VC_PORT_PICK_NBITS(mrs,p_num_cores)-1:0] icache_refill_net_resp_in_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_resp_in_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_resp_in_rdy;

  wire [`VC_PORT_PICK_NBITS(mrs,p_num_cores)-1:0] icache_refill_net_resp_out_msg;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_resp_out_val;
  wire [`VC_PORT_PICK_NBITS(1  ,p_num_cores)-1:0] icache_refill_net_resp_out_rdy;

  // declare wires for the manager interface

  wire [`VC_PORT_PICK_NBITS(32,p_num_cores)-1:0]  from_mngr_msg;
  wire [`VC_PORT_PICK_NBITS(1 ,p_num_cores)-1:0]  from_mngr_val;
  wire [`VC_PORT_PICK_NBITS(1 ,p_num_cores)-1:0]  from_mngr_rdy;

  wire [`VC_PORT_PICK_NBITS(32,p_num_cores)-1:0]  to_mngr_msg;
  wire [`VC_PORT_PICK_NBITS(1 ,p_num_cores)-1:0]  to_mngr_val;
  wire [`VC_PORT_PICK_NBITS(1 ,p_num_cores)-1:0]  to_mngr_rdy;

  // define proc0 name

  `define PLAB5_MCORE_PROC0 CORES_CACHES[0].PROC.proc

  genvar i;

  generate
  for ( i = 0; i < p_num_cores; i = i + 1 ) begin: CORES_CACHES

    wire [prq-1:0] icache_req_msg;
    wire           icache_req_val;
    wire           icache_req_rdy;

    wire [prs-1:0] icache_resp_msg;
    wire           icache_resp_val;
    wire           icache_resp_rdy;

    // processor

    if ( i == 0 ) begin: PROC
      // proc0 uses the manager interface to communicate with test/sim harness

      plab2_proc_PipelinedProcBypass
      #(
        .p_num_cores  (p_num_cores),
        .p_core_id    (i)
      )
      proc
      (
        .clk           (clk),
        .reset         (reset),

        .imemreq_msg   (icache_req_msg),
        .imemreq_val   (icache_req_val),
        .imemreq_rdy   (icache_req_rdy),

        .imemresp_msg  (icache_resp_msg),
        .imemresp_val  (icache_resp_val),
        .imemresp_rdy  (icache_resp_rdy),

        .dmemreq_msg   (dcache_net_req_in_msg[`VC_PORT_PICK_FIELD(prq,i)]),
        .dmemreq_val   (dcache_net_req_in_val[`VC_PORT_PICK_FIELD(1,  i)]),
        .dmemreq_rdy   (dcache_net_req_in_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

        .dmemresp_msg  (dcache_net_resp_out_msg[`VC_PORT_PICK_FIELD(prs,i)]),
        .dmemresp_val  (dcache_net_resp_out_val[`VC_PORT_PICK_FIELD(1,  i)]),
        .dmemresp_rdy  (dcache_net_resp_out_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

        .from_mngr_msg (proc0_from_mngr_msg),
        .from_mngr_val (proc0_from_mngr_val),
        .from_mngr_rdy (proc0_from_mngr_rdy),

        .to_mngr_msg   (proc0_to_mngr_msg),
        .to_mngr_val   (proc0_to_mngr_val),
        .to_mngr_rdy   (proc0_to_mngr_rdy),

        .stats_en      (stats_en)
      );
    end else begin: PROC
      // rest of the processors don't use the manager interface

      plab2_proc_PipelinedProcBypass
      #(
        .p_num_cores  (p_num_cores),
        .p_core_id    (i)
      )
      proc
      (
        .clk           (clk),
        .reset         (reset),

        .imemreq_msg   (icache_req_msg),
        .imemreq_val   (icache_req_val),
        .imemreq_rdy   (icache_req_rdy),

        .imemresp_msg  (icache_resp_msg),
        .imemresp_val  (icache_resp_val),
        .imemresp_rdy  (icache_resp_rdy),

        .dmemreq_msg   (dcache_net_req_in_msg[`VC_PORT_PICK_FIELD(prq,i)]),
        .dmemreq_val   (dcache_net_req_in_val[`VC_PORT_PICK_FIELD(1,  i)]),
        .dmemreq_rdy   (dcache_net_req_in_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

        .dmemresp_msg  (dcache_net_resp_out_msg[`VC_PORT_PICK_FIELD(prs,i)]),
        .dmemresp_val  (dcache_net_resp_out_val[`VC_PORT_PICK_FIELD(1,  i)]),
        .dmemresp_rdy  (dcache_net_resp_out_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

        .from_mngr_msg (0),
        .from_mngr_val (1'b0),

        .to_mngr_rdy   (1'b0)

      );
    end

    // instruction cache

    plab3_mem_BlockingCacheAlt
    #(
      .p_mem_nbytes         (p_icache_nbytes),
      .p_num_banks          (1),
      .p_opaque_nbits       (o)
    )
    icache
    (
      .clk           (clk),
      .reset         (reset),

      .cachereq_msg  (icache_req_msg),
      .cachereq_val  (icache_req_val),
      .cachereq_rdy  (icache_req_rdy),

      .cacheresp_msg (icache_resp_msg),
      .cacheresp_val (icache_resp_val),
      .cacheresp_rdy (icache_resp_rdy),

      .memreq_msg    (icache_refill_net_req_in_msg[`VC_PORT_PICK_FIELD(mrq,i)]),
      .memreq_val    (icache_refill_net_req_in_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .memreq_rdy    (icache_refill_net_req_in_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

      .memresp_msg   (icache_refill_net_resp_out_msg[`VC_PORT_PICK_FIELD(mrs,i)]),
      .memresp_val   (icache_refill_net_resp_out_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .memresp_rdy   (icache_refill_net_resp_out_rdy[`VC_PORT_PICK_FIELD(1,  i)])

    );

    // data cache

    plab3_mem_BlockingCacheAlt
    #(
      .p_mem_nbytes         (p_dcache_nbytes),
      .p_num_banks          (p_num_cores),
      .p_opaque_nbits       (o)
    )
    dcache
    (
      .clk           (clk),
      .reset         (reset),

      .cachereq_msg  (dcache_net_req_out_msg[`VC_PORT_PICK_FIELD(prq,i)]),
      .cachereq_val  (dcache_net_req_out_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .cachereq_rdy  (dcache_net_req_out_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

      .cacheresp_msg (dcache_net_resp_in_msg[`VC_PORT_PICK_FIELD(prs,i)]),
      .cacheresp_val (dcache_net_resp_in_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .cacheresp_rdy (dcache_net_resp_in_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

      .memreq_msg    (dcache_refill_net_req_in_msg[`VC_PORT_PICK_FIELD(mrq,i)]),
      .memreq_val    (dcache_refill_net_req_in_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .memreq_rdy    (dcache_refill_net_req_in_rdy[`VC_PORT_PICK_FIELD(1,  i)]),

      .memresp_msg   (dcache_refill_net_resp_out_msg[`VC_PORT_PICK_FIELD(mrs,i)]),
      .memresp_val   (dcache_refill_net_resp_out_val[`VC_PORT_PICK_FIELD(1,  i)]),
      .memresp_rdy   (dcache_refill_net_resp_out_rdy[`VC_PORT_PICK_FIELD(1,  i)])

    );

  end
  endgenerate

  // dcache net

  plab5_mcore_MemNet
  #(
    .p_mem_opaque_nbits   (o),
    .p_mem_addr_nbits     (a),
    .p_mem_data_nbits     (d),

    .p_num_ports          (p_num_cores),

    .p_single_bank        (0)
  )
  dcache_net
  (
    .clk          (clk),
    .reset        (reset),

    .req_in_msg   (dcache_net_req_in_msg),
    .req_in_val   (dcache_net_req_in_val),
    .req_in_rdy   (dcache_net_req_in_rdy),

    .req_out_msg  (dcache_net_req_out_msg),
    .req_out_val  (dcache_net_req_out_val),
    .req_out_rdy  (dcache_net_req_out_rdy),

    .resp_in_msg  (dcache_net_resp_in_msg),
    .resp_in_val  (dcache_net_resp_in_val),
    .resp_in_rdy  (dcache_net_resp_in_rdy),

    .resp_out_msg (dcache_net_resp_out_msg),
    .resp_out_val (dcache_net_resp_out_val),
    .resp_out_rdy (dcache_net_resp_out_rdy)
  );

  // icache refill net

  plab5_mcore_MemNet
  #(
    .p_mem_opaque_nbits   (o),
    .p_mem_addr_nbits     (a),
    .p_mem_data_nbits     (rd),

    .p_num_ports          (p_num_cores),

    .p_single_bank        (1)
  )
  icache_refill_net
  (
    .clk          (clk),
    .reset        (reset),

    .req_in_msg   (icache_refill_net_req_in_msg),
    .req_in_val   (icache_refill_net_req_in_val),
    .req_in_rdy   (icache_refill_net_req_in_rdy),

    .req_out_msg  (icache_refill_net_req_out_msg),
    .req_out_val  (icache_refill_net_req_out_val),
    .req_out_rdy  (icache_refill_net_req_out_rdy),

    .resp_in_msg  (icache_refill_net_resp_in_msg),
    .resp_in_val  (icache_refill_net_resp_in_val),
    .resp_in_rdy  (icache_refill_net_resp_in_rdy),

    .resp_out_msg (icache_refill_net_resp_out_msg),
    .resp_out_val (icache_refill_net_resp_out_val),
    .resp_out_rdy (icache_refill_net_resp_out_rdy)
  );

  // dcache refill net

  plab5_mcore_MemNet
  #(
    .p_mem_opaque_nbits   (o),
    .p_mem_addr_nbits     (a),
    .p_mem_data_nbits     (rd),

    .p_num_ports          (p_num_cores),

    .p_single_bank        (1)
  )
  dcache_refill_net
  (
    .clk          (clk),
    .reset        (reset),

    .req_in_msg   (dcache_refill_net_req_in_msg),
    .req_in_val   (dcache_refill_net_req_in_val),
    .req_in_rdy   (dcache_refill_net_req_in_rdy),

    .req_out_msg  (dcache_refill_net_req_out_msg),
    .req_out_val  (dcache_refill_net_req_out_val),
    .req_out_rdy  (dcache_refill_net_req_out_rdy),

    .resp_in_msg  (dcache_refill_net_resp_in_msg),
    .resp_in_val  (dcache_refill_net_resp_in_val),
    .resp_in_rdy  (dcache_refill_net_resp_in_rdy),

    .resp_out_msg (dcache_refill_net_resp_out_msg),
    .resp_out_val (dcache_refill_net_resp_out_val),
    .resp_out_rdy (dcache_refill_net_resp_out_rdy)
  );


  // assign the global memory ports to refill ports

  assign memreq0_msg = icache_refill_net_req_out_msg[`VC_PORT_PICK_FIELD(mrq,0)];
  assign memreq0_val = icache_refill_net_req_out_val[`VC_PORT_PICK_FIELD(1  ,0)];
  assign icache_refill_net_req_out_rdy[`VC_PORT_PICK_FIELD(1  ,0)] = memreq0_rdy;

  assign icache_refill_net_resp_in_msg[`VC_PORT_PICK_FIELD(mrs,0)] = memresp0_msg;
  assign icache_refill_net_resp_in_val[`VC_PORT_PICK_FIELD(1  ,0)] = memresp0_val;
  assign memresp0_rdy = icache_refill_net_resp_in_rdy[`VC_PORT_PICK_FIELD(1  ,0)];

  assign memreq1_msg = dcache_refill_net_req_out_msg[`VC_PORT_PICK_FIELD(mrq,0)];
  assign memreq1_val = dcache_refill_net_req_out_val[`VC_PORT_PICK_FIELD(1  ,0)];
  assign dcache_refill_net_req_out_rdy[`VC_PORT_PICK_FIELD(1  ,0)] = memreq1_rdy;

  assign dcache_refill_net_resp_in_msg[`VC_PORT_PICK_FIELD(mrs,0)] = memresp1_msg;
  assign dcache_refill_net_resp_in_val[`VC_PORT_PICK_FIELD(1  ,0)] = memresp1_val;
  assign memresp1_rdy = dcache_refill_net_resp_in_rdy[`VC_PORT_PICK_FIELD(1  ,0)];

  `include "vc-trace-tasks.v"

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin
    CORES_CACHES[0].PROC.proc.trace_module( trace );
    vc_trace_str( trace, "|" );
    CORES_CACHES[0].icache.trace_module( trace );
    CORES_CACHES[0].dcache.trace_module( trace );

    vc_trace_str( trace, "|" );
    CORES_CACHES[1].PROC.proc.trace_module( trace );
    vc_trace_str( trace, "|" );
    CORES_CACHES[1].icache.trace_module( trace );
    CORES_CACHES[1].dcache.trace_module( trace );

    vc_trace_str( trace, "|" );
    CORES_CACHES[2].PROC.proc.trace_module( trace );
    vc_trace_str( trace, "|" );
    CORES_CACHES[2].icache.trace_module( trace );
    CORES_CACHES[2].dcache.trace_module( trace );

    vc_trace_str( trace, "|" );
    CORES_CACHES[3].PROC.proc.trace_module( trace );
    vc_trace_str( trace, "|" );
    CORES_CACHES[3].icache.trace_module( trace );
    CORES_CACHES[3].dcache.trace_module( trace );

    icache_refill_net.req_net.trace_module( trace );
    vc_trace_str( trace, "|" );
    icache_refill_net.resp_net.trace_module( trace );
  end
  endtask

  //+++ gen-harness : end cut ++++++++++++++++++++++++++++++++++++++++++++

  //+++ gen-harness : begin insert +++++++++++++++++++++++++++++++++++++++
// 
//   `include "vc-trace-tasks.v"
// 
//   task trace_module( inout [vc_trace_nbits-1:0] trace );
//   begin
//     // uncomment following for line tracing
// 
//     // proc0.trace_module( trace );
//     // icache0.trace_module( trace );
// 
//     // vc_trace_str( trace, "|" );
// 
//     // proc1.trace_module( trace );
//     // icache1.trace_module( trace );
// 
//     // vc_trace_str( trace, "|" );
// 
//     // proc2.trace_module( trace );
//     // icache2.trace_module( trace );
// 
//     // vc_trace_str( trace, "|" );
// 
//     // proc3.trace_module( trace );
//     // icache3.trace_module( trace );
// 
//     // vc_trace_str( trace, "|" );
// 
//     // dcache0.trace_module( trace );
//     // dcache1.trace_module( trace );
//     // dcache2.trace_module( trace );
//     // dcache3.trace_module( trace );
// 
//   end
//   endtask
// 
  //+++ gen-harness : end insert +++++++++++++++++++++++++++++++++++++++++

endmodule

`endif /* PLAB5_MCORE_PROC_CACHE_NET_ALT_V */
