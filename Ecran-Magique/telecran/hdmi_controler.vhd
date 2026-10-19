library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
	generic (
		-- Resolution
		h_res 	: positive := 720;
		v_res 	: positive := 480;

		-- Timings magic values (480p)
		h_sync	: positive := 61;
		h_fp	: positive := 58;
		h_bp	: positive := 18;

		v_sync	: positive := 5;
		v_fp	: positive := 30;
		v_bp	: positive := 9
	);
	port (
		i_clk  		: in std_logic;
    	i_rst_n 	: in std_logic;
		
    	o_hdmi_hs   : out std_logic;
    	o_hdmi_vs   : out std_logic;
    	o_hdmi_de   : out std_logic;

		o_pixel_en : out std_logic;
		o_pixel_address : out natural range 0 to (h_res * v_res - 1);
		o_x_counter : out natural range 0 to (h_res - 1);
		o_y_counter : out natural range 0 to (v_res - 1)
  	);
end hdmi_controler;

architecture rtl of hdmi_controler is
    constant h_start: positive := h_sync + h_fp;	-- 119
	constant h_end  : positive := h_res + h_start;	-- 839
	constant h_total: positive := h_end + h_bp;	    -- 857

	constant v_start: positive := v_sync + v_fp;	-- 35
	constant v_end  : positive := v_res + v_start;	-- 515
	constant v_total: positive := v_end + v_bp;	    -- 524

	constant pixel_number : natural := h_res*v_res;

    signal r_h_count : natural range 0 to h_total := 0;
    signal r_h_active: std_logic := '0';

	signal r_v_count : natural range 0 to v_total := 0;
    signal r_v_active: std_logic := '0';

	signal s_x_counter : natural range 0 to (h_res - 1) := 0;
	signal s_y_counter : natural range 0 to (v_res - 1) := 0;
begin
    -- Horizontal control signals
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			r_h_count   <= 0;
			o_hdmi_hs    <= '1';
			r_h_active     <= '0';
		elsif rising_edge(i_clk) then
			if (r_h_count = h_total) then
				r_h_count <= 0;
			else
				r_h_count <= r_h_count + 1;
			end if;

			if ((r_h_count >= h_sync) and (r_h_count /= h_total)) then
				o_hdmi_hs <= '1';
			else
				o_hdmi_hs <= '0';
			end if;

			if (r_h_count = h_start) then
				r_h_active <= '1';
			elsif (r_h_count = h_end) then
				r_h_active <= '0';
			end if;
		end if;
	end process;

	-- Vertical control signals
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			r_v_count <= 0;
			o_hdmi_vs  <= '1';
			r_v_active   <= '0';
		elsif rising_edge(i_clk) then
			if (r_h_count = h_total) then
				if (r_v_count = v_total) then
					r_v_count <= 0;
				else
					r_v_count <= r_v_count + 1;
				end if;
	
				if ((r_v_count >= v_sync) and (r_v_count /= v_total)) then
					o_hdmi_vs <= '1';
				else
					o_hdmi_vs <= '0';
				end if;

				if (r_v_count = v_start) then
					r_v_active <= '1';
				elsif (r_v_count = v_end) then
					r_v_active <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Display enable and dummy pixels
	process(i_clk, i_rst_n)
	begin
		if (i_rst_n = '0') then
			o_hdmi_de <= '0';
		elsif rising_edge(i_clk) then
			o_hdmi_de <= r_v_active and r_h_active;
		end if;
	end process;

	-- Generate address
	o_pixel_en <= '1' when (r_v_active = '1') and (r_h_active = '1') else '0';

	-- Modelsim is unhappy when s_x_counter is < 0 or > h_res. 
	-- We don't care as pixels are only considered valid when 0 <= s_x_counter < h_res
	-- But we need modelsim to simulate our component
	-- so we have add the when ... else statement
	-- Same goes for s_y_counter.
	-- Also works with a modulo, but takes a lot more resources
	-- Works without when ... else or mod on quartus
	s_x_counter <= (r_h_count - h_start - 1) when (r_h_count > h_start) and (r_h_count < h_res + h_start + 1) else 0;
	s_y_counter <= (r_v_count - v_start - 1) when (r_v_count > v_start) and (r_v_count < v_res + v_start + 1) else 0;

	o_pixel_address <= s_x_counter + (s_y_counter * h_res); --r_pixel_counter;
	
	o_x_counter <= s_x_counter;
	o_y_counter <= s_y_counter;
end architecture rtl;