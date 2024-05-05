
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.MATH_REAL.ALL;

use work.video_timings_pkg.all;


entity pong_game_logic is
    Generic ( 
        H_VISIBLE_AREA : integer := 1280;
        V_VISIBLE_AREA : integer := 1024;
        BORDER_FRAME_WIDTH : integer := 4;
		
        PADDLE_WIDTH : integer := 32; -- 30 pix wide starting at x= 5 ending at x= 30
        PADDLE_HEIGHT: integer := 96;
        PADDLE_VERT_STARTPOS : integer := 466;-- bottom of paddle (512 - 45)    
		
        BALL_WIDTH : integer := 21;
        BALL_HEIGHT : integer := 29;
        BALL_VERT_STARTPOS : integer := 509; -- 1024/2 - (half ball width) - 1
        BALL_HORZ_STARTPOS : integer := 637        
    );
    Port (
        clk : in std_logic;
        rst : in std_logic; 
        
        i_plyr1_up    : in std_logic;
        i_plyr1_down  : in std_logic;
        i_loc_pixel_x : in integer;
        i_loc_pixel_y : in integer;

        o_pong_vga_r  : out std_logic_vector(3 downto 0);
        o_pong_vga_g  : out std_logic_vector(3 downto 0);
        o_pong_vga_b  : out std_logic_vector(3 downto 0)                        
    );
end pong_game_logic;

	    
architecture rtl of pong_game_logic is


    signal FILLER_LOGIC : std_logic := '0';
	
	type type_paddle_state is (st_idle, st_move_up, st_move_down);
	signal ps_paddle : type_paddle_state := st_idle;	
	signal PADDLE_CURRENTPOS_BOT : integer := PADDLE_VERT_STARTPOS;
	signal PADDLE_HORZ_POS : integer := BORDER_FRAME_WIDTH + 1;
	signal counter_paddle : integer := 0;  -- 316406 move across whole screen in 3s
	
	type type_ball_state is (st_wait_for_start, st_ball_move); --, st_ball_bounce);
	signal ps_ball : type_ball_state := st_wait_for_start;
	signal BALL_HORZ_POS_LEFT : integer := BALL_HORZ_STARTPOS;
    signal BALL_VERT_POS_BOT : integer := BALL_VERT_STARTPOS;
    signal reg0_ball_horz_pos : std_logic_vector(11 downto 0) := (others => '0');
    signal reg0_ball_vert_pos : std_logic_vector(11 downto 0) := (others => '0');
	
	type type_ball_vertmove_state is (st_vertmove_wait_for_start, st_ball_up, st_ball_down);
	signal ps_vertmove_ball : type_ball_vertmove_state := st_vertmove_wait_for_start;
    signal vert_counter_up : integer := 0;
    signal vert_counter_down : integer := 0;

	type type_ball_horzmove_state is (st_horzmove_wait_for_start, st_ball_left, st_ball_right);
	signal ps_horzmove_ball : type_ball_horzmove_state := st_horzmove_wait_for_start;
	signal horz_counter_left : integer := 0;	
	signal horz_counter_right : integer := 0;	
	
	type type_cpu_paddle_state is (st_cpu_paddle_wait_for_start, st_cpu_track_ball);
    signal ps_cpu_paddle : type_cpu_paddle_state := st_cpu_paddle_wait_for_start;
    signal CPU_PADDLE_CURRENTPOS_BOT : integer := PADDLE_VERT_STARTPOS;
    signal CPU_PADDLE_HORZ_POS : integer := H_VISIBLE_AREA - 2 - PADDLE_WIDTH - BORDER_FRAME_WIDTH;

    signal game_round_done : std_logic := '0';
	signal game_start : std_logic := '0';
    signal fix_count : std_logic := '0';		
	
	type type_initial_velocity_arr is array (0 to 9) of integer;
	signal initial_vel_arr : type_initial_velocity_arr := (200000, 250000, 100000, 150000, 175000, 125000, 225000, 169000, 133333, 190000);
	signal rand_counter_1 : integer := 0;
	signal rand_counter_2 : integer := 0; 
	
	signal vert_counter_max_tmp : integer := 200000;
	signal horz_counter_max_tmp : integer := 200000;
	signal vert_counter_max : integer := 200000;
	signal horz_counter_max : integer := 200000;
	signal load_counters : std_logic := '0';
	signal initial_vert_dir : std_logic := '0';
	signal initial_horz_dir : std_logic := '0';
	signal initial_vert_dir_tmp : std_logic := '1';
	signal initial_horz_dir_tmp : std_logic := '0';
		
    signal horz_spd_ratechange : integer := 1;		
	signal vert_spd_ratechange : integer := 1;
	
begin


game_start <= i_plyr1_up or i_plyr1_down;

