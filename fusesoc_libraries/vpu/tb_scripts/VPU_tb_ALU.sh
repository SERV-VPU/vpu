
verilator -Wall ../rtl/vector_ALU.v ../bench/verilator_tb_ALU.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvector_ALU.mk Vvector_ALU

./obj_dir/Vvector_ALU

gtkwave wave.vcd

rm wave.vcd

rm -r ./obj_dir/