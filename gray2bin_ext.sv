`timescale 1ns / 1ps

module gray2bin_ext (
    input wire CLK_24M,
    input wire reset,
    input logic [5:0] gray,
    output logic [11:0] bin_extended
);

  logic gray_wrapped;
  logic prev_MSB;
  logic [5:0] extension;
  logic [5:0] extension_reg;
  logic [5:0] binary;

  int i;

  always_comb begin
    binary[5] = gray[5];
    for (i = 4; i >= 0; i = i - 1) begin
      binary[i] = binary[i+1] ^ gray[i];
    end
  end

  always_ff @(posedge CLK_24M or negedge reset) begin
    if(!reset) begin
        prev_MSB <= 0;
        extension_reg <= 0;
    end else begin
        prev_MSB <= gray[5];
        extension_reg <= extension;
    end
  end

  always_comb begin
    if(prev_MSB == 1'b1 && gray[5] == 1'b0) begin
        extension = extension_reg + 1;
    end else begin
        extension = extension_reg;
    end
  end

  assign bin_extended = {extension,binary};

endmodule
