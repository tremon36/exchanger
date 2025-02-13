`timescale 1ns / 1ps

module DOGX_digital_converter (
    input wire CLK_24M,
    input wire reset,
    input wire [8:0] counter_HSNR_p,
    input wire [8:0] counter_HSNR_n,
    input wire [8:0] counter_HDR_p,
    input wire [8:0] counter_HDR_n,
    input wire [8:0] alpha_th_high,
    input wire [8:0] alpha_th_low,
    input wire [4:0] alpha_timeout_mask,
    input wire operation_mode,
    input wire [23:0] HSNR_offset_gain_pos,
    input wire [23:0] HSNR_offset_gain_neg,
    input wire alpha_in,
    output wire alpha_out,
    output wire [10:0] converter_output,
    output wire clock_3M_out
);

  // Clock gate enable generation

  logic enable_3M;
  logic enable_6M;
  logic generated_3M_output_clock;

  clockgen cg_enable_generator (
      .CLK_24M(CLK_24M),
      .reset(reset),
      .enable_3M(enable_3M),
      .enable_6M(enable_6M),
      .generated_3M_output_clock(generated_3M_output_clock)
  );

  // HDR and HSNR channels

  logic [ 8:0] HSNR_ns_output;
  logic [ 8:0] HDR_ns_output;

  logic [10:0] HSNR_output_extended;
  logic [10:0] HDR_output_extended;

  datapath_one_clock #(
      .N_BITS_ACC_EXT(3)
  ) HSNR_datapath (
      .enable_3M(enable_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .counter_p(counter_HSNR_p),
      .counter_n(counter_HSNR_n),
      .channel_output(HSNR_ns_output)
  );

  datapath_one_clock #(
      .N_BITS_ACC_EXT(3)
  ) HDR_datapath (
      .enable_3M(enable_3M),
      .CLK_24M(CLK_24M),
      .reset(reset),
      .counter_p(counter_HDR_p),
      .counter_n(counter_HDR_n),
      .channel_output(HDR_ns_output)
  );

  // ALPHA LOGIC (ALPHA GENERATION)

  logic alpha_internal;
  assign alpha_out = alpha_internal;

  alpha_block_v2 alpha_gen (
      .clk(CLK_24M),
      .enable_sampling(enable_3M),
      .reset(reset),
      .hdr_current_value(HDR_ns_output),
      .threshold_high(alpha_th_high),
      .threshold_low(alpha_th_low),
      .timeout_mask(alpha_timeout_mask),
      .alpha(alpha_internal)
  );

  always_comb begin
    HSNR_output_extended = {{2{HSNR_ns_output[8]}}, HSNR_ns_output};
    HDR_output_extended  = {HDR_ns_output, 2'b00};
  end

  // Fifth order NS

  // Mix channels according to alpha

  logic signed [10:0] combined_channels;

  always_comb begin
    if (alpha_in) begin
      combined_channels = HSNR_output_extended;
    end else begin
      combined_channels = HDR_output_extended;
    end
  end

  logic one_bit_output;

  fifth_order_ns #(
      .NR_SIG_PATH_BITS(21)
  ) fifth_order (
      .CLK_24M(CLK_24M),
      .enable_3M(enable_3M),
      .reset(reset),
      .alpha(alpha_in),
      .HSNR_offset_gain_pos(HSNR_offset_gain_pos),
      .HSNR_offset_gain_neg(HSNR_offset_gain_neg),
      .data_i(combined_channels),
      .data_o(one_bit_output)
  );

  // Choose operation mode:
  // MODE0 - Output 11 bits at 6 MHz:
  // MODE1 - Ouput 1 bit at 3MHz (Using alpha):

  logic [10:0] converter_output_internal;

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) begin
      converter_output_internal <= 0;
    end else begin
      unique case (operation_mode)

        1'b0: begin  // Full bits
          if (enable_6M) begin
            if (generated_3M_output_clock) begin  // If clock output is 1, output HSNR
              converter_output_internal <= HDR_output_extended;
            end else begin
              converter_output_internal <= HSNR_output_extended;
            end
          end
        end

        1'b1: begin
          if (enable_3M) begin
            converter_output_internal <= {10'd0, one_bit_output};  // Place bit in the LSB position
          end
        end

      endcase
    end
  end

  assign converter_output = converter_output_internal;
  assign clock_3M_out = generated_3M_output_clock;

endmodule
