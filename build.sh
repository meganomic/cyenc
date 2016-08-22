#!/usr/bin/sh

nasm -f elf64 cyencsse.asm

g++ -shared -fPIC cyencsse.o -o cyencsse.so
