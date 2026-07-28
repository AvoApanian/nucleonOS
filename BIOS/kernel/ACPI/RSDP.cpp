#include "../types.hpp"
#include "../lib/string/string.hpp"
#include "../lib/vga/vga.hpp"
#include "RSDP.hpp"

RSDPDescriptor20* findRSDP(EFI_SYSTEM_TABLE* systemTable){
    for (uint64_t i = 0; i < systemTable->NumberOfTableEntries; i++){
        EFI_CONFIGURATION_TABLE* table =
            &systemTable->ConfigurationTable[i];

        if (isACPI20GUID(table->VendorGuid)){
            RSDPDescriptor20* rsdp = (RSDPDescriptor20*)table->VendorTable;

            vga("RSDP FOUND", 0x0F, 0);

            vga("RSDP Address:", 0x0F, 0);
            vgaHex((uint64_t)rsdp, 0x0F);

            vga("Revision:", 0x0F, 0);
            vgaHex(rsdp->revision, 0x0F);

            vga("XSDT Address:", 0x0F, 0);
            vgaHex(rsdp->xsdtAddress, 0x0F);

            return rsdp;
        }
    }

    vga("RSDP NOT FOUND", 0x04, 1);
    return nullptr;
}
