library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity oled_controller is
    Port ( 
           -- input --
           clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           
           -- output --
           oled_spi_clock : out STD_LOGIC;
           oled_spi_data : out STD_LOGIC;
           oled_vdd : out STD_LOGIC;
           oled_vbat : out STD_LOGIC;
           oled_reset_n : out STD_LOGIC;
           oled_dc_n : out STD_LOGIC;
           oled_vbat : out STD_LOGIC;
           aaa : out STD_LOGIC
           
           );
end oled_controller;

architecture Behavioral of oled_controller is

    ----------------------------------- Types ----------------------------------
    type STATE_TYPE is (IDLE, INIT, DELAY, RESET, CHARGE_PUMP);
    
    ---------------------------------- Signals ---------------------------------
    signal state : STATE_TYPE := IDLE;  
    signal next_state : STATE_TYPE := IDLE;  
    signal delay_done : STD_LOGIC := '0';  
    signal delay_start : STD_LOGIC := '0';  
    signal spi_load_data : STD_LOGIC := '0';  
    signal spi_done : STD_LOGIC := '0';  
    signal spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');  

    --------------------------------- Headers ----------------------------------

    component delay_gen 
        Port ( clock : in STD_LOGIC;
               delay_en : in STD_LOGIC;
               delay_done : out STD_LOGIC
            );
    end delay_gen;
    
    ----------------------------------------------------------------------------

    component SPI_Control
        Port ( clock : in STD_LOGIC;
               reset : in STD_LOGIC;
               data_in : in STD_LOGIC_VECTOR (7 downto 0); 
               load_data : in STD_LOGIC; -- signal indicates new data for transmission
               spi_data : out STD_LOGIC;
               spi_clock : out STD_LOGIC; -- 10MHz max
               done_sent : out STD_LOGIC); -- signal indicates data has been sent over SPI interface
    end SPI_Control;

begin

----------------------------------- State Machine ----------------------------------- 

    process (clock) 
    begin
        if falling_edge(spi_clock_temp) then
            if reset = '1' then
                state <= IDLE;
                next_state <= IDLE;
                oled_vdd <= '1';
                oled_vbat <= '1';
                oled_rst_n <= '1';
                oled_dc_n <= '1';
                delay_start <= '0';
                delay_done <= '0';
                spi_load_data <= '0';
                spi_data <= (others => '0');
                
            else 
                case state is
                    when IDLE =>
                        oled_vbat <= '1';
                        oled_rst_n <= '1';
                        oled_dc_n <= '0';
                        oled_vdd <= '0'; -- this module power is active low !!!
                        next_state <= INIT; -- because we wanna use delay several times
                    when DELAY =>
                        delay_start <= '1';
                        
                        if delay_done then
                            state <= next_state;
                        end if;
                        
                    when INIT =>
                        spi_data <=  x"000000ae";
                        spi_load_data <= '1';
                        if spi_done then
                            spi_load_data <= '0';
                            spi_data <= (others => '0');
                            oled_rst_n <= '0';
                            state <= DELAY;
                        end if;
                    when RESET => 
                            oled_rst_n <= '1';
                            next_state <= ;
                            state <= DELAY;
                            
                    when CHARGE_PUMP => 
                        spi_data <=  x"0000008d";
                        spi_load_data <= '1';
                        if spi_done then
                            spi_data <= (others => '0');
                            oled_rst_n <= '0';
                            state <= DELAY;
                        end if;
                    others => 
                        fuck
            
            end if;
        end if;
    
    
    end process;


----------------------------------- Port mapping ----------------------------------- 

       SPI :  Port MAP (   clock => clock,
                           reset => reset,
                           data_in => spi_data,
                           load_data => spi_load_data,
                           spi_data => oled_spi_data,
                           spi_clock => oled_spi_clock,
                           done_sent => spi_done);
                           
------------------------------------------------------------------------------------ 
   DELAY : component delay_gen Port MAP ( clock => clock,
                                          delay_en => delay_start,
                                          delay_done => delay_done);
                                          
end Behavioral;
