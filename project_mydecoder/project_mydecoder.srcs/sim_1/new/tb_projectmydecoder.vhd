----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/01/2025 04:52:23 AM
-- Design Name: 4-bit Calculator Testbench
-- Module Name: tb_projectmydecoder - Behavioral
-- Project Name: Calculator Design with VHDL and FPGA
-- Target Devices: Basys-3
-- Tool Versions: Vivado
-- Description: Testbench to simulate calculator operations (ADD, SUB, MUL, DIV),
--              including decimal outputs and error handling.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_projectmydecoder is
end tb_projectmydecoder;

architecture Behavioral of tb_projectmydecoder is

    -- DUT Component Declaration
    component project_mydecoder
        port(
            clk  : in std_logic;
            sw   : in std_logic_vector(15 downto 0);
            btnU : in std_logic; -- ADD
            btnD : in std_logic; -- SUB
            btnR : in std_logic; -- MUL
            btnL : in std_logic; -- DIV
            btnC : in std_logic; -- CLEAR/RESET
            an   : out std_logic_vector(3 downto 0);
            seg  : out std_logic_vector(6 downto 0);
            dp   : out std_logic
        );
    end component;

    -- Internal Signals
    signal clk  : std_logic;
    signal sw   : std_logic_vector(15 downto 0);
    signal btnU : std_logic;
    signal btnD : std_logic;
    signal btnR : std_logic;
    signal btnL : std_logic;
    signal btnC : std_logic;
    signal an   : std_logic_vector(3 downto 0);
    signal seg  : std_logic_vector(6 downto 0);
    signal dp   : std_logic;

    constant TbPeriod : time := 1000 ns; -- 1 us clock cycle
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin
    ----------------------------------------------------------------------
    -- Instantiate the DUT (Device Under Test)
    ----------------------------------------------------------------------
    dut : project_mydecoder
    port map(
        clk  => clk,
        sw   => sw,
        btnU => btnU,
        btnD => btnD,
        btnR => btnR,
        btnL => btnL,
        btnC => btnC,
        an   => an,
        seg  => seg,
        dp   => dp
    );

    ----------------------------------------------------------------------
    -- Clock Generation
    ----------------------------------------------------------------------
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;

    ----------------------------------------------------------------------
    -- TEST STIMULUS PROCESS
    ----------------------------------------------------------------------
stimuli : process
begin
    --------------------------------------------------------------------
    -- GLOBAL DISPLAY ON + INITIALIZATION
    --------------------------------------------------------------------
    sw <= (others => '0');
    sw(4) <= '1';       -- <<< ENABLE SEVEN-SEGMENT DISPLAY >>>
    btnU <= '0'; btnD <= '0'; btnR <= '0'; btnL <= '0'; btnC <= '0';
    wait for 1 us;

    --------------------------------------------------------------------
    -- RESET SYSTEM USING btnC
    --------------------------------------------------------------------
    btnC <= '1';
    wait for 1 us;
    btnC <= '0';
    wait for 1 us;

    --------------------------------------------------------------------
    -- TEST 1: 5 + 7 = 12
    --------------------------------------------------------------------
    sw(3 downto 0) <= "0101";  -- A = 5
    wait for 1 us;
    btnU <= '1';              -- Press ADD
    wait for 1 us;
    btnU <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0111";  -- B = 7
    sw(15) <= '1';            -- Equal pressed
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 2: 9 - 3 = 6
    --------------------------------------------------------------------
    sw(3 downto 0) <= "1001";  -- A = 9
    wait for 1 us;
    btnD <= '1';              -- Press SUB
    wait for 1 us;
    btnD <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0011";  -- B = 3
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 3: 3 * 4 = 12
    --------------------------------------------------------------------
    sw(3 downto 0) <= "0011";  -- A = 3
    wait for 1 us;
    btnR <= '1';              -- Press MUL
    wait for 1 us;
    btnR <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0100";  -- B = 4
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 4: 8 / 2 = 4 (Exact division, no decimal)
    --------------------------------------------------------------------
    sw(3 downto 0) <= "1000";  -- A = 8
    wait for 1 us;
    btnL <= '1';              -- Press DIV
    wait for 1 us;
    btnL <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0010";  -- B = 2
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 5: 7 / 3 = 2.33 (Decimal handling)
    --------------------------------------------------------------------
    sw(3 downto 0) <= "0111";  -- A = 7
    wait for 1 us;
    btnL <= '1';
    wait for 1 us;
    btnL <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0011";  -- B = 3
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 6: ERROR CASE - DIVIDE BY ZERO (9 / 0)
    --------------------------------------------------------------------
    sw(3 downto 0) <= "1001";  -- A = 9
    wait for 1 us;
    btnL <= '1';
    wait for 1 us;
    btnL <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0000";  -- B = 0 (error)
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- TEST 7: ERROR CASE - NEGATIVE SUBTRACTION (2 - 7)
    --------------------------------------------------------------------
    sw(3 downto 0) <= "0010";  -- A = 2
    wait for 1 us;
    btnD <= '1';
    wait for 1 us;
    btnD <= '0';
    wait for 1 us;

    sw(3 downto 0) <= "0111";  -- B = 7 (error)
    sw(15) <= '1';
    wait for 1 us;
    sw(15) <= '0';
    wait for 3 us;

    --------------------------------------------------------------------
    -- END SIMULATION
    --------------------------------------------------------------------
    TbSimEnded <= '1';
    wait;
end process;


end Behavioral;

-- Seven-seg does not change in simulation because multiplexing updates only every ~16 ms at 1 MHz.



