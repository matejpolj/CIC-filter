----------------------------------------------------------------------------------
-- Company: University of Ljubljana, Faculty of electircal engeneering
-- Engineer: Matej Poljanšek            
-- 
-- Create Date: 26.02.2024 09:54:54
-- Design Name: Comb for CIC filter
-- Module Name: comb - Behavioral
-- Project Name: CIC filter
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity comb is
    Generic ( BIN_width     : integer   := 2;
              N             : integer   := 1);
    Port ( clk      : in STD_LOGIC;
           nrst     : in STD_LOGIC;
           D_in     : in signed(BIN_width-1 downto 0);
           D_out    : out signed(BIN_width-1 downto 0));
end comb;

architecture Behavioral of comb is

    subtype  reg_size is    signed(BIN_width-1 downto 0);
    type COMB_CASCADING is array (1 to N) of reg_size;

    signal      buff        : signed(BIN_width-1 downto 0) := (others => '0');   
    signal      buff_array  : COMB_CASCADING;

begin

    main: process (clk)
        variable    buff_out   : signed(BIN_width-1 downto 0) := (others => '0');  
    begin
        if rising_edge(clk) then
            if (nrst = '0') then
                buff_array  <= (others => (others => '0'));
                buff_out    := (others => '0');
            else
                buff_out    := D_in-buff_array(N);
                for i in 1 to N loop
                    if i=1 then
                        buff_array(i)   <= D_in;
                    else
                        buff_array(i)   <= buff_array(i-1);
                    end if;                 
                end loop;
                buff        <= buff_out;
            end if;
        end if;
    end process;

    D_out   <= buff;

end Behavioral;
