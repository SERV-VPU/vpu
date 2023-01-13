verilator -Wall ../rtl/vector_registers.v ../bench/verilator_tb_registers.c --cc --trace --exe --build

make -C ./obj_dir/ -f ./Vvector_registers.mk Vvector_registers

./obj_dir/Vvector_registers

gtkwave ./wave.vcd

rm ./wave.vcd

rm -r ./obj_dir