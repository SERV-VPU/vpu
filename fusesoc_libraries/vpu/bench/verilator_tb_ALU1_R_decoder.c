#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvector_ALU1_R_decoder.h"

vluint64_t main_time = 0;  //initial 仿真时间

double sc_time_stamp(){
    return main_time;
}

int main(int argc, char **argv){

    Verilated::commandArgs(argc, argv); 

    Verilated::traceEverOn(true); //导出vcd波形需要加此语句

    VerilatedVcdC* tfp = new VerilatedVcdC; //导出vcd波形需要加此语句

    Vvector_ALU1_R_decoder *top = new Vvector_ALU1_R_decoder("vector_ALU1_R_decoder"); //Vtest.h里面的IO struct

    top->trace(tfp, 0);

    tfp->open("wave.vcd"); //打开vcd
    for(int i=0; i<4;i++){
        for(int j=0; j<8; j++){
            top->i_width = i;
            top->i_ALU1_R = j;
            top->eval(); //计算输出
            tfp->dump(main_time); //dump wave
            main_time++; //推动仿真时间
            //printf("%ld: %08X\n", main_time, top->mem_outputs);
        }
    }

    top->final();

    tfp->close();

    delete top;

    return 0;

}
