verilator -Wall rtl/vpu_top_simplified.v rtl/vector_ALU.v rtl/vector_registers.v bench/verilator_tb_simplified.c --cc --trace --exe --build

make -C obj_dir/ -f Vvpu_top_simplified.mk Vvpu_top_simplified

./obj_dir/Vvpu_top_simplified

gtkwave wave.vcd

rm wave.vcd

rm -r obj_dir