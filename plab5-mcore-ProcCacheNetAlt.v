//========================================================================
// 1-Core Processor-Cache-Network
//========================================================================

`ifndef PLAB5_MCORE_PROC_CACHE_NET_ALT_V
`define PLAB5_MCORE_PROC_CACHE_NET_ALT_V
`define PLAB4_NET_NUM_PORTS_4

`include "vc-mem-msgs.v"
`include "plab2-proc-PipelinedProcBypass.v"
`include "plab3-mem-BlockingCacheAlt.v"
`include "plab3-mem-BLockingCacheL2.v"
`include "plab5-mcore-MemNet.v"
`include "plab5-mcore-RefillNet.v"

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
  input {L} clk,
  input {L} reset,

  // proc0 manager ports

  input  [31:0] {D0} proc0_from_mngr_msg,
  input         {D0} proc0_from_mngr_val,
  output        {D0} proc0_from_mngr_rdy,

  output [31:0] {D0} proc0_to_mngr_msg,
  output        {D0} proc0_to_mngr_val,
  input         {D0} proc0_to_mngr_rdy,

  output  [c_memreq_nbits-1:0] {Domain cur_sd} memreq0_msg,
  output                       {Domain cur_sd} memreq0_val,
  input                        {Domain cur_sd} memreq0_rdy,

  input  [c_memresp_nbits-1:0] {Domain cur_sd} memresp0_msg,
  input                        {Domain cur_sd} memresp0_val,
  output                       {Domain cur_sd} memresp0_rdy,

  output  [c_memreq_nbits-1:0] {Domain cur_sd} memreq1_msg,
  output                       {Domain cur_sd} memreq1_val,
  input                        {Domain cur_sd} memreq1_rdy,

  input  [c_memresp_nbits-1:0] {Domain cur_sd} memresp1_msg,
  input                        {Domain cur_sd} memresp1_val,
  output                       {Domain cur_sd} memresp1_rdy,

  output                       {D0} stats_en
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

  // current security domain of the system
  reg                          {L} cur_sd;
  
  always @ (posedge clk) begin
      cur_sd <= ~cur_sd;
  end
  
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

  wire [mrq-1:0] {D0} dcache_net_req_in_msg_0;
  wire           {D0} dcache_net_req_in_val_0;
  wire           {D0} dcache_net_req_in_rdy_0;
  
  wire [mrq-1:0] {D0} dcache_net_req_in_msg_1;
  wire           {D0} dcache_net_req_in_val_1;
  wire           {D0} dcache_net_req_in_rdy_1;
  
  wire [mrq-1:0] {D1} dcache_net_req_in_msg_2;
  wire           {D1} dcache_net_req_in_val_2;
  wire           {D1} dcache_net_req_in_rdy_2;
  
  wire [mrq-1:0] {D1} dcache_net_req_in_msg_3;
  wire           {D1} dcache_net_req_in_val_3;
  wire           {D1} dcache_net_req_in_rdy_3;
  
  wire [mrq-1:0] {D0} dcache_net_req_out_msg_0;
  wire           {D0} dcache_net_req_out_val_0;
  wire           {D0} dcache_net_req_out_rdy_0;
  
  wire [mrq-1:0] {D0} dcache_net_req_out_msg_1;
  wire           {D0} dcache_net_req_out_val_1;
  wire           {D0} dcache_net_req_out_rdy_1;
  
  wire [mrq-1:0] {D1} dcache_net_req_out_msg_2;
  wire           {D1} dcache_net_req_out_val_2;
  wire           {D1} dcache_net_req_out_rdy_2;
  
  wire [mrq-1:0] {D1} dcache_net_req_out_msg_3;
  wire           {D1} dcache_net_req_out_val_3;
  wire           {D1} dcache_net_req_out_rdy_3;

  wire [mrs-1:0] {D0} dcache_net_resp_in_msg_0;
  wire           {D0} dcache_net_resp_in_val_0;
  wire           {D0} dcache_net_resp_in_rdy_0;
  
  wire [mrs-1:0] {D0} dcache_net_resp_in_msg_1;
  wire           {D0} dcache_net_resp_in_val_1;
  wire           {D0} dcache_net_resp_in_rdy_1;
  
  wire [mrs-1:0] {D1} dcache_net_resp_in_msg_2;
  wire           {D1} dcache_net_resp_in_val_2;
  wire           {D1} dcache_net_resp_in_rdy_2;
  
  wire [mrs-1:0] {D1} dcache_net_resp_in_msg_3;
  wire           {D1} dcache_net_resp_in_val_3;
  wire           {D1} dcache_net_resp_in_rdy_3;
  
  wire [mrs-1:0] {D0} dcache_net_resp_out_msg_0;
  wire           {D0} dcache_net_resp_out_val_0;
  wire           {D0} dcache_net_resp_out_rdy_0;
  
  wire [mrs-1:0] {D0} dcache_net_resp_out_msg_1;
  wire           {D0} dcache_net_resp_out_val_1;
  wire           {D0} dcache_net_resp_out_rdy_1;
  
  wire [mrs-1:0] {D1} dcache_net_resp_out_msg_2;
  wire           {D1} dcache_net_resp_out_val_2;
  wire           {D1} dcache_net_resp_out_rdy_2;
  
  wire [mrs-1:0] {D1} dcache_net_resp_out_msg_3;
  wire           {D1} dcache_net_resp_out_val_3;
  wire           {D1} dcache_net_resp_out_rdy_3;
  
  wire [mrq-1:0] {D0} dcache_refill_net_req_in_msg_0;
  wire           {D0} dcache_refill_net_req_in_val_0;
  wire           {D0} dcache_refill_net_req_in_rdy_0;
  
  wire [mrq-1:0] {D0} dcache_refill_net_req_in_msg_1;
  wire           {D0} dcache_refill_net_req_in_val_1;
  wire           {D0} dcache_refill_net_req_in_rdy_1;
  
  wire [mrq-1:0] {D1} dcache_refill_net_req_in_msg_2;
  wire           {D1} dcache_refill_net_req_in_val_2;
  wire           {D1} dcache_refill_net_req_in_rdy_2;
  
  wire [mrq-1:0] {D1} dcache_refill_net_req_in_msg_3;
  wire           {D1} dcache_refill_net_req_in_val_3;
  wire           {D1} dcache_refill_net_req_in_rdy_3;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_refill_net_req_out_msg_0;
  wire           {Domain cur_sd} dcache_refill_net_req_out_val_0;
  wire           {Domain cur_sd} dcache_refill_net_req_out_rdy_0;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_refill_net_req_out_msg_1;
  wire           {Domain cur_sd} dcache_refill_net_req_out_val_1;
  wire           {Domain cur_sd} dcache_refill_net_req_out_rdy_1;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_refill_net_req_out_msg_2;
  wire           {Domain cur_sd} dcache_refill_net_req_out_val_2;
  wire           {Domain cur_sd} dcache_refill_net_req_out_rdy_2;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_refill_net_req_out_msg_3;
  wire           {Domain cur_sd} dcache_refill_net_req_out_val_3;
  wire           {Domain cur_sd} dcache_refill_net_req_out_rdy_3;

  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_in_msg_0;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_val_0;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_rdy_0;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_in_msg_1;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_val_1;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_rdy_1;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_in_msg_2;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_val_2;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_rdy_2;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_in_msg_3;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_val_3;
  wire           {Domain cur_sd} dcache_refill_net_resp_in_rdy_3;
  
  wire [mrs-1:0] {D0} dcache_refill_net_resp_out_msg_0;
  wire           {D0} dcache_refill_net_resp_out_val_0;
  wire           {D0} dcache_refill_net_resp_out_rdy_0;
  
  wire [mrs-1:0] {D0} dcache_refill_net_resp_out_msg_1;
  wire           {D0} dcache_refill_net_resp_out_val_1;
  wire           {D0} dcache_refill_net_resp_out_rdy_1;
  
  wire [mrs-1:0] {D1} dcache_refill_net_resp_out_msg_2;
  wire           {D1} dcache_refill_net_resp_out_val_2;
  wire           {D1} dcache_refill_net_resp_out_rdy_2;
  
  wire [mrs-1:0] {D1} dcache_refill_net_resp_out_msg_3;
  wire           {D1} dcache_refill_net_resp_out_val_3;
  wire           {D1} dcache_refill_net_resp_out_rdy_3;

  wire [mrq-1:0] {D0} icache_refill_net_req_in_msg_0;
  wire           {D0} icache_refill_net_req_in_val_0;
  wire           {D0} icache_refill_net_req_in_rdy_0;
  
  wire [mrq-1:0] {D0} icache_refill_net_req_in_msg_1;
  wire           {D0} icache_refill_net_req_in_val_1;
  wire           {D0} icache_refill_net_req_in_rdy_1;
  
  wire [mrq-1:0] {D1} icache_refill_net_req_in_msg_2;
  wire           {D1} icache_refill_net_req_in_val_2;
  wire           {D1} icache_refill_net_req_in_rdy_2;
  
  wire [mrq-1:0] {D1} icache_refill_net_req_in_msg_3;
  wire           {D1} icache_refill_net_req_in_val_3;
  wire           {D1} icache_refill_net_req_in_rdy_3;
  
  wire [mrq-1:0] {Domain cur_sd} icache_refill_net_req_out_msg_0;
  wire           {Domain cur_sd} icache_refill_net_req_out_val_0;
  wire           {Domain cur_sd} icache_refill_net_req_out_rdy_0;
  
  wire [mrq-1:0] {Domain cur_sd} icache_refill_net_req_out_msg_1;
  wire           {Domain cur_sd} icache_refill_net_req_out_val_1;
  wire           {Domain cur_sd} icache_refill_net_req_out_rdy_1;
  
  wire [mrq-1:0] {Domain cur_sd} icache_refill_net_req_out_msg_2;
  wire           {Domain cur_sd} icache_refill_net_req_out_val_2;
  wire           {Domain cur_sd} icache_refill_net_req_out_rdy_2;
  
  wire [mrq-1:0] {Domain cur_sd} icache_refill_net_req_out_msg_3;
  wire           {Domain cur_sd} icache_refill_net_req_out_val_3;
  wire           {Domain cur_sd} icache_refill_net_req_out_rdy_3;

  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_in_msg_0;
  wire           {Domain cur_sd} icache_refill_net_resp_in_val_0;
  wire           {Domain cur_sd} icache_refill_net_resp_in_rdy_0;
  
  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_in_msg_1;
  wire           {Domain cur_sd} icache_refill_net_resp_in_val_1;
  wire           {Domain cur_sd} icache_refill_net_resp_in_rdy_1;
  
  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_in_msg_2;
  wire           {Domain cur_sd} icache_refill_net_resp_in_val_2;
  wire           {Domain cur_sd} icache_refill_net_resp_in_rdy_2;
  
  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_in_msg_3;
  wire           {Domain cur_sd} icache_refill_net_resp_in_val_3;
  wire           {Domain cur_sd} icache_refill_net_resp_in_rdy_3;
  
  wire [mrs-1:0] {D0} icache_refill_net_resp_out_msg_0;
  wire           {D0} icache_refill_net_resp_out_val_0;
  wire           {D0} icache_refill_net_resp_out_rdy_0;
  
  wire [mrs-1:0] {D0} icache_refill_net_resp_out_msg_1;
  wire           {D0} icache_refill_net_resp_out_val_1;
  wire           {D0} icache_refill_net_resp_out_rdy_1;
  
  wire [mrs-1:0] {D1} icache_refill_net_resp_out_msg_2;
  wire           {D1} icache_refill_net_resp_out_val_2;
  wire           {D1} icache_refill_net_resp_out_rdy_2;
  
  wire [mrs-1:0] {D1} icache_refill_net_resp_out_msg_3;
  wire           {D1} icache_refill_net_resp_out_val_3;
  wire           {D1} icache_refill_net_resp_out_rdy_3;

  // define proc0 name

  `define PLAB5_MCORE_PROC0 CORES_CACHES[0].PROC.proc

  // =========================  Processor 0 =========================================
  
  wire [prq-1:0] {D0} icache_req_msg_0;
  wire           {D0} icache_req_val_0;
  wire           {D0} icache_req_rdy_0;

  wire [prs-1:0] {D0} icache_resp_msg_0;
  wire           {D0} icache_resp_val_0;
  wire           {D0} icache_resp_rdy_0;
  
  wire [prq-1:0] {D0} dcache_req_msg_0;
  wire           {D0} dcache_req_val_0;
  wire           {D0} dcache_req_rdy_0;

  wire [prs-1:0] {D0} dcache_resp_msg_0;
  wire           {D0} dcache_resp_val_0;
  wire           {D0} dcache_resp_rdy_0;
  
  plab2_proc_PipelinedProcBypass
  #(
    .p_num_cores  (p_num_cores),
    .p_core_id    (0)
  )
  proc_0
  (
    .clk           (clk),
    .reset         (reset),

    .imemreq_msg   (icache_req_msg_0),
    .imemreq_val   (icache_req_val_0),
    .imemreq_rdy   (icache_req_rdy_0),

    .imemresp_msg  (icache_resp_msg_0),
    .imemresp_val  (icache_resp_val_0),
    .imemresp_rdy  (icache_resp_rdy_0),

    .dmemreq_msg   (dcache_req_msg_0),
    .dmemreq_val   (dcache_req_val_0),
    .dmemreq_rdy   (dcache_req_rdy_0),
                   
    .dmemresp_msg  (dcache_resp_msg_0),
    .dmemresp_val  (dcache_resp_val_0),
    .dmemresp_rdy  (dcache_resp_rdy_0),

    .from_mngr_msg (proc0_from_mngr_msg),
    .from_mngr_val (proc0_from_mngr_val),
    .from_mngr_rdy (proc0_from_mngr_rdy),

    .to_mngr_msg   (proc0_to_mngr_msg),
    .to_mngr_val   (proc0_to_mngr_val),
    .to_mngr_rdy   (proc0_to_mngr_rdy),

    .stats_en      (stats_en),
    .sd            (0)
  );
  
  // instruction cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_icache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  icache_0
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (icache_req_msg_0),
    .cachereq_val  (icache_req_val_0),
    .cachereq_rdy  (icache_req_rdy_0),

    .cacheresp_msg (icache_resp_msg_0),
    .cacheresp_val (icache_resp_val_0),
    .cacheresp_rdy (icache_resp_rdy_0),

    .memreq_msg    (icache_refill_net_req_in_msg_0),
    .memreq_val    (icache_refill_net_req_in_val_0),
    .memreq_rdy    (icache_refill_net_req_in_rdy_0),

    .memresp_msg   (icache_refill_net_resp_out_msg_0),
    .memresp_val   (icache_refill_net_resp_out_val_0),
    .memresp_rdy   (icache_refill_net_resp_out_rdy_0),
    .sd            (0)
  );

  // $L1 data cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  l1_dcache_0
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_req_msg_0),
    .cachereq_val  (dcache_req_val_0),
    .cachereq_rdy  (dcache_req_rdy_0),

    .cacheresp_msg (dcache_resp_msg_0),
    .cacheresp_val (dcache_resp_val_0),
    .cacheresp_rdy (dcache_resp_rdy_0),

    .memreq_msg    (dcache_net_req_in_msg_0),
    .memreq_val    (dcache_net_req_in_val_0),
    .memreq_rdy    (dcache_net_req_in_rdy_0),

    .memresp_msg   (dcache_net_resp_out_msg_0),
    .memresp_val   (dcache_net_resp_out_val_0),
    .memresp_rdy   (dcache_net_resp_out_rdy_0),
    .sd            (0)

  );

  // $L2 data cache
  plab3_mem_BlockingCacheL2
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (p_num_cores),
    .p_opaque_nbits       (o)
  )
  l2_dcache_0
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_net_req_out_msg_0),
    .cachereq_val  (dcache_net_req_out_val_0),
    .cachereq_rdy  (dcache_net_req_out_rdy_0),

    .cacheresp_msg (dcache_net_resp_in_msg_0),
    .cacheresp_val (dcache_net_resp_in_val_0),
    .cacheresp_rdy (dcache_net_resp_in_rdy_0),

    .memreq_msg    (dcache_refill_net_req_in_msg_0),
    .memreq_val    (dcache_refill_net_req_in_val_0),
    .memreq_rdy    (dcache_refill_net_req_in_rdy_0),

    .memresp_msg   (dcache_refill_net_resp_out_msg_0),
    .memresp_val   (dcache_refill_net_resp_out_val_0),
    .memresp_rdy   (dcache_refill_net_resp_out_rdy_0),
    .sd            (0)

  );

  // =========================  Processor 1 =========================================

  wire [prq-1:0] {D0} icache_req_msg_1;
  wire           {D0} icache_req_val_1;
  wire           {D0} icache_req_rdy_1;

  wire [prs-1:0] {D0} icache_resp_msg_1;
  wire           {D0} icache_resp_val_1;
  wire           {D0} icache_resp_rdy_1;

  wire [prq-1:0] {D0} dcache_req_msg_1;
  wire           {D0} dcache_req_val_1;
  wire           {D0} dcache_req_rdy_1;

  wire [prs-1:0] {D0} dcache_resp_msg_1;
  wire           {D0} dcache_resp_val_1;
  wire           {D0} dcache_resp_rdy_1;

  plab2_proc_PipelinedProcBypass
  #(
    .p_num_cores  (p_num_cores),
    .p_core_id    (1)
  )
  proc_1
  (
    .clk           (clk),
    .reset         (reset),

    .imemreq_msg   (icache_req_msg_1),
    .imemreq_val   (icache_req_val_1),
    .imemreq_rdy   (icache_req_rdy_1),

    .imemresp_msg  (icache_resp_msg_1),
    .imemresp_val  (icache_resp_val_1),
    .imemresp_rdy  (icache_resp_rdy_1),

    .dmemreq_msg   (dcache_req_msg_1),
    .dmemreq_val   (dcache_req_val_1),
    .dmemreq_rdy   (dcache_req_rdy_1),

    .dmemresp_msg  (dcache_resp_msg_1),
    .dmemresp_val  (dcache_resp_val_1),
    .dmemresp_rdy  (dcache_resp_rdy_1),

    .from_mngr_msg (0),
    .from_mngr_val (1'b0),

    .to_mngr_rdy   (1'b0),
    .sd            (0)
  );

  // instruction cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_icache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  icache_1
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (icache_req_msg_1),
    .cachereq_val  (icache_req_val_1),
    .cachereq_rdy  (icache_req_rdy_1),

    .cacheresp_msg (icache_resp_msg_1),
    .cacheresp_val (icache_resp_val_1),
    .cacheresp_rdy (icache_resp_rdy_1),

    .memreq_msg    (icache_refill_net_req_in_msg_1),
    .memreq_val    (icache_refill_net_req_in_val_1),
    .memreq_rdy    (icache_refill_net_req_in_rdy_1),

    .memresp_msg   (icache_refill_net_resp_out_msg_1),
    .memresp_val   (icache_refill_net_resp_out_val_1),
    .memresp_rdy   (icache_refill_net_resp_out_rdy_1),
    .sd            (0)
  );

  // $L1 data cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  l1_dcache_1
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_req_msg_1),
    .cachereq_val  (dcache_req_val_1),
    .cachereq_rdy  (dcache_req_rdy_1),

    .cacheresp_msg (dcache_resp_msg_1),
    .cacheresp_val (dcache_resp_val_1),
    .cacheresp_rdy (dcache_resp_rdy_1),

    .memreq_msg    (dcache_net_req_in_msg_1),
    .memreq_val    (dcache_net_req_in_val_1),
    .memreq_rdy    (dcache_net_req_in_rdy_1),

    .memresp_msg   (dcache_net_resp_out_msg_1),
    .memresp_val   (dcache_net_resp_out_val_1),
    .memresp_rdy   (dcache_net_resp_out_rdy_1),
    .sd            (0)

  );

  // $L2 data cache
  plab3_mem_BlockingCacheL2
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (p_num_cores),
    .p_opaque_nbits       (o)
  )
  l2_dcache_1
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_net_req_out_msg_1),
    .cachereq_val  (dcache_net_req_out_val_1),
    .cachereq_rdy  (dcache_net_req_out_rdy_1),

    .cacheresp_msg (dcache_net_resp_in_msg_1),
    .cacheresp_val (dcache_net_resp_in_val_1),
    .cacheresp_rdy (dcache_net_resp_in_rdy_1),

    .memreq_msg    (dcache_refill_net_req_in_msg_1),
    .memreq_val    (dcache_refill_net_req_in_val_1),
    .memreq_rdy    (dcache_refill_net_req_in_rdy_1),

    .memresp_msg   (dcache_refill_net_resp_out_msg_1),
    .memresp_val   (dcache_refill_net_resp_out_val_1),
    .memresp_rdy   (dcache_refill_net_resp_out_rdy_1),
    .sd            (0)

  );

  // =========================  Processor 2 =========================================

  wire [prq-1:0] {D1} icache_req_msg_2;
  wire           {D1} icache_req_val_2;
  wire           {D1} icache_req_rdy_2;

  wire [prs-1:0] {D1} icache_resp_msg_2;
  wire           {D1} icache_resp_val_2;
  wire           {D1} icache_resp_rdy_2;

  wire [prq-1:0] {D1} dcache_req_msg_2;
  wire           {D1} dcache_req_val_2;
  wire           {D1} dcache_req_rdy_2;

  wire [prs-1:0] {D1} dcache_resp_msg_2;
  wire           {D1} dcache_resp_val_2;
  wire           {D1} dcache_resp_rdy_2;

  plab2_proc_PipelinedProcBypass
  #(
    .p_num_cores  (p_num_cores),
    .p_core_id    (2)
  )
  proc_2
  (
    .clk           (clk),
    .reset         (reset),

    .imemreq_msg   (icache_req_msg_2),
    .imemreq_val   (icache_req_val_2),
    .imemreq_rdy   (icache_req_rdy_2),

    .imemresp_msg  (icache_resp_msg_2),
    .imemresp_val  (icache_resp_val_2),
    .imemresp_rdy  (icache_resp_rdy_2),

    .dmemreq_msg   (dcache_req_msg_2),
    .dmemreq_val   (dcache_req_val_2),
    .dmemreq_rdy   (dcache_req_rdy_2),

    .dmemresp_msg  (dcache_resp_msg_2),
    .dmemresp_val  (dcache_resp_val_2),
    .dmemresp_rdy  (dcache_resp_rdy_2),

    .from_mngr_msg (0),
    .from_mngr_val (1'b0),

    .to_mngr_rdy   (1'b0),
    .sd            (1)
  );

  // instruction cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_icache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  icache_2
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (icache_req_msg_2),
    .cachereq_val  (icache_req_val_2),
    .cachereq_rdy  (icache_req_rdy_2),

    .cacheresp_msg (icache_resp_msg_2),
    .cacheresp_val (icache_resp_val_2),
    .cacheresp_rdy (icache_resp_rdy_2),

    .memreq_msg    (icache_refill_net_req_in_msg_2),
    .memreq_val    (icache_refill_net_req_in_val_2),
    .memreq_rdy    (icache_refill_net_req_in_rdy_2),

    .memresp_msg   (icache_refill_net_resp_out_msg_2),
    .memresp_val   (icache_refill_net_resp_out_val_2),
    .memresp_rdy   (icache_refill_net_resp_out_rdy_2),
    .sd            (1)
  );

  // $L1 data cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  l1_dcache_2
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_req_msg_2),
    .cachereq_val  (dcache_req_val_2),
    .cachereq_rdy  (dcache_req_rdy_2),

    .cacheresp_msg (dcache_resp_msg_2),
    .cacheresp_val (dcache_resp_val_2),
    .cacheresp_rdy (dcache_resp_rdy_2),

    .memreq_msg    (dcache_net_req_in_msg_2),
    .memreq_val    (dcache_net_req_in_val_2),
    .memreq_rdy    (dcache_net_req_in_rdy_2),

    .memresp_msg   (dcache_net_resp_out_msg_2),
    .memresp_val   (dcache_net_resp_out_val_2),
    .memresp_rdy   (dcache_net_resp_out_rdy_2),
    .sd            (1)

  );

  // $L2 data cache
  plab3_mem_BlockingCacheL2
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (p_num_cores),
    .p_opaque_nbits       (o)
  )
  l2_dcache_2
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_net_req_out_msg_2),
    .cachereq_val  (dcache_net_req_out_val_2),
    .cachereq_rdy  (dcache_net_req_out_rdy_2),

    .cacheresp_msg (dcache_net_resp_in_msg_2),
    .cacheresp_val (dcache_net_resp_in_val_2),
    .cacheresp_rdy (dcache_net_resp_in_rdy_2),

    .memreq_msg    (dcache_refill_net_req_in_msg_2),
    .memreq_val    (dcache_refill_net_req_in_val_2),
    .memreq_rdy    (dcache_refill_net_req_in_rdy_2),

    .memresp_msg   (dcache_refill_net_resp_out_msg_2),
    .memresp_val   (dcache_refill_net_resp_out_val_2),
    .memresp_rdy   (dcache_refill_net_resp_out_rdy_2),
    .sd            (1)

  );

  // =========================  Processor 3 =========================================

  wire [prq-1:0] {D1} icache_req_msg_3;
  wire           {D1} icache_req_val_3;
  wire           {D1} icache_req_rdy_3;

  wire [prs-1:0] {D1} icache_resp_msg_3;
  wire           {D1} icache_resp_val_3;
  wire           {D1} icache_resp_rdy_3;

  wire [prq-1:0] {D1} dcache_req_msg_3;
  wire           {D1} dcache_req_val_3;
  wire           {D1} dcache_req_rdy_3;

  wire [prs-1:0] {D1} dcache_resp_msg_3;
  wire           {D1} dcache_resp_val_3;
  wire           {D1} dcache_resp_rdy_3;

  plab2_proc_PipelinedProcBypass
  #(
    .p_num_cores  (p_num_cores),
    .p_core_id    (3)
  )
  proc_3
  (
    .clk           (clk),
    .reset         (reset),

    .imemreq_msg   (icache_req_msg_3),
    .imemreq_val   (icache_req_val_3),
    .imemreq_rdy   (icache_req_rdy_3),

    .imemresp_msg  (icache_resp_msg_3),
    .imemresp_val  (icache_resp_val_3),
    .imemresp_rdy  (icache_resp_rdy_3),

    .dmemreq_msg   (dcache_req_msg_3),
    .dmemreq_val   (dcache_req_val_3),
    .dmemreq_rdy   (dcache_req_rdy_3),

    .dmemresp_msg  (dcache_resp_msg_3),
    .dmemresp_val  (dcache_resp_val_3),
    .dmemresp_rdy  (dcache_resp_rdy_3),

    .from_mngr_msg (0),
    .from_mngr_val (1'b0),

    .to_mngr_rdy   (1'b0),
    .sd            (1)
  );

  // instruction cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_icache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  icache_3
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (icache_req_msg_3),
    .cachereq_val  (icache_req_val_3),
    .cachereq_rdy  (icache_req_rdy_3),

    .cacheresp_msg (icache_resp_msg_3),
    .cacheresp_val (icache_resp_val_3),
    .cacheresp_rdy (icache_resp_rdy_3),

    .memreq_msg    (icache_refill_net_req_in_msg_3),
    .memreq_val    (icache_refill_net_req_in_val_3),
    .memreq_rdy    (icache_refill_net_req_in_rdy_3),

    .memresp_msg   (icache_refill_net_resp_out_msg_3),
    .memresp_val   (icache_refill_net_resp_out_val_3),
    .memresp_rdy   (icache_refill_net_resp_out_rdy_3),
    .sd            (1)
  );

  // $L1 data cache

  plab3_mem_BlockingCacheAlt
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (1),
    .p_opaque_nbits       (o)
  )
  l1_dcache_3
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_req_msg_3),
    .cachereq_val  (dcache_req_val_3),
    .cachereq_rdy  (dcache_req_rdy_3),

    .cacheresp_msg (dcache_resp_msg_3),
    .cacheresp_val (dcache_resp_val_3),
    .cacheresp_rdy (dcache_resp_rdy_3),

    .memreq_msg    (dcache_net_req_in_msg_3),
    .memreq_val    (dcache_net_req_in_val_3),
    .memreq_rdy    (dcache_net_req_in_rdy_3),

    .memresp_msg   (dcache_net_resp_out_msg_3),
    .memresp_val   (dcache_net_resp_out_val_3),
    .memresp_rdy   (dcache_net_resp_out_rdy_3),
    .sd            (1)

  );

  // $L2 data cache
  plab3_mem_BlockingCacheL2
  #(
    .p_mem_nbytes         (p_dcache_nbytes),
    .p_num_banks          (p_num_cores),
    .p_opaque_nbits       (o)
  )
  l2_dcache_3
  (
    .clk           (clk),
    .reset         (reset),

    .cachereq_msg  (dcache_net_req_out_msg_3),
    .cachereq_val  (dcache_net_req_out_val_3),
    .cachereq_rdy  (dcache_net_req_out_rdy_3),

    .cacheresp_msg (dcache_net_resp_in_msg_3),
    .cacheresp_val (dcache_net_resp_in_val_3),
    .cacheresp_rdy (dcache_net_resp_in_rdy_3),

    .memreq_msg    (dcache_refill_net_req_in_msg_3),
    .memreq_val    (dcache_refill_net_req_in_val_3),
    .memreq_rdy    (dcache_refill_net_req_in_rdy_3),

    .memresp_msg   (dcache_refill_net_resp_out_msg_3),
    .memresp_val   (dcache_refill_net_resp_out_val_3),
    .memresp_rdy   (dcache_refill_net_resp_out_rdy_3),
    .sd            (1)

  );

  // =============================== On-Chip Networks ==========================
  // dcache net ===============================================================

  wire [mrq-1:0] {Domain cur_sd} dcache_net_req_out_msg_pre_0;
  wire           {Domain cur_sd} dcache_net_req_out_val_pre_0;
  wire           {Domain cur_sd} dcache_net_req_out_rdy_pre_0;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_net_req_out_msg_pre_1;
  wire           {Domain cur_sd} dcache_net_req_out_val_pre_1;
  wire           {Domain cur_sd} dcache_net_req_out_rdy_pre_1;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_net_req_out_msg_pre_2;
  wire           {Domain cur_sd} dcache_net_req_out_val_pre_2;
  wire           {Domain cur_sd} dcache_net_req_out_rdy_pre_2;
  
  wire [mrq-1:0] {Domain cur_sd} dcache_net_req_out_msg_pre_3;
  wire           {Domain cur_sd} dcache_net_req_out_val_pre_3;
  wire           {Domain cur_sd} dcache_net_req_out_rdy_pre_3;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_net_resp_out_msg_pre_0;
  wire           {Domain cur_sd} dcache_net_resp_out_val_pre_0;
  wire           {Domain cur_sd} dcache_net_resp_out_rdy_pre_0;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_net_resp_out_msg_pre_1;
  wire           {Domain cur_sd} dcache_net_resp_out_val_pre_1;
  wire           {Domain cur_sd} dcache_net_resp_out_rdy_pre_1;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_net_resp_out_msg_pre_2;
  wire           {Domain cur_sd} dcache_net_resp_out_val_pre_2;
  wire           {Domain cur_sd} dcache_net_resp_out_rdy_pre_2;
  
  wire [mrs-1:0] {Domain cur_sd} dcache_net_resp_out_msg_pre_3;
  wire           {Domain cur_sd} dcache_net_resp_out_val_pre_3;
  wire           {Domain cur_sd} dcache_net_resp_out_rdy_pre_3;
  
  plab5_mcore_MemNet
  #(
    .p_mem_opaque_nbits   (o),
    .p_mem_addr_nbits     (a),
    .p_mem_data_nbits     (rd),

    .p_num_ports          (p_num_cores),

    .p_single_bank        (0)
  )
  dcache_net
  (
    .clk          (clk),
    .reset        (reset),

    .req_in_msg_0   (dcache_net_req_in_msg_0),
    .req_in_val_0   (dcache_net_req_in_val_0),
    .req_in_rdy_0   (dcache_net_req_in_rdy_0),
    .req_in_sd_0    (0),
    
    .req_in_msg_1   (dcache_net_req_in_msg_1),
    .req_in_val_1   (dcache_net_req_in_val_1),
    .req_in_rdy_1   (dcache_net_req_in_rdy_1),
    .req_in_sd_1    (0),
    
    .req_in_msg_2   (dcache_net_req_in_msg_2),
    .req_in_val_2   (dcache_net_req_in_val_2),
    .req_in_rdy_2   (dcache_net_req_in_rdy_2),
    .req_in_sd_2    (1),
    
    .req_in_msg_3   (dcache_net_req_in_msg_3),
    .req_in_val_3   (dcache_net_req_in_val_3),
    .req_in_rdy_3   (dcache_net_req_in_rdy_3),
    .req_in_sd_3    (1),

    .req_out_msg_0  (dcache_net_req_out_msg_pre_0),
    .req_out_val_0  (dcache_net_req_out_val_pre_0),
    .req_out_rdy_0  (dcache_net_req_out_rdy_pre_0),
    
    .req_out_msg_1  (dcache_net_req_out_msg_pre_1),
    .req_out_val_1  (dcache_net_req_out_val_pre_1),
    .req_out_rdy_1  (dcache_net_req_out_rdy_pre_1),
    
    .req_out_msg_2  (dcache_net_req_out_msg_pre_2),
    .req_out_val_2  (dcache_net_req_out_val_pre_2),
    .req_out_rdy_2  (dcache_net_req_out_rdy_pre_2),
    
    .req_out_msg_3  (dcache_net_req_out_msg_pre_3),
    .req_out_val_3  (dcache_net_req_out_val_pre_3),
    .req_out_rdy_3  (dcache_net_req_out_rdy_pre_3),

    .resp_in_msg_0  (dcache_net_resp_in_msg_0),
    .resp_in_val_0  (dcache_net_resp_in_val_0),
    .resp_in_rdy_0  (dcache_net_resp_in_rdy_0),
    .resp_in_sd_0   (0),
    
    .resp_in_msg_1  (dcache_net_resp_in_msg_1),
    .resp_in_val_1  (dcache_net_resp_in_val_1),
    .resp_in_rdy_1  (dcache_net_resp_in_rdy_1),
    .resp_in_sd_1   (0),
    
    .resp_in_msg_2  (dcache_net_resp_in_msg_2),
    .resp_in_val_2  (dcache_net_resp_in_val_2),
    .resp_in_rdy_2  (dcache_net_resp_in_rdy_2),
    .resp_in_sd_2   (1),
    
    .resp_in_msg_3  (dcache_net_resp_in_msg_3),
    .resp_in_val_3  (dcache_net_resp_in_val_3),
    .resp_in_rdy_3  (dcache_net_resp_in_rdy_3),
    .resp_in_sd_3   (1),

    .resp_out_msg_0 (dcache_net_resp_out_msg_pre_0),
    .resp_out_val_0 (dcache_net_resp_out_val_pre_0),
    .resp_out_rdy_0 (dcache_net_resp_out_rdy_pre_0),
    
    .resp_out_msg_1 (dcache_net_resp_out_msg_pre_1),
    .resp_out_val_1 (dcache_net_resp_out_val_pre_1),
    .resp_out_rdy_1 (dcache_net_resp_out_rdy_pre_1),
    
    .resp_out_msg_2 (dcache_net_resp_out_msg_pre_2),
    .resp_out_val_2 (dcache_net_resp_out_val_pre_2),
    .resp_out_rdy_2 (dcache_net_resp_out_rdy_pre_2),
    
    .resp_out_msg_3 (dcache_net_resp_out_msg_pre_3),
    .resp_out_val_3 (dcache_net_resp_out_val_pre_3),
    .resp_out_rdy_3 (dcache_net_resp_out_rdy_pre_3),
    
    .cur_sd         (cur_sd)
  );
  
  assign dcache_net_req_out_msg_0 = (cur_sd == 0) ? dcache_net_req_out_msg_pre_0 : 0;
  assign dcache_net_req_out_val_0 = (cur_sd == 0) ? dcache_net_req_out_val_pre_0 : 0;
  assign dcache_net_req_out_rdy_pre_0 = (cur_sd == 0) ? dcache_net_req_out_rdy_0 : 0;
  
  assign dcache_net_req_out_msg_1 = (cur_sd == 0) ? dcache_net_req_out_msg_pre_1 : 0;
  assign dcache_net_req_out_val_1 = (cur_sd == 0) ? dcache_net_req_out_val_pre_1 : 0;
  assign dcache_net_req_out_rdy_pre_1 = (cur_sd == 0) ? dcache_net_req_out_rdy_1 : 0;
  
  assign dcache_net_req_out_msg_2 = (cur_sd == 1) ? dcache_net_req_out_msg_pre_2 : 0;
  assign dcache_net_req_out_val_2 = (cur_sd == 1) ? dcache_net_req_out_val_pre_2 : 0;
  assign dcache_net_req_out_rdy_pre_2 = (cur_sd == 1) ? dcache_net_req_out_rdy_2 : 0;
  
  assign dcache_net_req_out_msg_3 = (cur_sd == 1) ? dcache_net_req_out_msg_pre_3 : 0;
  assign dcache_net_req_out_val_3 = (cur_sd == 1) ? dcache_net_req_out_val_pre_3 : 0;
  assign dcache_net_req_out_rdy_pre_3 = (cur_sd == 1) ? dcache_net_req_out_rdy_3 : 0;

  // icache refill net =============================================================
  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_out_msg_pre_0;
  wire           {Domain cur_sd} icache_refill_net_resp_out_val_pre_0;
  wire           {Domain cur_sd} icache_refill_net_resp_out_rdy_pre_0;

  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_out_msg_pre_1;
  wire           {Domain cur_sd} icache_refill_net_resp_out_val_pre_1;
  wire           {Domain cur_sd} icache_refill_net_resp_out_rdy_pre_1;

  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_out_msg_pre_2;
  wire           {Domain cur_sd} icache_refill_net_resp_out_val_pre_2;
  wire           {Domain cur_sd} icache_refill_net_resp_out_rdy_pre_2;

  wire [mrs-1:0] {Domain cur_sd} icache_refill_net_resp_out_msg_pre_3;
  wire           {Domain cur_sd} icache_refill_net_resp_out_val_pre_3;
  wire           {Domain cur_sd} icache_refill_net_resp_out_rdy_pre_3;
  
  plab5_mcore_RefillNet
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

    .req_in_msg_0   (icache_refill_net_req_in_msg_0),
    .req_in_val_0   (icache_refill_net_req_in_val_0),
    .req_in_rdy_0   (icache_refill_net_req_in_rdy_0),
    .req_in_sd_0    (0),
    
    .req_in_msg_1   (icache_refill_net_req_in_msg_1),
    .req_in_val_1   (icache_refill_net_req_in_val_1),
    .req_in_rdy_1   (icache_refill_net_req_in_rdy_1),
    .req_in_sd_1    (0),
    
    .req_in_msg_2   (icache_refill_net_req_in_msg_2),
    .req_in_val_2   (icache_refill_net_req_in_val_2),
    .req_in_rdy_2   (icache_refill_net_req_in_rdy_2),
    .req_in_sd_2    (1),
    
    .req_in_msg_3   (icache_refill_net_req_in_msg_3),
    .req_in_val_3   (icache_refill_net_req_in_val_3),
    .req_in_rdy_3   (icache_refill_net_req_in_rdy_3),
    .req_in_sd_3    (1),

    .req_out_msg_0  (icache_refill_net_req_out_msg_0),
    .req_out_val_0  (icache_refill_net_req_out_val_0),
    .req_out_rdy_0  (icache_refill_net_req_out_rdy_0),
    
    .req_out_msg_1  (icache_refill_net_req_out_msg_1),
    .req_out_val_1  (icache_refill_net_req_out_val_1),
    .req_out_rdy_1  (icache_refill_net_req_out_rdy_1),
    
    .req_out_msg_2  (icache_refill_net_req_out_msg_2),
    .req_out_val_2  (icache_refill_net_req_out_val_2),
    .req_out_rdy_2  (icache_refill_net_req_out_rdy_2),
    
    .req_out_msg_3  (icache_refill_net_req_out_msg_3),
    .req_out_val_3  (icache_refill_net_req_out_val_3),
    .req_out_rdy_3  (icache_refill_net_req_out_rdy_3),

    .resp_in_msg_0  (icache_refill_net_resp_in_msg_0),
    .resp_in_val_0  (icache_refill_net_resp_in_val_0),
    .resp_in_rdy_0  (icache_refill_net_resp_in_rdy_0),
    .resp_in_sd_0   (0),
    
    .resp_in_msg_1  (icache_refill_net_resp_in_msg_1),
    .resp_in_val_1  (icache_refill_net_resp_in_val_1),
    .resp_in_rdy_1  (icache_refill_net_resp_in_rdy_1),
    .resp_in_sd_1   (0),
    
    .resp_in_msg_2  (icache_refill_net_resp_in_msg_2),
    .resp_in_val_2  (icache_refill_net_resp_in_val_2),
    .resp_in_rdy_2  (icache_refill_net_resp_in_rdy_2),
    .resp_in_sd_2   (1),
    
    .resp_in_msg_3  (icache_refill_net_resp_in_msg_3),
    .resp_in_val_3  (icache_refill_net_resp_in_val_3),
    .resp_in_rdy_3  (icache_refill_net_resp_in_rdy_3),
    .resp_in_sd_3   (1),

    .resp_out_msg_0 (icache_refill_net_resp_out_msg_pre_0),
    .resp_out_val_0 (icache_refill_net_resp_out_val_pre_0),
    .resp_out_rdy_0 (icache_refill_net_resp_out_rdy_pre_0),
    
    .resp_out_msg_1 (icache_refill_net_resp_out_msg_pre_1),
    .resp_out_val_1 (icache_refill_net_resp_out_val_pre_1),
    .resp_out_rdy_1 (icache_refill_net_resp_out_rdy_pre_1),
    
    .resp_out_msg_2 (icache_refill_net_resp_out_msg_pre_2),
    .resp_out_val_2 (icache_refill_net_resp_out_val_pre_2),
    .resp_out_rdy_2 (icache_refill_net_resp_out_rdy_pre_2),
    
    .resp_out_msg_3 (icache_refill_net_resp_out_msg_pre_3),
    .resp_out_val_3 (icache_refill_net_resp_out_val_pre_3),
    .resp_out_rdy_3 (icache_refill_net_resp_out_rdy_pre_3),
    
    .cur_sd         (cur_sd)
  );
  
  assign icache_refill_net_resp_out_msg_0 = (cur_sd == 0) ? icache_refill_net_resp_out_msg_pre_0 : 0;
  assign icache_refill_net_resp_out_val_0 = (cur_sd == 0) ? icache_refill_net_resp_out_val_pre_0 : 0;
  assign icache_refill_net_resp_out_rdy_pre_0 = (cur_sd == 0) ? icache_refill_net_resp_out_rdy_0 : 0;

  assign icache_refill_net_resp_out_msg_1 = (cur_sd == 0) ? icache_refill_net_resp_out_msg_pre_1 : 0;
  assign icache_refill_net_resp_out_val_1 = (cur_sd == 0) ? icache_refill_net_resp_out_val_pre_1 : 0;
  assign icache_refill_net_resp_out_rdy_pre_1 = (cur_sd == 0) ? icache_refill_net_resp_out_rdy_1 : 0;

  assign icache_refill_net_resp_out_msg_2 = (cur_sd == 1) ? icache_refill_net_resp_out_msg_pre_2 : 0;
  assign icache_refill_net_resp_out_val_2 = (cur_sd == 1) ? icache_refill_net_resp_out_val_pre_2 : 0;
  assign icache_refill_net_resp_out_rdy_pre_2 = (cur_sd == 1) ? icache_refill_net_resp_out_rdy_2 : 0;

  assign icache_refill_net_resp_out_msg_3 = (cur_sd == 1) ? icache_refill_net_resp_out_msg_pre_3 : 0;
  assign icache_refill_net_resp_out_val_3 = (cur_sd == 1) ? icache_refill_net_resp_out_val_pre_3 : 0;
  assign icache_refill_net_resp_out_rdy_pre_3 = (cur_sd == 1) ? icache_refill_net_resp_out_rdy_3 : 0;

  // dcache refill net =======================================================
  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_out_msg_pre_0;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_val_pre_0;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_rdy_pre_0;

  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_out_msg_pre_1;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_val_pre_1;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_rdy_pre_1;

  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_out_msg_pre_2;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_val_pre_2;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_rdy_pre_2;

  wire [mrs-1:0] {Domain cur_sd} dcache_refill_net_resp_out_msg_pre_3;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_val_pre_3;
  wire           {Domain cur_sd} dcache_refill_net_resp_out_rdy_pre_3;
  
  plab5_mcore_RefillNet
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

    .req_in_msg_0   (dcache_refill_net_req_in_msg_0),
    .req_in_val_0   (dcache_refill_net_req_in_val_0),
    .req_in_rdy_0   (dcache_refill_net_req_in_rdy_0),
    .req_in_sd_0    (0),
    
    .req_in_msg_1   (dcache_refill_net_req_in_msg_1),
    .req_in_val_1   (dcache_refill_net_req_in_val_1),
    .req_in_rdy_1   (dcache_refill_net_req_in_rdy_1),
    .req_in_sd_1    (0),
    
    .req_in_msg_2   (dcache_refill_net_req_in_msg_2),
    .req_in_val_2   (dcache_refill_net_req_in_val_2),
    .req_in_rdy_2   (dcache_refill_net_req_in_rdy_2),
    .req_in_sd_2    (1),
    
    .req_in_msg_3   (dcache_refill_net_req_in_msg_3),
    .req_in_val_3   (dcache_refill_net_req_in_val_3),
    .req_in_rdy_3   (dcache_refill_net_req_in_rdy_3),
    .req_in_sd_3    (1),

    .req_out_msg_0  (dcache_refill_net_req_out_msg_0),
    .req_out_val_0  (dcache_refill_net_req_out_val_0),
    .req_out_rdy_0  (dcache_refill_net_req_out_rdy_0),
    
    .req_out_msg_1  (dcache_refill_net_req_out_msg_1),
    .req_out_val_1  (dcache_refill_net_req_out_val_1),
    .req_out_rdy_1  (dcache_refill_net_req_out_rdy_1),
    
    .req_out_msg_2  (dcache_refill_net_req_out_msg_2),
    .req_out_val_2  (dcache_refill_net_req_out_val_2),
    .req_out_rdy_2  (dcache_refill_net_req_out_rdy_2),
    
    .req_out_msg_3  (dcache_refill_net_req_out_msg_3),
    .req_out_val_3  (dcache_refill_net_req_out_val_3),
    .req_out_rdy_3  (dcache_refill_net_req_out_rdy_3),

    .resp_in_msg_0  (dcache_refill_net_resp_in_msg_0),
    .resp_in_val_0  (dcache_refill_net_resp_in_val_0),
    .resp_in_rdy_0  (dcache_refill_net_resp_in_rdy_0),
    .resp_in_sd_0   (0),
    
    .resp_in_msg_1  (dcache_refill_net_resp_in_msg_1),
    .resp_in_val_1  (dcache_refill_net_resp_in_val_1),
    .resp_in_rdy_1  (dcache_refill_net_resp_in_rdy_1),
    .resp_in_sd_1   (0),
    
    .resp_in_msg_2  (dcache_refill_net_resp_in_msg_2),
    .resp_in_val_2  (dcache_refill_net_resp_in_val_2),
    .resp_in_rdy_2  (dcache_refill_net_resp_in_rdy_2),
    .resp_in_sd_2   (1),
    
    .resp_in_msg_3  (dcache_refill_net_resp_in_msg_3),
    .resp_in_val_3  (dcache_refill_net_resp_in_val_3),
    .resp_in_rdy_3  (dcache_refill_net_resp_in_rdy_3),
    .resp_in_sd_3   (1),

    .resp_out_msg_0 (dcache_refill_net_resp_out_msg_pre_0),
    .resp_out_val_0 (dcache_refill_net_resp_out_val_pre_0),
    .resp_out_rdy_0 (dcache_refill_net_resp_out_rdy_pre_0),
                                               
    .resp_out_msg_1 (dcache_refill_net_resp_out_msg_pre_1),
    .resp_out_val_1 (dcache_refill_net_resp_out_val_pre_1),
    .resp_out_rdy_1 (dcache_refill_net_resp_out_rdy_pre_1),
                                               
    .resp_out_msg_2 (dcache_refill_net_resp_out_msg_pre_2),
    .resp_out_val_2 (dcache_refill_net_resp_out_val_pre_2),
    .resp_out_rdy_2 (dcache_refill_net_resp_out_rdy_pre_2),
                                               
    .resp_out_msg_3 (dcache_refill_net_resp_out_msg_pre_3),
    .resp_out_val_3 (dcache_refill_net_resp_out_val_pre_3),
    .resp_out_rdy_3 (dcache_refill_net_resp_out_rdy_pre_3),
    
    .cur_sd         (cur_sd)
  );
  
  assign dcache_refill_net_resp_out_msg_0 = (cur_sd == 0) ? dcache_refill_net_resp_out_msg_pre_0 : 0;
  assign dcache_refill_net_resp_out_val_0 = (cur_sd == 0) ? dcache_refill_net_resp_out_val_pre_0 : 0;
  assign dcache_refill_net_resp_out_rdy_pre_0 = (cur_sd == 0) ? dcache_refill_net_resp_out_rdy_0 : 0;

  assign dcache_refill_net_resp_out_msg_1 = (cur_sd == 0) ? dcache_refill_net_resp_out_msg_pre_1 : 0;
  assign dcache_refill_net_resp_out_val_1 = (cur_sd == 0) ? dcache_refill_net_resp_out_val_pre_1 : 0;
  assign dcache_refill_net_resp_out_rdy_pre_1 = (cur_sd == 0) ? dcache_refill_net_resp_out_rdy_1 : 0;

  assign dcache_refill_net_resp_out_msg_2 = (cur_sd == 1) ? dcache_refill_net_resp_out_msg_pre_2 : 0;
  assign dcache_refill_net_resp_out_val_2 = (cur_sd == 1) ? dcache_refill_net_resp_out_val_pre_2 : 0;
  assign dcache_refill_net_resp_out_rdy_pre_2 = (cur_sd == 1) ? dcache_refill_net_resp_out_rdy_2 : 0;

  assign dcache_refill_net_resp_out_msg_3 = (cur_sd == 1) ? dcache_refill_net_resp_out_msg_pre_3 : 0;
  assign dcache_refill_net_resp_out_val_3 = (cur_sd == 1) ? dcache_refill_net_resp_out_val_pre_3 : 0;
  assign dcache_refill_net_resp_out_rdy_pre_3 = (cur_sd == 1) ? dcache_refill_net_resp_out_rdy_3 : 0;

  
  // assign the global memory ports to refill ports

  assign memreq0_msg = icache_refill_net_req_out_msg_0;
  assign memreq0_val = icache_refill_net_req_out_val_0;
  assign icache_refill_net_req_out_rdy_0 = memreq0_rdy;

  assign icache_refill_net_resp_in_msg_0 = memresp0_msg;
  assign icache_refill_net_resp_in_val_0 = memresp0_val;
  assign memresp0_rdy = icache_refill_net_resp_in_rdy_0;

  assign memreq1_msg = dcache_refill_net_req_out_msg_0;
  assign memreq1_val = dcache_refill_net_req_out_val_0;
  assign dcache_refill_net_req_out_rdy_0 = memreq1_rdy;

  assign dcache_refill_net_resp_in_msg_0 = memresp1_msg;
  assign dcache_refill_net_resp_in_val_0 = memresp1_val;
  assign memresp1_rdy = dcache_refill_net_resp_in_rdy_0;

  // `include "vc-trace-tasks.v"
  //
  // task trace_module( inout [vc_trace_nbits-1:0] trace );
  // begin
  //   CORES_CACHES[0].PROC.proc.trace_module( trace );
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[0].icache.trace_module( trace );
  //   CORES_CACHES[0].l1_dcache.trace_module( trace );
  //   CORES_CACHES[0].l2_dcache.trace_module( trace );
  //
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[1].PROC.proc.trace_module( trace );
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[1].l1_dcache.trace_module( trace );
  //   CORES_CACHES[1].l2_dcache.trace_module( trace );
  //
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[2].PROC.proc.trace_module( trace );
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[2].l1_dcache.trace_module( trace );
  //   CORES_CACHES[2].l2_dcache.trace_module( trace );
  //
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[3].PROC.proc.trace_module( trace );
  //   vc_trace_str( trace, "|" );
  //   CORES_CACHES[3].l1_dcache.trace_module( trace );
  //   CORES_CACHES[3].l2_dcache.trace_module( trace );
  //
  // end
  // endtask

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
