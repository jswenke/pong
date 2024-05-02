----------------------------------------------------------------------------------
-- https://github.com/jswenke
--
-- Target Device - xc7a100tcsg324-1
-- Revision - 0x00000001
-- Date     - 0x05012024
--
-- Comments:
-- Going to add more commentary explaining the registering required to sync up timing in the top, 
-- also need to add some info about the thought process behind the pong logic state machine design
-- this will either be in code comments or on the readme
-- 
-- Minimal but for some of the VGA parts the digilent example design for the nexys a7 dev board was referenced,
-- comments on some of the timing related portions were minimal though - hence why I'd like to explain
-- some of it in here
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

use work.video_timings_pkg.all;


entity top is
    Port (
        sys_clk     : in std_logic;
        rst     : in std_logic;
        
		i_bg_mode_sw : in std_logic_vector(15 downto 0); -- add to s0, s1 in constraints, maybe debounce these too
        i_pong_plyr1_up_btn : in std_logic := '0';
        i_pong_plyr1_down_btn : in std_logic := '0';
        
        o_top_vga_r : out std_logic_vector(3 downto 0); 
        o_top_vga_g : out std_logic_vector(3 downto 0);
        o_top_vga_b : out std_logic_vector(3 downto 0);
        o_top_hsync : out std_logic;
        o_top_vsync : out std_logic;
        
        o_db_pong_plyr1_up_btn : out std_logic;
        o_db_pong_plyr1_down_btn : out std_logic 
        
    );
end top;


architecture rtl of top is


    component clk_wiz_0
        port (
            reset        : in std_logic;
            i_clk_100MHz : in std_logic;
            locked       : out std_logic;
            o_clk_108MHz : out std_logic;
            o_clk_200MHz : out std_logic             
        );
    end component;     
    
    -- NOTE: Using a display w/ resolution 1280x1024 @ 60Hz, a 108MHz pixel clock is required
    -- Also worth noting is that this frequency must take into account the non-active video time 
    -- whole line or whole frame = visible area + front porch + back porch + sync pulse
    --
    -- pixel clock f = whole line * whole frame * refresh rate
    -- pix_f = 1688 * 1066 * 60 = 108MHz
		
    constant timings_VGA : video_timing_type := c_timings_1280x1024_VGA_INIT;
    signal video_active : std_logic;
	
    signal hsync_reg0 : std_logic := '0';
	signal hsync_reg1 : std_logic := '0';
    signal vsync_reg0 : std_logic := '0';
	signal vsync_reg1 : std_logic := '0';	   
	
    signal hcount : integer := 0;	
    signal hcount_reg0 : std_logic_vector(11 downto 0) := (others => '0');
    signal hcount_reg1 : std_logic_vector(11 downto 0) := (others => '0');
    signal vcount : integer := 0;
	signal vcount_reg0 : std_logic_vector(11 downto 0) := (others => '0');
    signal vcount_reg1 : std_logic_vector(11 downto 0) := (others => '0');
	
	signal loc_pixel_x : integer := 0;
	signal loc_pixel_y : integer := 0;
	
	-- VGA combinatorial and registered sigs
    signal vga_r : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_r_cmb : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_r_reg : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_g : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_g_cmb : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_g_reg : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_b : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_b_cmb : std_logic_vector(3 downto 0) := (others => '0');
	signal vga_b_reg : std_logic_vector(3 downto 0) := (others => '0');
	
	signal pong_vga_r : std_logic_vector(3 downto 0) := (others => '0');
	signal pong_vga_g : std_logic_vector(3 downto 0) := (others => '0');
	signal pong_vga_b : std_logic_vector(3 downto 0) := (others => '0');		
	
	signal pong_vga_r_reg0 : std_logic_vector(3 downto 0) := (others => '0');
	signal pong_vga_g_reg0 : std_logic_vector(3 downto 0) := (others => '0');
	signal pong_vga_b_reg0 : std_logic_vector(3 downto 0) := (others => '0');
				
	-- Clock wizard ins/outs
    signal locked : std_logic := '0';
    signal clk_108MHz, clk_200MHz : std_logic;   
    signal sys_rst : std_logic := '0';
	
	-- Debounced pong player control buttons
	signal db_pong_plyr1_up_btn : std_logic := '0';    
	signal db_pong_plyr1_down_btn : std_logic := '0';		
	
	-- Inputs to pong_game_logic generics
	constant TOP_BORDER_FRAME_WIDTH : integer := 4;	
	constant TOP_PADDLE_WIDTH : integer := 15;
	constant TOP_PADDLE_HEIGHT: integer := 90;
	constant TOP_PADDLE_HORZ_LEFT_STARTPOS: integer := 5;   -- starting at x_pix 5 going to x_pix 35 (5 + 30)
	constant TOP_PADDLE_VERT_BOT_STARTPOS : integer := 466; -- starting at y_pix 466 going to y_pix 556 (466 + 90) 
	
		
