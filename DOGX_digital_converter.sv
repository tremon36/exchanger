`timescale 1ns / 1ps

import include_local_constants::*;

module DOGX_digital_converter (
    input wire CLK_24M,
    input wire CLK_3M,
    input wire reset,
    input wire [5:0] counter_HSNR_p_gray,
    input wire [5:0] counter_HSNR_n_gray,
    input wire [5:0] counter_HDR_p_gray,
    input wire [5:0] counter_HDR_n_gray,
    input wire enable_HSNR,
    input wire enable_HDR,
    input wire [8:0] alpha_th_high,
    input wire [8:0] alpha_th_low,
    input wire [4:0] alpha_timeout_mask,
    input wire operation_mode,
    input wire enable_dc_filter,
    input wire [23:0] HSNR_offset_gain_pos,
    input wire [23:0] HSNR_offset_gain_neg,
    input wire alpha_in,
    output wire alpha_out,
    output wire [10:0] converter_output
);

  // HDR and HSNR channels

  logic signed [8:0] HSNR_ns_output;
  logic signed [8:0] HDR_ns_output;

  logic [11:0] counter_HSNR_p;
  logic [11:0] counter_HSNR_n;
  logic [11:0] counter_HDR_p;
  logic [11:0] counter_HDR_n;

  gray2bin_ext gray2bin_HSNR_p (
    .CLK_24M(CLK_24M),
    .reset(reset),
    .gray(counter_HSNR_p_gray),
    .bin_extended(counter_HSNR_p)
  );

  gray2bin_ext gray2bin_HSNR_n (
    .CLK_24M(CLK_24M),
    .reset(reset),
    .gray(counter_HSNR_n_gray),
    .bin_extended(counter_HSNR_n)
  );

  gray2bin_ext gray2bin_HDR_p (
    .CLK_24M(CLK_24M),
    .reset(reset),
    .gray(counter_HDR_p_gray),
    .bin_extended(counter_HDR_p)
  );

  gray2bin_ext gray2bin_HDR_n (
    .CLK_24M(CLK_24M),
    .reset(reset),
    .gray(counter_HDR_n_gray),
    .bin_extended(counter_HDR_n)
  );

  datapath_two_clocks #(
      .N_DIV(3)
  ) HSNR_datapath (
      .CLK_3M(CLK_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .enable(enable_HSNR),
      .counter_p(counter_HSNR_p),
      .counter_n(counter_HSNR_n),
      .channel_output(HSNR_ns_output)
  );

  datapath_two_clocks #(
      .N_DIV(3)
  ) HDR_datapath (
      .CLK_3M(CLK_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .enable(enable_HDR),
      .counter_p(counter_HDR_p),
      .counter_n(counter_HDR_n),
      .channel_output(HDR_ns_output)
  );

  // DC filters

  logic signed [31:0] HSNR_filtered_32b;
  logic signed [31:0] HDR_filtered_32b;
  logic signed [22:0] HSNR_filtered_23b;
  logic signed [22:0] HDR_filtered_23b;

  dc_filter filter_HSNR(
    .reset(reset),
    .CLK_3M(CLK_3M),
    .enable(enable_HSNR && enable_dc_filter),
    .c_data(HSNR_ns_output),
    .filter_out(HSNR_filtered_32b)
  );

  assign HSNR_filtered_23b = $signed(HSNR_filtered_32b[31:11] + HSNR_filtered_32b[10]); // Round filter output to 21 bits, apply sign extension for combination

  dc_filter filter_HDR(
    .reset(reset),
    .CLK_3M(CLK_3M),
    .enable(enable_HDR && enable_dc_filter),
    .c_data(HDR_ns_output),
    .filter_out(HDR_filtered_32b)
  );

  assign HDR_filtered_23b = $signed((HDR_filtered_32b[31:11] + HDR_filtered_32b[10])) << 2; // Round filter output to 21 bits, apply gain of 2 for combination

  // ALPHA LOGIC (ALPHA GENERATION)

  logic alpha_internal;
  assign alpha_out = alpha_internal;

  alpha_block_v2 alpha_gen (
      .CLK_3M(CLK_3M),
      .reset(reset),
      .hdr_current_value(HDR_ns_output),
      .threshold_high(alpha_th_high),
      .threshold_low(alpha_th_low),
      .timeout_mask(alpha_timeout_mask),
      .alpha(alpha_internal)
  );

  // Fifth order NS

  // Mix channels according to alpha

  logic signed [22:0] combined_channels;

  always_comb begin
    if (alpha_in == `ALPHA_SELECT_HDR) begin
      if(enable_dc_filter) begin
        combined_channels = HDR_filtered_23b;
      end else begin
        combined_channels = $signed(HDR_ns_output) << 14;  // 14, << 2 for gain adjustment and << 12 for decimal adjustment
      end
    end else begin
      if(enable_dc_filter) begin
        combined_channels = HSNR_filtered_23b;
      end else begin
        combined_channels = $signed(HSNR_ns_output) << 12;
      end
    end
  end

  logic one_bit_output;
  logic one_bit_output_pl;  // pipeline reg for output (barely any cost and useful)

  always_ff @(posedge CLK_3M) begin
    if(!operation_mode) begin
      one_bit_output_pl <= one_bit_output;
    end
  end

  fifth_order_ns #(
      .NR_SIG_PATH_BITS(21)
  ) fifth_order (
      .CLK_3M(CLK_3M),
      .reset(reset),
      .enable(operation_mode == `OP_MODE_FIFTH_ORDER),
      .alpha(alpha_in),
      .HSNR_offset_gain_pos(HSNR_offset_gain_pos),
      .HSNR_offset_gain_neg(HSNR_offset_gain_neg),
      .data_i(combined_channels),
      .data_o(one_bit_output)
  );

  // Choose operation mode:
  // MODE0 - Output 1 bits at 3 MHz:
  // MODE1 - Ouput 11 bit according to alpha:

  logic [10:0] converter_output_internal;

  always_comb begin
    if (operation_mode == `OP_MODE_FIFTH_ORDER) begin
      converter_output_internal = {10'd0, one_bit_output_pl};
    end else begin
      if (alpha_in == `ALPHA_SELECT_HDR) begin
        converter_output_internal = $signed(HDR_ns_output << 2); 
      end else begin
        converter_output_internal = $signed(HSNR_ns_output);
      end
    end
  end

  assign converter_output = converter_output_internal;

endmodule
