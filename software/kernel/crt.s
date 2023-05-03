/* See: https://github.com/openhwgroup/cv32e40p/blob/master/example_tb/core/custom/crt0.S */

.section .text.start
.global _start
.type _start, @function

_start:
/* initialize global pointer */
.option push
.option norelax
1:	auipc gp, %pcrel_hi(__global_pointer$)
	addi  gp, gp, %pcrel_lo(1b)
.option pop

/* Clear all architectural registers except x0, sp & gp */
	li ra, 0
	li tp, 0
	li t0, 0
	li t1, 0
	li t2, 0
	li s0, 0
	li s1, 0
	li a0, 0
	li a1, 0
	li a2, 0
	li a3, 0
	li a4, 0
	li a5, 0
	li a6, 0
	li a7, 0
	li s2, 0
	li s3, 0
	li s4, 0
	li s5, 0
	li s6, 0
	li s7, 0
	li s8, 0
	li s9, 0
	li s10, 0
	li s11, 0
	li t3, 0
	li t4, 0
	li t5, 0
	li t6, 0

/* initialize stack pointer */
	la sp, _sp

/* clear the bss segment */
	la a0, __bss_start
	la a2, __bss_end
	sub a2, a2, a0
	li a1, 0
	call memset

/* new-style constructors and destructors */
	la a0, __libc_fini_array
	call atexit
	call __libc_init_array

/* call main */
	lw a0, 0(sp)                    /* a0 = argc */
	addi a1, sp, 4                  /* a1 = argv */
	li a2, 0                        /* a2 = envp = NULL */
	call main
	tail exit

.size  _start, .-_start

.global _init
.type   _init, @function
.global _fini
.type   _fini, @function
_init:
_fini:
 /* These don't have to do anything since we use init_array/fini_array. Prevent
    missing symbol error */
	ret
.size  _init, .-_init
.size _fini, .-_fini
