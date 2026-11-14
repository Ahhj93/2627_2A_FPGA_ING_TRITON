library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler_tb is
end entity hdmi_controler_tb;

architecture tb of hdmi_controler_tb is
    -- Generic parameters
    constant h_res 	: positive := 720;
    constant v_res 	: positive := 480;

    constant h_sync	: positive := 61;
    constant h_fp	: positive := 58;
    constant h_bp	: positive := 18;

    constant v_sync	: positive := 5;
    constant v_fp	: positive := 30;
    constant v_bp	: positive := 9;

    -- Simulation constants
    constant h_total : positive := h_res + h_sync + h_fp + h_bp;
    constant v_total : positive := v_res + v_sync + v_fp + v_bp;

    -- Stimuli signals
    signal tb_i_clk     : std_logic;
    signal tb_i_rst_n   : std_logic;

    signal tb_o_hdmi_hs : std_logic;
    signal tb_o_hdmi_vs : std_logic;
    signal tb_o_hdmi_de : std_logic;

    signal tb_o_pixel_en      : std_logic;
    signal tb_o_pixel_address : natural range 0 to (h_res * v_res - 1);
    signal tb_o_x_counter     : natural range 0 to (h_res - 1);
    signal tb_o_y_counter     : natural range 0 to (v_res - 1);

    signal finished : boolean := false;
begin
    uut: entity work.hdmi_controler
    	generic map (
		    -- Resolution
		    h_res   => h_res,
		    v_res   => v_res,

		    -- Timings magic values (480p)
		    h_sync	=> h_sync,
		    h_fp	=> h_fp,
		    h_bp	=> h_bp,

		    v_sync	=> v_sync,
		    v_fp	=> v_fp,
		    v_bp	=> v_bp
	    )
	    port map (
            i_clk  		=> tb_i_clk,
            i_rst_n 	=> tb_i_rst_n,

            o_hdmi_hs   => tb_o_hdmi_hs,
            o_hdmi_vs   => tb_o_hdmi_vs,
            o_hdmi_de   => tb_o_hdmi_de,

            o_pixel_en      => tb_o_pixel_en,
            o_pixel_address => tb_o_pixel_address,
            o_x_counter     => tb_o_x_counter,
            o_y_counter     => tb_o_y_counter
  	    );
    
    p_clk : process
    begin
        if (finished = false) then
            tb_i_clk <= '0'; wait for 5 ns;
            tb_i_clk <= '1'; wait for 5 ns;
        else
            wait;
        end if;
    end process;

    p_stimuli : process
    begin
        tb_i_rst_n <= '0';
        wait until rising_edge(tb_i_clk);
        tb_i_rst_n <= '1';
        wait until rising_edge(tb_i_clk);

        for i in 0 to 2 * h_total*v_total loop
            wait until rising_edge(tb_i_clk);
        end loop;

        finished <= true;
        wait;
    end process;
end architecture tb;