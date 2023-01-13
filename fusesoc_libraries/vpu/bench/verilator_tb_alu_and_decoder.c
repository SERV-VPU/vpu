#include <stdlib.h>
#include "verilated_vcd_c.h" //可选，如果要导出vcd则需要加上
#include "Vvector_alu_and_decoder.h"

 
vluint64_t main_time = 0;  //initial 仿真时间
int count = 0;
int pass = 0;

#pragma region Helper functions
u_int8_t get_8_bits(u_int32_t i, int index)
{
    return (i >> (8*index)) & 0xFF;
}

u_int16_t get_16_bits(u_int32_t i, int index)
{
    return ( i >> (16*index) ) & 0xFFFF;
}

u_int32_t get_32_bits(u_int8_t i1, u_int8_t i2, u_int8_t i3, u_int8_t i4 )
{
    u_int32_t result = 0;
    result |= i4;
    result <<= 8;
    result |= i3;
    result <<= 8;
    result |= i2;
    result <<= 8;
    result |= i1;

    return result;
}

u_int32_t get_32_bits(u_int16_t i1, u_int16_t i2)
{
    u_int32_t result;
    result |= i2;
    result <<= 16;
    result |= i1;
    return result;
}

int8_t overflow32(u_int32_t A, u_int32_t B, u_int32_t R)
{
    if(  ((A & 0x80000000) == (B & 0x80000000)) && ((A & 0x80000000) != (R & 0x80000000)) )
    {
        if(R & 0x80000000) return 1;
        else return -1;
    }
    else return 0;
}
int8_t overflow16(u_int16_t A, u_int16_t B, u_int16_t R)
{
    if(  ((A & 0x8000) == (B & 0x8000)) && ((A & 0x8000) != (R & 0x8000)) )
    {
        if(R & 0x8000) return 1;
        else return -1;
    }
    else return 0;
}
int8_t overflow8(u_int8_t A, u_int8_t B, u_int8_t R)
{
    if(  ((A & 0x80) == (B & 0x80)) && ((A & 0x80) != (R & 0x80)) )
    {
        if(R & 0x80) return 1;
        else return -1;
    }
    else return 0;
}

