`timescale 1ns / 1ps

module clockgen (
    input  wire CLK_24M,
    input  wire reset,
    output wire enable_3M,
    output wire enable_6M,
    output wire generated_3M_output_clock
);

  logic unsigned [2:0] count;
  logic enable_3M_i;
  logic enable_6M_i;
  logic generated_3M_output_clock_i;

  assign enable_3M = enable_3M_i;
  assign enable_6M = enable_6M_i;
  assign generated_3M_output_clock = generated_3M_output_clock_i;

  always_ff @(posedge CLK_24M or negedge reset) begin
    if (!reset) count <= 0;
    else count <= count + 1;
  end

  always_comb begin
    enable_3M_i = count == 0;
    enable_6M_i = count == 0 || count == 4;
    generated_3M_output_clock_i = count < 4;
  end


endmodule
