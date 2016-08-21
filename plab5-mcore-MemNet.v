//========================================================================
// Memory Request/Response Network
//========================================================================

`ifndef PLAB5_MCORE_MEM_NET_V
`define PLAB5_MCORE_MEM_NET_V

`include "vc-mem-msgs.v"
`include "vc-net-msgs.v"
`include "plab5-mcore-mem-net-adapters.v"
`include "plab4-net-RingNetBase_4.v"

module plab5_mcore_MemNet
#(
  parameter p_mem_opaque_nbits  = 8,
  parameter p_mem_addr_nbits    = 32,
  parameter p_mem_data_nbits    = 32,

  parameter p_num_ports         = 4,

  parameter p_single_bank       = 0,
  
  parameter p_cohere_net        = 0,

  parameter o = p_mem_opaque_nbits,
  parameter a = p_mem_addr_nbits,
  parameter d = p_mem_data_nbits,

  parameter c_net_srcdest_nbits = $clog2(p_num_ports),
  parameter c_net_opaque_nbits  = 4,

  parameter ns = c_net_srcdest_nbits,
  parameter no = c_net_opaque_nbits,

  parameter c_req_nbits   = `VC_MEM_REQ_MSG_NBITS(o,a,d),
  parameter c_resp_nbits  = `VC_MEM_RESP_MSG_NBITS(o,d),

  parameter rq = c_req_nbits,
  parameter rs = c_resp_nbits,

  parameter c_req_net_msg_nbits   = `VC_NET_MSG_NBITS(rq,no,ns),
  parameter c_resp_net_msg_nbits  = `VC_NET_MSG_NBITS(rs,no,ns),

  parameter nrq = c_req_net_msg_nbits,
  parameter nrs = c_resp_net_msg_nbits

)
(

  input        {L} clk,
  input        {L} reset,

  input   [rq-1:0] {Domain req_in_sd_0} req_in_msg_0,
  input            {Domain req_in_sd_0} req_in_val_0,
  output           {Domain req_in_sd_0} req_in_rdy_0,
  input            {L}  req_in_sd_0,
  
  input   [rq-1:0] {Domain req_in_sd_1} req_in_msg_1,
  input            {Domain req_in_sd_1} req_in_val_1,
  output           {Domain req_in_sd_1} req_in_rdy_1,
  input            {L}  req_in_sd_1,
  
  input   [rq-1:0] {Domain req_in_sd_2} req_in_msg_2,
  input            {Domain req_in_sd_2} req_in_val_2,
  output           {Domain req_in_sd_2} req_in_rdy_2,
  input            {L}  req_in_sd_2,
  
  input   [rq-1:0] {Domain req_in_sd_3} req_in_msg_3,
  input            {Domain req_in_sd_3} req_in_val_3,
  output           {Domain req_in_sd_3} req_in_rdy_3,
  input            {L}  req_in_sd_3,

  output  [rs-1:0] {Domain cur_sd} resp_out_msg_0,
  output           {Domain cur_sd} resp_out_val_0,
  input            {Domain cur_sd} resp_out_rdy_0,
  
  output  [rs-1:0] {Domain cur_sd} resp_out_msg_1,
  output           {Domain cur_sd} resp_out_val_1,
  input            {Domain cur_sd} resp_out_rdy_1,
  
  output  [rs-1:0] {Domain cur_sd} resp_out_msg_2,
  output           {Domain cur_sd} resp_out_val_2,
  input            {Domain cur_sd} resp_out_rdy_2,
  
  output  [rs-1:0] {Domain cur_sd} resp_out_msg_3,
  output           {Domain cur_sd} resp_out_val_3,
  input            {Domain cur_sd} resp_out_rdy_3,

  output  [rq-1:0] {Domain cur_sd} req_out_msg_0,
  output           {Domain cur_sd} req_out_val_0,
  input            {Domain cur_sd} req_out_rdy_0,
  
  output  [rq-1:0] {Domain cur_sd} req_out_msg_1,
  output           {Domain cur_sd} req_out_val_1,
  input            {Domain cur_sd} req_out_rdy_1,
  
  output  [rq-1:0] {Domain cur_sd} req_out_msg_2,
  output           {Domain cur_sd} req_out_val_2,
  input            {Domain cur_sd} req_out_rdy_2,
  
  output  [rq-1:0] {Domain cur_sd} req_out_msg_3,
  output           {Domain cur_sd} req_out_val_3,
  input            {Domain cur_sd} req_out_rdy_3,

  input   [rs-1:0] {Domain resp_in_sd_0} resp_in_msg_0,
  input            {Domain resp_in_sd_0} resp_in_val_0,
  output           {Domain resp_in_sd_0} resp_in_rdy_0,
  input            {L}  resp_in_sd_0,
  
  input   [rs-1:0] {Domain resp_in_sd_1} resp_in_msg_1,
  input            {Domain resp_in_sd_1} resp_in_val_1,
  output           {Domain resp_in_sd_1} resp_in_rdy_1,
  input            {L}  resp_in_sd_1,
  
  input   [rs-1:0] {Domain resp_in_sd_2} resp_in_msg_2,
  input            {Domain resp_in_sd_2} resp_in_val_2,
  output           {Domain resp_in_sd_2} resp_in_rdy_2,
  input            {L}  resp_in_sd_2,
  
  input   [rs-1:0] {Domain resp_in_sd_3} resp_in_msg_3,
  input            {Domain resp_in_sd_3} resp_in_val_3,
  output           {Domain resp_in_sd_3} resp_in_rdy_3,
  input            {L}  resp_in_sd_3,
  
  input            {L} cur_sd

);

  wire [nrq-1:0] {Domain req_in_sd_0} req_net_in_msg_0;
  wire [nrq-1:0] {Domain req_in_sd_1} req_net_in_msg_1;
  wire [nrq-1:0] {Domain req_in_sd_2} req_net_in_msg_2;
  wire [nrq-1:0] {Domain req_in_sd_3} req_net_in_msg_3;
  
  wire [nrq-1:0] {Domain cur_sd} req_net_out_msg_0;
  wire [nrq-1:0] {Domain cur_sd} req_net_out_msg_1;
  wire [nrq-1:0] {Domain cur_sd} req_net_out_msg_2;
  wire [nrq-1:0] {Domain cur_sd} req_net_out_msg_3;
  
  wire [nrs-1:0] {Domain resp_in_sd_0} resp_net_in_msg_0;
  wire [nrs-1:0] {Domain resp_in_sd_1} resp_net_in_msg_1;
  wire [nrs-1:0] {Domain resp_in_sd_2} resp_net_in_msg_2;
  wire [nrs-1:0] {Domain resp_in_sd_3} resp_net_in_msg_3;
  
  wire [nrs-1:0] {Domain cur_sd} resp_net_out_msg_0;
  wire [nrs-1:0] {Domain cur_sd} resp_net_out_msg_1;
  wire [nrs-1:0] {Domain cur_sd} resp_net_out_msg_2;
  wire [nrs-1:0] {Domain cur_sd} resp_net_out_msg_3;

  // Port 0
  plab5_mcore_MemReqMsgToNetMsg
  #(
    .p_net_src            (0),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_addr_nbits     (p_mem_addr_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),

    .p_single_bank        (p_single_bank)
  )
  proc_mem_msg_to_net_msg_0
  (
    .mem_msg (req_in_msg_0),
    .net_msg (req_net_in_msg_0),
    .sd      (req_in_sd_0)
  );

  // extract the cache req mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} req_out_dest_0;
  wire [ns-1:0]    {Domain cur_sd} req_out_src_0;
  wire [no-1:0]    {Domain cur_sd} req_out_opaque_0;

  vc_NetMsgUnpack #(rq,no,ns) req_net_msg_unpack_0
  (
    .msg      (req_net_out_msg_0),
    .payload  (req_out_msg_0),
    .dest     (req_out_dest_0),
    .src      (req_out_src_0),
    .opaque   (req_out_opaque_0),
    .sd       (cur_sd)
  );

  // cache resp mem msg to net msg adapter

  plab5_mcore_MemRespMsgToNetMsg
  #(
    .p_net_src            (0),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),
    .p_cohere_net         (p_cohere_net)
  )
  cache_mem_msg_to_net_msg_0
  (
    .mem_msg (resp_in_msg_0),
    .net_msg (resp_net_in_msg_0),
    .sd      (resp_in_sd_0)
  );

  // extract the proc resp mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} resp_out_dest_0;
  wire [ns-1:0]    {Domain cur_sd} resp_out_src_0;
  wire [no-1:0]    {Domain cur_sd} resp_out_opaque_0;

  vc_NetMsgUnpack #(rs,no,ns) resp_net_msg_unpack_0
  (
    .msg      (resp_net_out_msg_0),
    .payload  (resp_out_msg_0),
    .dest     (resp_out_dest_0),
    .src      (resp_out_src_0),
    .opaque   (resp_out_opaque_0),
    .sd       (cur_sd)
  );

  // Port 1
  plab5_mcore_MemReqMsgToNetMsg
  #(
    .p_net_src            (1),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_addr_nbits     (p_mem_addr_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),

    .p_single_bank        (p_single_bank)
  )
  proc_mem_msg_to_net_msg_1
  (
    .mem_msg (req_in_msg_1),
    .net_msg (req_net_in_msg_1),
    .sd      (req_in_sd_1)
  );

  // extract the cache req mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} req_out_dest_1;
  wire [ns-1:0]    {Domain cur_sd} req_out_src_1;
  wire [no-1:0]    {Domain cur_sd} req_out_opaque_1;

  vc_NetMsgUnpack #(rq,no,ns) req_net_msg_unpack_1
  (
    .msg      (req_net_out_msg_1),
    .payload  (req_out_msg_1),
    .dest     (req_out_dest_1),
    .src      (req_out_src_1),
    .opaque   (req_out_opaque_1),
    .sd       (cur_sd)
  );

  // cache resp mem msg to net msg adapter

  plab5_mcore_MemRespMsgToNetMsg
  #(
    .p_net_src            (1),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),
    .p_cohere_net         (p_cohere_net)
  )
  cache_mem_msg_to_net_msg_1
  (
    .mem_msg (resp_in_msg_1),
    .net_msg (resp_net_in_msg_1),
    .sd      (resp_in_sd_1)
  );

  // extract the proc resp mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} resp_out_dest_1;
  wire [ns-1:0]    {Domain cur_sd} resp_out_src_1;
  wire [no-1:0]    {Domain cur_sd} resp_out_opaque_1;

  vc_NetMsgUnpack #(rs,no,ns) resp_net_msg_unpack_1
  (
    .msg      (resp_net_out_msg_1),
    .payload  (resp_out_msg_1),
    .dest     (resp_out_dest_1),
    .src      (resp_out_src_1),
    .opaque   (resp_out_opaque_1),
    .sd       (cur_sd)
  );

  // Port 2
  plab5_mcore_MemReqMsgToNetMsg
  #(
    .p_net_src            (2),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_addr_nbits     (p_mem_addr_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),

    .p_single_bank        (p_single_bank)
  )
  proc_mem_msg_to_net_msg_2
  (
    .mem_msg (req_in_msg_2),
    .net_msg (req_net_in_msg_2),
    .sd      (req_in_sd_2)
  );

  // extract the cache req mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} req_out_dest_2;
  wire [ns-1:0]    {Domain cur_sd} req_out_src_2;
  wire [no-1:0]    {Domain cur_sd} req_out_opaque_2;

  vc_NetMsgUnpack #(rq,no,ns) req_net_msg_unpack_2
  (
    .msg      (req_net_out_msg_2),
    .payload  (req_out_msg_2),
    .dest     (req_out_dest_2),
    .src      (req_out_src_2),
    .opaque   (req_out_opaque_2),
    .sd       (cur_sd)
  );

  // cache resp mem msg to net msg adapter

  plab5_mcore_MemRespMsgToNetMsg
  #(
    .p_net_src            (2),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),
    .p_cohere_net         (p_cohere_net)
  )
  cache_mem_msg_to_net_msg_2
  (
    .mem_msg (resp_in_msg_2),
    .net_msg (resp_net_in_msg_2),
    .sd      (resp_in_sd_2)
  );

  // extract the proc resp mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} resp_out_dest_2;
  wire [ns-1:0]    {Domain cur_sd} resp_out_src_2;
  wire [no-1:0]    {Domain cur_sd} resp_out_opaque_2;

  vc_NetMsgUnpack #(rs,no,ns) resp_net_msg_unpack_2
  (
    .msg      (resp_net_out_msg_2),
    .payload  (resp_out_msg_2),
    .dest     (resp_out_dest_2),
    .src      (resp_out_src_2),
    .opaque   (resp_out_opaque_2),
    .sd       (cur_sd)
  );

  // Port 3
  plab5_mcore_MemReqMsgToNetMsg
  #(
    .p_net_src            (3),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_addr_nbits     (p_mem_addr_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),

    .p_single_bank        (p_single_bank)
  )
  proc_mem_msg_to_net_msg_3
  (
    .mem_msg (req_in_msg_3),
    .net_msg (req_net_in_msg_3),
    .sd      (req_in_sd_3)
  );

  // extract the cache req mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} req_out_dest_3;
  wire [ns-1:0]    {Domain cur_sd} req_out_src_3;
  wire [no-1:0]    {Domain cur_sd} req_out_opaque_3;

  vc_NetMsgUnpack #(rq,no,ns) req_net_msg_unpack_3
  (
    .msg      (req_net_out_msg_3),
    .payload  (req_out_msg_3),
    .dest     (req_out_dest_3),
    .src      (req_out_src_3),
    .opaque   (req_out_opaque_3),
    .sd       (cur_sd)
  );

  // cache resp mem msg to net msg adapter

  plab5_mcore_MemRespMsgToNetMsg
  #(
    .p_net_src            (3),
    .p_num_ports          (p_num_ports),

    .p_mem_opaque_nbits   (p_mem_opaque_nbits),
    .p_mem_data_nbits     (p_mem_data_nbits),

    .p_net_opaque_nbits   (c_net_opaque_nbits),
    .p_net_srcdest_nbits  (c_net_srcdest_nbits),
    .p_cohere_net         (p_cohere_net)
  )
  cache_mem_msg_to_net_msg_3
  (
    .mem_msg (resp_in_msg_3),
    .net_msg (resp_net_in_msg_3),
    .sd      (resp_in_sd_3)
  );

  // extract the proc resp mem msg from net msg payload

  wire [ns-1:0]    {Domain cur_sd} resp_out_dest_3;
  wire [ns-1:0]    {Domain cur_sd} resp_out_src_3;
  wire [no-1:0]    {Domain cur_sd} resp_out_opaque_3;

  vc_NetMsgUnpack #(rs,no,ns) resp_net_msg_unpack_3
  (
    .msg      (resp_net_out_msg_3),
    .payload  (resp_out_msg_3),
    .dest     (resp_out_dest_3),
    .src      (resp_out_src_3),
    .opaque   (resp_out_opaque_3),
    .sd       (cur_sd)
  );

  // request network

  `define PLAB4_NET_NUM_PORTS_4

  // wire [p_num_ports-1:0] req_net_in_val;
  // wire [p_num_ports-1:0] req_net_out_rdy;
  // wire [p_num_ports-1:0] resp_net_in_val;
  // wire [p_num_ports-1:0] resp_net_out_rdy;
  //
  // // for single bank mode, the cache side of things are padded to 0 other
  // // than cache/mem 0
  //
  // assign req_net_in_val   = req_in_val;
  // assign req_net_out_rdy  = p_single_bank ? { 32'h0, req_out_rdy[0] } :
  //                                           req_out_rdy;
  //
  // assign resp_net_in_val  = p_single_bank ? { 32'h0, resp_in_val[0] } :
  //                                           resp_in_val;
  // assign resp_net_out_rdy = resp_out_rdy;

  plab4_net_RingNetBase_4 #(rq,no,ns,4) req_net
  (
    .clk      (clk),
    .reset    (reset),

    .in_val_0   (req_in_val_0),
    .in_rdy_0   (req_in_rdy_0),
    .in_msg_0   (req_net_in_msg_0),
    .in_sd_0    (req_in_sd_0),

    .out_val_0  (req_out_val_0),
    .out_rdy_0  (req_out_rdy_0),
    .out_msg_0  (req_net_out_msg_0),

    .in_val_1   (req_in_val_1),
    .in_rdy_1   (req_in_rdy_1),
    .in_msg_1   (req_net_in_msg_1),
    .in_sd_1    (req_in_sd_1),

    .out_val_1  (req_out_val_1),
    .out_rdy_1  (req_out_rdy_1),
    .out_msg_1  (req_net_out_msg_1),

    .in_val_2   (req_in_val_2),
    .in_rdy_2   (req_in_rdy_2),
    .in_msg_2   (req_net_in_msg_2),
    .in_sd_2    (req_in_sd_2),

    .out_val_2  (req_out_val_2),
    .out_rdy_2  (req_out_rdy_2),
    .out_msg_2  (req_net_out_msg_2),

    .in_val_3   (req_in_val_3),
    .in_rdy_3   (req_in_rdy_3),
    .in_msg_3   (req_net_in_msg_3),
    .in_sd_3    (req_in_sd_3),

    .out_val_3  (req_out_val_3),
    .out_rdy_3  (req_out_rdy_3),
    .out_msg_3  (req_net_out_msg_3),

    .cur_sd     (cur_sd)
  );

  // response network

  plab4_net_RingNetBase_4 #(rs,no,ns,4) resp_net
  (
    .clk      (clk),
    .reset    (reset),

    .in_val_0   (resp_in_val_0),
    .in_rdy_0   (resp_in_rdy_0),
    .in_msg_0   (resp_net_in_msg_0),
    .in_sd_0    (resp_in_sd_0),

    .out_val_0  (resp_out_val_0),
    .out_rdy_0  (resp_out_rdy_0),
    .out_msg_0  (resp_net_out_msg_0),

    .in_val_1   (resp_in_val_1),
    .in_rdy_1   (resp_in_rdy_1),
    .in_msg_1   (resp_net_in_msg_1),
    .in_sd_1    (resp_in_sd_1),

    .out_val_1  (resp_out_val_1),
    .out_rdy_1  (resp_out_rdy_1),
    .out_msg_1  (resp_net_out_msg_1),

    .in_val_2   (resp_in_val_2),
    .in_rdy_2   (resp_in_rdy_2),
    .in_msg_2   (resp_net_in_msg_2),
    .in_sd_2    (resp_in_sd_2),

    .out_val_2  (resp_out_val_2),
    .out_rdy_2  (resp_out_rdy_2),
    .out_msg_2  (resp_net_out_msg_2),

    .in_val_3   (resp_in_val_3),
    .in_rdy_3   (resp_in_rdy_3),
    .in_msg_3   (resp_net_in_msg_3),
    .in_sd_3    (resp_in_sd_3),

    .out_val_3  (resp_out_val_3),
    .out_rdy_3  (resp_out_rdy_3),
    .out_msg_3  (resp_net_out_msg_3),

    .cur_sd     (cur_sd)
  );



endmodule

`endif /* PLAB5_MCORE_MEM_NET_V */
