# README

This directory contains C code along with some helper scripts.

## Compiling the C Code

To compile the C code, run the following commands **from within this directory**:

```bash
make clean;make traphandler.s;make traphandler.o;make traphandler.dump
```

> **Note:**  
> We avoid using Makefile dependencies because running `make traphandler.dump` would automatically trigger:
>
> ```bash
> cc -c -o traphandler.o traphandler.c
> ```
> ...which we **do not want** to happen automatically.

After running the commands above, the generated hex files will be:

- `machine_inst.mem` – contains the instruction memory
- `machine_data.mem` – contains the data memory

## Loading the Program

You can now load the program through UART by running:

```bash
sudo python3 load_program.py
```

## Debugging / Disassembly

To convert the instruction memory to a hex file format compatible with Vivado:

```bash
python3 convert_hex.py machine_inst.mem ../machine.mem
```

If you'd like to view the disassembly of the program:

```bash
make traphandler.dis
```
