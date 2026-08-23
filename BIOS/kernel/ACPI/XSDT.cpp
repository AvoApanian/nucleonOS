#include "../types.hpp"
#include "../../driver/vga/vga.hpp"
#include "XSDT.hpp"


ACPISDTHeader* getXSDT(uint32_t address)
{
    if(address == 0)
    {
        vga("XSDT ADDRESS NULL",0x04,1);
        return nullptr;
    }


    ACPISDTHeader* xsdt =
        (ACPISDTHeader*)address;


    if(xsdt->signature[0] != 'X' ||
       xsdt->signature[1] != 'S' ||
       xsdt->signature[2] != 'D' ||
       xsdt->signature[3] != 'T')
    {
        vga("XSDT INVALID",0x04,1);

        return nullptr;
    }


    vga("XSDT FOUND",0x0F,1);


    vga("XSDT ADDRESS:",0x0F,0);
    vgaHex(address,0x0F);


    vga("XSDT LENGTH:",0x0F,0);
    vgaHex(xsdt->length,0x0F);


    vga("XSDT REVISION:",0x0F,0);
    vgaHex(xsdt->revision,0x0F);


    vga("XSDT CHECKSUM:",0x0F,0);
    vgaHex(xsdt->checksum,0x0F);


    return xsdt;
}
