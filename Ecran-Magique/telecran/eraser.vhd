library ieee;
use ieee.std_logic_1164.all;

entity eraser is
    generic (
        mem_size : positive := 720 * 480
    );
    port (
        i_clk      : in std_logic;
        i_rst_n    : in std_logic;
        i_pb_n     : in std_logic;
        o_clearing : out std_logic;
        o_address  : out natural range 0 to mem_size - 1
    );
end entity eraser;

architecture rtl of eraser is
    signal r_pb : std_logic := '1';

    signal r_clearing : std_logic := '1';
    signal r_address  : natural range 0 to mem_size - 1 := 0;
begin
    push : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_pb <= '1';
        elsif rising_edge(i_clk) then
            r_pb <= i_pb_n;
        end if;
    end process push;

    -- Address counter
    counter : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_clearing <= '1';
            r_address  <= 0;
        elsif rising_edge(i_clk) then
            if (r_clearing = '1') then
                if (r_address = mem_size - 1) then
                    r_clearing <= '0';
                    r_address  <= 0;
                else
                    r_address <= r_address + 1;
                end if;
            elsif (r_pb = '0') then
                r_clearing <= '1';
            end if;
        end if;
    end process counter;

    o_clearing <= r_clearing;
    o_address  <= r_address;
end architecture rtl;
