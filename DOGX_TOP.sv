
module DOGX_TOP (

    input wire CLK_24M,  // CLK from DLL
    input wire reset,    // Reset only used for simulation, leave connected to 1

    input wire SCLK,  // CLK for programming port
    input wire SDI,   // Serial data for programming port
    input wire CS,    // Chip select for programming port

    input wire [8:0] counter_HSNR_p,  // Counters from VCOs (already extended)
    input wire [8:0] counter_HSNR_n,
    input wire [8:0] counter_HDR_p,
    input wire [8:0] counter_HDR_n,

    input  wire  alpha_in,  // Alpha out and in
    output logic alpha_out,

    output logic [7:0] GTHDR,       // Programming bits for analog side
    output logic [7:0] GTHSNR,
    output logic [3:0] FCHSNR,
    output logic       HSNR_EN,
    output logic       HDR_EN,
    output logic       BG_PROG_EN,
    output logic [3:0] BG_PROG,
    output logic       LDOA_BP,
    output logic       LDOA_tweak,
    output logic       REF_OUT,
    output logic       DLLFILT,
    output logic       DLL_EN,
    output logic       DLL_FB_EN,
    output logic       DLL_TR,
    output logic       HO,

    output logic [10:0] converter_output,  // Digital output
    output wire clock_3M_out

);

  // Programmer

  logic [3:0] GTHDR_encoded;
  logic [3:0] GTHSNR_encoded;

  logic [8:0] ATHHI;
  logic [8:0] ATHLO;
  logic [4:0] ATO;

  logic DRESET;
  logic [23:0] HSNR_COMP_P;
  logic [23:0] HSNR_COMP_N;
  logic OP_MODE;

  programmer DOGX_programmer (
      .reset(reset),
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
      .LDOA_BP(LDOA_BP),
      .LDOA_tweak(LDOA_tweak),
      .ATHHI(ATHHI),
      .ATHLO(ATHLO),
      .ATO(ATO),
      .REF_OUT(REF_OUT),
      .HSNR_COMP_P(HSNR_COMP_P),
      .HSNR_COMP_N(HSNR_COMP_N),
      .OP_MODE(OP_MODE),
      .DLLFILT(DLLFILT),
      .DLL_EN(DLL_EN),
      .DLL_FB_EN(DLL_FB_EN),
      .DLL_TR(DLL_TR),
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
      .reset(DRESET),
      .counter_HSNR_p(counter_HSNR_p),
      .counter_HSNR_n(counter_HSNR_n),
      .counter_HDR_p(counter_HDR_p),
      .counter_HDR_n(counter_HDR_n),
      .alpha_th_high(ATHHI),
      .alpha_th_low(ATHLO),
      .alpha_timeout_mask(ATO),
      .alpha_in(alpha_in),
      .alpha_out(alpha_out),
      .operation_mode(OP_MODE),
      .HSNR_offset_gain_pos(HSNR_COMP_P),
      .HSNR_offset_gain_neg(HSNR_COMP_N),
      .converter_output(converter_output),
      .clock_3M_out(clock_3M_out)
  );

endmodule
