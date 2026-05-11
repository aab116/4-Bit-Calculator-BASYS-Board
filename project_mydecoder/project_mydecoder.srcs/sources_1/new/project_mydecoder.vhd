library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_mydecoder is
    Port ( 
        clk  : in  STD_LOGIC;
        sw   : in  STD_LOGIC_VECTOR (15 downto 0); -- SW3..0=input, SW15=equal, SW4=Display ON/OFF
        btnU : in  STD_LOGIC;  -- ADD
        btnD : in  STD_LOGIC;  -- SUB
        btnR : in  STD_LOGIC;  -- MUL
        btnL : in  STD_LOGIC;  -- DIV
        btnC : in  STD_LOGIC;  -- CLEAR
        an   : out STD_LOGIC_VECTOR (3 downto 0);  -- Anodes (active LOW)
        seg  : out STD_LOGIC_VECTOR (6 downto 0);  -- Segments (active LOW)
        dp   : out STD_LOGIC                      -- Decimal point
    );
end project_mydecoder;

architecture Behavioral of project_mydecoder is

    --------------------------------------------------------------------
    -- STATES
    --------------------------------------------------------------------
    type calc_state_type is (state_inputA, state_inputB, state_result, state_error);
    signal calc_state : calc_state_type := state_inputA;

    --------------------------------------------------------------------
    -- DATA REGISTERS
    --------------------------------------------------------------------
    signal A, B, result_val : integer range -9999 to 9999 := 0;
    signal current_in : integer range 0 to 15 := 0;
    signal op_code : STD_LOGIC_VECTOR(1 downto 0) := "00"; -- 00:+, 01:-, 10:*, 11:/

    -- Digit signals (0-9 normal, 15='E', 17='r', others blank)
    signal thousands_digit, hundreds_digit, tens_digit, ones_digit : integer range 0 to 18 := 0;
    signal decimal_needed : STD_LOGIC := '0';

    --------------------------------------------------------------------
    -- DISPLAY MULTIPLEXING
    --------------------------------------------------------------------
    signal refresh_cnt : unsigned(15 downto 0) := (others => '0');
    signal refresh_sel : STD_LOGIC_VECTOR(1 downto 0);
    signal current_digit_val : integer range 0 to 18 := 0;

    signal an_int  : STD_LOGIC_VECTOR(3 downto 0) := "1111";
    signal seg_int : STD_LOGIC_VECTOR(6 downto 0);

