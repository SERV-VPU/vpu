#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvector_registers.h"

vluint64_t main_time = 0;  //initial 仿真时间

double sc_time_stamp(){
    return main_time;
}

int main(int argc, char **argv){

    Verilated::commandArgs(argc, argv); 

    Verilated::traceEverOn(true); //导出vcd波形需要加此语句

    VerilatedVcdC* tfp = new VerilatedVcdC; //导出vcd波形需要加此语句

    Vvector_registers *top = new Vvector_registers("registers"); //Vtest.h里面的IO struct

    top->trace(tfp, 0);

    tfp->open("wave.vcd"); //打开vcd

    int clk = 0;
    while (main_time < 6) { //控制仿真时间
        top->i_clk = clk & 1;
        for (int i=0; i<8;i++)
            top->i_ALU_result[i] = 0xFF;
        top->i_update_vreg = 1;
        top->i_Vregs_input_adr = 1;

        top->eval(); //计算输出
        tfp->dump(main_time); //dump wave
        main_time++; //推动仿真时间
        clk++;
    }
    while (main_time < 12) { //控制仿真时间
        top->i_clk = clk++ & 1;
        top->i_update_vreg = 0;
        top->i_mask_addr = 1;
        top->i_Vregs_output_addr[0] = 1;
        top->i_Vregs_output_addr[1] = 2;

        top->eval(); //计算输出
        tfp->dump(main_time); //dump wave
        main_time++; //推动仿真时间

    }

    top->final();

    tfp->close();

    delete top;

    return 0;

}
