OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    rom (rx)    : ORIGIN = 0x10000000,  LENGTH = 0x1000
    ram (rwx)   : ORIGIN = 0x00000000,  LENGTH = 0x10000
}

STACK_SIZE  = 0x800; /* 2 kB*/

SECTIONS
{
    .text : ALIGN(4)
    {
        *(.text*)
    } > rom

    _sp = ORIGIN(ram) + LENGTH(ram);
}