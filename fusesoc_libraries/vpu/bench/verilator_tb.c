#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvpu_top.h"



vluint64_t main_time = 0;  //initial 仿真时间



double sc_time_stamp()

{

    return main_time;

}



int main(int argc, char **argv)

{

    Verilated::commandArgs(argc, argv);

    Verilated::traceEverOn(true); //导出vcd波形需要加此语句



    VerilatedVcdC* tfp = new VerilatedVcdC; //导出vcd波形需要加此语句



    Vvpu_top *top = new Vvpu_top("top"); //Vtest.h里面的IO struct



    top->trace(tfp, 0);

    tfp->open("wave.vcd"); //打开vcd


    int clk = 0;
    while (main_time < 100) { //控制仿真时间
        if(main_time < 2){
            top->i_load_fp_op = 1;
            top->i_vpu_valid = 1;
        }
        else{
            top->i_load_fp_op = 0;
            top->i_vpu_valid = 0;
        }
        top->i_width = 2;
        top->i_vpu_rs1 = 0;
        //top->i_vpu_rs2 = 0;
        top->i_vpu_vd = 0;
        top->i_vpu_mem_dat = 0xFFFFFFFF;
        top->i_element_size = 3;

        top->i_clk = clk&1;
        clk++;

        top->eval(); //计算输出

        //printf("%ld: %u %u %u\n", main_time, top->V3_0, top->V3_1, top->V3_2); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    top->final();

    tfp->close();

    delete top;



    return 0;

}
