RV_PREFIX     := riscv64-unknown-linux-gnu-
RV_GCC        := $(RV_PREFIX)gcc
RV_OBJCOPY    := $(RV_PREFIX)objcopy
RV_OBJDUMP    := $(RV_PREFIX)objdump

# Compile and link flags
RV_FLAGS      := -march=rv32i_zicsr -mabi=ilp32
LD_SCRIPT     := linker_script.ld   # Your custom linker script

# Optional extra flags that remove the default CRT startup, etc.
# since we’re doing bare-metal
NO_STANDARD   := -nostdlib -nostartfiles

# Where you want to put intermediate and final files
TARGET        := traphandler

.PHONY: all clean

all: $(TARGET).bin  $(TARGET).hex

# 1) Compile from C to object file
$(TARGET).o: $(TARGET).c
	$(RV_GCC) $(RV_FLAGS) -c $(TARGET).c -o $@

# 2) Link object file into an ELF, using your custom linker script
$(TARGET).elf: $(TARGET).o $(LD_SCRIPT)
	$(RV_GCC) $(RV_FLAGS) $(NO_STANDARD) -T $(LD_SCRIPT) -o $@ $(TARGET).o

# 3) Convert ELF to raw binary
$(TARGET).bin: $(TARGET).elf
	$(RV_OBJCOPY) -O binary $(TARGET).elf $(TARGET).bin

# 4) Disassemble the ELF to produce a readable .hex or listing
$(TARGET).hex: $(TARGET).elf
	$(RV_OBJDUMP) -d -M no-aliases -M numeric $(TARGET).elf > $(TARGET).hex

clean:
	rm -f *.o *.bin *.elf *.hex
