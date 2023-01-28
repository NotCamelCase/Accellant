all:
	riscv64-unknown-elf-gcc start.s boot.c -O3 -Wall -nostartfiles -nostdlib -nodefaultlibs -march=rv32im -mabi=ilp32 -ffreestanding -Wl,-Map,boot.map -T boot.ld -o boot.elf
	riscv64-unknown-elf-objcopy boot.elf -S -O binary -j .text -j .rodata boot.hex
	riscv64-unknown-elf-objdump boot.elf --disassemble-all --disassemble-zeroes --section=.text --section=.data --section=.rodata > boot.out
	python3 generate_rom_coe.py boot.hex

clean:
	rm boot.coe -f
	rm boot.elf -f
	rm boot.hex -f
	rm boot.out -f
	rm boot.map -f