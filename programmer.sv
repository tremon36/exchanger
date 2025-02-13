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
    input wire reset,
    input wire SDI,
    input wire SCLK,
    input wire CS,
    output wire [3:0] GTHDR,
    output wire [3:0] GTHSNR,
    output wire [3:0] FCHSNR,
    output wire HSNR_EN,
    output wire HDR_EN,
    output wire BG_PROG_EN,
    output wire [3:0] BG_PROG,
    output wire LDOA_BP,
    output wire LDOA_tweak,
    output wire [8:0] ATHHI,
    output wire [8:0] ATHLO,
    output wire [4:0] ATO,
    output wire REF_OUT,
    output wire [23:0] HSNR_COMP_P,
    output wire [23:0] HSNR_COMP_N,
    output wire OP_MODE,
    output wire DLLFILT,
    output wire DLL_EN,
    output wire DLL_FB_EN,
    output wire DLL_FINE_TUNE,
    output wire [4:0] DLL_DAC,
    output wire CLK_OUT_SEL,
    output wire DRESET,
    output wire HO
);

  `define NUM_REGS 22
  `define NUM_BITS 104

  logic [`NUM_BITS-1:0] prog_data;

  // Assign each output to the corresponding data

  assign GTHDR = prog_data[3:0];
  assign GTHSNR = prog_data[7:4];
  assign FCHSNR = prog_data[11:8];
  assign HSNR_EN = prog_data[12];
  assign HDR_EN = prog_data[13];
  assign BG_PROG_EN = prog_data[14];
  assign BG_PROG = prog_data[18:15];
  assign LDOA_BP = prog_data[19];
  assign LDOA_tweak = prog_data[20];
  assign ATHHI = prog_data[29:21];
  assign ATHLO = prog_data[38:30];
  assign ATO = prog_data[43:39];
  assign REF_OUT = prog_data[44];
  assign HSNR_COMP_P = prog_data[68:45];
  assign HSNR_COMP_N = prog_data[92:69];
  assign OP_MODE = prog_data[93];
  assign DLLFILT = prog_data[94];
  assign DLL_EN = prog_data[95];
  assign DLL_FB_EN = prog_data[96];
  assign DLL_FINE_TUNE = prog_data[97];
  assign DLL_DAC = prog_data[102:98];
  assign CLK_OUT_SEL = prog_data[103];

  // Populate input prog_data_aux with SCLK

  logic [`NUM_BITS-1:0] prog_data_aux;


  always_ff @(posedge SCLK or negedge reset) begin
    if (!reset) begin
      prog_data_aux <= 0;
    end else begin
      if (!CS) begin  // Only do a shift when CS is low
        prog_data_aux[`NUM_BITS-1]   <= SDI;
        prog_data_aux[`NUM_BITS-2:0] <= prog_data_aux[`NUM_BITS-1:1];
      end
    end
  end

  always_ff @(posedge CS or negedge reset) begin
    if (!reset) begin
      prog_data <= 0;
    end else begin
      prog_data <= prog_data_aux;
    end
  end

  // HZ and DRESET

  assign DRESET = !(CS & SCLK);
  assign HO = CS & SDI;

endmodule
