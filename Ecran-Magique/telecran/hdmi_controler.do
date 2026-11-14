quit -sim

vcom hdmi_controler.vhd
vcom hdmi_controler_tb.vhd

vsim -c work.hdmi_controler_tb

# INPUTS
add wave -divider Inputs:
add wave -color yellow uut/i_clk
add wave -color yellow uut/i_rst_n

# Horizontal
add wave -divider Horizontal:
add wave uut/r_h_count
add wave uut/r_h_active
# Horizontal
add wave -divider Vertical:
add wave uut/r_v_count
add wave uut/r_v_active

# OUTPUTS
add wave -divider ADV7513:
add wave uut/o_hdmi_hs
add wave uut/o_hdmi_vs
add wave uut/o_hdmi_de

add wave -divider Pixel:
add wave uut/o_pixel_en
add wave uut/o_pixel_address
add wave uut/o_x_counter
add wave uut/o_y_counter

run -all