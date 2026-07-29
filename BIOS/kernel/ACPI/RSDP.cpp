#include "../types.hpp"
#include "../../driver/string/string.hpp"
#include "../../driver/vga/vga.hpp"
#include "RSDP.hpp"


RSDPDescriptor20* findRSDP(){

    for(uint64_t address = 0xE0000; address < 0x100000; address += 16){

        char* ptr = (char*)address;

        if(ptr[0] == 'R' &&
           ptr[1] == 'S' &&
           ptr[2] == 'D' &&
           ptr[3] == ' ' &&
           ptr[4] == 'P' &&
           ptr[5] == 'T' &&
           ptr[6] == 'R')
        {

            RSDPDescriptor20* rsdp = (RSDPDescriptor20*)address;


            vga("RSDP FOUND",0x0F,1);

            vga("Address:",0x0F,0);
            vgaHex(address,0x0F);


            vga("Revision:",0x0F,0);
            vgaHex(rsdp->revision,0x0F);


            vga("XSDT:",0x0F,0);
            vgaHex(rsdp->xsdtAddress,0x0F);


            return rsdp;
        }
    }


    vga("RSDP NOT FOUND",0x04,1);

    return nullptr;
}
