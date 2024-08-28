----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.02.2024 18:33:59
-- Design Name: 
-- Module Name: test_integrator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

--package fun_def1 is new work.fun_def generic map (M => 3, R => 8, N => 2, BIN_width => 1);
--use work.fun_def1.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use std.textio.all;

use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity test_cic_filter is
    Generic (   BIN_width :     integer := 1;   -- input signal width
                BOUT_width :    integer := 10;   -- output signal width
                M :             integer := 3;   -- number of integer and comb stages
                R :             integer := 8;   -- recimation factor
                N :             integer := 2);  -- diferential delay
--  Port ( );
end test_cic_filter;

architecture Behavioral of test_cic_filter is

    --Declare components
    component cic_filter is
    Generic (   BIN_width : integer := 1;
                BOUT_width :integer := 16;
                M :         integer := 3;   -- number of integer and comb stages
                R :         integer := 8;   -- recimation factor
                N :         integer := 2);  -- diferential delay
    Port (      clk_i : in STD_LOGIC;
                clk_o : out STD_LOGIC;
                nrst :  in STD_LOGIC;
                D_in :  in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
                D_out : out STD_LOGIC_VECTOR (BOUT_width-1 downto 0));
    end component;
    
    CONSTANT period : TIME := 1 ns;
    signal D_in     : std_logic_vector(BIN_width-1 downto 0);
    signal D_out    : std_logic_vector(BOUT_width-1 downto 0);
    signal clk_i    : std_logic;
    signal clk_o    : std_logic;
    signal nrst     : std_logic;
    
    signal buff     : std_logic_vector(BIN_width-1 downto 0) := (others => '0');
    
    signal en       : std_logic := '0';
    
    signal o_valid  : std_logic := '0';
    signal o_add    : std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    
    
begin

    dut: cic_filter
    generic map(
        BIN_width   => BIN_width,
        BOUT_width  => BOUT_width,
        M           => M,
        R           => R,
        N           => N
    )
    port map(
       clk_i    => clk_i,
       clk_o    => clk_o,
       nrst     => nrst,
       D_in     => D_in,
       D_out    => D_out
    );
    
    clk_process : process
    begin
        clk_i <= '0';
        wait for period/2;  --for 0.5 ns signal is '0'.
        clk_i <= '1';
        wait for period/2;  --for next 0.5 ns signal is '1'.
    end process;
   
    file_read_process : process(clk_i, nrst)
        constant NUM_COL : integer := 1;
        type t_integer_array is array(integer range <>) of integer;
        file test_vector : text open read_mode is "D:\faks\2_letnik\mikroelektronski_sistemi\lab vaje\vaja09\VAJA10\TestData.txt";
        variable row : line;
        variable v_data_read : t_integer_array(1 to NUM_COL);
        variable v_data_row_counter : integer := 0;
    begin
        if (nrst = '0') then
            v_data_read := (others => -1);
            v_data_row_counter := 0;
        elsif (rising_edge(clk_i)) then
            if (en = '1') then
                if (not endfile(test_vector)) then
                    v_data_row_counter := v_data_row_counter+1;
                    readline(test_vector, row);
                end if;
                for kk in 1 to NUM_COL loop
                    read(row, v_data_read(kk));
                end loop;
                buff <= conv_std_logic_vector(v_data_read(1), BIN_width);
            end if;
        end if;
    end process;
    
    file_write_process: process(clk_o, nrst)
        file test_vectorw : text open write_mode is "D:\faks\2_letnik\mikroelektronski_sistemi\lab vaje\vaja09\VAJA10\CIC_fitered_data.txt";
        variable roww : line;
    begin
        if (rising_edge(clk_o)) then
            if (o_valid = '1') then
                write(roww, conv_integer(o_add), right, 10);
                writeline(test_vectorw, roww); 
            end if;
        end if;
    end process;

    testprocess : process 
        variable count :    integer     := 0;
    begin	
        nrst    <= '1';
        --buff    <= TO_SIGNED(0, 2);
        D_in    <= (others => '0'); --resize(buff, BIN_width);
        --first   <= '1';
        
        wait for 10 ns;
        
        nrst    <= '0';
        wait for 6 ns;
        nrst    <= '1';
        en      <= '1';
        o_valid <= '1';
        
        for i in 0 to 200000000 loop
            --buff    <= TO_SIGNED(i/2, 2);
--            if (count > 500) then
--                count := 0;
--                if (D_in(0) = '1') then
--                    D_in    <= (0 => '0', others => '0');
--                    wait for period;
--                else
--                    D_in    <= (0 => '1', others => '0');
--                    wait for period;
--                end if;
----                D_in    <= (0 => '1', others => '0');--resize(buff, BIN_width);
----                --D_in    <= TO_SIGNED(i/2, BIN_width);
----                wait for period;
----                D_in    <= (0 => '0', others => '0');
----                wait for period;
--            else 
--                count := count+1;
--                wait for period;
--            end if; 
            D_in <= buff;
            o_add <= D_out;
            wait for period/2;
            
        end loop;
        
        wait for 1000 ns;
        
        nrst    <= '0';
        
        wait for 20 ns;
	wait;
end process;
end Behavioral;