begin


--------------------------------------------------------------------------------------------
-- Generate clocks, push buttons/Switches debounce & clock syncing
--------------------------------------------------------------------------------------------


INST_CLK_WIZARD: clk_wiz_0
    port map(
        reset       => rst,
        i_clk_100MHz=> sys_clk,
        locked      => locked,
        o_clk_108MHz=> clk_108MHz,
        o_clk_200MHz=> clk_200MHz        
    );      
   
    
o_db_pong_plyr1_up_btn  <= db_pong_plyr1_up_btn;
o_db_pong_plyr1_down_btn<= db_pong_plyr1_down_btn;

    
INST_RST_BTN_DEBOUNCE: entity work.button_debounce(rtl)
    generic map (
            debounce_time => 1048576 -- .1 ms @ 100MHz
        )
    port map (
            clk         => clk_108MHz,
            rst         => '0',
            i_button    => rst,
            o_debounced => sys_rst
        );

INST_PLYR1_UP_BTN_DEBOUNCE: entity work.button_debounce(rtl)
    generic map (
            debounce_time => 1048576 -- .1 ms @ 100MHz
        )
    port map (
            clk         => clk_108MHz,
            rst         => sys_rst,
            i_button    => i_pong_plyr1_up_btn,
            o_debounced => db_pong_plyr1_up_btn
        );
        
INST_PLYR1_DOWN_BTN_DEBOUNCE: entity work.button_debounce(rtl)
    generic map (
            debounce_time => 1048576 -- .1 ms @ 100MHz
        )
    port map (
            clk         => clk_108MHz,
            rst         => sys_rst,
            i_button    => i_pong_plyr1_down_btn,
            o_debounced => db_pong_plyr1_down_btn 
        );                  


--------------------------------------------------------------------------------------------
-- Generating HSYNC and VSYNC, X/Y pixel counters, X/Y pixel locations, and video active
--------------------------------------------------------------------------------------------


PROC_HSYNC: process(clk_108MHz)
begin
    if(rising_edge(clk_108MHz))then
        if(hcount_reg0 >= (timings_VGA.H_FP + (timings_VGA.H_VISIBLE_AREA - 1)) and 
           hcount_reg0 <  (timings_VGA.H_FP + timings_VGA.H_VISIBLE_AREA + (timings_VGA.HSYNC - 1))) then
            hsync_reg0 <= timings_VGA.H_POL;
        else
            hsync_reg0 <= not(timings_VGA.H_POL);
        end if;            
    end if;
end process;

PROC_VSYNC: process(clk_108MHz)
begin
    if(rising_edge(clk_108MHz))then
        if(vcount_reg0 >= (timings_VGA.V_FP + (timings_VGA.V_VISIBLE_AREA - 1)) and 
           vcount_reg0 <  (timings_VGA.V_FP + timings_VGA.V_VISIBLE_AREA + (timings_VGA.VSYNC - 1))) then
            vsync_reg0 <= timings_VGA.V_POL;
        else
            vsync_reg0 <= not(timings_VGA.V_POL);    
        end if;                    
    end if;
end process;    

PROC_PIX_HCOUNT: process(clk_108MHz) 
begin          
    if(rising_edge(clk_108MHz)) then
        if(hcount_reg0 = timings_VGA.H_WHOLE_LINE - 1) then
            hcount_reg0 <= (others => '0');
        else
            hcount_reg0 <= hcount_reg0 + 1;
        end if;            
    end if;        
end process;

