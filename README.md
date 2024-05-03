# pong
Pong with output to VGA display, written in VHDL for implementation on nexys a7 dev board (part no. xc7a100tcsg324-1)

Build uses vivado 2023.2

## Building project (draft)
**Note: build script unfinished**
1. Open git bash, consider $origin_dir as the root directory of the repo
`source $origin_dir/scripts/env.sh`
2. Make the vivado project
`vivado -mode batch -source $origin_dir/scripts/build_project.tcl`
3. Open .xpr made in $origin_dir/project
4. Run through implementation & generate bitstream if desired

## To-do
- Build script (just need to include xilinx ip and debug)
- Further comments on time sync done for some of the VGA related signals in top file
- Comments on pong_game_logic.vhd, walkthrough?
- Image/GIF of gameplay on display