PROC_RAND_INITIAL : process(clk, rst)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            vert_counter_max_tmp <= 0;
            horz_counter_max_tmp <= 0;
            vert_counter_max <= 0;
            horz_counter_max <= 0;     
        else
            if(load_counters = '1') then
                vert_counter_max <= vert_counter_max_tmp;
                horz_counter_max <= horz_counter_max_tmp;
                initial_vert_dir <= initial_vert_dir_tmp;
                initial_horz_dir <= initial_horz_dir_tmp;
            else
                initial_vert_dir_tmp <= not(initial_vert_dir_tmp);
                if(vert_counter_max mod 2 = 0) then 
                    initial_horz_dir_tmp <= not(initial_horz_dir_tmp);
                end if;                     
                if(vert_counter_max_tmp < 250000) then
                    vert_counter_max_tmp <= vert_counter_max_tmp + 1;
                else
                    vert_counter_max_tmp <= 150001;
                end if;
                if(horz_counter_max_tmp > 150000) then
                    horz_counter_max_tmp <= horz_counter_max_tmp - 1;
                else
                    horz_counter_max_tmp <= 250000;
                end if;
            end if;                                                  
        end if;
    end if;
end process;                
            
PROC_BALL_VERT_MOVEMENT_FSM : process(clk, rst)
begin
	if(rising_edge(clk)) then
		if(rst = '1') then
			ps_vertmove_ball <= st_vertmove_wait_for_start;
		else
			case ps_vertmove_ball is
				when st_vertmove_wait_for_start =>
                    BALL_VERT_POS_BOT   <= BALL_VERT_STARTPOS;
                    vert_counter_up     <= 0;
                    vert_counter_down   <= 0;
                    --horz_spd_ratechange <= 0;
                    --vert_spd_ratechange <= 0;
                    if(game_start = '1' and initial_vert_dir = '1') then
                        load_counters <= '1';
                        ps_vertmove_ball <= st_ball_up;                        
                    elsif(game_start = '1' and initial_vert_dir = '0') then
                        load_counters <= '1';
                        ps_vertmove_ball <= st_ball_down;                        
                    end if;
				
				when st_ball_up =>
				    load_counters <= '0';
                    if(game_round_done = '1') then
                        ps_vertmove_ball <= st_vertmove_wait_for_start;
                    else
                        vert_counter_down <= 0;
                        if((BALL_VERT_POS_BOT < BORDER_FRAME_WIDTH + 1)) then --or ((BALL_VERT_POS_BOT <= PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT + BALL_HEIGHT) and (BALL_HORZ_POS_LEFT <= PADDLE_HORZ_POS + PADDLE_WIDTH))) then  
                            ps_vertmove_ball    <= st_ball_down;
                            --vert_spd_ratechange <= vert_spd_ratechange + 1;
                        else
                            if(vert_counter_up < vert_counter_max) then
                                vert_counter_up <= vert_counter_up + 1;
                            else
                                BALL_VERT_POS_BOT <= BALL_VERT_POS_BOT - 1;
                                vert_counter_up <= 0;
                            end if;
                        end if;
                    end if;

				when st_ball_down =>
				    load_counters <= '0';
                    if(game_round_done = '1') then
                        ps_vertmove_ball <= st_vertmove_wait_for_start;
                    else
                        vert_counter_up <= 0; 
                        if((BALL_VERT_POS_BOT > V_VISIBLE_AREA - BORDER_FRAME_WIDTH)) then -- or ((BALL_VERT_POS_BOT >= PADDLE_CURRENTPOS_BOT - BALL_HEIGHT) and (BALL_HORZ_POS_LEFT <= PADDLE_HORZ_POS + PADDLE_WIDTH))) then                                                 
                            ps_vertmove_ball    <= st_ball_up;
                            --vert_spd_ratechange <= vert_spd_ratechange + 1;
                        else
                            if(vert_counter_down < vert_counter_max) then
                                vert_counter_down <= vert_counter_down + 1;
                            else
                                BALL_VERT_POS_BOT <= BALL_VERT_POS_BOT + 1;
                                vert_counter_down <= 0;
                            end if;
                        end if;
                    end if;

				when others =>
				
			end case;
		end if;
	end if;
end process;

