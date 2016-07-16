//=========================================================================
// Alternative Blocking Cache Datapath
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_L2_DPATH_V
`define PLAB3_MEM_BLOCKING_CACHE_L2_DPATH_V

`include "vc-mem-msgs.v"
`include "vc-arithmetic.v"
`include "vc-muxes.v"
`include "vc-srams.v"
`include "vc-regs.v"

module plab3_mem_BlockingCacheL2Dpath
#(
  parameter size    = 256,            // Cache size in bytes

  parameter p_idx_shamt = 0,

  parameter p_opaque_nbits   = 8,

  // local parameters not meant to be set from outside
  parameter dbw     = 128,             // Short name for data bitwidth
  parameter abw     = 32,             // Short name for addr bitwidth
  parameter clw     = 128,            // Short name for cacheline bitwidth
  parameter nblocks = size*8/clw,     // Number of blocks in the cache
  parameter idw     = $clog2(nblocks),// Short name for index width

  parameter o = p_opaque_nbits
)
(
  input                                              {L} clk,
  input                                              {L} reset,

  // Cache Request

  input [`VC_MEM_REQ_MSG_NBITS(o,abw,dbw)-1:0]       {Domain sd} cachereq_msg,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(o,dbw)-1:0]         {Domain sd} cacheresp_msg,

  // Memory Request

  output [`VC_MEM_REQ_MSG_NBITS(o,abw,clw)-1:0]      {Domain sd} memreq_msg,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(o,clw)-1:0]          {Domain sd} memresp_msg,

  // control signals (ctrl->dpath)
  input [1:0]                                        {Domain sd} amo_sel,
  input                                              {Domain sd} cachereq_en,
  input                                              {Domain sd} memresp_en,
  input                                              {Domain sd} is_refill,
  input                                              {Domain sd} tag_array_0_wen,
  input                                              {Domain sd} tag_array_0_ren,
  input                                              {Domain sd} tag_array_1_wen,
  input                                              {Domain sd} tag_array_1_ren,
  input                                              {Domain sd} way_sel,
  input                                              {Domain sd} data_array_wen,
  input                                              {Domain sd} data_array_ren,
  // width of cacheline divided by number of bits per byte
  input [clw/8-1:0]                                  {Domain sd} data_array_wben,
  input                                              {Domain sd} read_data_reg_en,
  input                                              {Domain sd} read_tag_reg_en,
  input [$clog2(clw/dbw)-1:0]                        {Domain sd} read_byte_sel,
  input [`VC_MEM_RESP_MSG_TYPE_NBITS(o,clw)-1:0]     {Domain sd} memreq_type,
  input [`VC_MEM_RESP_MSG_TYPE_NBITS(o,dbw)-1:0]     {Domain sd} cacheresp_type,

  // status signals (dpath->ctrl)
  output [`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_type,
  output [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_addr,
  output                                             {Domain sd} tag_match_0,
  output                                             {Domain sd} tag_match_1,
  input                                              {L} sd
);

  // Unpack cache request

  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_addr_out;
  wire [`VC_MEM_REQ_MSG_DATA_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_data_out;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_opaque_out;
  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_type_out;
  wire [`VC_MEM_REQ_MSG_LEN_NBITS(o,abw,dbw)-1:0]    {Domain sd} cachereq_len_out;

  vc_MemReqMsgUnpack#(o,abw,dbw) cachereq_msg_unpack
  (
    .msg    (cachereq_msg),

    .type   (cachereq_type_out),
    .opaque (cachereq_opaque_out),
    .addr   (cachereq_addr_out),
    .len    (cachereq_len_out),
    .data   (cachereq_data_out),
    .sd     (sd)
  );

  // Unpack memory response

  wire [`VC_MEM_RESP_MSG_DATA_NBITS(o,clw)-1:0]        {Domain sd} memresp_data_out;
  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(o,clw)-1:0]        {Domain sd} memresp_data_type;
  wire [`VC_MEM_RESP_MSG_OPAQUE_NBITS(o,clw)-1:0]      {Domain sd} memresp_data_opaque;
  wire [`VC_MEM_RESP_MSG_LEN_NBITS(o,clw)-1:0]         {Domain sd} memresp_data_len;

  vc_MemRespMsgUnpack#(o,clw) memresp_msg_unpack
  (
    .msg    (memresp_msg),

    .opaque (memresp_data_opaque),
    .type   (memresp_data_type),
    .len    (memresp_data_len),
    .data   (memresp_data_out),
    .sd     (sd)
  );

  // Register the unpacked cachereq_msg

  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_addr_reg_out;
  wire [`VC_MEM_REQ_MSG_DATA_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_data_reg_out;
  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_type_reg_out;
  wire [`VC_MEM_REQ_MSG_OPAQUE_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_opaque_reg_out;

  vc_EnResetReg #(`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw), 0) cachereq_type_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (cachereq_en),
    .d      (cachereq_type_out),
    .q      (cachereq_type_reg_out),
    .sd     (sd)
  );

  vc_EnResetReg #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw), 0) cachereq_addr_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (cachereq_en),
    .d      (cachereq_addr_out),
    .q      (cachereq_addr_reg_out),
    .sd     (sd)
  );

  vc_EnResetReg #(`VC_MEM_REQ_MSG_OPAQUE_NBITS(o,abw,dbw), 0) cachereq_opaque_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (cachereq_en),
    .d      (cachereq_opaque_out),
    .q      (cachereq_opaque_reg_out),
    .sd     (sd)
  );

  vc_EnResetReg #(`VC_MEM_REQ_MSG_DATA_NBITS(o,abw,dbw), 0) cachereq_data_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (cachereq_en),
    .d      (cachereq_data_out),
    .q      (cachereq_data_reg_out),
    .sd     (sd)
  );

  assign cachereq_type = cachereq_type_reg_out;
  assign cachereq_addr = cachereq_addr_reg_out;

  // Register the unpacked data from memresp_msg

  wire [clw-1:0]                                   {Domain sd} memresp_data_reg_out;

  vc_EnResetReg #(clw, 0) memresp_data_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (memresp_en),
    .d      (memresp_data_out),
    .q      (memresp_data_reg_out),
    .sd     (sd)
  );

  // Generate cachereq write data which will be the data field or some
  // calculation with the read data for amos

  wire [`VC_MEM_REQ_MSG_DATA_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_write_data;
  wire [`VC_MEM_REQ_MSG_DATA_NBITS(o,abw,dbw)-1:0] {Domain sd} read_byte_sel_mux_out;

  vc_Mux4 #(dbw) amo_sel_mux
  (
    .in0  (cachereq_data_reg_out),
    .in1  (cachereq_data_reg_out + read_byte_sel_mux_out),
    .in2  (cachereq_data_reg_out & read_byte_sel_mux_out),
    .in3  (cachereq_data_reg_out | read_byte_sel_mux_out),
    .sel  (amo_sel),
    .out  (cachereq_write_data),
    .sd   (sd)
  );

  // Refill mux

  wire [`VC_MEM_RESP_MSG_DATA_NBITS(o,clw)-1:0] {Domain sd} refill_mux_out;

  vc_Mux2 #(clw) refill_mux
  (
    .in0  (cachereq_write_data),
    .in1  (memresp_data_reg_out),
    .sel  (is_refill),
    .out  (refill_mux_out),
    .sd   (sd)
  );

  // Taking slices of the cache request address
  //     byte offset: 2 bits wide
  //     word offset: 2 bits wide
  //     index: $clog2(nblocks) - 1 bits wide
  //     nbits: width of tag = width of addr - $clog2(nblocks) - 4
  //     entries: 256*8/128 = 16
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4-1:0] {Domain sd} cachereq_tag;
  // Index is 3 bits to account for the way number
  wire [2:0]                                         {Domain sd} cachereq_idx;

  assign cachereq_tag = cachereq_addr_reg_out[`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:4];
  // -1 for way
  assign cachereq_idx = cachereq_addr_reg_out[4+p_idx_shamt +: 3];

  // Tag array
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0] {Domain sd} tag_array_0_read_out;

  vc_CombinationalSRAM_1rw #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw),nblocks/2) tag_array_0
  (
    .clk           (clk),
    .reset         (reset),
    .read_addr     (cachereq_idx),
    .read_data     (tag_array_0_read_out),
    .write_en      (tag_array_0_wen),
    .read_en       (tag_array_0_ren),
    .write_byte_en (4'b1111),
    .write_addr    (cachereq_idx),
    .write_data    ( { 4'h0, cachereq_tag } ),
    .sd            (sd)
  );

  // Tag array 1
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0] {Domain sd} tag_array_1_read_out;

  vc_CombinationalSRAM_1rw #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw),nblocks/2) tag_array_1
  (
    .clk           (clk),
    .reset         (reset),
    .read_addr     (cachereq_idx),
    .read_data     (tag_array_1_read_out),
    .write_en      (tag_array_1_wen),
    .read_en       (tag_array_1_ren),
    .write_byte_en (4'b1111),
    .write_addr    (cachereq_idx),
    .write_data    ( { 4'h0, cachereq_tag } ),
    .sd            (sd)
  );

  wire [clw-1:0] {Domain sd} data_array_read_out;

  // Data array
  vc_CombinationalSRAM_1rw #(clw, nblocks) data_array
  (
    .clk           (clk),
    .reset         (reset),
    // Whether way_sel is appended or prepended does not matter since
    // it's just a matter of how the cachelines are actually organized in
    // the data_array
    .read_addr     ( { cachereq_idx, way_sel } ),
    .read_data     (data_array_read_out),
    .write_en      (data_array_wen),
    .read_en       (data_array_ren),
    .write_byte_en (16'hffff),
    .write_addr    ( { cachereq_idx, way_sel } ),
    .write_data    (refill_mux_out),
    .sd            (sd)
  );

  // Eq comparator to check for tag matching (tag_compare_0)
  vc_EqComparator #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4) tag_compare_0
  (
    .in0 (cachereq_tag),
    .in1 (tag_array_0_read_out[27:0]),
    .out (tag_match_0),
    .sd  (sd)
  );

  // Eq comparator to check for tag matching (tag_compare_1)
  vc_EqComparator #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4) tag_compare_1
  (
    .in0 (cachereq_tag),
    .in1 (tag_array_1_read_out[27:0]),
    .out (tag_match_1),
    .sd  (sd)
  );

  // Mux that selects between the ways for requesting from memory
  wire [27:0]    {Domain sd} way_sel_mux_out;

  vc_Mux2 #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4) way_sel_mux
  (
    .in0 (tag_array_0_read_out[27:0]),
    .in1 (tag_array_1_read_out[27:0]),
    .sel (way_sel),
    .out (way_sel_mux_out),
    .sd  (sd)
  );

  // Read data register

  wire [clw-1:0]   {Domain sd} read_data_reg_out;

  vc_EnResetReg #(clw, 0) read_data_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (read_data_reg_en),
    .d      (data_array_read_out),
    .q      (read_data_reg_out),
    .sd     (sd)
  );

  // Read data register

  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4-1:0]   {Domain sd} read_tag_reg_out;

  vc_EnResetReg #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4, 0) read_tag_reg
  (
    .clk    (clk),
    .reset  (reset),
    .en     (read_tag_reg_en),
    .d      (way_sel_mux_out),
    .q      (read_tag_reg_out),
    .sd     (sd)
  );

  // Memreq Type Mux

  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4-1:0] {Domain sd} memreq_type_mux_out;

  vc_Mux2 #(`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-4) memreq_type_mux
  (
    .in0  (cachereq_tag),
    .in1  (read_tag_reg_out),
    // TODO: change the following
    .sel  (memreq_type[0]),
    .out  (memreq_type_mux_out),
    .sd   (sd)
  );

  // Pack address for memory request

  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,clw)-1:0] {Domain sd} memreq_addr;
  assign memreq_addr = { memreq_type_mux_out, 4'b0000 };

  // Pack cache response

  vc_MemRespMsgPack#(o,dbw) cacheresp_msg_pack
  (
    .type   (cacheresp_type),
    .opaque (cachereq_opaque_reg_out),
    .len    (4'h0),
    .data   (read_data_reg_out),
    .msg    (cacheresp_msg),
    .sd     (sd)
  );

  // Pack cache response
  vc_MemReqMsgPack#(o,abw,clw) memreq_msg_pack
  (
    .type   (memreq_type),
    .opaque (8'h00),
    .addr   (memreq_addr),
    .len    (4'h0),
    .data   (read_data_reg_out),
    .msg    (memreq_msg),
    .sd     (sd)
  );

endmodule

`endif