bool testFormat(u_int32_t e, u_int32_t r)
{
    count++;
    printf(":%s\r\n", e==r ? "\033[32mPass\033[39m" : "\033[31mFail\033[39m" );
    if(e==r) pass++;
    else printf("Expected: %#010x Result: %#010x\r\n", e, r);
    printf("\r\n");
    return e==r;
}
#pragma endregion
#pragma region Signed add and subtract
void testAdd32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit signed vector add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000000;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A + B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testAdd16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("16-bit signed vector add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000000;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    u_int16_t expected1 = get_16_bits(A, 0) + get_16_bits(B, 0);
    u_int16_t expected2 = get_16_bits(A, 1) + get_16_bits(B, 1);

    u_int32_t expected = get_32_bits(expected1, expected2);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testAdd8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("8-bit signed vector add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000000;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = get_8_bits(A, 0) + get_8_bits(B, 0);
    u_int8_t expected1 = get_8_bits(A, 1) + get_8_bits(B, 1); 
    u_int8_t expected2 = get_8_bits(A, 2) + get_8_bits(B, 2); 
    u_int8_t expected3 = get_8_bits(A, 3) + get_8_bits(B, 3); 

    u_int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSub32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit signed vector sub test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000010;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A - B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSub16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("16-bit signed vector sub test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000010;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    int16_t expected1 = get_16_bits(A, 0) - get_16_bits(B, 0); 
    int16_t expected2 = get_16_bits(A, 1) - get_16_bits(B, 1);

    u_int32_t expected = get_32_bits(expected1, expected2);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSub8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("8-bit signed vector sub test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000010;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = (int8_t)get_8_bits(A, 0) - (int8_t)get_8_bits(B, 0);
    u_int8_t expected1 = (int8_t)get_8_bits(A, 1) - (int8_t)get_8_bits(B, 1);
    u_int8_t expected2 = (int8_t)get_8_bits(A, 2) - (int8_t)get_8_bits(B, 2);
    u_int8_t expected3 = (int8_t)get_8_bits(A, 3) - (int8_t)get_8_bits(B, 3);

    u_int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}
#pragma endregion
#pragma region bitwise operations
void testAnd(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit vector and test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b001001;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A & B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testOr(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit vector or test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b001010;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A | B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testXor(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit vector xor test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b001011;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A ^ B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}
#pragma endregion
#pragma region Max/Min 
void testMax32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("32-bit signed vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000111;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = ( (int32_t)A > (int32_t)B)?A:B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMax16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("16-bit signed vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000111;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    u_int16_t ex0 = ((int16_t)get_16_bits(A, 0)) > ((int16_t)get_16_bits(B, 0))? get_16_bits(A, 0) : get_16_bits(B, 0) ; 
    u_int16_t ex1 = ((int16_t)get_16_bits(A, 1)) > ((int16_t)get_16_bits(B, 1))? get_16_bits(A, 1) : get_16_bits(B, 1) ; 

    u_int32_t expected = get_32_bits(ex0, ex1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMax8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("8-bit signed vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000111;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = ((int8_t)get_8_bits(A, 0)) > ((int8_t)get_8_bits(B, 0)) ? get_8_bits(A, 0) : get_8_bits(B, 0);
    u_int8_t expected1 = ((int8_t)get_8_bits(A, 1)) > ((int8_t)get_8_bits(B, 1)) ? get_8_bits(A, 1) : get_8_bits(B, 1);
    u_int8_t expected2 = ((int8_t)get_8_bits(A, 2)) > ((int8_t)get_8_bits(B, 2)) ? get_8_bits(A, 2) : get_8_bits(B, 2);
    u_int8_t expected3 = ((int8_t)get_8_bits(A, 3)) > ((int8_t)get_8_bits(B, 3)) ? get_8_bits(A, 3) : get_8_bits(B, 3);

    int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMin32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("32-bit signed vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000101;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = ( (int32_t)A < (int32_t)B)?A:B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMin16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("16-bit signed vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000101;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    u_int16_t ex0 = ((int16_t)get_16_bits(A, 0)) < ((int16_t)get_16_bits(B, 0))? get_16_bits(A, 0) : get_16_bits(B, 0) ; 
    u_int16_t ex1 = ((int16_t)get_16_bits(A, 1)) < ((int16_t)get_16_bits(B, 1))? get_16_bits(A, 1) : get_16_bits(B, 1) ; 

    u_int32_t expected = get_32_bits(ex0, ex1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMin8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("8-bit signed vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000101;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = ((int8_t)get_8_bits(A, 0)) < ((int8_t)get_8_bits(B, 0)) ? get_8_bits(A, 0) : get_8_bits(B, 0);
    u_int8_t expected1 = ((int8_t)get_8_bits(A, 1)) < ((int8_t)get_8_bits(B, 1)) ? get_8_bits(A, 1) : get_8_bits(B, 1);
    u_int8_t expected2 = ((int8_t)get_8_bits(A, 2)) < ((int8_t)get_8_bits(B, 2)) ? get_8_bits(A, 2) : get_8_bits(B, 2);
    u_int8_t expected3 = ((int8_t)get_8_bits(A, 3)) < ((int8_t)get_8_bits(B, 3)) ? get_8_bits(A, 3) : get_8_bits(B, 3);

    int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMaxu32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("32-bit unsigned vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000110;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = ( A > B)?A:B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMaxu16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("16-bit unsigned vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000110;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    u_int16_t ex0 = (get_16_bits(A, 0)) > (get_16_bits(B, 0))? get_16_bits(A, 0) : get_16_bits(B, 0) ; 
    u_int16_t ex1 = (get_16_bits(A, 1)) > (get_16_bits(B, 1))? get_16_bits(A, 1) : get_16_bits(B, 1) ; 

    u_int32_t expected = get_32_bits(ex0, ex1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMaxu8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("8-bit unsigned vector max test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000110;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = (get_8_bits(A, 0)) > (get_8_bits(B, 0)) ? get_8_bits(A, 0) : get_8_bits(B, 0);
    u_int8_t expected1 = (get_8_bits(A, 1)) > (get_8_bits(B, 1)) ? get_8_bits(A, 1) : get_8_bits(B, 1);
    u_int8_t expected2 = (get_8_bits(A, 2)) > (get_8_bits(B, 2)) ? get_8_bits(A, 2) : get_8_bits(B, 2);
    u_int8_t expected3 = (get_8_bits(A, 3)) > (get_8_bits(B, 3)) ? get_8_bits(A, 3) : get_8_bits(B, 3);

    int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMinu32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("32-bit unsigned vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000100;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = ( A < B)?A:B;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMinu16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("16-bit unsigned vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000100;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;

    u_int16_t ex0 = (get_16_bits(A, 0)) < (get_16_bits(B, 0))? get_16_bits(A, 0) : get_16_bits(B, 0) ; 
    u_int16_t ex1 = (get_16_bits(A, 1)) < (get_16_bits(B, 1))? get_16_bits(A, 1) : get_16_bits(B, 1) ; 

    u_int32_t expected = get_32_bits(ex0, ex1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testMinu8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, int32_t A, int32_t B)
{
    printf("8-bit unsigned vector min test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b000100;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t expected0 = (get_8_bits(A, 0)) < (get_8_bits(B, 0)) ? get_8_bits(A, 0) : get_8_bits(B, 0);
    u_int8_t expected1 = (get_8_bits(A, 1)) < (get_8_bits(B, 1)) ? get_8_bits(A, 1) : get_8_bits(B, 1);
    u_int8_t expected2 = (get_8_bits(A, 2)) < (get_8_bits(B, 2)) ? get_8_bits(A, 2) : get_8_bits(B, 2);
    u_int8_t expected3 = (get_8_bits(A, 3)) < (get_8_bits(B, 3)) ? get_8_bits(A, 3) : get_8_bits(B, 3);

    int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}
#pragma endregion
#pragma region Signed Saturation add
void testSadd32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit signed vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100001;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    int32_t expected = A + B;
    if(overflow32(A, B, expected) == 1) expected = 0x7FFFFFFF;
    else if(overflow32(A, B, expected) == -1) expected = 0x80000001;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSadd16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("16-bit signed vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100001;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;
    
    int16_t A0 = get_16_bits(A, 0);
    int16_t A1 = get_16_bits(A, 1);

    int16_t B0 = get_16_bits(B, 0);    
    int16_t B1 = get_16_bits(B, 1);        

    int16_t expected0 = A0 + B0;
    int16_t expected1 = A1 + B1;

    if(overflow32(A0, B0, expected0) == 1) expected0 = 0x7FFF;
    else if(overflow32(A0, B0, expected0) == -1) expected0 = 0x8001;
    if(overflow16(A1, B1, expected1)) expected1 = 0x7FFF;
    else if(overflow32(A1, B1, expected1) == -1) expected1 = 0x8001;

    u_int32_t expected = get_32_bits(expected0, expected1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSadd8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("8-bit signed vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100001;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    int8_t A0 = get_8_bits(A, 0);    
    int8_t A1 = get_8_bits(A, 1);
    int8_t A2 = get_8_bits(A, 2);
    int8_t A3 = get_8_bits(A, 3);

    int8_t B0 = get_8_bits(B, 0);
    int8_t B1 = get_8_bits(B, 1);
    int8_t B2 = get_8_bits(B, 2);    
    int8_t B3 = get_8_bits(B, 3);        

    int8_t expected0 = A0 + B0;
    int8_t expected1 = A1 + B1; 
    int8_t expected2 = A2 + B2; 
    int8_t expected3 = A3 + B3; 

    if(overflow8(A0, B0, expected0) == 1) expected0 = 0x7F;
    else if(overflow32(A0, B0, expected0) == -1) expected0 = 0x81;
    if(overflow8(A1, B1, expected1)== 1) expected1 = 0x7F;
    else if(overflow32(A1, B1, expected1) == -1) expected1 = 0x81;
    if(overflow8(A2, B2, expected2)== 1) expected2 = 0x7F;
    else if(overflow32(A2, B2, expected2) == -1) expected2 = 0x81;
    if(overflow8(A3, B3, expected3)== 1) expected3 = 0x7F;
    else if(overflow32(A3, B3, expected3) == -1) expected3 = 0x81;

    u_int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}
#pragma endregion
#pragma region Unsigned saturation add
void testSaddu32(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("32-bit unsigned vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100000;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 0;

    u_int32_t expected = A + B;
    if( (expected < A) || (expected < B) ) expected = 0xFFFFFFFF;

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSaddu16(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("16-bit unsigned vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100000;
    top->i_masks = 0b1111;
    top->i_16bits = 1;
    top->i_8bits = 0;
    
    u_int16_t A0 = get_16_bits(A, 0);
    u_int16_t A1 = get_16_bits(A, 1);

    u_int16_t B0 = get_16_bits(B, 0);    
    u_int16_t B1 = get_16_bits(B, 1);

    u_int16_t expected0 = A0 + B0;
    u_int16_t expected1 = A1 + B1;

    if( (expected0 < A0) || (expected0 < B0) ) expected0 = 0xFFFF;
    if( (expected1 < A1) || (expected1 < B1) ) expected1 = 0xFFFF;

    u_int32_t expected = get_32_bits(expected0, expected1);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}

void testSaddu8(VerilatedVcdC* tfp, Vvector_alu_and_decoder *top, u_int32_t A, u_int32_t B)
{
    printf("8-bit unsigned vector saturation add test");
    top->input1 = A;
    top->input2 = B;
    top->i_funct6 = 0b100000;
    top->i_masks = 0b1111;
    top->i_16bits = 0;
    top->i_8bits = 1;

    u_int8_t A0 = get_8_bits(A, 0);    
    u_int8_t A1 = get_8_bits(A, 1);
    u_int8_t A2 = get_8_bits(A, 2);
    u_int8_t A3 = get_8_bits(A, 3);

    u_int8_t B0 = get_8_bits(B, 0);
    u_int8_t B1 = get_8_bits(B, 1);
    u_int8_t B2 = get_8_bits(B, 2);    
    u_int8_t B3 = get_8_bits(B, 3);        

    u_int8_t expected0 = A0 + B0;
    u_int8_t expected1 = A1 + B1; 
    u_int8_t expected2 = A2 + B2; 
    u_int8_t expected3 = A3 + B3; 

    if( (expected0 < A0) || (expected0 < B0) ) expected0 = 0xFF;
    if( (expected1 < A1) || (expected1 < B1) ) expected1 = 0xFF;
    if( (expected2 < A2) || (expected2 < B2) ) expected2 = 0xFF;
    if( (expected3 < A3) || (expected3 < B3) ) expected3 = 0xFF;

    u_int32_t expected = get_32_bits(expected0, expected1, expected2, expected3);

    top->eval();

    testFormat( expected, top->masked_result );

    main_time++;

    tfp->dump(main_time);
}
#pragma endregion
int main(int argc, char **argv)

{
    srand((unsigned int)time(NULL));

    Verilated::commandArgs(argc, argv); 

    Verilated::traceEverOn(true); //导出vcd波形需要加此语句

    VerilatedVcdC* tfp = new VerilatedVcdC; //导出vcd波形需要加此语句

    Vvector_alu_and_decoder *top = new Vvector_alu_and_decoder("Hello"); //Vtest.h里面的IO struct

    top->trace(tfp, 0);   

    tfp->open("wave.vcd"); //打开vcd

    uint32_t memory[1] = {1};

    int clk = 0;

    u_int32_t A = rand() & 0xFFFFFFFF;
    u_int32_t B = rand() & 0xFFFFFFFF;

    printf("A: %#010x\r\n", A);
    printf("B: %#010x\r\n", B);

    testAdd32(tfp, top, A, B);
    testAdd16(tfp, top, A, B);
    testAdd8(tfp, top, A, B);

    testSub32(tfp, top, A, B);
    testSub16(tfp, top, A, B);
    testSub8(tfp, top, A, B);

    testAnd(tfp, top, A, B);
    testOr(tfp, top, A, B);
    testXor(tfp, top, A, B);

    testMax32(tfp, top, A, B);
    testMax16(tfp, top, A, B);
    testMax8(tfp, top, A, B);

    testMin32(tfp, top, A, B);
    testMin16(tfp, top, A, B);
    testMin8(tfp, top, A, B);

    testMaxu32(tfp, top, A, B);
    testMaxu16(tfp, top, A, B);
    testMaxu8(tfp, top, A, B);
    
    testMinu32(tfp, top, A, B);
    testMinu16(tfp, top, A, B);
    testMinu8(tfp, top, A, B);

    testSadd32(tfp, top, A, B);
    testSadd16(tfp, top, A, B);
    testSadd8(tfp, top, A, B);

    testSaddu32(tfp, top, A, B);
    testSaddu16(tfp, top, A, B);
    testSaddu8(tfp, top, A, B);

    main_time++;

    tfp->dump(main_time);

    printf("%d out of %d tests passed\r\n", pass, count);

    top->final();

    tfp->close();

    delete top;

    return 0;

}
