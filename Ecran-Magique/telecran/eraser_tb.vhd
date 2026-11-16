library ieee;
use ieee.std_logic_1164.all;

entity eraser_tb is
end entity eraser_tb;

architecture tb of eraser_tb is
    constant MEM_SIZE   : positive := 32;    -- small RAM for short simulation
    constant CLK_PERIOD : time := 37 ns;     -- ~27 MHz

    signal clk           : std_logic := '0';
    signal rst_n         : std_logic := '0';
    signal pb_n          : std_logic := '1';
    signal clearing      : std_logic;
    signal clear_address : natural range 0 to MEM_SIZE - 1;
    signal ended         : boolean := false;
begin
    uut : entity work.eraser
        generic map (
            mem_size => MEM_SIZE
        )
        port map (
            i_clk      => clk,
            i_rst_n    => rst_n,
            i_pb_n     => pb_n,
            o_clearing => clearing,
            o_address  => clear_address
        );

    stim_proc : process
    begin
        rst_n <= '0';
        wait for CLK_PERIOD;
        rst_n <= '1';
        wait for 50 * CLK_PERIOD;

        pb_n <= '0';
        wait for CLK_PERIOD;
        pb_n <= '1';
        wait for 50 * CLK_PERIOD;

        ended <= true;
        wait;
    end process stim_proc;

    clk_process : process
    begin
        clk <= '0';
        wait for (CLK_PERIOD / 2);
        clk <= '1';
        wait for (CLK_PERIOD / 2);
        if (ended = true) then
            wait;
        end if;
    end process clk_process;
end architecture tb;
