#!/bin/sh
#nasm -f elf64 gol.asm -o gol.o && 
nasm -f elf64 gol.asm -o gol.o -g -F dwarf || exit
ld gol.o -o gol -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2 || exit

if [ "$1" == "debug" ] || [ "$1" == "d" ];  then
	gdb gol -tui
else
	./gol
fi
