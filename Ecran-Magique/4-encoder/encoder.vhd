library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
    generic (
        -- 5000000 @ 50 MHz = 100 ms
        PERIOD_S_EN : natural := 5000000;
        WIDTH : natural := 10
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;
        i_A     : in std_logic;
        i_B     : in std_logic;
        o_leds  : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity encoder;

architecture rtl of encoder is
    signal s_en : std_logic := '0';

    signal r_a_cur  : std_logic := '0';
    signal r_a_prev : std_logic := '0';
    signal r_b_cur  : std_logic := '0';
    signal r_b_prev : std_logic := '0';

    signal s_a_rising  : std_logic;
    signal s_a_falling : std_logic;
    signal s_b_rising  : std_logic;
    signal s_b_falling : std_logic;

    signal s_clockwise     : std_logic;
    signal s_cntclockwise  : std_logic;

    signal r_cnt : unsigned(WIDTH-1 downto 0) := (others => '0');
begin
    -- Diviseur de fréquence pour avoir 100ms
    divider : process(i_clk, i_rst_n)
        variable counter : natural range 0 to PERIOD_S_EN-1 := 0;
    begin
        if (i_rst_n = '0') then
            counter := 0;
            s_en <= '0';
        elsif (rising_edge(i_clk)) then
            if (counter = PERIOD_S_EN-1) then
                counter := 0;
                s_en <= '1';
            else
                counter := counter + 1;
                s_en <= '0';
            end if;
        end if;
    end process divider;

    -- Echantillonage A et B
    sampling : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_a_cur  <= '0';
            r_a_prev <= '0';
            r_b_cur  <= '0';
            r_b_prev <= '0';
        elsif (rising_edge(i_clk)) then
            if (s_en = '1') then
                r_a_cur  <= i_A;
                r_a_prev <= r_a_cur;
                r_b_cur  <= i_B;
                r_b_prev <= r_b_cur;
            end if;
        end if;
    end process sampling;

    -- Détection fronts
    s_a_rising  <= r_a_cur and not r_a_prev;
    s_a_falling <= not r_a_cur and r_a_prev;

    s_b_rising  <= r_b_cur and not r_b_prev;
    s_b_falling <= not r_b_cur and r_b_prev;

    -- Sens
    s_clockwise    <= (s_a_rising and not r_b_cur) or (s_b_falling and r_a_cur);
    s_cntclockwise <= (s_b_rising and not r_a_cur) or (s_a_falling and r_b_cur);

    -- Compteur
    cnt_dcnt : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_cnt <= (others => '0');
        elsif (rising_edge(i_clk)) then
            if (s_en = '1') then
                if (s_clockwise = '1') then
                    r_cnt <= r_cnt + 1;
                elsif (s_cntclockwise = '1') then
                    r_cnt <= r_cnt - 1;
                end if;
            end if;
        end if;
    end process cnt_dcnt;

    o_leds <= std_logic_vector(r_cnt);
end architecture rtl;