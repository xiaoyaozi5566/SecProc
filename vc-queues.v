//========================================================================
// Verilog Components: Queues
//========================================================================

`ifndef VC_QUEUES_V
`define VC_QUEUES_V

`include "vc-regs.v"
`include "vc-muxes.v"
`include "vc-regfiles.v"

//------------------------------------------------------------------------
// Defines
//------------------------------------------------------------------------

`define VC_QUEUE_NORMAL   4'b0000
`define VC_QUEUE_PIPE     4'b0001
`define VC_QUEUE_BYPASS   4'b0010

//------------------------------------------------------------------------
// Single-Element Queue Control Logic
//------------------------------------------------------------------------
// This is the control logic for a single-elment queue. It is designed to
// be attached to a storage element with a write enable. Additionally, it
// includes the ability to statically enable pipeline and/or bypass
// behavior. Pipeline behavior is when the deq_rdy signal is
// combinationally wired to the enq_rdy signal allowing elements to be
// dequeued and enqueued in the same cycle when the queue is full. Bypass
// behavior is when the enq_val signal is combinationally wired to the
// deq_val signal allowing elements to bypass the storage element if the
// storage element is empty.

module vc_QueueCtrl1
#(
  parameter p_type = `VC_QUEUE_NORMAL
)(
  input  {L} clk,
  input  {L} reset,

  input  {Domain sd} enq_val,        // Enqueue data is valid
  output {Domain sd} enq_rdy,        // Ready for producer to do an enqueue

  output {Domain sd} deq_val,        // Dequeue data is valid
  input  {Domain sd} deq_rdy,        // Consumer is ready to do a dequeue

  output {Domain sd} write_en,       // Write en signal to wire up to storage element
  output {Domain sd} bypass_mux_sel, // Used to control bypass mux for bypass queues
  output {Domain sd} num_free_entries, // Either zero or one
  input  {L} sd
);

  // Status register

  reg  {Domain sd} full;
  wire {Domain sd} full_next;

  always @ (posedge clk) begin
    full <= reset ? 0 : full_next;
  end

  assign num_free_entries = full ? 0 : 1;

  // Determine if pipeline or bypass behavior is enabled

  localparam c_pipe_en   = |( p_type & `VC_QUEUE_PIPE   );
  localparam c_bypass_en = |( p_type & `VC_QUEUE_BYPASS );

  // We enq/deq only when they are both ready and valid

  wire {Domain sd} do_enq = enq_rdy && enq_val;
  wire {Domain sd} do_deq = deq_rdy && deq_val;

  // Determine if we have pipeline or bypass behaviour and
  // set the write enable accordingly.

  wire {Domain sd} empty     = ~full;
  wire {Domain sd} do_pipe   = c_pipe_en   && full  && do_enq && do_deq;
  wire {Domain sd} do_bypass = c_bypass_en && empty && do_enq && do_deq;

  assign write_en = do_enq && ~do_bypass;

  // Regardless of the type of queue or whether or not we are actually
  // doing a bypass, if the queue is empty then we select the enq bits,
  // otherwise we select the output of the queue state elements.

  assign bypass_mux_sel = empty;

  // Ready signals are calculated from full register. If pipeline
  // behavior is enabled, then the enq_rdy signal is also calculated
  // combinationally from the deq_rdy signal. If bypass behavior is
  // enabled then the deq_val signal is also calculated combinationally
  // from the enq_val signal.

  assign enq_rdy  = ~full  || ( c_pipe_en   && full  && deq_rdy );
  assign deq_val  = ~empty || ( c_bypass_en && empty && enq_val );

  // Control logic for the full register input

  assign full_next = ( do_deq && ~do_pipe )   ? 1'b0
                   : ( do_enq && ~do_bypass ) ? 1'b1
                   :                            full;

endmodule

//------------------------------------------------------------------------
// Single-Element Queue Datapath
//------------------------------------------------------------------------
// This is the datpath for single element queues. It includes a register
// and a bypass mux if needed.

module vc_QueueDpath1
#(
  parameter p_type      = `VC_QUEUE_NORMAL,
  parameter p_msg_nbits = 1
)(
  input                    {L} clk,
  input                    {L} reset,
  input                    {Domain sd} write_en,
  input                    {Domain sd} bypass_mux_sel,
  input  [p_msg_nbits-1:0] {Domain sd} enq_msg,
  output [p_msg_nbits-1:0] {Domain sd} deq_msg,
  input                    {L} sd
);

  // Queue storage

  wire [p_msg_nbits-1:0] {Domain sd} qstore;

  vc_EnReg#(p_msg_nbits) qstore_reg
  (
    .clk   (clk),
    .reset (reset),
    .en    (write_en),
    .d     (enq_msg),
    .q     (qstore),
    .sd    (sd)
  );

  // Bypass muxing

  generate
  if ( |(p_type & `VC_QUEUE_BYPASS ) )

    vc_Mux2#(p_msg_nbits) bypass_mux
    (
      .in0 (qstore),
      .in1 (enq_msg),
      .sel (bypass_mux_sel),
      .out (deq_msg),
      .sd  (sd)
    );

  else
    assign deq_msg = qstore;
  endgenerate

endmodule

//------------------------------------------------------------------------
// Multi-Element Queue Control Logic
//------------------------------------------------------------------------
// This is the control logic for a multi-elment queue. It is designed to
// be attached to a Regfile storage element. Additionally, it includes
// the ability to statically enable pipeline and/or bypass behavior.
// Pipeline behavior is when the deq_rdy signal is combinationally wired
// to the enq_rdy signal allowing elements to be dequeued and enqueued in
// the same cycle when the queue is full. Bypass behavior is when the
// enq_val signal is cominationally wired to the deq_val signal allowing
// elements to bypass the storage element if the storage element is
// empty.

module vc_QueueCtrl
#(
  parameter p_type     = `VC_QUEUE_NORMAL,
  parameter p_num_msgs = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits = $clog2(p_num_msgs)
)(
  input                     {L} clk, reset,

  input                     {Domain sd} enq_val,        // Enqueue data is valid
  output                    {Domain sd} enq_rdy,        // Ready for producer to enqueue

  output                    {Domain sd} deq_val,        // Dequeue data is valid
  input                     {Domain sd} deq_rdy,        // Consumer is ready to dequeue

  output                    {Domain sd} write_en,       // Wen to wire to regfile
  output [c_addr_nbits-1:0] {Domain sd} write_addr,     // Waddr to wire to regfile
  output [c_addr_nbits-1:0] {Domain sd} read_addr,      // Raddr to wire to regfile
  output                    {Domain sd} bypass_mux_sel, // Control mux for bypass queues
  output [c_addr_nbits:0]   {Domain sd} num_free_entries, // Num of free entries in queue
  input                     {L} sd
);

  // Enqueue and dequeue pointers

  wire [c_addr_nbits-1:0] {Domain sd} enq_ptr;
  wire [c_addr_nbits-1:0] {Domain sd} enq_ptr_next;

  vc_ResetReg#(c_addr_nbits) enq_ptr_reg
  (
    .clk     (clk),
    .reset   (reset),
    .d       (enq_ptr_next),
    .q       (enq_ptr),
    .sd      (sd)
  );

  wire [c_addr_nbits-1:0] {Domain sd} deq_ptr;
  wire [c_addr_nbits-1:0] {Domain sd} deq_ptr_next;

  vc_ResetReg#(c_addr_nbits) deq_ptr_reg
  (
    .clk   (clk),
    .reset (reset),
    .d     (deq_ptr_next),
    .q     (deq_ptr),
    .sd    (sd)
  );

  assign write_addr = enq_ptr;
  assign read_addr  = deq_ptr;

  // Extra state to tell difference between full and empty

  wire {Domain sd} full;
  wire {Domain sd} full_next;

  vc_ResetReg#(1) full_reg
  (
    .clk   (clk),
    .reset (reset),
    .d     (full_next),
    .q     (full),
    .sd    (sd)
  );

  // Determine if pipeline or bypass behavior is enabled

  localparam c_pipe_en   = |( p_type & `VC_QUEUE_PIPE   );
  localparam c_bypass_en = |( p_type & `VC_QUEUE_BYPASS );

  // We enq/deq only when they are both ready and valid

  wire {Domain sd} do_enq = enq_rdy && enq_val;
  wire {Domain sd} do_deq = deq_rdy && deq_val;

  // Determine if we have pipeline or bypass behaviour and
  // set the write enable accordingly.

  wire   {Domain sd} empty     = ~full && (enq_ptr == deq_ptr);
  wire   {Domain sd} do_pipe   = c_pipe_en   && full  && do_enq && do_deq;
  wire   {Domain sd} do_bypass = c_bypass_en && empty && do_enq && do_deq;

  assign write_en = do_enq && ~do_bypass;

  // Regardless of the type of queue or whether or not we are actually
  // doing a bypass, if the queue is empty then we select the enq bits,
  // otherwise we select the output of the queue state elements.

  assign bypass_mux_sel = empty;

  // Ready signals are calculated from full register. If pipeline
  // behavior is enabled, then the enq_rdy signal is also calculated
  // combinationally from the deq_rdy signal. If bypass behavior is
  // enabled then the deq_val signal is also calculated combinationally
  // from the enq_val signal.

  assign enq_rdy  = ~full  || ( c_pipe_en   && full  && deq_rdy );
  assign deq_val  = ~empty || ( c_bypass_en && empty && enq_val );

  // Control logic for the enq/deq pointers and full register

  wire [c_addr_nbits-1:0] {Domain sd} deq_ptr_plus1 = deq_ptr + 1'b1;
  wire [c_addr_nbits-1:0] {Domain sd} deq_ptr_inc
    = (deq_ptr_plus1 == p_num_msgs) ? {c_addr_nbits{1'b0}} : deq_ptr_plus1;

  wire [c_addr_nbits-1:0] {Domain sd} enq_ptr_plus1 = enq_ptr + 1'b1;
  wire [c_addr_nbits-1:0] {Domain sd} enq_ptr_inc
    = (enq_ptr_plus1 == p_num_msgs) ? {c_addr_nbits{1'b0}} : enq_ptr_plus1;

  assign deq_ptr_next
    = ( do_deq && ~do_bypass ) ? ( deq_ptr_inc ) : deq_ptr;

  assign enq_ptr_next
    = ( do_enq && ~do_bypass ) ? ( enq_ptr_inc ) : enq_ptr;

  assign full_next
    = ( do_enq && ~do_deq && ( enq_ptr_inc == deq_ptr ) ) ? 1'b1
    : ( do_deq && full && ~do_pipe )                      ? 1'b0
    :                                                       full;

  // Number of free entries

  assign num_free_entries
    = full                ? {(c_addr_nbits+1){1'b0}}
    : empty               ? p_num_msgs[c_addr_nbits:0]
    : (enq_ptr > deq_ptr) ? p_num_msgs[c_addr_nbits:0] - (enq_ptr - deq_ptr)
    : (deq_ptr > enq_ptr) ? deq_ptr - enq_ptr
    :                       {(c_addr_nbits+1){1'bx}};

endmodule

//------------------------------------------------------------------------
// Multi-Element Queue Datapath
//------------------------------------------------------------------------
// This is the datpath for multi-element queues. It includes a register
// and a bypass mux if needed.

module vc_QueueDpath
#(
  parameter p_type      = `VC_QUEUE_NORMAL,
  parameter p_msg_nbits = 4,
  parameter p_num_msgs  = 2,

  // Local constants not meant to be set from outside the module
  parameter c_addr_nbits = $clog2(p_num_msgs)
)(
  input                     {L} clk,
  input                     {L} reset,
  input                     {Domain sd} write_en,
  input                     {Domain sd} bypass_mux_sel,
  input  [c_addr_nbits-1:0] {Domain sd} write_addr,
  input  [c_addr_nbits-1:0] {Domain sd} read_addr,
  input   [p_msg_nbits-1:0] {Domain sd} enq_msg,
  output  [p_msg_nbits-1:0] {Domain sd} deq_msg,
  input                     {L} sd
);

  // Queue storage

  wire [p_msg_nbits-1:0] {Domain sd} read_data;

  vc_Regfile_1r1w#(p_msg_nbits,p_num_msgs) qstore
  (
    .clk        (clk),
    .reset      (reset),
    .read_addr  (read_addr),
    .read_data  (read_data),
    .write_en   (write_en),
    .write_addr (write_addr),
    .write_data (enq_msg),
    .sd         (sd)
  );

  // Bypass muxing

  generate
  if ( |(p_type & `VC_QUEUE_BYPASS ) )

    vc_Mux2#(p_msg_nbits) bypass_mux
    (
      .in0 (read_data),
      .in1 (enq_msg),
      .sel (bypass_mux_sel),
      .out (deq_msg),
      .sd  (sd)
    );

  else
    assign deq_msg = read_data;
  endgenerate

endmodule

//------------------------------------------------------------------------
// Queue
//------------------------------------------------------------------------

module vc_Queue
#(
  parameter p_type      = `VC_QUEUE_NORMAL,
  parameter p_msg_nbits = 1,
  parameter p_num_msgs  = 2,

  // parameters not meant to be set outside this module
  parameter c_addr_nbits = $clog2(p_num_msgs)
)(
  input                    {L} clk,
  input                    {L} reset,

  input                    {Domain cur_sd} enq_val,
  output                   {Domain cur_sd} enq_rdy,
  input  [p_msg_nbits-1:0] {Domain cur_sd} enq_msg,

  output                   {Domain cur_sd} deq_val,
  input                    {Domain cur_sd} deq_rdy,
  output [p_msg_nbits-1:0] {Domain cur_sd} deq_msg,

  output [c_addr_nbits:0]  {Domain cur_sd} num_free_entries,
  input                    {L} cur_sd
);


  generate
  if ( p_num_msgs == 1 )
  begin

    wire {Domain cur_sd} write_en;
    wire {Domain cur_sd} bypass_mux_sel;

    vc_QueueCtrl1#(p_type) ctrl
    (
      .clk              (clk),
      .reset            (reset),
      .enq_val          (enq_val),
      .enq_rdy          (enq_rdy),
      .deq_val          (deq_val),
      .deq_rdy          (deq_rdy),
      .write_en         (write_en),
      .bypass_mux_sel   (bypass_mux_sel),
      .num_free_entries (num_free_entries),
      .sd               (cur_sd)
    );

    vc_QueueDpath1#(p_type,p_msg_nbits) dpath
    (
      .clk            (clk),
      .reset          (reset),
      .write_en       (write_en),
      .bypass_mux_sel (bypass_mux_sel),
      .enq_msg        (enq_msg),
      .deq_msg        (deq_msg),
      .sd             (cur_sd)
    );

  end
  else
  begin

    wire                    {Domain cur_sd} write_en;
    wire                    {Domain cur_sd} bypass_mux_sel;
    wire [c_addr_nbits-1:0] {Domain cur_sd} write_addr;
    wire [c_addr_nbits-1:0] {Domain cur_sd} read_addr;

    vc_QueueCtrl#(p_type,p_num_msgs) ctrl
    (
      .clk              (clk),
      .reset            (reset),
      .enq_val          (enq_val),
      .enq_rdy          (enq_rdy),
      .deq_val          (deq_val),
      .deq_rdy          (deq_rdy),
      .write_en         (write_en),
      .write_addr       (write_addr),
      .read_addr        (read_addr),
      .bypass_mux_sel   (bypass_mux_sel),
      .num_free_entries (num_free_entries),
      .sd               (cur_sd)
    );

    vc_QueueDpath#(p_type,p_msg_nbits,p_num_msgs) dpath
    (
      .clk              (clk),
      .reset            (reset),
      .write_en         (write_en),
      .bypass_mux_sel   (bypass_mux_sel),
      .write_addr       (write_addr),
      .read_addr        (read_addr),
      .enq_msg          (enq_msg),
      .deq_msg          (deq_msg),
      .sd               (cur_sd)
    );

  end
  endgenerate

  // Assertions

  always @( posedge clk ) begin
    if ( !reset ) begin
      `VC_ASSERT_NOT_X( enq_val );
      `VC_ASSERT_NOT_X( enq_rdy );
      `VC_ASSERT_NOT_X( deq_val );
      `VC_ASSERT_NOT_X( deq_rdy );
    end
  end

  // Line Tracing

  `include "vc-trace-tasks.v"

  reg [`VC_TRACE_NBITS_TO_NCHARS(p_msg_nbits)*8-1:0] str;
  task trace_module( inout [vc_trace_nbits-1:0] trace );
  begin

    $sformat( str, "%x", enq_msg );
    vc_trace_str_val_rdy( trace, enq_val, enq_rdy, str );

    vc_trace_str( trace, "(" );
    $sformat( str, "%x", p_num_msgs-num_free_entries );
    vc_trace_str( trace, str );
    vc_trace_str( trace, ")" );

    $sformat( str, "%x", deq_msg );
    vc_trace_str_val_rdy( trace, deq_val, deq_rdy, str );

  end
  endtask

endmodule

`endif /* VC_QUEUES_V */

