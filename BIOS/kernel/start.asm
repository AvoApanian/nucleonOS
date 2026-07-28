bits 64
section .text.start
global _start
extern kernelMain

_start:
    call kernelMain
.hang:
    hlt
    jmp .hang
