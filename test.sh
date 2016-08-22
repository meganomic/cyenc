#!/usr/bin/sh

nasm -f elf64 cyencsse.asm

ar rvs cyencsse.a cyencsse.o

g++ test/test.cpp cyencsse.a -o runtest 
