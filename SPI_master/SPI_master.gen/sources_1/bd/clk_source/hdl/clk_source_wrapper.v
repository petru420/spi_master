//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Mon Feb  1 18:29:58 2021
//Host        : DESKTOP-BCLG5TG running 64-bit major release  (build 9200)
//Command     : generate_target clk_source_wrapper.bd
//Design      : clk_source_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clk_source_wrapper
   (clk_in1_n_0,
    clk_in1_p_0,
    clk_out1_0,
    reset_0);
  input clk_in1_n_0;
  input clk_in1_p_0;
  output clk_out1_0;
  input reset_0;

  wire clk_in1_n_0;
  wire clk_in1_p_0;
  wire clk_out1_0;
  wire reset_0;

  clk_source clk_source_i
       (.clk_in1_n_0(clk_in1_n_0),
        .clk_in1_p_0(clk_in1_p_0),
        .clk_out1_0(clk_out1_0),
        .reset_0(reset_0));
endmodule
