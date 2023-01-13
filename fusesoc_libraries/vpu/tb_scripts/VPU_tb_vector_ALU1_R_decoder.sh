verilator -Wall ../rtl/vector_ALU1_R_decoder.v ../bench/verilator_tb_ALU1_R_decoder.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvector_ALU1_R_decoder.mk Vvector_ALU1_R_decoder

./obj_dir/Vvector_ALU1_R_decoder

gtkwave wave.vcd

rm wave.vcd

rm -r ./obj_dir/