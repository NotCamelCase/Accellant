# Accellant
A demo SoC implementation with a simple 6-10* stage RISC-V CPU and various I/O cores realized on [Arty S7](https://digilent.com/reference/programmable-logic/arty-s7/start) FPGA. The CPU runs at 100 Mhz and supports a 256 MB DDR3 SDRAM with separate 16 Kb 4-way I$ and 32 Kb 4-way write-back, write-allocate D$.

Upon reset, a bootloader is executed from the instruction ROM to load a program via serial port onto RAM and then the core jumps to application code after setting up the necessary stack pointer, program data, etc.

![accellant_cpu](https://github.com/NotCamelCase/Accellant/blob/master/docs/accellant_cpu.png)

Space Invaders demo running at 20 FPS

https://github.com/NotCamelCase/Accellant/assets/3171841/c6daba9e-5ca7-4a4a-976e-4a3d0feef247

*Pipelined divider takes 16 clk

# Credits
I took lots of ideas and code from the following projects, so, go see them
- https://github.com/jbush001/NyuziProcessor
- https://github.com/ultraembedded/riscv
- https://github.com/alexforencich/verilog-axi