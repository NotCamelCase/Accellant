.text
.align 4

.global _start
.type _start,@function

.global main

.section .start,"ax",@progbits
_start:
    # Set up global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # Set up stack pointer
    la sp, __sp

bss_init:
    la a0, __bss_start
    la a1, __bss_end
bss_loop:
    beq a0,a1,bss_done
    sw zero,0(a0)
    add a0,a0,4
    j bss_loop
bss_done:

ctors_init:
    la a0, __ctors_start
    addi sp,sp,-4
ctors_loop:
    la a1, __ctors_end
    beq a0,a1,ctors_done
    lw a3,0(a0)
    add a0,a0,4
    sw a0,0(sp)
    jalr  a3
    lw a0,0(sp)
    j ctors_loop
ctors_done:
    addi sp,sp,4

    jal main