PROC_BALL_HORZ_MOVEMENT_FSM : process(clk, rst)
begin
	if(rising_edge(clk)) then
		if(rst = '1') then
			ps_horzmove_ball <= st_horzmove_wait_for_start;
		else
			case ps_horzmove_ball is
				when st_horzmove_wait_for_start =>                                
                    BALL_HORZ_POS_LEFT <= BALL_HORZ_STARTPOS;
                    game_round_done <= '0';
                    horz_counter_left <= 0;
                    horz_counter_right <= 0;
					if(game_start = '1' and initial_horz_dir = '1') then
						ps_horzmove_ball <= st_ball_left;                        
					elsif(game_start = '1' and initial_horz_dir = '0') then
						ps_horzmove_ball <= st_ball_right;                        
					end if;
					
				when st_ball_left =>
					horz_counter_right <= 0;
                    if(BALL_HORZ_POS_LEFT < 0 - BALL_WIDTH + 1) then                   -- CASE 1: BALL GOES OFFSCREEN ON EITHER SIDE
                        game_round_done <= '1';
                        ps_horzmove_ball <= st_horzmove_wait_for_start;
                    else
                        if(((BALL_HORZ_POS_LEFT <= PADDLE_HORZ_POS + PADDLE_WIDTH - 2) and ((BALL_VERT_POS_BOT >= PADDLE_CURRENTPOS_BOT) and -- CASE 3: BALL HITS PLAYER PADDLE
                        (BALL_VERT_POS_BOT <= PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)))) then
                            ps_horzmove_ball <= st_ball_right;
                            --horz_spd_ratechange <= horz_spd_ratechange + 1;
                        else
                            if(horz_counter_left <  horz_counter_max) then
                                horz_counter_left <= horz_counter_left + 1;
                            else
                                BALL_HORZ_POS_LEFT <= BALL_HORZ_POS_LEFT - 1;
                                horz_counter_left <= 0;                                     
                            end if;
                        end if;
					end if;

				when st_ball_right =>
					horz_counter_left <= 0;
                    if(BALL_HORZ_POS_LEFT > H_VISIBLE_AREA + BALL_WIDTH - 1) then
                        game_round_done <= '1';    
                        ps_horzmove_ball <= st_horzmove_wait_for_start;
                    else
                        if(((BALL_HORZ_POS_LEFT > CPU_PADDLE_HORZ_POS - 1) and ((BALL_VERT_POS_BOT >= CPU_PADDLE_CURRENTPOS_BOT) and -- CASE 4: BALL HITS CPU PADDLE
                        (BALL_VERT_POS_BOT <= CPU_PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT - BALL_HEIGHT)))) then
                            ps_horzmove_ball <= st_ball_left;
                            --horz_spd_ratechange <= horz_spd_ratechange + 1;
                        else
                            if(horz_counter_right <  horz_counter_max) then
                                horz_counter_right <= horz_counter_right + 1;
                            else
                                BALL_HORZ_POS_LEFT <= BALL_HORZ_POS_LEFT + 1;
                                horz_counter_right <= 0;                                     						
                            end if;
                        end if;
                    end if;
					
				when others =>
				
			end case;
		end if;
	end if;
end process;
                                                                                                                            

PROC_PLYR_PADDLE_MOVEMENT_FSM: process(clk, rst)
begin
	if(rising_edge(clk)) then
        if(rst = '1') then
           counter_paddle <= 0;    
	       ps_paddle <= st_idle;
	       PADDLE_CURRENTPOS_BOT <= PADDLE_VERT_STARTPOS;
        else	       
            case ps_paddle is
                when st_idle =>
                    if(i_plyr1_up = '1') then
                        ps_paddle <= st_move_up;
                    elsif(i_plyr1_down = '1') then
                        ps_paddle <= st_move_down;
                    elsif(i_plyr1_up = '1' and i_plyr1_down = '1') then
                        ps_paddle <= st_idle;
                    end if;
                    
                when st_move_down =>  
                    if(i_plyr1_down = '1') then
                        if(PADDLE_CURRENTPOS_BOT < V_VISIBLE_AREA - 6 - PADDLE_HEIGHT) then
                            if(counter_paddle <  100000) then
                                counter_paddle <= counter_paddle + 1;
                            else
                                PADDLE_CURRENTPOS_BOT <= PADDLE_CURRENTPOS_BOT + 1;
                                counter_paddle <= 0;                                     
                            end if;
                        else
                            PADDLE_CURRENTPOS_BOT <= PADDLE_CURRENTPOS_BOT;
                        end if;
                    elsif(i_plyr1_up = '1' or (i_plyr1_up = '1' and i_plyr1_down = '1')) then
                        counter_paddle <= 0;                                     
                        ps_paddle <= st_idle;
                    else
                        ps_paddle <= st_idle;
                    end if;
                    
                when st_move_up =>
                    if(i_plyr1_up = '1') then
                        if(PADDLE_CURRENTPOS_BOT > 5) then
                            if(counter_paddle <  100000) then
                                counter_paddle <= counter_paddle + 1;
                            else
                                PADDLE_CURRENTPOS_BOT <= PADDLE_CURRENTPOS_BOT - 1;
                                counter_paddle <= 0;                                     
                            end if;                            
                        else
                            PADDLE_CURRENTPOS_BOT <= PADDLE_CURRENTPOS_BOT;
                        end if;
                    elsif(i_plyr1_down = '1' or (i_plyr1_up = '1' and i_plyr1_down = '1')) then
                        ps_paddle <= st_idle;
                    else
                        counter_paddle <= 0;
                        ps_paddle <= st_idle;
                    end if;
                    
                when others=>
                
            end case;
        end if;            
	end if;
