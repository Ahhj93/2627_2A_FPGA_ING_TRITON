quit -sim

vlib work
vmap work work

vcom eraser.vhd
vcom eraser_tb.vhd

vsim work.eraser_tb

# INPUTS
add wave -divider inputs:
add wave -color yellow uut/i_clk
add wave -color yellow uut/i_rst_n
add wave -color yellow uut/i_pb_n

# ERASER
add wave -divider eraser:
add wave uut/r_pb
add wave uut/r_clearing
add wave -radix unsigned uut/r_address

# OUTPUTS
add wave -divider outputs:
add wave uut/o_clearing
add wave -radix unsigned uut/o_address

run -all
wave zoom full
