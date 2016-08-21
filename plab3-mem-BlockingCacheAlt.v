//=========================================================================
// Alternative Blocking Cache
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_V

`include "vc-mem-msgs.v"
`include "plab3-mem-BlockingCacheAltCtrl.v"
`include "plab3-mem-BlockingCacheAltDpath.v"


module plab3_mem_BlockingCacheAlt
#(
  parameter p_mem_nbytes = 256,            // Cache size in bytes
  parameter p_num_banks  = 0,              // Total number of cache banks

  // opaque field from the cache and memory side
  parameter p_opaque_nbits = 8,

  // local parameters not meant to be set from outside
  parameter dbw          = 32,             // Short name for data bitwidth
  parameter abw          = 32,             // Short name for addr bitwidth
  parameter clw          = 128,            // Short name for cacheline bitwidth

  parameter o = p_opaque_nbits
)
(
  input                                         {L} clk,
  input                                         {L} reset,

  // Cache Request

  input [`VC_MEM_REQ_MSG_NBITS(o,abw,dbw)-1:0]  {Domain sd} cachereq_msg,
  input                                         {Domain sd} cachereq_val,
  output                                        {Domain sd} cachereq_rdy,

  // Cache Response

  output [`VC_MEM_RESP_MSG_NBITS(o,dbw)-1:0]    {Domain sd} cacheresp_msg,
  output                                        {Domain sd} cacheresp_val,
  input                                         {Domain sd} cacheresp_rdy,

  // Memory Request

  output [`VC_MEM_REQ_MSG_NBITS(o,abw,clw)-1:0] {Domain sd} memreq_msg,
  output                                        {Domain sd} memreq_val,
  input                                         {Domain sd} memreq_rdy,

  // Memory Response

  input [`VC_MEM_RESP_MSG_NBITS(o,clw)-1:0]     {Domain sd} memresp_msg,
  input                                         {Domain sd} memresp_val,
  output                                        {Domain sd} memresp_rdy,
  
  // Coherent Memory Request
  
  input [`VC_MEM_REQ_MSG_NBITS(o,abw,clw)-1:0]  {Domain sd} coherereq_msg,
  input                                         {Domain sd} coherereq_val,
  
  // Coherent Memory Response
  
  output [`VC_MEM_RESP_MSG_NBITS(o,clw)-1:0]    {Domain sd} cohereresp_msg,
  output                                        {Domain sd} cohereresp_val,
  input                                         {Domain sd} cohereresp_rdy,
  
  input                                         {L} sd
);

  // calculate the index shift amount based on number of banks

  localparam c_idx_shamt = $clog2( p_num_banks );

  //----------------------------------------------------------------------
  // Wires
  //----------------------------------------------------------------------

  // control signals (ctrl->dpath)
  wire [1:0]                                    {Domain sd} amo_sel;
  wire                                          {Domain sd} cachereq_en;
  wire                                          {Domain sd} memresp_en;
  wire                                          {Domain sd} is_refill;
  wire                                          {Domain sd} tag_array_0_wen;
  wire                                          {Domain sd} tag_array_0_ren;
  wire                                          {Domain sd} tag_array_1_wen;
  wire                                          {Domain sd} tag_array_1_ren;
  wire                                          {Domain sd} way_sel;
  wire                                          {Domain sd} data_array_wen;
  wire                                          {Domain sd} data_array_ren;
  wire [clw/8-1:0]                              {Domain sd} data_array_wben;
  wire                                          {Domain sd} read_data_reg_en;
  wire                                          {Domain sd} read_tag_reg_en;
  wire [$clog2(clw/dbw)-1:0]                    {Domain sd} read_byte_sel;
  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(o,clw)-1:0] {Domain sd} memreq_type;
  wire [`VC_MEM_RESP_MSG_TYPE_NBITS(o,dbw)-1:0] {Domain sd} cacheresp_type;
  wire [1:0]                                    {Domain sd} req_sel;


  // status signals (dpath->ctrl)
  wire [`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_type;
  wire [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0] {Domain sd} cachereq_addr;
  wire                                             {Domain sd} tag_match_0;
  wire                                             {Domain sd} tag_match_1;

  wire [`VC_MEM_REQ_MSG_NBITS(o,abw,clw)-1:0]   {Domain sd} muxreq_msg;
  
  reg  [`VC_MEM_REQ_MSG_NBITS(o,abw,clw)-1:0]   {Domain sd} coherereq_msg_reg;
  
  assign muxreq_msg = (req_sel == 2'd0) ? cachereq_msg : 
                      (req_sel == 2'd1) ? coherereq_msg :
                      (req_sel == 2'd2) ? coherereq_msg_reg : 0 ;
  
  always @ (posedge clk) begin
    // store the msg in a register to process later
    if (cachereq_val == 1'b1 && coherereq_val == 1'b1) begin
        coherereq_msg_reg <= coherereq_msg;
    end
  end
    
  //----------------------------------------------------------------------
  // Control
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltCtrl
  #(
    .size                   (p_mem_nbytes),
    .p_idx_shamt            (c_idx_shamt),
    .p_opaque_nbits         (p_opaque_nbits)
  )
  ctrl
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_val      (cachereq_val),
   .cachereq_rdy      (cachereq_rdy),

   // Cache Response

   .cacheresp_val     (cacheresp_val),
   .cacheresp_rdy     (cacheresp_rdy),

   // Memory Request

   .memreq_val        (memreq_val),
   .memreq_rdy        (memreq_rdy),

   // Memory Response

   .memresp_val       (memresp_val),
   .memresp_rdy       (memresp_rdy),

   // Coherent Memory Request
   .coherereq_val     (coherereq_val),
   
   // Coherent Memory Response
   .cohereresp_val    (cohereresp_val),
   .cohereresp_rdy    (cohereresp_rdy),
   
   // control signals (ctrl->dpath)
   .amo_sel           (amo_sel),
   .cachereq_en       (cachereq_en),
   .memresp_en        (memresp_en),
   .is_refill         (is_refill),
   .tag_array_0_wen   (tag_array_0_wen),
   .tag_array_0_ren   (tag_array_0_ren),
   .tag_array_1_wen   (tag_array_1_wen),
   .tag_array_1_ren   (tag_array_1_ren),
   .way_sel           (way_sel),
   .data_array_wen    (data_array_wen),
   .data_array_ren    (data_array_ren),
   .data_array_wben   (data_array_wben),
   .read_data_reg_en  (read_data_reg_en),
   .read_tag_reg_en   (read_tag_reg_en),
   .read_byte_sel     (read_byte_sel),
   .memreq_type       (memreq_type),
   .cacheresp_type    (cacheresp_type),
   .req_sel           (req_sel),

   // status signals  (dpath->ctrl)
   .cachereq_type     (cachereq_type),
   .cachereq_addr     (cachereq_addr),
   .tag_match_0       (tag_match_0),
   .tag_match_1       (tag_match_1),
   .sd                (sd)
  );

  //----------------------------------------------------------------------
  // Datapath
  //----------------------------------------------------------------------

  plab3_mem_BlockingCacheAltDpath
  #(
    .size                   (p_mem_nbytes),
    .p_idx_shamt            (c_idx_shamt),
    .p_opaque_nbits         (p_opaque_nbits)
  )
  dpath
  (
   .clk               (clk),
   .reset             (reset),

   // Cache Request

   .cachereq_msg      (muxreq_msg),

   // Cache Response

   .cacheresp_msg     (cacheresp_msg),

   // Memory Request

   .memreq_msg        (memreq_msg),

   // Memory Response

   .memresp_msg       (memresp_msg),
   
   // Memory Coherent Request
   .coherereq_msg     (coherereq_msg),
   
   // Memory Coherent Response
   
   .cohereresp_msg    (cohereresp_msg),

   // control signals (ctrl->dpath)
   .amo_sel           (amo_sel),
   .cachereq_en       (cachereq_en),
   .memresp_en        (memresp_en),
   .is_refill         (is_refill),
   .tag_array_0_wen   (tag_array_0_wen),
   .tag_array_0_ren   (tag_array_0_ren),
   .tag_array_1_wen   (tag_array_1_wen),
   .tag_array_1_ren   (tag_array_1_ren),
   .way_sel           (way_sel),
   .data_array_wen    (data_array_wen),
   .data_array_ren    (data_array_ren),
   .data_array_wben   (data_array_wben),
   .read_data_reg_en  (read_data_reg_en),
   .read_tag_reg_en   (read_tag_reg_en),
   .read_byte_sel     (read_byte_sel),
   .memreq_type       (memreq_type),
   .cacheresp_type    (cacheresp_type),

   // status signals  (dpath->ctrl)
   .cachereq_type     (cachereq_type),
   .cachereq_addr     (cachereq_addr),
   .tag_match_0       (tag_match_0),
   .tag_match_1       (tag_match_1),
   .sd                (sd)
  );


  //----------------------------------------------------------------------
  // Line tracing
  //----------------------------------------------------------------------
  `include "vc-trace-tasks.v"

  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    case ( ctrl.state_reg )

      ctrl.STATE_IDLE:                  vc_trace_str( trace, "(I )" );
      ctrl.STATE_TAG_CHECK:             vc_trace_str( trace, "(TC)" );
      ctrl.STATE_READ_DATA_ACCESS:      vc_trace_str( trace, "(RD)" );
      ctrl.STATE_WRITE_DATA_ACCESS:     vc_trace_str( trace, "(WD)" );
      ctrl.STATE_AMO_READ_DATA_ACCESS:  vc_trace_str( trace, "(AR)" );
      ctrl.STATE_AMO_WRITE_DATA_ACCESS: vc_trace_str( trace, "(AW)" );
      ctrl.STATE_INIT_DATA_ACCESS:      vc_trace_str( trace, "(IN)" );
      ctrl.STATE_REFILL_REQUEST:        vc_trace_str( trace, "(RR)" );
      ctrl.STATE_REFILL_WAIT:           vc_trace_str( trace, "(RW)" );
      ctrl.STATE_REFILL_UPDATE:         vc_trace_str( trace, "(RU)" );
      ctrl.STATE_EVICT_PREPARE:         vc_trace_str( trace, "(EP)" );
      ctrl.STATE_EVICT_REQUEST:         vc_trace_str( trace, "(ER)" );
      ctrl.STATE_EVICT_WAIT:            vc_trace_str( trace, "(EW)" );
      ctrl.STATE_WAIT:                  vc_trace_str( trace, "(W )" );
      default:                          vc_trace_str( trace, "(? )" );

    endcase

  end
  endtask

endmodule

`endif
