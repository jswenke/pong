# pong
Pong with output to VGA display, written in VHDL for implementation on nexys a7 dev board (part no. xc7a100tcsg324-1), built in vivado 2023.2



## Creating & building project
### Option 1
1. Open git bash, consider $origin_dir as the root directory of the repo

`source $origin_dir/scripts/build_project.tcl`

### Option 2
1. Open Vivado 2023.2 GUI
2. Click Tools > Run Tcl Script...
3. Select $origin_dir/scripts/build_project.tcl



## Output example
Controlling up/down movement of the left paddle with push buttons on the dev board, CPU right paddle just tracks ball vertical position

![](https://github.com/jswenke/pong/blob/main/gif_and_misc/pong_vga_output.gif)
Note: visual distortion in top middle of screen is due to degrading monitor hardware, not errors in the VGA HDL sections


## To-do
### Features
- Try different methods of pseudo-randomizing the initial ball position/velocity
- Change ball velocity when hitting P1 or CPU paddle
- CPU difficulty modes
- Win/Loss record
- Visual/audio cues & effects

### Documentation
- Further comments on time sync done for some of the VGA related signals in top file
- Logic walkthrough/state diagrams for hdl/pong_game_logic

