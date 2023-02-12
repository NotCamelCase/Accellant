PROJ_NAME := hello_world
SRC := $(wildcard ./*.c) \
		$(wildcard ./*.cpp) \
		$(wildcard ./*.s)

LINKER := linker.ld
C_FLAGS := -O3 -Wall -march=rv32im -mabi=ilp32 -nostartfiles -ffreestanding -static-libgcc -static-libstdc++ -T $(LINKER) -o $(PROJ_NAME).elf
LD_FLAGS := -Bstatic,-Map,$(PROJ_NAME).map,--gc-sections,--print-memory-usage

all: $(PROJ_NAME).hex

$(PROJ_NAME).hex: $(SRC)
	riscv64-unknown-elf-gcc $(SRC) $(C_FLAGS) -Wl,$(LD_FLAGS)
	riscv64-unknown-elf-objcopy $(PROJ_NAME).elf -S -O binary $(PROJ_NAME).hex
	riscv64-unknown-elf-objdump $(PROJ_NAME).elf --disassemble-all --disassemble-zeroes > $(PROJ_NAME).out

.PHONY: clean
clean:
	rm $(PROJ_NAME).elf -f
	rm $(PROJ_NAME).hex -f
	rm $(PROJ_NAME).out -f
	rm $(PROJ_NAME).map -f

clean-all: clean