PROC_PIX_VCOUNT: process(clk_108MHz)
begin
    if(rising_edge(clk_108MHz)) then
        if((hcount_reg0 = timings_VGA.H_WHOLE_LINE - 1) and (vcount_reg0 = timings_VGA.V_WHOLE_FRAME - 1)) then
            vcount_reg0 <= (others => '0');
        elsif(hcount_reg0 = timings_VGA.H_WHOLE_LINE - 1) then
            vcount_reg0 <= vcount_reg0 + 1;
        end if;
    end if;
end process;               		

loc_pixel_x <= conv_integer(hcount_reg1) when (hcount_reg1 < timings_VGA.H_VISIBLE_AREA) else 0;
loc_pixel_y <= conv_integer(vcount_reg1) when (vcount_reg1 < timings_VGA.V_VISIBLE_AREA) else 0;
video_active <= '1' when hcount_reg1 < timings_VGA.H_VISIBLE_AREA and vcount_reg1 < timings_VGA.V_VISIBLE_AREA else '0';		 
		
		
--------------------------------------------------------------------------------------------
-- pong_game_logic contains FSMs for ball movement, player paddle control, 
-- cpu paddle control, and VGA display logic for the game elements
--------------------------------------------------------------------------------------------
		
		
INST_PONG_LOGIC : entity work.pong_game_logic(rtl)
    Generic map ( 
        H_VISIBLE_AREA      => timings_VGA.H_VISIBLE_AREA,  -- 1280
        V_VISIBLE_AREA      => timings_VGA.V_VISIBLE_AREA,  -- 1024
        BORDER_FRAME_WIDTH  => TOP_BORDER_FRAME_WIDTH,
        PADDLE_WIDTH        => TOP_PADDLE_WIDTH,            -- 30 
        PADDLE_HEIGHT       => TOP_PADDLE_HEIGHT,           -- 90
        PADDLE_VERT_STARTPOS=> TOP_PADDLE_VERT_BOT_STARTPOS -- 466
    )
    Port map (
        clk => clk_108MHz,
        rst => rst, 
        
        i_plyr1_up    => db_pong_plyr1_up_btn,
        i_plyr1_down  => db_pong_plyr1_down_btn,
        i_loc_pixel_x => loc_pixel_x,
        i_loc_pixel_y => loc_pixel_y,

        o_pong_vga_r => pong_vga_r_reg0,  
        o_pong_vga_g => pong_vga_g_reg0,
        o_pong_vga_b => pong_vga_b_reg0
        
    );
	
	
--------------------------------------------------------------------------------------------
-- Clock/time syncing stuff
-- ***
--------------------------------------------------------------------------------------------

	
vga_r <=pong_vga_r;
vga_g <=pong_vga_g;
vga_b <=pong_vga_b;

-- if there's unexpected delay here try change back to a "vga_r_cmb <= (active & active ....) and (vga_r)" approach
vga_r_cmb <= vga_r when video_active = '1' else (others => '0'); 
vga_g_cmb <= vga_g when video_active = '1' else (others => '0'); 
vga_b_cmb <= vga_b when video_active = '1' else (others => '0'); 


-- register non-clocked rgb signals and delay hsync/vsync one more cycle to line up
-- go back and run through why/if there needs to be another hsync/vsync delay here
process(clk_108MHz) 
begin
	if(rising_edge(clk_108Mhz)) then
        pong_vga_r <= pong_vga_r_reg0;
        pong_vga_g <= pong_vga_g_reg0;
        pong_vga_b <= pong_vga_b_reg0;
        			
		hcount_reg1 <= hcount_reg0;
		vcount_reg1 <= vcount_reg0;
		
		hsync_reg1 <= hsync_reg0;
		vsync_reg1 <= vsync_reg0;
		
		vga_r_reg <= vga_r_cmb;
		vga_g_reg <= vga_g_cmb;
		vga_b_reg <= vga_b_cmb;
	end if;
end process;	
       
	   
o_top_hsync <= hsync_reg1; 
o_top_vsync <= vsync_reg1;
o_top_vga_r <= vga_r_reg;
o_top_vga_g <= vga_g_reg;
o_top_vga_b <= vga_b_reg;     
    
 
end rtl;

