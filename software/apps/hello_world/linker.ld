OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    ram (rwx) : ORIGIN = 0x00000000,  LENGTH = 0x10000
}

STACK_SIZE  = 0x1000; /* 4 kB*/

SECTIONS
{
    .text : ALIGN(4)
    {
        *(.start*);
        *(.text*)
    } > ram

    .data :
    {
        *(.rdata)
        *(.rodata .rodata.*)
        *(.gnu.linkonce.r.*)
        *(.data .data.*)
        *(.gnu.linkonce.d.*)
        . = ALIGN(8);
        __global_pointer$ = . + 0x800;
        *(.sdata .sdata.*)
        *(.gnu.linkonce.s.*)
        . = ALIGN(8);
        *(.srodata.cst16)
        *(.srodata.cst8)
        *(.srodata.cst4)
        *(.srodata.cst2)
        *(.srodata .srodata.*)
    } > ram

    .ctors :
    {
        . = ALIGN(4);
        __ctors_start = .;
        KEEP(*(.init_array*))
        KEEP (*(SORT(.ctors.*)))
        KEEP (*(.ctors))
        . = ALIGN(4);
        __ctors_end = .;
    } > ram

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
		__bss_start = .;
        *(.sbss*)
        *(.gnu.linkonce.sb.*)
        *(.bss .bss.*)
        *(.gnu.linkonce.b.*)
        *(COMMON)
	    . = ALIGN(4);
	    __bss_end = .;
    } > ram

    /* Place heap after program data */
    .heap (NOLOAD) :
    {
        . = ALIGN(16);
        __heap_start = . ;
        . = ALIGN(16);
        __heap_end = ORIGIN(ram) + LENGTH(ram) - STACK_SIZE;
    } > ram

    /* Place stack on top of RAM */
    .stack ORIGIN(ram) + LENGTH(ram) (NOLOAD) :
    {
        __sp = . ;
    }
}