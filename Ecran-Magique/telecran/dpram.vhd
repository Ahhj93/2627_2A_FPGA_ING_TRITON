library ieee;
use ieee.std_logic_1164.all;

entity dpram is
    generic
    (
        mem_size    : natural := 720 * 480;
        data_width  : natural := 8
    );
   port 
   (   
        i_clk_a        : in std_logic;
        i_clk_b        : in std_logic;

        i_data_a    : in std_logic_vector(data_width-1 downto 0);
        i_data_b    : in std_logic_vector(data_width-1 downto 0);
        i_addr_a    : in natural range 0 to mem_size-1;
        i_addr_b    : in natural range 0 to mem_size-1;
        i_we_a      : in std_logic := '1';
        i_we_b      : in std_logic := '1';
        o_q_a       : out std_logic_vector(data_width-1 downto 0);
        o_q_b       : out std_logic_vector(data_width-1 downto 0)
   );
   
end dpram;

architecture rtl of dpram is
    -- Build a 2-D array type for the RAM
    subtype word_t is std_logic_vector(data_width-1 downto 0);
    type memory_t is array(0 to mem_size-1) of word_t;
    
    -- Declare the RAM
    shared variable ram : memory_t;
begin
    -- Port A
    process(i_clk_a)
    begin
        if(rising_edge(i_clk_a)) then 
            if(i_we_a = '1') then
                ram(i_addr_a) := i_data_a;
            end if;
            o_q_a <= ram(i_addr_a);
        end if;
    end process;
    
    -- Port B
    process(i_clk_b)
    begin
        if(rising_edge(i_clk_b)) then
            if(i_we_b = '1') then
                ram(i_addr_b) := i_data_b;
            end if;
            o_q_b <= ram(i_addr_b);
        end if;
    end process;
end rtl;
