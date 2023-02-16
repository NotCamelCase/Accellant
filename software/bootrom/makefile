all: boot.coe loader

boot.coe: boot.c start.s
	riscv64-unknown-elf-g++ start.s boot.c -O3 -fstrict-volatile-bitfields -fno-strict-aliasing -Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror -nostartfiles -nostdlib -nodefaultlibs -march=rv32im -mabi=ilp32 -ffreestanding -static -Wl,-Bstatic,-Map,boot.map,--gc-sections,--print-memory-usage -T boot.ld -o boot.elf
	riscv64-unknown-elf-objcopy boot.elf -S -O binary boot.hex
	riscv64-unknown-elf-objdump boot.elf --disassemble-all --disassemble-zeroes > boot.out
	python3 generate_rom_coe.py boot.hex

loader: loader.c
	gcc loader.c -O3 -o loader

.PHONY: clean
clean:
	rm boot.coe -f
	rm boot.elf -f
	rm boot.hex -f
	rm boot.out -f
	rm boot.map -f
	rm loader -f

clean-all : clean
