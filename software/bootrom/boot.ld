ENTRY(_start)

MEMORY
{
    rom (rx)    : ORIGIN = 0x10000000,  LENGTH = 0x2000
    ram (rwx)   : ORIGIN = 0x00000000,  LENGTH = 0x4000
}

STACK_SIZE  = 0x800; /* 2 kB*/

SECTIONS
{
   .text :
    {
        *(.text*)
        *(.rodata)
        *(.eh_frame)
    } > rom

    .bss (NOLOAD) :
    {
        *(.bss)
    } > ram AT >rom

    .data : { *(.data) }

    .stack (NOLOAD):
    {
        . = ALIGN(8);
        . = . + STACK_SIZE;
        . = ALIGN(8);
        _sp = . -16;
    } > ram
}