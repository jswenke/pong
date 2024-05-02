
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- debounced output "o_debounced" stays high for as long as button is pushed after the minimum time (.1ms) has passed

entity button_debounce is
    generic(
            debounce_time : natural := 1048576 -- .1 ms @ 100MHz
        );
    Port (
            clk     : in std_logic;
            rst     : in std_logic;
            i_button: in std_logic;
            o_debounced : out std_logic
        );
end button_debounce;

architecture rtl of button_debounce is

    signal counter_timer : integer := 0;
    signal btn_reg0, btn_reg1 : std_logic := '0';
    
begin

PROC_DEBOUNCE: process(clk, rst)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            counter_timer <= 0;
            btn_reg0 <= '0';
            btn_reg1 <= '0';
        else
            btn_reg0 <= i_button;
            btn_reg1 <= btn_reg0;
            if(btn_reg1 = '1') then
                if(counter_timer < debounce_time) then
                    counter_timer <= counter_timer + 1;
                else
                    o_debounced <= '1';
                end if;                    
            else
                o_debounced <= '0';
            end if;
        end if;
    end if;
end process;                                        

end rtl;
