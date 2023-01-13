verilator -Wall ../rtl/vector_mem_if.v ../bench/verilator_tb_mem_if.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvector_mem_if.mk Vvector_mem_if

./obj_dir/Vvector_mem_if

gtkwave wave.vcd

rm wave.vcd

rm -r ./obj_dir/