begin

    --------------------------------------------------------------------
    -- READ 4-BIT INPUT FROM SWITCHES (SW3..0)
    --------------------------------------------------------------------
    process(sw)
    begin
        current_in <= to_integer(unsigned(sw(3 downto 0)));
    end process;


    --------------------------------------------------------------------
    -- FSM FOR OPERATIONS
    --------------------------------------------------------------------
    process(clk)
        variable bu_prev, bd_prev, br_prev, bl_prev, bc_prev, eq_prev : STD_LOGIC := '0';
    begin
        if rising_edge(clk) then

            -- RESET
            if (btnC = '1') then
                calc_state <= state_inputA;
                A <= 0; B <= 0; result_val <= 0;

            -- FIRST OPERAND
            elsif calc_state = state_inputA then
                if (btnU='1' and bu_prev='0') then 
                    A <= current_in; op_code <= "00"; calc_state <= state_inputB; -- ADD
                elsif (btnD='1' and bd_prev='0') then 
                    A <= current_in; op_code <= "01"; calc_state <= state_inputB; -- SUB
                elsif (btnR='1' and br_prev='0') then 
                    A <= current_in; op_code <= "10"; calc_state <= state_inputB; -- MUL
                elsif (btnL='1' and bl_prev='0') then 
                    A <= current_in; op_code <= "11"; calc_state <= state_inputB; -- DIV
                end if;

            -- SECOND OPERAND + EQUAL (SW15)
            elsif calc_state = state_inputB then
                if (sw(15)='1' and eq_prev='0') then  -- Equal pressed
                    B <= current_in;

                    -- ERROR: divide by zero OR negative subtraction
                    if (op_code = "11" and current_in = 0) or
                       (op_code = "01" and (A - current_in) < 0) then
                        calc_state <= state_error;

                    else
                        case op_code is
                            when "00" => result_val <= A + current_in;   -- integer
                            when "01" => result_val <= A - current_in;   -- integer, non-negative by check
                            when "10" => result_val <= A * current_in;   -- integer
                            when "11" => result_val <= A / current_in;   -- store integer quotient
                            when others => null;
                        end case;
                        calc_state <= state_result;
                    end if;
                end if;
            end if;

            -- SAVE PREVIOUS BUTTON/SW STATES
            bu_prev := btnU; bd_prev := btnD; br_prev := btnR;
            bl_prev := btnL; bc_prev := btnC; eq_prev := sw(15);
        end if;
    end process;


    --------------------------------------------------------------------
    -- DIGIT EXTRACTION (NORMAL / RESULT / ERROR)
    -- Only DIVISION can produce decimal; others always integer.
    --------------------------------------------------------------------
    process(calc_state, result_val, current_in, op_code, A, B)
        variable temp_val    : integer;
        variable q           : integer;
        variable r           : integer;
        variable scaled_val  : integer;
    begin
        if calc_state = state_inputA or calc_state = state_inputB then
            -- Show current input
            decimal_needed  <= '0';
            thousands_digit <= 0;
            hundreds_digit  <= 0;
            tens_digit      <= current_in / 10;
            ones_digit      <= current_in mod 10;

        elsif calc_state = state_result then

            if op_code = "11" then
                -- DIVISION: decide if we need decimals
                if B /= 0 then
                    q := A / B;
                    r := A mod B;

                    if r = 0 then
                        -- Exact division, no decimal
                        decimal_needed <= '0';
                        temp_val := q;
                    else
                        -- Non-exact division → scale to 2 decimal places
                        decimal_needed <= '1';
                        scaled_val := (A * 100) / B;  -- e.g., 7/3 → 233 (=2.33)
                        temp_val := scaled_val;
                    end if;
                else
                    -- Shouldn't happen (handled as error in FSM), but safe default
                    decimal_needed <= '0';
                    temp_val := 0;
                end if;
            else
                -- +, -, * → always integer, no decimal
                decimal_needed <= '0';
                temp_val := result_val;
            end if;

            -- Extract digits from temp_val
            thousands_digit <= (abs(temp_val) / 1000) mod 10;
            hundreds_digit  <= (abs(temp_val) / 100) mod 10;
            tens_digit      <= (abs(temp_val) / 10) mod 10;
            ones_digit      <= abs(temp_val) mod 10;

        elsif calc_state = state_error then
            -- Show "Err "
            decimal_needed  <= '0';
            thousands_digit <= 15; -- 'E'
            hundreds_digit  <= 17; -- 'r'
            tens_digit      <= 17; -- 'r'
            ones_digit      <= 18; -- blank

        else
            -- Should not happen, but default to 0000
            decimal_needed  <= '0';
            thousands_digit <= 0;
            hundreds_digit  <= 0;
            tens_digit      <= 0;
            ones_digit      <= 0;
        end if;
    end process;


    --------------------------------------------------------------------
    -- 7-SEG MULTIPLEXING
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    refresh_sel <= std_logic_vector(refresh_cnt(15 downto 14));

    process(refresh_sel)
    begin
        case refresh_sel is
            when "00" => an_int <= "1110"; current_digit_val <= ones_digit;      -- AN0 (rightmost)
            when "01" => an_int <= "1101"; current_digit_val <= tens_digit;      -- AN1
            when "10" => an_int <= "1011"; current_digit_val <= hundreds_digit;  -- AN2
            when "11" => an_int <= "0111"; current_digit_val <= thousands_digit; -- AN3 (leftmost)
            when others =>
                an_int <= "1111"; 
                current_digit_val <= 18;
        end case;
    end process;


    --------------------------------------------------------------------
    -- 7-SEG DECODER (0-9, E, r, blank)
    --------------------------------------------------------------------
    process(current_digit_val)
    begin
        case current_digit_val is
            when 0  => seg_int <= "1000000";
            when 1  => seg_int <= "1111001";
            when 2  => seg_int <= "0100100";
            when 3  => seg_int <= "0110000";
            when 4  => seg_int <= "0011001";
            when 5  => seg_int <= "0010010";
            when 6  => seg_int <= "0000010";
            when 7  => seg_int <= "1111000";
            when 8  => seg_int <= "0000000";
            when 9  => seg_int <= "0010000";
            when 15 => seg_int <= "0000110"; -- 'E'
            when 17 => seg_int <= "0101111"; -- 'r'
            when others => seg_int <= "1111111"; -- blank
        end case;
    end process;


    --------------------------------------------------------------------
    -- FINAL OUTPUTS (SW4 = master display ON/OFF)
    --------------------------------------------------------------------
    an  <= (others => '1') when sw(4)='0' else an_int;
    seg <= (others => '1') when sw(4)='0' else seg_int;

    -- Decimal point ON only for non-integer division, at AN2 (hundreds_digit)
    dp <= '0' when (
              calc_state = state_result AND
              decimal_needed = '1' AND
              refresh_sel = "10" AND  -- AN2 (third from right)
              sw(4) = '1'
          )
          else '1';  -- active LOW

end Behavioral;
