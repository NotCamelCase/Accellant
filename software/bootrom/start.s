.text
.align 4

.globl _start
.type _start,@function

_start:
    # Setup stack pointer
    lui sp, %hi(_sp)
    add sp, sp, %lo(_sp)

    jal main
