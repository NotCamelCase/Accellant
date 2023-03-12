PROJ_NAME := ranpi

DEBUG=no

BUILD_DIR = ./build
SRC_DIRS = ./src
KERNEL_SRC_DIRS = ../../../kernel

LDSCRIPT = ../../../kernel/linker.ld

MABI=ilp32
MARCH := rv32im

CFLAGS += -march=$(MARCH) -mabi=$(MABI) -DNDEBUG
LDFLAGS += -march=$(MARCH) -mabi=$(MABI)

ifeq ($(DEBUG),yes)
	CFLAGS += -g3 -O0
endif

ifeq ($(DEBUG),no)
	CFLAGS += -g -O3
endif

RISCV_OBJCOPY = riscv64-unknown-elf-objcopy
RISCV_OBJDUMP = riscv64-unknown-elf-objdump
# Notice: Building all source code w/ g++!
RISCV_CC = riscv64-unknown-elf-g++
RISCV_CPP = riscv64-unknown-elf-g++

CFLAGS += -fstrict-volatile-bitfields -fno-strict-aliasing -Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror
CXXFLAGS += -fno-exceptions
LDFLAGS += -lgcc -mcmodel=medany -nostartfiles -ffreestanding -Wl,-Bstatic,-T,$(LDSCRIPT),-Map,$(BUILD_DIR)/$(PROJ_NAME).map,--gc-sections,--print-memory-usage

# Find all source files to compile
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s')
SRCS += $(shell find $(KERNEL_SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s')

# Remove dir from all source files
SRCS := $(notdir $(SRCS))

# Prefix all source .o files w/ BUILD_DIR to place all the compiled objects under BUILD_DIR
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# Header dependencies
DEPS := $(OBJS:.o=.d)

# All include directories
INC_DIRS := $(shell find $(SRC_DIRS) -type d)
INC_DIRS += $(shell find $(KERNEL_SRC_DIRS) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

CFLAGS += $(INC_FLAGS) -MMD -MP

all: $(BUILD_DIR)/$(PROJ_NAME).elf $(BUILD_DIR)/$(PROJ_NAME).hex $(BUILD_DIR)/$(PROJ_NAME).asm $(BUILD_DIR)/$(PROJ_NAME).v $(BUILD_DIR)/$(PROJ_NAME).bin

$(BUILD_DIR)/%.elf: $(OBJS)
	$(RISCV_CPP) $(CFLAGS) -o $@ $^ $(LDFLAGS)

%.hex: %.elf
	$(RISCV_OBJCOPY) -O ihex $^ $@

%.bin: %.elf
	$(RISCV_OBJCOPY) -S -O binary $^ $@

%.v: %.elf
	$(RISCV_OBJCOPY) -O verilog $^ $@

%.asm: %.elf
	$(RISCV_OBJDUMP) -S -d $^ > $@

# Application code
$(BUILD_DIR)/%.c.o: $(SRC_DIRS)/%.c
	mkdir -p $(dir $@)
	$(RISCV_CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cpp.o: $(SRC_DIRS)/%.cpp
	mkdir -p $(dir $@)
	$(RISCV_CPP) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.s.o: $(SRC_DIRS)/%.s
	mkdir -p $(dir $@)
	$(RISCV_CPP) -c $(CFLAGS) -o $@ $^ -D__ASSEMBLY__=1

# Library code
$(BUILD_DIR)/%.c.o: $(KERNEL_SRC_DIRS)/%.c
	mkdir -p $(dir $@)
	$(RISCV_CPP) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.cpp.o: $(KERNEL_SRC_DIRS)/%.cpp
	mkdir -p $(dir $@)
	$(RISCV_CPP) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.s.o: $(KERNEL_SRC_DIRS)/%.s
	mkdir -p $(dir $@)
	$(RISCV_CPP) -c $(CFLAGS) -o $@ $^ -D__ASSEMBLY__=1

$(BUILD_DIR):
	mkdir -p $@

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)