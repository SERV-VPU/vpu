#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvector_mem_if.h"
#include <stdbool.h>

vluint64_t main_time = 0;  //initial 仿真时间

double sc_time_stamp(){
    return main_time;
}

u_int32_t reorder(int error, u_int32_t base[4]){
    u_int32_t result;
    switch (error & 0b11){
        case 0:
            result = (base[0] << 24) + (base[1] << 16) + (base[2] << 8) + (base[3]);
            break;
        case 1:
            result = (base[1] << 24) + (base[2] << 16) + (base[3] << 8) + (base[0]);
            break;
        case 2:
            result = (base[2] << 24) + (base[3] << 16) + (base[0] << 8) + (base[1]);
            break;
        case 3:
            result = (base[3] << 24) + (base[0] << 16) + (base[1] << 8) + (base[2]);
            break;
    }
    return result;
}
int main(int argc, char **argv){

    Verilated::commandArgs(argc, argv); 

    Verilated::traceEverOn(true); //导出vcd波形需要加此语句

    VerilatedVcdC* tfp = new VerilatedVcdC; //导出vcd波形需要加此语句

    Vvector_mem_if *top = new Vvector_mem_if("vector_mem_if"); //Vtest.h里面的IO struct

    top->trace(tfp, 0);

    tfp->open("wave.vcd"); //打开vcd
    bool tested = false;
    u_int32_t A[4] = {0x11, 0x22, 0x33, 0x44};
    u_int32_t B[3] = {0b000, 0b101, 0b110};
    printf("original layout\n");
    for(int i=0; i<4;i++)
        printf("%x ", A[i]);
    printf("\n");
    printf("\n8-bit alginment error in 32-bit\n");
    for(int i=0; i<4;i++){
        for(int j=0; j<4;j++){
                tested = false;
                top->mem_inputs = reorder(0, A);
                top->shift_offset = i;
                top->i_Vreg_shift = j;
                top->i_width = 0;
                top->eval(); //计算输出
                tfp->dump(main_time); //dump wave
                main_time++; //推动仿真时间
                if(top->o_mem_outputs == reorder(i-j, A)){
                    tested = true;
                }
                printf("%02ld: Vadr: %02d, Madr: %02d, %08X %s\n", main_time, i*8, j*8, top->o_mem_outputs, tested? "correct":"wrong");
        }
    }
    printf("\n16-bit alginment error in 32-bit\n");
    for(int i=0; i<2;i++){
        for(int j=0; j<2;j++){
                tested = false;
                top->mem_inputs = reorder(0, A);
                top->shift_offset = i*2;
                top->i_Vreg_shift = j;
                top->i_width = 0b101;
                top->eval(); //计算输出
                tfp->dump(main_time); //dump wave
                main_time++; //推动仿真时间
                if(top->o_mem_outputs == reorder(i*2-j*2, A)){
                    tested = true;
                }
                printf("%02ld: Vadr: %02d, Madr: %02d, %08X %s\n", main_time, (i*8)<<1, (j*8)<<1,  top->o_mem_outputs, tested? "correct":"wrong");
        }
    }

    top->final();

    tfp->close();

    delete top;

    return 0;

}
