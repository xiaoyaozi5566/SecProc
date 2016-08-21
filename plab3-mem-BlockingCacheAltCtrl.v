//=========================================================================
// Alternative Blocking Cache Control
//=========================================================================

`ifndef PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V
`define PLAB3_MEM_BLOCKING_CACHE_ALT_CTRL_V

`include "plab3-mem-DecodeWben.v"
`include "vc-mem-msgs.v"
`include "vc-assert.v"
`include "vc-regfiles.v"
`include "vc-regs.v"

module plab3_mem_BlockingCacheAltCtrl
#(
  parameter size    = 256,            // Cache size in bytes

  parameter p_idx_shamt = 0,

  parameter p_opaque_nbits  = 8,

  // local parameters not meant to be set from outside
  parameter dbw     = 32,             // Short name for data bitwidth
  parameter abw     = 32,             // Short name for addr bitwidth
  parameter clw     = 128,            // Short name for cacheline bitwidth
  parameter nblocks = size*8/clw,     // Number of blocks in the cache

  parameter o = p_opaque_nbits
)
(
  input                                               {L} clk,
  input                                               {L} reset,

  // Cache Request

  input                                               {Domain sd} cachereq_val,
  output reg                                          {Domain sd} cachereq_rdy,

  // Cache Response

  output reg                                          {Domain sd} cacheresp_val,
  input                                               {Domain sd} cacheresp_rdy,

  // Memory Request

  output reg                                          {Domain sd} memreq_val,
  input                                               {Domain sd} memreq_rdy,

  // Memory Response

  input                                               {Domain sd} memresp_val,
  output reg                                          {Domain sd} memresp_rdy,
  
  // Coherent Memory Request
  
  input                                               {Domain sd} coherereq_val,
  
  // Coherent Memory Response
  
  output                                              {Domain sd} cohereresp_val,
  input                                               {Domain sd} cohereresp_rdy,
  
  // control signals (ctrl->dpath)
  output reg [1:0]                                    {Domain sd} amo_sel,
  output reg                                          {Domain sd} cachereq_en,
  output reg                                          {Domain sd} memresp_en,
  output reg                                          {Domain sd} is_refill,
  output reg                                          {Domain sd} tag_array_0_wen,
  output reg                                          {Domain sd} tag_array_0_ren,
  output reg                                          {Domain sd} tag_array_1_wen,
  output reg                                          {Domain sd} tag_array_1_ren,
  output                                              {Domain sd} way_sel,
  output reg                                          {Domain sd} data_array_wen,
  output reg                                          {Domain sd} data_array_ren,
  // width of cacheline divided by number of bits per byte
  output reg [clw/8-1:0]                              {Domain sd} data_array_wben,
  output reg                                          {Domain sd} read_data_reg_en,
  output reg                                          {Domain sd} read_tag_reg_en,
  output [$clog2(clw/dbw)-1:0]                        {Domain sd} read_byte_sel,
  output reg [`VC_MEM_RESP_MSG_TYPE_NBITS(o,clw)-1:0] {Domain sd} memreq_type,
  output reg [`VC_MEM_RESP_MSG_TYPE_NBITS(o,dbw)-1:0] {Domain sd} cacheresp_type,
  output reg [1:0]                                    {Domain sd} req_sel,

   // status signals (dpath->ctrl)
  input [`VC_MEM_REQ_MSG_TYPE_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_type,
  input [`VC_MEM_REQ_MSG_ADDR_NBITS(o,abw,dbw)-1:0]   {Domain sd} cachereq_addr,
  input                                               {Domain sd} tag_match_0,
  input                                               {Domain sd} tag_match_1,
  input                                               {L} sd
 );

  //----------------------------------------------------------------------
  // State Definitions
  //----------------------------------------------------------------------

  localparam STATE_IDLE               = 5'd0;
  localparam STATE_TAG_CHECK          = 5'd1;
  localparam STATE_READ_DATA_ACCESS   = 5'd2;
  localparam STATE_WRITE_DATA_ACCESS  = 5'd3;
  localparam STATE_WAIT               = 5'd4;
  localparam STATE_REFILL_REQUEST     = 5'd5;
  localparam STATE_REFILL_WAIT        = 5'd6;
  localparam STATE_REFILL_UPDATE      = 5'd7;
  localparam STATE_EVICT_PREPARE      = 5'd8;
  localparam STATE_EVICT_REQUEST      = 5'd9;
  localparam STATE_EVICT_WAIT         = 5'd10;
  localparam STATE_AMO_READ_DATA_ACCESS  = 5'd11;
  localparam STATE_AMO_WRITE_DATA_ACCESS = 5'd12;
  localparam STATE_INIT_DATA_ACCESS   = 5'd15;
  localparam STATE_COHERE_EVICT_REQUEST  = 5'd13;
  localparam STATE_COHERE_EVICT_PREPARE  = 5'd14;
  localparam STATE_EXTRA_WAIT         = 5'd16;

  //----------------------------------------------------------------------
  // Handle Normal Requests and Coherent Requests Arriving at the same time
  //----------------------------------------------------------------------
  reg {Domain sd} flag;
  
  //----------------------------------------------------------------------
  // State
  //----------------------------------------------------------------------

  always @( posedge clk ) begin
    if ( reset ) begin
      state_reg <= STATE_IDLE;
    end
    else begin
      state_reg <= state_next;
    end
  end

  //----------------------------------------------------------------------
  // State Transitions
  //----------------------------------------------------------------------

  wire {Domain sd} in_go        = ( cachereq_val || coherereq_val )  && cachereq_rdy;
  wire {Domain sd} out_go       = cacheresp_val && cacheresp_rdy;
  wire {Domain sd} hit_0        = is_valid_0 && tag_match_0;
  wire {Domain sd} hit_1        = is_valid_1 && tag_match_1;
  wire {Domain sd} hit          = hit_0 || hit_1;
  wire {Domain sd} is_read      = cachereq_type == `VC_MEM_REQ_MSG_TYPE_READ;
  wire {Domain sd} is_write     = cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE;
  wire {Domain sd} is_init      = cachereq_type == `VC_MEM_REQ_MSG_TYPE_WRITE_INIT;
  wire {Domain sd} is_getM      = cachereq_type == `VC_MEM_REQ_MSG_TYPE_GETM;
  wire {Domain sd} is_amo       = amo_sel != 0;
  wire {Domain sd} read_hit     = is_read && hit;
  wire {Domain sd} write_hit    = is_write && hit;
  wire {Domain sd} amo_hit      = is_amo && hit;
  wire {Domain sd} cohere_hit   = is_getM && hit;
  wire {Domain sd} miss_0       = !hit_0;
  wire {Domain sd} miss_1       = !hit_1;
  wire {Domain sd} refill       = (miss_0 && !is_dirty_0 && !lru_way) || (miss_1 && !is_dirty_1 && lru_way);
  wire {Domain sd} evict        = (miss_0 && is_dirty_0 && !lru_way) || (miss_1 && is_dirty_1 && lru_way);

  reg [3:0] {Domain sd} state_reg;
  reg [3:0] {Domain sd} state_next;

  always @(*) begin

    state_next = state_reg;
    case ( state_reg )

      STATE_IDLE:
             if ( in_go && cachereq_val && coherereq_val ) begin
                 state_next = STATE_TAG_CHECK;
                 req_sel = 2'd0;
                 flag = 1'b1;
             end
             else if ( in_go && !cachereq_val && coherereq_val ) begin
                 state_next = STATE_TAG_CHECK;
                 req_sel = 2'd1;
                 flag = 1'b0;
             end
             else if ( in_go && cachereq_val && !coherereq_val ) begin
                 state_next = STATE_TAG_CHECK;
                 req_sel = 2'd0;
                 flag = 1'b0;
             end

      STATE_TAG_CHECK:
             if ( is_init      ) state_next = STATE_INIT_DATA_ACCESS;
        else if ( read_hit     ) state_next = STATE_READ_DATA_ACCESS;
        else if ( write_hit    ) state_next = STATE_WRITE_DATA_ACCESS;
        else if ( cohere_hit   ) state_next = STATE_COHERE_EVICT_PREPARE;
        else if ( amo_hit      ) state_next = STATE_AMO_READ_DATA_ACCESS;
        else if ( refill       ) state_next = STATE_REFILL_REQUEST;
        else if ( evict        ) state_next = STATE_EVICT_PREPARE;

      STATE_READ_DATA_ACCESS:
        state_next = STATE_WAIT;

      STATE_WRITE_DATA_ACCESS:
        state_next = STATE_WAIT;

      STATE_INIT_DATA_ACCESS:
        state_next = STATE_WAIT;

      STATE_AMO_READ_DATA_ACCESS:
        state_next = STATE_AMO_WRITE_DATA_ACCESS;

      STATE_AMO_WRITE_DATA_ACCESS:
        state_next = STATE_WAIT;

      STATE_REFILL_REQUEST:
             if ( memreq_rdy   ) state_next = STATE_REFILL_WAIT;
        else if ( !memreq_rdy  ) state_next = STATE_REFILL_REQUEST;

      STATE_REFILL_WAIT:
             if ( memresp_val  ) state_next = STATE_REFILL_UPDATE;
        else if ( !memresp_val ) state_next = STATE_REFILL_WAIT;

      STATE_REFILL_UPDATE:
             if ( is_read      ) state_next = STATE_READ_DATA_ACCESS;
        else if ( is_write     ) state_next = STATE_WRITE_DATA_ACCESS;
        else if ( is_amo       ) state_next = STATE_AMO_READ_DATA_ACCESS;

      STATE_COHERE_EVICT_PREPARE:
        state_next = STATE_COHERE_EVICT_REQUEST;
      
      STATE_COHERE_EVICT_REQUEST:
             if (cohereresp_rdy)  state_next = STATE_IDLE;
        else if (!cohereresp_rdy) state_next = STATE_COHERE_EVICT_REQUEST;
        
      STATE_EVICT_PREPARE:
        state_next = STATE_EVICT_REQUEST;

      STATE_EVICT_REQUEST:
             if ( memreq_rdy   ) state_next = STATE_EVICT_WAIT;
        else if ( !memreq_rdy  ) state_next = STATE_EVICT_REQUEST;

      STATE_EVICT_WAIT:
             if ( memresp_val  ) state_next = STATE_REFILL_REQUEST;
        else if ( !memresp_val ) state_next = STATE_EVICT_WAIT;

      STATE_WAIT:
             if ( out_go && flag == 1'b0 ) state_next = STATE_IDLE;
        else if ( out_go && flag == 1'b1 ) begin
            state_next = STATE_EXTRA_WAIT;
            flag = 1'b0;
            req_sel = 2'd2;
        end
      
      STATE_EXTRA_WAIT:
          state_next = STATE_TAG_CHECK;
    endcase

  end

  //----------------------------------------------------------------------
  // Valid/Dirty bits record
  //----------------------------------------------------------------------

  wire [2:0] {Domain sd} cachereq_idx = cachereq_addr[4+p_idx_shamt +: 3];
  reg        {Domain sd} valid_bit_in;
  reg        {Domain sd} valid_bits_write_en;
  wire       {Domain sd} valid_bits_write_en_0 = valid_bits_write_en && !way_sel;
  wire       {Domain sd} valid_bits_write_en_1 = valid_bits_write_en && way_sel;
  wire       {Domain sd} is_valid_0;
  wire       {Domain sd} is_valid_1;

  vc_ResetRegfile_1r1w#(1,8) valid_bits_0
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (cachereq_idx),
    .read_data  (is_valid_0),
    .write_en   (valid_bits_write_en_0),
    .write_addr (cachereq_idx),
    .write_data (valid_bit_in),
    .sd         (sd)
  );

  vc_ResetRegfile_1r1w#(1,8) valid_bits_1
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (cachereq_idx),
    .read_data  (is_valid_1),
    .write_en   (valid_bits_write_en_1),
    .write_addr (cachereq_idx),
    .write_data (valid_bit_in),
    .sd         (sd)
  );

  reg        {Domain sd} dirty_bit_in;
  reg        {Domain sd} dirty_bits_write_en;
  wire       {Domain sd} dirty_bits_write_en_0 = dirty_bits_write_en && !way_sel;
  wire       {Domain sd} dirty_bits_write_en_1 = dirty_bits_write_en && way_sel;
  wire       {Domain sd} is_dirty_0;
  wire       {Domain sd} is_dirty_1;

  vc_ResetRegfile_1r1w#(1,8) dirty_bits_0
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (cachereq_idx),
    .read_data  (is_dirty_0),
    .write_en   (dirty_bits_write_en_0),
    .write_addr (cachereq_idx),
    .write_data (dirty_bit_in),
    .sd         (sd)
  );

  vc_ResetRegfile_1r1w#(1,8) dirty_bits_1
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (cachereq_idx),
    .read_data  (is_dirty_1),
    .write_en   (dirty_bits_write_en_1),
    .write_addr (cachereq_idx),
    .write_data (dirty_bit_in),
    .sd         (sd)
  );

  reg        {Domain sd} lru_bit_in;
  reg        {Domain sd} lru_bits_write_en;
  wire       {Domain sd} lru_way;

  vc_ResetRegfile_1r1w#(1,8) lru_bits
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (cachereq_idx),
    .read_data  (lru_way),
    .write_en   (lru_bits_write_en),
    .write_addr (cachereq_idx),
    .write_data (lru_bit_in),
    .sd         (sd)
  );

  //----------------------------------------------------------------------
  // Way selection.
  //   The way is determined in the tag check state, and is
  //   then recorded for the entire transaction
  //----------------------------------------------------------------------

  reg        {Domain sd} way_record_en;
  reg        {Domain sd} way_record_in;

  always @(*) begin
    if (hit) begin
      way_record_in = hit_0 ? 1'b0 :
                      ( hit_1 ? 1'b1 : 1'bx );
    end
    else
      way_record_in = lru_way; // If miss, write to the LRU way
  end

  vc_EnResetReg #(1, 0) way_record
  (
    .clk    (clk),
    .reset  (reset),
    .en     (way_record_en),
    .d      (way_record_in),
    .q      (way_sel),
    .sd     (sd)
  );

  //----------------------------------------------------------------------
  // State Outputs
  //----------------------------------------------------------------------

  // General parameters
  localparam x       = 1'dx;

  // Parameters for is_refill
  localparam r_x     = 1'dx;
  localparam r_c     = 1'd0; // fill data array from _c_ache
  localparam r_m     = 1'd1; // fill data array from _m_em

  // Parameters for memreq_type_mux
  localparam m_x     = 1'dx;
  localparam m_e     = `VC_MEM_REQ_MSG_TYPE_WRITE; // write to memory in an _e_vict
  localparam m_r     = `VC_MEM_REQ_MSG_TYPE_READ;  // write to memory in a _r_efill
  localparam m_c     = `VC_MEM_REQ_MSG_TYPE_PUTM;  // write to memory in response to coherent request

  reg {Domain sd} tag_array_wen;
  reg {Domain sd} tag_array_ren;

  task cs
  (
   input cs_cachereq_rdy,
   input cs_cacheresp_val,
   input cs_memreq_val,
   input cs_memresp_rdy,
   input cs_cohereresp_val,
   input cs_cachereq_en,
   input cs_memresp_en,
   input cs_is_refill,
   input cs_tag_array_wen,
   input cs_tag_array_ren,
   input cs_data_array_wen,
   input cs_data_array_ren,
   input cs_read_data_reg_en,
   input cs_read_tag_reg_en,
   input cs_memreq_type,
   input cs_valid_bit_in,
   input cs_valid_bits_write_en,
   input cs_dirty_bit_in,
   input cs_dirty_bits_write_en,
   input cs_lru_bits_write_en,
   input cs_way_record_en
  );
  begin
    cachereq_rdy        = cs_cachereq_rdy;
    cacheresp_val       = cs_cacheresp_val;
    memreq_val          = cs_memreq_val;
    memresp_rdy         = cs_memresp_rdy;
    cohereresp_val      = cs_cohereresp_val;
    cachereq_en         = cs_cachereq_en;
    memresp_en          = cs_memresp_en;
    is_refill           = cs_is_refill;
    tag_array_wen       = cs_tag_array_wen;
    tag_array_ren       = cs_tag_array_ren;
    data_array_wen      = cs_data_array_wen;
    data_array_ren      = cs_data_array_ren;
    read_data_reg_en    = cs_read_data_reg_en;
    read_tag_reg_en     = cs_read_tag_reg_en;
    memreq_type         = cs_memreq_type;
    valid_bit_in        = cs_valid_bit_in;
    valid_bits_write_en = cs_valid_bits_write_en;
    dirty_bit_in        = cs_dirty_bit_in;
    dirty_bits_write_en = cs_dirty_bits_write_en;
    lru_bits_write_en   = cs_lru_bits_write_en;
    way_record_en       = cs_way_record_en;
  end
  endtask

  // Set outputs using a control signal "table"

  always @(*) begin
                                   cs( 0,   0,    0,  0,  0,  x,    x,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );
    case ( state_reg )
      //                              cache cache mem mem  cache mem         tag   tag   data  data  read read mem  valid valid dirty dirty lru   way
      //                              req   resp  req resp req   resp is     array array array array data tag  req  bit   write bit   write write record
      //                              rdy   val   val rdy  en    en   refill wen   ren   wen   ren   en   en   type in    en    in    en    en    en
      STATE_IDLE:                  cs( 1,   0,    0,  0,  0,  1,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_TAG_CHECK:             cs( 0,   0,    0,  0,  0,   0,    0,   r_x,   0,    1,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    1       );
      STATE_READ_DATA_ACCESS:      cs( 0,   0,    0,  0,  0,   0,    0,   r_x,   0,    0,    0,    1,    1,   0,   m_x, x,    0,    x,    0,    1,    0       );
      STATE_WRITE_DATA_ACCESS:     cs( 0,   0,    0,  0,  0,   0,    0,   r_c,   1,    0,    1,    0,    0,   0,   m_x, 1,    1,    1,    1,    1,    0       );
      STATE_INIT_DATA_ACCESS:      cs( 0,   0,    0,  0,  0,   0,    0,   r_c,   1,    0,    1,    0,    0,   0,   m_x, 1,    1,    0,    1,    1,    0       );
      STATE_AMO_READ_DATA_ACCESS:  cs( 0,   0,    0,  0,  0,   0,    0,   r_x,   0,    0,    0,    1,    1,   0,   m_x, x,    0,    x,    0,    1,    0       );
      STATE_AMO_WRITE_DATA_ACCESS: cs( 0,   0,    0,  0,  0,   0,    0,   r_c,   1,    0,    1,    0,    0,   0,   m_x, 1,    1,    1,    1,    1,    0       );
      STATE_REFILL_REQUEST:        cs( 0,   0,    1,  0,  0,   0,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_r, x,    0,    x,    0,    0,    0       );
      STATE_REFILL_WAIT:           cs( 0,   0,    0,  1,  0,   0,    1,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_REFILL_UPDATE:         cs( 0,   0,    0,  0,  0,   0,    0,   r_m,   1,    0,    1,    0,    0,   0,   m_x, 1,    1,    0,    1,    0,    0       );
      STATE_COHERE_EVICT_PREPARE:  cs( 0,   0,    0,  0,  0,   0,    0,   r_x,   0,    1,    0,    1,    1,   1,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_COHERE_EVICT_REQUEST:  cs( 0,   0,    0,  0,  1,   0,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_e, x,    0,    x,    0,    0,    0       );
      STATE_EVICT_PREPARE:         cs( 0,   0,    0,  0,  0,   0,    0,   r_x,   0,    1,    0,    1,    1,   1,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_EVICT_REQUEST:         cs( 0,   0,    1,  0,  0,   0,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_e, x,    0,    x,    0,    0,    0       );
      STATE_EVICT_WAIT:            cs( 0,   0,    0,  1,  0,   0,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_WAIT:                  cs( 0,   1,    0,  0,  0,   0,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );
      STATE_EXTRA_WAIT:            cs( 0,   0,    0,  0,  0,   1,    0,   r_x,   0,    0,    0,    0,    0,   0,   m_x, x,    0,    x,    0,    0,    0       );

    endcase
  end

  // lru bit determination
  always @(*) begin
    lru_bit_in = !way_sel;
  end

  // tag array enables

  always @(*) begin
    tag_array_0_wen = tag_array_wen && !way_sel;
    tag_array_0_ren = tag_array_ren;
    tag_array_1_wen = tag_array_wen && way_sel;
    tag_array_1_ren = tag_array_ren;
  end

  // Building data_array_wben
  // This is in control because we want to facilitate more complex patterns
  //   when we want to start supporting subword accesses

  wire [1:0]  {Domain sd} cachereq_offset = cachereq_addr[3:2];
  wire [15:0] {Domain sd} wben_decoder_out;

  plab3_mem_DecoderWben#(2) wben_decoder
  (
    .in  (cachereq_offset),
    .out (wben_decoder_out),
    .sd  (sd)
  );

  // Choose byte to read from cacheline based on what the offset was

  assign read_byte_sel = cachereq_offset;

  // determine amo type

  always @(*) begin
    case ( cachereq_type )
      `VC_MEM_REQ_MSG_TYPE_AMO_ADD: amo_sel = 2'h1;
      `VC_MEM_REQ_MSG_TYPE_AMO_AND: amo_sel = 2'h2;
      `VC_MEM_REQ_MSG_TYPE_AMO_OR : amo_sel = 2'h3;
      default                     : amo_sel = 2'h0;
    endcase
  end

  // managing the wben

  always @(*) begin
    // Logic to enable writing of the entire cacheline in case of refill and just one word for writes and init

    if ( is_refill )
      data_array_wben = 16'hffff;
    else
      data_array_wben = wben_decoder_out;

    // Managing the cache response type based on cache request type

    cacheresp_type = cachereq_type;
  end

  //----------------------------------------------------------------------
  // Assertions
  //----------------------------------------------------------------------

  always @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( cachereq_val  );
      `VC_ASSERT_NOT_X( cacheresp_rdy );
      `VC_ASSERT_NOT_X( memreq_rdy    );
      `VC_ASSERT_NOT_X( memresp_val   );
    end
  end

endmodule

`endif
