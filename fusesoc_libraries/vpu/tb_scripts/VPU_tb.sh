verilator -Wall -I../rtl ../rtl/vpu_top.v ../rtl/vector_ALU.v ../rtl/vector_registers.v ../rtl/vector_ALU_R_address_alignment.v ../bench/verilator_tb.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvpu_top.mk Vvpu_top

./obj_dir/Vvpu_top

gtkwave ./wave.vcd

rm ./wave.vcd

rm -r ./obj_dir/