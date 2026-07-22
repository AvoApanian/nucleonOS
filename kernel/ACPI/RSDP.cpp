#include "../types.hpp"
#include "../lib/string/string.hpp"
#include "../lib/vga/vga.hpp"


void findRSDP(){
    uint8_t* ptr = (uint8_t*)0xE0000;


    while(ptr < (uint8_t*)0x100000){
        if(memoryEqual(ptr, "RSD PTR ", 8)){
            vga("RSDP FOUND:", 0x0F, 0);
	    vgaHex((uint64_t)ptr,0x0F);

	    	
            return;
        }

        ptr += 16;
    }


    vga("RSDP NOT FOUND", 0x04, 1);
}
