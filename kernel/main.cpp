#include "lib/vga/vga.hpp"
extern void findRSDP();

extern "C" void kernelMain(){
    vga("Kernel is loading", 0x0F, 1);

    findRSDP();

    while(1){
        asm volatile("hlt");
    }
}
