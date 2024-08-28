----------------------------------------------------------------------------------
-- Company: University of Ljubljana, Faculty of electircal engeneering
-- Engineer: Matej Poljanšek            
-- 
-- Create Date: 26.02.2024 09:54:54
-- Design Name: Integrator for CIC filter
-- Module Name: integrator - Behavioral
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

entity integrator is
    generic ( BIN_width : integer := 16);
    Port ( clk      : in STD_LOGIC;
           nrst     : in STD_LOGIC;
           D_in     : in signed(BIN_width-1 downto 0);
           D_out    : out signed(BIN_width-1 downto 0));
end integrator;

architecture Behavioral of integrator is 
    
    signal      buff_in, buff_out   : signed(BIN_width-1 downto 0) := (others => '0');   

begin

    main: process (clk)
    begin
        if rising_edge(clk) then
            if (nrst = '0') then
                buff_in     <= (others => '0');
                buff_out    <= (others => '0');
            else
                buff_in     <= D_in;
                buff_out    <= buff_in+buff_out;
            end if;
        end if;
    end process;

    D_out   <= buff_out;
    
end Behavioral;