end process;

PROC_CPU_PADDLE_MOVEMENT_FSM: process(clk, rst)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            ps_cpu_paddle <= st_cpu_paddle_wait_for_start;
        else
            case ps_cpu_paddle is
                when st_cpu_paddle_wait_for_start =>
                    CPU_PADDLE_CURRENTPOS_BOT <= PADDLE_VERT_STARTPOS; 
                    if(game_start = '1') then
                        ps_cpu_paddle <= st_cpu_track_ball;
                    end if;
                    
                when st_cpu_track_ball =>
                    if(game_round_done = '1') then
                        ps_cpu_paddle <= st_cpu_paddle_wait_for_start;
                    else
                        CPU_PADDLE_CURRENTPOS_BOT <= BALL_VERT_POS_BOT - (PADDLE_HEIGHT/2);
                    end if;

                when others =>

            end case;
        end if;
    end if;
end process;
			
-- multiplexers for output vga data for pong graphics (player1 paddle, ball, cpu player paddle)

o_pong_vga_r <= X"F" when (i_loc_pixel_x > PADDLE_HORZ_POS       and i_loc_pixel_x < PADDLE_HORZ_POS + PADDLE_WIDTH 
                    and   i_loc_pixel_y > PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)
                    else
                    X"F" when (i_loc_pixel_x > CPU_PADDLE_HORZ_POS  and i_loc_pixel_x < CPU_PADDLE_HORZ_POS + PADDLE_WIDTH
                    and   i_loc_pixel_y > CPU_PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < CPU_PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)
                    else                        
					X"F" when (i_loc_pixel_x < BALL_HORZ_POS_LEFT + BALL_WIDTH and i_loc_pixel_x > BALL_HORZ_POS_LEFT 
                        and    i_loc_pixel_y < BALL_VERT_POS_BOT + BALL_HEIGHT and i_loc_pixel_y > BALL_VERT_POS_BOT) 
  					else
                    X"0"; -- black
                     
o_pong_vga_g <= X"F" when (i_loc_pixel_x > PADDLE_HORZ_POS       and i_loc_pixel_x < PADDLE_HORZ_POS + PADDLE_WIDTH 
                    and   i_loc_pixel_y > PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)
                    else
                    X"F" when (i_loc_pixel_x > CPU_PADDLE_HORZ_POS  and i_loc_pixel_x < CPU_PADDLE_HORZ_POS + PADDLE_WIDTH 
                    and   i_loc_pixel_y > CPU_PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < CPU_PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)
                    else  
                    X"F" when (i_loc_pixel_x < BALL_HORZ_POS_LEFT + BALL_WIDTH and i_loc_pixel_x > BALL_HORZ_POS_LEFT 
                    and    i_loc_pixel_y < BALL_VERT_POS_BOT + BALL_HEIGHT and i_loc_pixel_y > BALL_VERT_POS_BOT) 
                    else
                    X"F" when (i_loc_pixel_x < BORDER_FRAME_WIDTH or i_loc_pixel_x > H_VISIBLE_AREA - 1 - BORDER_FRAME_WIDTH -- can maybe take the - 1 out here and below
                        or    i_loc_pixel_y < BORDER_FRAME_WIDTH or i_loc_pixel_y > V_VISIBLE_AREA - 1 - BORDER_FRAME_WIDTH) 
                    else
                    X"0"; -- black
                     
o_pong_vga_b <= X"F" when (i_loc_pixel_x > PADDLE_HORZ_POS       and i_loc_pixel_x < PADDLE_HORZ_POS + PADDLE_WIDTH 
                    and   i_loc_pixel_y > PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)                  
                    else
                    X"F" when (i_loc_pixel_x > CPU_PADDLE_HORZ_POS  and i_loc_pixel_x < CPU_PADDLE_HORZ_POS + PADDLE_WIDTH 
                    and   i_loc_pixel_y > CPU_PADDLE_CURRENTPOS_BOT and i_loc_pixel_y < CPU_PADDLE_CURRENTPOS_BOT + PADDLE_HEIGHT)
                    else  
                    X"F" when (i_loc_pixel_x < BALL_HORZ_POS_LEFT + BALL_WIDTH and i_loc_pixel_x > BALL_HORZ_POS_LEFT 
                    and    i_loc_pixel_y < BALL_VERT_POS_BOT + BALL_HEIGHT and i_loc_pixel_y > BALL_VERT_POS_BOT) 
  					else
                    X"0";                                                 
                         

end rtl;

