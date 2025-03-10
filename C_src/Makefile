RV_PREFIX := riscv64-unknown-linux-gnu-
RV_GCC := $(RV_PREFIX)gcc
RV_AS := $(RV_PREFIX)as
RV_FLAGS := -mabi=ilp32 -march=rv32i_zicsr
RV_OBJDUMP := $(RV_PREFIX)objdump
RV_FLAGS_OBJ := -S --no-addresses -M no-aliases -M numeric

*.asm: *.c
		$(RV_GCC) $(RV_FLAGS) *.c -o *.asm -S

*.o: *.c
		$(RV_GCC) $(RV_FLAGS) *.c -o *.o -S

*.elf: *.o
		$(RV_AS) $(RV_FLAGS) *.o -o *.elf

*.bin: *.c
		$(RV_GCC) -o *.bin *.c


.PHONY:clean

clean:
		rm  *.o *.elf *.hex *.asm

*.hex: *.elf
		eval $(RV_OBJDUMP) *.elf $(RV_FLAGS_OBJ) >> *.hex