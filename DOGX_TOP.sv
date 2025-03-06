
module DOGX_TOP (

    input wire CLK_24M,  // CLK from DLL
    input wire CLK_3M,   // CLK reference

    input wire SCLK,  // CLK for programming port
    input wire SDI,   // Serial data for programming port
    input wire CS,    // Chip select for programming port

    input wire [5:0] counter_HSNR_p_gray,  // Counters from VCOs (already extended)
    input wire [5:0] counter_HSNR_n_gray,
    input wire [5:0] counter_HDR_p_gray,
    input wire [5:0] counter_HDR_n_gray,

    input  wire  alpha_in,  // Alpha out and in
    output logic alpha_out,

    output logic [7:0] GTHDR,         // Programming bits for analog side
    output logic [7:0] GTHSNR,
    output logic [3:0] FCHSNR,
    output logic       HSNR_EN,
    output logic       HDR_EN,
    output logic       BG_PROG_EN,
    output logic [3:0] BG_PROG,
    output logic       LDOA_OFF,
    output logic       LDOD_OFF,
    output logic       LDOA_BP,
    output logic       LDOD_BP,
    output logic       LDOD_mode_1V,
    output logic       LDOA_tweak,
    output logic       REF_OUT,
    output logic       DLLFILT,
    output logic       DLL_EN,
    output logic       DLL_FBK,
    output logic [5:0] DLL_DAC_FULL,
    output logic       CLK_OUT_SEL,
    output logic       HO,
    output logic       dll_reset,

    output logic [10:0] converter_output  // Digital output

);

  // Programmer

  logic [4:0] GTHDR_encoded;
  logic [4:0] GTHSNR_encoded;

  logic [8:0] ATHHI;
  logic [8:0] ATHLO;
  logic [4:0] ATO;

  logic DRESET;
  assign dll_reset = DRESET;

  logic [23:0] OGPH;
  logic [23:0] OGPN;
  logic OP_MODE;
  logic HPFEN;

  programmer DOGX_programmer (
      .SDI(SDI),
      .SCLK(SCLK),
      .CS(CS),
      .GTHDR(GTHDR_encoded),
      .GTHSNR(GTHSNR_encoded),
      .FCHSNR(FCHSNR),
      .HSNR_EN(HSNR_EN),
      .HDR_EN(HDR_EN),
      .BG_PROG_EN(BG_PROG_EN),
      .BG_PROG(BG_PROG),
      .LDOA_OFF(LDOA_OFF),
      .LDOD_OFF(LDOD_OFF),
      .LDOA_BP(LDOA_BP),
      .LDOD_BP(LDOD_BP),
      .LDOD_mode_1V(LDOD_mode_1V),
      .LDOA_tweak(LDOA_tweak),
      .HPFEN(HPFEN),
      .OGPH(OGPH),
      .OGPN(OGPN),
      .ATHHI(ATHHI),
      .ATHLO(ATHLO),
      .ATO(ATO),
      .REF_OUT(REF_OUT),
      .DLLFILT(DLLFILT),
      .DLL_EN(DLL_EN),
      .DLL_FBK(DLL_FBK),
      .DLLFT(DLL_DAC_FULL[5]),
      .DLLDAC(DLL_DAC_FULL[4:0]),
      .CLKOUTSEL(CLK_OUT_SEL),
      .OP_MODE(OP_MODE),
      .DRESET(DRESET),
      .HO(HO)
  );

  // Resistors decoder

  resistors_decoder HDR_r_decoder (
      .r_prog(GTHDR_encoded),
      .R_ctr (GTHDR)
  );

  resistors_decoder HSNR_r_decoder (
      .r_prog(GTHSNR_encoded),
      .R_ctr (GTHSNR)
  );


  // Converter

  DOGX_digital_converter DOGX_converter (
      .CLK_24M(CLK_24M),
      .CLK_3M(CLK_3M),
      .reset(DRESET),
      .counter_HSNR_p_gray(counter_HSNR_p_gray),
      .counter_HSNR_n_gray(counter_HSNR_n_gray),
      .counter_HDR_p_gray(counter_HDR_p_gray),
      .counter_HDR_n_gray(counter_HDR_n_gray),
      .enable_HSNR(HSNR_EN),
      .enable_HDR(HDR_EN),
      .alpha_th_high(ATHHI),
      .alpha_th_low(ATHLO),
      .alpha_timeout_mask(ATO),
      .operation_mode(OP_MODE),
      .enable_dc_filter(HPFEN),
      .HSNR_offset_gain_pos(OGPH),
      .HSNR_offset_gain_neg(OGPN),
      .alpha_in(alpha_in),
      .alpha_out(alpha_out),
      .converter_output(converter_output)
  );

endmodule
