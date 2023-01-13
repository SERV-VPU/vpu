
verilator ../rtl/vector_alu_and_decoder.v ../bench/verilator_tb_alu_and_decoder.c --cc --trace --exe  --build

make -C ./obj_dir/ -f Vvector_alu_and_decoder.mk Vvector_alu_and_decoder

./obj_dir/Vvector_alu_and_decoder