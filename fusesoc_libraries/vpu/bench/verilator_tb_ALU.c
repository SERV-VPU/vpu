#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvector_ALU.h"

 

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

 

    Vvector_ALU *top = new Vvector_ALU("ALU"); //Vtest.h里面的IO struct

 

    top->trace(tfp, 0);   

    tfp->open("wave.vcd"); //打开vcd

    uint32_t memory[1] = {1};

    int clk = 0;

    srand((unsigned int)time(NULL));
    printf("32 bits plus test\n");
    while (main_time < 20) { //控制仿真时间
        uint32_t A = rand() & 0xFFFFFFFF;
        uint32_t B = rand() & 0xFFFFFFFF;
        top->input1 = A;
        top->input2 = B;
        top->calculate_code = 0;
        top->i_16bits = 0;
        top->i_8bits = 0;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %d + %d = %u  %s\n", main_time, A, B, top->masked_result, (A+B==top->masked_result)? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    printf("32 bits minus test\n");
    while (main_time < 40) { //控制仿真时间
        uint32_t A = rand() & 0xFFFFFFFF;
        uint32_t B = rand() & 0xFFFFFFFF;
        top->input1 = A;
        top->input2 = B;
        top->calculate_code = 1;
        top->i_16bits = 0;
        top->i_8bits = 0;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %d - %d = %u  %s\n", main_time, A, B, top->masked_result, (A-B==top->masked_result)? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    printf("2 * 16 bits plus test\n");
    while (main_time < 60) { //控制仿真时间
        uint32_t A = rand() & 0xFFFF;
        uint32_t B = rand() & 0xFFFF;
        uint32_t C = rand() & 0xFFFF;
        uint32_t D = rand() & 0xFFFF;
        uint32_t E = (A<<16)+B;
        uint32_t F = (C<<16)+D;
        top->input1 = E;
        top->input2 = F;
        top->calculate_code = 0;
        top->i_16bits = 1;
        top->i_8bits = 0;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %x + %x = %x   %s\n", main_time, A, C, top->masked_result>>16, (((A+C)&0xFFFF)==((top->masked_result>>16)&0xFFFF))? "Correct":"Wrong"); //命令行输出仿真结果
        printf("%ld: %x + %x = %x  %s\n", main_time, B, D, top->masked_result&0xFFFF, (((B+D)&0xFFFF)==(top->masked_result&0xFFFF))? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    printf("2 * 16 bits minus test\n");
    while (main_time < 80) { //控制仿真时间
        uint32_t A = rand() & 0xFFFF;
        uint32_t B = rand() & 0xFFFF;
        uint32_t C = rand() & 0xFFFF;
        uint32_t D = rand() & 0xFFFF;
        uint32_t E = (A<<16)+B;
        uint32_t F = (C<<16)+D;
        top->input1 = E;
        top->input2 = F;
        top->calculate_code = 1;
        top->i_16bits = 1;
        top->i_8bits = 0;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %x - %x = %x  %s\n", main_time, A, C, top->masked_result>>16, (((A-C)&0xFFFF)==((top->masked_result>>16)&0xFFFF))? "Correct":"Wrong"); //命令行输出仿真结果
        printf("%ld: %x - %x = %x  %s\n", main_time, B, D, top->masked_result&0xFFFF, (((B-D)&0xFFFF)==(top->masked_result&0xFFFF))? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }
    printf("4 * 8 bits plus test\n");
    while (main_time < 400) { //控制仿真时间
        uint32_t A = rand() & 0xFF;
        uint32_t B = rand() & 0xFF;
        uint32_t C = rand() & 0xFF;
        uint32_t D = rand() & 0xFF;
        uint32_t E = rand() & 0xFF;
        uint32_t F = rand() & 0xFF;
        uint32_t G = rand() & 0xFF;
        uint32_t H = rand() & 0xFF;
        uint32_t I = (A<<24)+(B<<16)+(C<<8)+D;
        uint32_t J = (E<<24)+(F<<16)+(G<<8)+H;
        top->input1 = I;
        top->input2 = J;
        top->calculate_code = 0;
        top->i_16bits = 0;
        top->i_8bits = 1;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %x - %x = %x  %s\n", main_time, I, J, top->masked_result, (((A+E)&0xFF)==((top->masked_result>>24)&0xFF))&&(((B+F)&0xFF)==((top->masked_result>>16)&0xFF))&&(((C+G)&0xFF)==((top->masked_result>>8)&0xFF))&&(((D+H)&0xFF)==((top->masked_result)&0xFF))? "Correct":"Wrong"); //命令行输出仿真结果
        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    printf("4 * 8 bits minus test\n");
    while (main_time < 900) { //控制仿真时间
        uint32_t A = rand() & 0xFF;
        uint32_t B = rand() & 0xFF;
        uint32_t C = rand() & 0xFF;
        uint32_t D = rand() & 0xFF;
        uint32_t E = rand() & 0xFF;
        uint32_t F = rand() & 0xFF;
        uint32_t G = rand() & 0xFF;
        uint32_t H = rand() & 0xFF;
        uint32_t I = (A<<24)+(B<<16)+(C<<8)+D;
        uint32_t J = (E<<24)+(F<<16)+(G<<8)+H;
        top->input1 = I;
        top->input2 = J;
        top->calculate_code = 1;
        top->i_16bits = 0;
        top->i_8bits = 1;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %x - %x = %x %s\n", main_time, I, J, top->masked_result, (((A-E)&0xFF)==((top->masked_result>>24)&0xFF))&&(((B-F)&0xFF)==((top->masked_result>>16)&0xFF))&&(((C-G)&0xFF)==((top->masked_result>>8)&0xFF))&&(((D-H)&0xFF)==((top->masked_result)&0xFF))? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave

        main_time++; //推动仿真时间

    }

    /*
        u_int64_t main_time_2 = 0;
    printf("4 * 8 bits minus test\n");
    while (main_time_2 <= 0xFFFFFFFFFFFFFFFF) { //控制仿真时间
        uint32_t A = main_time_2 & 0xFF;
        uint32_t B = (main_time_2>>8) & 0xFF;
        uint32_t C = (main_time_2>>16) & 0xFF;
        uint32_t D = (main_time_2>>24) & 0xFF;
        uint32_t E = (main_time_2>>32) & 0xFF;
        uint32_t F = (main_time_2>>40) & 0xFF;
        uint32_t G = (main_time_2>>48) & 0xFF;
        uint32_t H = (main_time_2>>56) & 0xFF;
        uint32_t I = (A<<24)+(B<<16)+(C<<8)+D;
        uint32_t J = (E<<24)+(F<<16)+(G<<8)+H;
        top->input1 = I;
        top->input2 = J;
        top->calculate_code = 1;
        top->i_16bits = 0;
        top->i_8bits = 1;
        top->i_masks = 0b1111;
 
        top->eval(); //计算输出

        printf("%ld: %x - %x = %x %s\n", main_time, I, J, top->masked_result, (((A-E)&0xFF)==((top->masked_result>>24)&0xFF))&&(((B-F)&0xFF)==((top->masked_result>>16)&0xFF))&&(((C-G)&0xFF)==((top->masked_result>>8)&0xFF))&&(((D-H)&0xFF)==((top->masked_result)&0xFF))? "Correct":"Wrong"); //命令行输出仿真结果

        tfp->dump(main_time); //dump wave
        main_time++;
        main_time_2++; //推动仿真时间

    }
    */


    top->final();

    tfp->close();

    delete top;

 

    return 0;

}
