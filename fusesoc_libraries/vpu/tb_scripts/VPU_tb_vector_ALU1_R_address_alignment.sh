verilator -Wall ../rtl/vector_ALU1_R_address_alignment.v ../bench/verilator_tb_ALU1_R_address_alignment.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvector_ALU1_R_address_alignment.mk Vvector_ALU1_R_address_alignment

./obj_dir/Vvector_ALU1_R_address_alignment

gtkwave wave.vcd

rm wave.vcd

rm -r ./obj_dir/