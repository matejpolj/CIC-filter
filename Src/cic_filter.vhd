----------------------------------------------------------------------------------
-- Company: University of Ljubljana, Faculty of electircal engeneering
-- Engineer: Matej Poljanšek            
-- 
-- Create Date: 26.02.2024 09:54:54
-- Design Name: CIC filter
-- Module Name: cic_filter - Behavioral
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
use ieee.math_real.all;

entity cic_filter is
    Generic (   BIN_width : integer := 1;       -- input size register 
                BOUT_width :integer := 16;      -- output size register 
                M :         integer := 3;       -- number of integer and comb stages
                R :         integer := 8;       -- decimation factor
                N :         integer := 2);      -- diferential delay
    Port (      clk_i : in STD_LOGIC;
                clk_o : out STD_LOGIC;
                nrst :  in STD_LOGIC;
                D_in :  in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
                D_out : out STD_LOGIC_VECTOR (BOUT_width-1 downto 0));
end cic_filter;

architecture Behavioral of cic_filter is
    
    function BMAX_width_calculate(BIN_width : natural; R : natural; 
            N : natural; M : natural) return natural is
        constant a  : real  := real(R*N);
        constant b  : real  := log2(a);
        constant c  : real  := real(real(M)*b);
    begin
        return natural(c)+BIN_width;
    end function;
    
    constant Bmax_width :   integer := BMAX_width_calculate(BIN_width, R, N, M);
    
    subtype  reg_size is    signed(Bmax_width-1 downto 0);
    
    type ARRAY_CASCADING is array (1 to M-1) of reg_size;
    type STATE_T is (sample, hold);
    
    constant one        :  signed(1 downto 0)   := "01";
    constant mineone    :  signed(1 downto 0)   := "11";
    
    component integrator is
        generic ( BIN_width : integer := 16);
        Port ( clk      : in STD_LOGIC;
               nrst     : in STD_LOGIC;
               D_in     : in signed(BIN_width-1 downto 0);
               D_out    : out signed(BIN_width-1 downto 0));
    end component;
    
    component comb is
        Generic ( BIN_width     : integer   := 2;
                  N             : integer   := 1);
        Port ( clk      : in STD_LOGIC;
               nrst     : in STD_LOGIC;
               D_in     : in signed(BIN_width-1 downto 0);
               D_out    : out signed(BIN_width-1 downto 0));
    end component;

    signal data_tmp : signed(1 downto 0)            := (others => '0'); 
    signal data_in  : signed(Bmax_width-1 downto 0) := (others => '0'); 
    
    signal int_data : ARRAY_CASCADING               := (others => (others => '0'));
    signal int_out  : reg_size                      := (others => '0');
    
    
    signal  clk_d   : std_logic                     := '0';
    signal  status  : STATE_T                       := hold;
    signal  count   : integer range 0 to (R-1)      := 0;
    
    signal comb_data: ARRAY_CASCADING               := (others => (others => '0'));
    signal comb_out : reg_size                      := (others => '0');
    
    
begin

    SEL:    process(D_in)
    begin
        if (D_in(0) = '0') then
            data_tmp    <= mineone;
         else
            data_tmp    <= one;
        end if;
    end process; 
    
    RES:    process(clk_i)
    begin
        if (nrst = '0') then
            data_in  <= (others => '0');
        elsif (rising_edge(clk_i)) then   
            data_in  <= RESIZE(data_tmp, Bmax_width);
        end if;
    end process;
    
    -- integrataion cascade
    CASCADE_INT: for i in 1 to M generate
    begin
        GEN_INT_1: if i = 1 generate
        begin
            INT_1: integrator generic map ( BIN_width => Bmax_width)
            Port map (  clk => clk_i,
                        nrst => nrst,
                        D_in => data_in,
                        D_out => int_data(i));
        end generate;
        
        GEN_INT_I: if ((i>1)and(i<M)) generate
        begin
            INT_I: integrator generic map ( BIN_width => Bmax_width)
            Port map (  clk => clk_i,
                        nrst => nrst,
                        D_in => int_data(i-1),
                        D_out => int_data(i));
        end generate;
        
        GEN_INT_M: if i = M generate
        begin
            INT_M: integrator generic map ( BIN_width => Bmax_width)
            Port map (  clk => clk_i,
                        nrst => nrst,
                        D_in => int_data(i-1),
                        D_out => int_out);
        end generate;
    end generate;
    

    -- decimation process (counting samples and settind output clock accordingly
    DEC:    process(clk_i)
    begin
        if (nrst = '0') then
            status  <= hold;
            clk_d   <= '0';
            count   <= 0;
        elsif (rising_edge(clk_i)) then
            if (count = (R-1)) then
                count   <= 0;
                status  <= hold;
                clk_d   <= '0';
             elsif (count = (R/2-1)) then
                count   <= count+1;
                status  <= sample;
                clk_d   <= '1';
             else
                count   <= count+1;
             end if;
        end if;
    end process;
    
    -- comb cascade
    CASCADE_COMB: for i in 1 to M generate
    begin
        GEN_COMB_1: if i = 1 generate
        begin
            COMB_1: comb generic map ( BIN_width => Bmax_width, N => N)
            Port map (  clk => clk_d,
                        nrst => nrst,
                        D_in => int_out,
                        D_out => comb_data(i));
        end generate;
        
        GEN_COMB_I: if ((i>1)and(i<M)) generate
        begin
            COMB_I: comb generic map ( BIN_width => Bmax_width, N => N)
            Port map (  clk => clk_d,
                        nrst => nrst,
                        D_in => comb_data(i-1),
                        D_out => comb_data(i));
        end generate;
        
        GEN_COMB_M: if i = M generate
        begin
            COMB_M: comb generic map ( BIN_width => Bmax_width, N => N)
            Port map (  clk => clk_d,
                        nrst => nrst,
                        D_in => comb_data(i-1),
                        D_out => comb_out);
        end generate;
    end generate;
    

    clk_o   <= clk_d;
    D_out   <= STD_LOGIC_VECTOR(resize(comb_out, BOUT_width));
    
end Behavioral;
