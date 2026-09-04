#include "../types.hpp"
#include "../../driver/vga/vga.hpp"
#include "RSDT.hpp"

static uint32_t getTableSignature(const ACPISDTHeader* table)
{
    uint32_t signature = 0;

    signature |= (uint32_t)(uint8_t)table->signature[0];
    signature |= (uint32_t)(uint8_t)table->signature[1] << 8;
    signature |= (uint32_t)(uint8_t)table->signature[2] << 16;
    signature |= (uint32_t)(uint8_t)table->signature[3] << 24;

    return signature;
}

ACPISDTHeader* getRSDT(uint32_t address)
{
    if(address == 0)
    {
        vga("RSDT ADDRESS NULL", 0x04, 1);
        return nullptr;
    }

    ACPISDTHeader* rsdt =
        (ACPISDTHeader*)address;

    if(rsdt->signature[0] != 'R' ||
       rsdt->signature[1] != 'S' ||
       rsdt->signature[2] != 'D' ||
       rsdt->signature[3] != 'T')
    {
        vga("RSDT INVALID", 0x04, 1);
        return nullptr;
    }

    vga("RSDT FOUND", 0x0F, 1);

    vga("RSDT ADDRESS:", 0x0F, 0);
    vgaHex(address, 0x0F);

    vga("RSDT LENGTH:", 0x0F, 0);
    vgaHex(rsdt->length, 0x0F);

    vga("RSDT REVISION:", 0x0F, 0);
    vgaHex(rsdt->revision, 0x0F);

    vga("RSDT CHECKSUM:", 0x0F, 0);
    vgaHex(rsdt->checksum, 0x0F);

    if(!validateSDTChecksum(rsdt))
    {
        vga("RSDT CHECKSUM INVALID", 0x04, 1);
        return nullptr;
    }

    vga("RSDT CHECKSUM VALID", 0x0A, 1);

    uint32_t entriesSize =
        rsdt->length - sizeof(ACPISDTHeader);

    uint32_t entryCount =
        entriesSize / sizeof(uint32_t);

    vga("RSDT ENTRIES:", 0x0F, 0);
    vgaHex(entryCount, 0x0F);

    uint32_t* entries =
        (uint32_t*)((uint8_t*)rsdt + sizeof(ACPISDTHeader));

    for(uint32_t i = 0; i < entryCount; i++)
    {
        uint32_t tableAddress = entries[i];

        if(tableAddress == 0)
        {
            vga("TABLE ADDRESS NULL", 0x04, 1);
            continue;
        }

        ACPISDTHeader* table =
            (ACPISDTHeader*)tableAddress;

        vga("TABLE ADDRESS:", 0x0F, 0);
        vgaHex(tableAddress, 0x0F);

        vga("TABLE SIGNATURE:", 0x0F, 0);
        vgaHex(getTableSignature(table), 0x0F);

        vga("TABLE LENGTH:", 0x0F, 0);
        vgaHex(table->length, 0x0F);

        if(validateSDTChecksum(table))
        {
            vga("TABLE CHECKSUM VALID", 0x0A, 1);
        }
        else
        {
            vga("TABLE CHECKSUM INVALID", 0x04, 1);
        }
    }

    return rsdt;
}
