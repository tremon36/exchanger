`timescale 1ns / 1ps

module fifth_order_ns #(
    parameter int NR_SIG_PATH_BITS = 21
) (
    input wire CLK_3M,
    input wire reset,
    input logic enable,
    input logic alpha,
    input logic signed [23:0] HSNR_offset_gain_pos,
    input logic signed [23:0] HSNR_offset_gain_neg,
    input logic signed [22:0] data_i,
    output logic data_o
);
  // DEBUG

  /* int samples_count = 0;

        int fd_integrator1;
        int fd_integrator2;
        int fd_integrator3;
        int fd_integrator4;
        int fd_integrator5;

        initial begin
            fd_integrator1 = $fopen("./vivado_integrator1.csv","w");
            fd_integrator2 = $fopen("./vivado_integrator2.csv","w");
            fd_integrator3 = $fopen("./vivado_integrator3.csv","w");
            fd_integrator4 = $fopen("./vivado_integrator4.csv","w");
            fd_integrator5 = $fopen("./vivado_integrator5.csv","w");
            forever begin
                @(negedge CLK_3M);
                samples_count++;
                #1;
                $fdisplay(fd_integrator1,"%d;",first_integrator_r);
                $fdisplay(fd_integrator2,"%d;",second_integrator_r);
                $fdisplay(fd_integrator3,"%d;",third_integrator_r);
                $fdisplay(fd_integrator4,"%d;",fourth_integrator_r);
                $fdisplay(fd_integrator5,"%d;",fifth_integrator_r);
            end
        end*/

  // END DEBUG

  // local parameters

  localparam int SAT_01_UPPER_LIMIT = 2 ** (NR_SIG_PATH_BITS + 2) - 1;
  localparam int SAT_01_LOWER_LIMIT = -(2 ** (NR_SIG_PATH_BITS + 2));

  localparam int SAT_02_UPPER_LIMIT = 2 ** (NR_SIG_PATH_BITS + 3) - 1;
  localparam int SAT_02_LOWER_LIMIT = -(2 ** (NR_SIG_PATH_BITS + 3));

  localparam int SAT_03_UPPER_LIMIT = $rtoi(1.8125 * 2 ** (NR_SIG_PATH_BITS + 2));
  localparam int SAT_03_LOWER_LIMIT = $rtoi(-1.8125 * 2 ** (NR_SIG_PATH_BITS + 2));

  localparam int SAT_04_UPPER_LIMIT = 2 ** (NR_SIG_PATH_BITS + 6) - 1;
  localparam int SAT_04_LOWER_LIMIT = -(2 ** (NR_SIG_PATH_BITS + 6));

  localparam int SAT_05_UPPER_LIMIT = 2 ** (NR_SIG_PATH_BITS + 9) - 1;
  localparam int SAT_05_LOWER_LIMIT = -(2 ** (NR_SIG_PATH_BITS + 9));

  localparam int FB_HDR_GAIN = 2 ** (NR_SIG_PATH_BITS);

  // Extension to 23 bit

  logic signed [NR_SIG_PATH_BITS+2:0] data_in_extended;
  assign data_in_extended = data_i;


  // First feedback

  logic signed [NR_SIG_PATH_BITS+2:0] sum1_fb;
  logic signed [NR_SIG_PATH_BITS+2:0] sum1_r;

  assign sum1_r = sum1_fb + data_in_extended;

  // First integrator

  logic signed [NR_SIG_PATH_BITS+2:0] first_integrator_r;
  logic signed [NR_SIG_PATH_BITS+3:0] sum02_r;


  assign sum02_r = sum1_r + first_integrator_r;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      first_integrator_r <= 0;
    end else begin
      if (enable) begin
        if (first_integrator_r > $signed(SAT_01_UPPER_LIMIT)) begin
          first_integrator_r <= $signed(SAT_01_UPPER_LIMIT);
          // $display("Saturation at integrator 1 (upper limit) happened at %d, when value was %d",samples_count,sum02_r);
        end else begin
          if (first_integrator_r < $signed(SAT_01_LOWER_LIMIT)) begin
            first_integrator_r <= $signed(SAT_01_LOWER_LIMIT);
            // $display("Saturation at integrator 1 (lower limit) happened at %d, when value was %d",samples_count,sum02_r);
          end else begin
            first_integrator_r <= sum02_r;
          end
        end
      end
    end
  end

  // Second feedback (resonator)

  logic signed [NR_SIG_PATH_BITS-7:0] resonator_fb;
  logic signed [NR_SIG_PATH_BITS+3:0] sum03_r;

  assign sum03_r = first_integrator_r - resonator_fb;

  // Second integrator

  logic signed [NR_SIG_PATH_BITS+3:0] second_integrator_r;
  logic signed [NR_SIG_PATH_BITS+4:0] sum04_r;

  assign sum04_r = sum03_r + second_integrator_r;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      second_integrator_r <= 0;
    end else begin
      if (enable) begin
        if (sum04_r > $signed(SAT_02_UPPER_LIMIT)) begin
          second_integrator_r <= $signed(SAT_02_UPPER_LIMIT);
          // $display("Saturation at integrator 2 (upper limit) happened at %d, when value was %d",samples_count,sum04_r);
        end else begin
          if (sum04_r < $signed(SAT_02_LOWER_LIMIT)) begin
            second_integrator_r <= $signed(SAT_02_LOWER_LIMIT);
            // $display("Saturation at integrator 2 (lower limit) happened at %d, when value was %d",samples_count,sum04_r);
          end else begin
            second_integrator_r <= sum04_r;
          end
        end
      end
    end
  end

  // Third integrator

  logic signed [NR_SIG_PATH_BITS+3:0] third_integrator_r;
  logic signed [NR_SIG_PATH_BITS+4:0] sum05_r;

  assign sum05_r = second_integrator_r + third_integrator_r;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      third_integrator_r <= 0;
    end else begin
      if (enable) begin
        if (sum05_r > $signed(SAT_03_UPPER_LIMIT)) begin
          // $display("Saturation at integrator 3 (upper limit) happened at %d, when value was %d",samples_count,sum05_r);
          third_integrator_r <= $signed(SAT_03_UPPER_LIMIT);
        end else begin
          if (sum05_r < $signed(SAT_03_LOWER_LIMIT)) begin
            // $display("Saturation at integrator 3 (lower limit) happened at %d, when value was %d",samples_count,sum05_r);
            third_integrator_r <= $signed(SAT_03_LOWER_LIMIT);
          end else begin
            third_integrator_r <= sum05_r;
          end
        end
      end
    end
  end

  // Fourth integrator (backwards euler,)

  logic signed [NR_SIG_PATH_BITS+6:0] fourth_integrator_r;
  logic signed [NR_SIG_PATH_BITS+6:0] backwards_delay_register;
  logic signed [NR_SIG_PATH_BITS+7:0] sum08_r;

  assign sum08_r = third_integrator_r + backwards_delay_register;

  always_comb begin
    if (sum08_r > $signed(SAT_04_UPPER_LIMIT)) begin
      fourth_integrator_r = $signed(SAT_04_UPPER_LIMIT);
      // $display("Saturation at integrator 4 (upper limit) happened at %d, when value was %d",samples_count,sum08_r);
    end else begin
      if (sum08_r < $signed(SAT_04_LOWER_LIMIT)) begin
        // $display("Saturation at integrator 4 (lower limit) happened at %d, when value was %d",samples_count,sum08_r);
        fourth_integrator_r = $signed(SAT_04_LOWER_LIMIT);
      end else begin
        fourth_integrator_r = sum08_r;
      end
    end
  end

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      backwards_delay_register <= 0;
    end else begin
      if (enable) begin
        backwards_delay_register <= fourth_integrator_r;
      end
    end
  end

  // Fifth integrator

  logic signed [ NR_SIG_PATH_BITS+9:0] fifth_integrator_r;
  logic signed [NR_SIG_PATH_BITS+10:0] sum09_r;

  assign sum09_r = fourth_integrator_r + fifth_integrator_r;

  always_ff @(posedge CLK_3M or negedge reset) begin
    if (!reset) begin
      fifth_integrator_r <= 0;
    end else begin
      if (enable) begin
        if (sum09_r > $signed(SAT_05_UPPER_LIMIT)) begin
          fifth_integrator_r <= $signed(SAT_05_UPPER_LIMIT);
          // $display("Saturation at integrator 5 (upper limit) happened at %d, when value was %d",samples_count,sum09_r);
        end else begin
          if (sum09_r < $signed(SAT_05_LOWER_LIMIT)) begin
            fifth_integrator_r <= $signed(SAT_05_LOWER_LIMIT);
            // $display("Saturation at integrator 5 (lower limit) happened at %d, when value was %d",samples_count,sum09_r);
          end else begin
            fifth_integrator_r <= sum09_r;
          end
        end
      end
    end
  end

  // resonator gain

  assign resonator_fb = third_integrator_r >>> 10;

  // Feed forward, adders

  logic signed [NR_SIG_PATH_BITS-10:0] ff_adder_result;

  assign ff_adder_result = (fifth_integrator_r >>> 24) +
                           (fourth_integrator_r >>> 20) +
                           (third_integrator_r >>> 17) +
                           (second_integrator_r >>> 15) +
                           (first_integrator_r >>> 14);

  // Assign output

  assign data_o = !ff_adder_result[NR_SIG_PATH_BITS-10];


  // Compute feedback

  always_comb begin
    if (alpha == `ALPHA_SELECT_HSNR) begin
      if (data_o == 1'b1) begin
        sum1_fb = HSNR_offset_gain_neg;
      end else begin
        sum1_fb = HSNR_offset_gain_pos;
      end
    end else begin
      if (data_o == 1'b1) begin
        sum1_fb = -$signed(FB_HDR_GAIN);
      end else begin
        sum1_fb = $signed(FB_HDR_GAIN);
      end
    end
  end


endmodule
