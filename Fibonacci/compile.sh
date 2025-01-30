#!/bin/sh
nasm -f elf64 fib.asm -o fib.o
ld fib.o -o fib -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2
./fib
