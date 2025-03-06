`timescale 1ns / 1ps

/*
    PROGRAMMER MODULE - Ricardo Carrero Bardon - 22/11/2024

    The module programming interface is SPI (mode 00)
    CS is used both as a sync input and a clock input.
    SCLK is a clock input.
    SDI is the data input for the programmer.
    Connect all the output programming ports to the corresponding place in the design

*/

module programmer (
    input wire SDI,
    input wire SCLK,
    input wire CS,
    output wire [4:0] GTHDR,
    output wire [4:0] GTHSNR,
    output wire [3:0] FCHSNR,
    output wire HSNR_EN,
    output wire HDR_EN,
    output wire BG_PROG_EN,
    output wire [3:0] BG_PROG,
    output wire LDOA_OFF,
    output wire LDOD_OFF,
    output wire LDOA_BP,
    output wire LDOD_BP,
    output wire LDOD_mode_1V,
    output wire LDOA_tweak,
    output wire HPFEN,
    output wire [23:0] OGPH,
    output wire [23:0] OGPN,
    output wire [8:0] ATHHI,
    output wire [8:0] ATHLO,
    output wire [4:0] ATO,
    output wire REF_OUT,
    output wire DLLFILT,
    output wire DLL_EN,
    output wire DLL_FBK,
    output wire DLLFT,
    output wire [4:0] DLLDAC,
    output wire CLKOUTSEL,
    output wire OP_MODE,
    output wire DRESET,
    output wire HO
);

  `define NUM_REGS 27
  `define NUM_BITS 111

  logic [`NUM_BITS-1:0] prog_data;

  // Assign each output to the corresponding data

  assign GTHDR = prog_data[4:0];
  assign GTHSNR = prog_data[9:5];
  assign FCHSNR = prog_data[13:10];
  assign HSNR_EN = prog_data[14];
  assign HDR_EN = prog_data[15];
  assign BG_PROG_EN = prog_data[16];
  assign BG_PROG = prog_data[20:17];
  assign LDOA_OFF = prog_data[21];
  assign LDOD_OFF = prog_data[22];
  assign LDOA_BP = prog_data[23];
  assign LDOD_BP = prog_data[24];
  assign LDOD_mode_1V = prog_data[25];
  assign LDOA_tweak = prog_data[26];
  assign HPFEN = prog_data[27];
  assign OGPH = prog_data[51:28];
  assign OGPN = prog_data[75:52];
  assign ATHHI = prog_data[84:76];
  assign ATHLO = prog_data[93:85];
  assign ATO = prog_data[98:94];
  assign REF_OUT = prog_data[99];
  assign DLLFILT = prog_data[100];
  assign DLL_EN = prog_data[101];
  assign DLL_FBK = prog_data[102];
  assign DLLFT = prog_data[103];
  assign DLLDAC = prog_data[108:104];
  assign CLKOUTSEL = prog_data[109];
  assign OP_MODE = prog_data[110];

  // Populate input prog_data_aux with SCLK

  logic [`NUM_BITS-1:0] prog_data_aux;


  always_ff @(posedge SCLK) begin
      if (!CS) begin  // Only do a shift when CS is low
        prog_data_aux[`NUM_BITS-1]   <= SDI;
        prog_data_aux[`NUM_BITS-2:0] <= prog_data_aux[`NUM_BITS-1:1];
      end
  end

  always_ff @(posedge CS) begin
      prog_data <= prog_data_aux;
  end

  // HZ and DRESET

  assign DRESET = !(CS & SCLK);
  assign HO = CS & SDI;

endmodule
