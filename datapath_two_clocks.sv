`timescale 1ns / 1ps

module datapath_two_clocks #(
    parameter int N_DIV = 3
) (
    input wire CLK_24M,
    input wire CLK_3M,
    input wire reset,
    input logic enable,
    input logic [11:0] counter_p,
    input logic [11:0] counter_n,
    output logic [8:0] channel_output
);


  logic signed [11:0] p_n_diff;
  logic signed [11:0] integrator_r;

  assign p_n_diff = counter_p - counter_n;

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) begin
      integrator_r <= 0;
    end else begin
      if (enable) begin
        integrator_r <= p_n_diff + integrator_r;
      end
    end
  end

  // Downsampling to 3M

  logic signed [11-N_DIV : 0] resample;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      resample <= 0;
    end else begin
      if (enable) begin
        resample <= (integrator_r >>> N_DIV);
      end
    end
  end

  // Final differences

  logic signed [11-N_DIV : 0] first_diff_r;
  logic signed [11-N_DIV : 0] first_diff_ff;
  logic signed [11-N_DIV : 0] second_diff_r;
  logic signed [11-N_DIV : 0] second_diff_ff;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      first_diff_ff  <= 0;
      second_diff_ff <= 0;
    end else begin
      if (enable) begin
        first_diff_ff  <= resample;
        second_diff_ff <= first_diff_r;
      end
    end
  end

  always_comb begin
    first_diff_r   = resample - first_diff_ff;
    second_diff_r  = first_diff_r - second_diff_ff;
    channel_output = second_diff_r;
  end





endmodule
