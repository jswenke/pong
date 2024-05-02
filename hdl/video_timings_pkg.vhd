
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- use package elsewhere by adding --> 
-- "use work.video_timings_pkg.all;"
-- instantiate signal constant type with default values by doing -->
-- signal "example_constant_group_timings_VGA" : timings_std_VGA := c_timings_std_VGA_INIT;

package video_timings_pkg is

type video_timing_type is record-- standard VGA = 640x480 @ 60 Hz
    --PIXEL_CLK : integer;      -- pixel clock frequency
    H_VISIBLE_AREA : integer;   -- horizontal visible area
    H_WHOLE_LINE : integer;     -- horizontal whole line
    H_FP : integer;             -- h front porch
    H_BP : integer;             -- h back porch
    HSYNC: integer;             -- horizontal sync pulse
    V_VISIBLE_AREA : integer;   -- vertical visible area
    V_WHOLE_FRAME : integer;    -- vertical whole frame
    V_FP : integer;             -- vertical front porch
    V_BP : integer;             -- vertical back porch
    VSYNC: integer;             -- vertical sync pulse
    H_POL: std_logic;           -- horizontal polarity
    V_POL: std_logic;           -- vertical polarity
    ACTIVE : std_logic;         -- video active
end record video_timing_type;
    
constant c_timings_1280x1024_VGA_INIT : video_timing_type := (
                                                      H_VISIBLE_AREA => 1280,
                                                      H_WHOLE_LINE => 1688,
                                                      H_FP => 48,
                                                      H_BP => 248,
                                                      HSYNC   => 112,
                                                      V_VISIBLE_AREA => 1024,
                                                      V_WHOLE_FRAME => 1066,
                                                      V_FP => 1,
                                                      V_BP => 38,
                                                      VSYNC => 3,
                                                      H_POL => '0', 
                                                      V_POL => '0', 
                                                      ACTIVE => '1');                  
    
constant c_timings_std_VGA_INIT : video_timing_type := (--PIXEL_CLK => 25,
                                                      H_VISIBLE_AREA => 640,
                                                      H_WHOLE_LINE => 800,
                                                      H_FP => 16,
                                                      H_BP => 48,
                                                      HSYNC   => 96,
                                                      V_VISIBLE_AREA => 480,
                                                      V_WHOLE_FRAME => 525,
                                                      V_FP => 10,
                                                      V_BP => 33,
                                                      VSYNC => 2,
                                                      H_POL => '0',
                                                      V_POL => '0',
                                                      ACTIVE => '1');
                                                          
constant c_timings_1080P_HDMI_INIT : video_timing_type := (--PIXEL_CLK => 25,
                                                      H_VISIBLE_AREA => 1920,
                                                      H_WHOLE_LINE => 2200,
                                                      H_FP => 88,
                                                      H_BP => 148,
                                                      HSYNC   => 44,
                                                      V_VISIBLE_AREA => 1080,
                                                      V_WHOLE_FRAME => 1125,
                                                      V_FP => 4,
                                                      V_BP => 36,
                                                      VSYNC => 5,
                                                      H_POL => '1',
                                                      V_POL => '1',
                                                      ACTIVE => '1');
                                                    


end package video_timings_pkg;