RV_PREFIX := riscv64-unknown-linux-gnu-
RV_GCC := $(RV_PREFIX)gcc
RV_AS := $(RV_PREFIX)as
RV_LD := $(RV_PREFIX)ld
RV_FLAGS := -Wall -ffreestanding -nostdlib -nostartfiles -march=rv32i_zicsr -mabi=ilp32
RV_OBJDUMP := $(RV_PREFIX)objdump
RV_OBJCOPY := $(RV_PREFIX)objcopy
RV_FLAGS_OBJ := -S -M no-aliases -D #--no-addresses  -M numeric

RV_FLAGS_LD := -mabi=ilp32 -march=rv32i_zicsr -m elf32lriscv

# OBJS := gpio_test.o

%.s: %.c
	$(RV_GCC) $(RV_FLAGS) -o $@ $< -S -nostdlib

%.o: %.s
	$(RV_GCC) $(RV_FLAGS) -c $< -o $@

%.elf: %.o 
	$(RV_LD) $(RV_FLAGS_LD) -T linker_script.ld $< -o $@

# traphandler.elf: $(OBJS)
# 	$(CC) $(CFLAGS) -o $@ $(OBJS)

%.dis: %.elf
	eval $(RV_OBJDUMP) $< $(RV_FLAGS_OBJ) > $@

#  riscv64-unknown-linux-gnu-objcopy -j .text -O verilog gpio_test.elf machine_data.hex
%.dump: %.elf
# riscv64-unknown-linux-gnu-objcopy -O binary traphandler.elf traphandler.bin
# hexdump -v -e '1/4 "%08x\n"' traphandler.bin > traphandler.hex 
	riscv64-unknown-linux-gnu-objcopy -j .text -O verilog $< machine_inst.mem
	riscv64-unknown-linux-gnu-objcopy -j .data -O verilog $< machine_data.mem

.PHONY:clean

clean:
	rm  *.bin *.o *.elf *.hex *.asm *.mem *.s *.dis
