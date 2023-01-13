verilator -Wall ../rtl/vector_mask_decoder.v ../bench/verilator_tb_mask_decoder.c --cc --trace --exe --build

make -C ./obj_dir/ -f Vvector_mask_decoder.mk Vvector_mask_decoder

./obj_dir/Vvector_mask_decoder

gtkwave wave.vcd

rm wave.vcd

rm -r ./obj_dir/