// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (win64) Build 4029153 Fri Oct 13 20:14:34 MDT 2023
// Date        : Wed May  1 21:28:39 2024
// Host        : DESKTOP-JACOB running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {c:/Users/Jacob/Desktop/FPGA
//               study/Github/Repos/pong/hdl/xilinx/clk_wiz_0/clk_wiz_0_stub.v}
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(o_clk_108MHz, o_clk_200MHz, reset, locked, 
  i_clk_108MHz)
/* synthesis syn_black_box black_box_pad_pin="reset,locked,i_clk_108MHz" */
/* synthesis syn_force_seq_prim="o_clk_108MHz" */
/* synthesis syn_force_seq_prim="o_clk_200MHz" */;
  output o_clk_108MHz /* synthesis syn_isclock = 1 */;
  output o_clk_200MHz /* synthesis syn_isclock = 1 */;
  input reset;
  output locked;
  input i_clk_108MHz;
endmodule
