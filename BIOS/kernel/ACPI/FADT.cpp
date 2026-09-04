#include "../types.hpp"
#include "../../driver/vga/vga.hpp"

#include "FADT.hpp"

static bool isDSDT(const ACPISDTHeader* table)
{
    vga("DSDT CHECK: START", 0x0F, 1);

    if(table == nullptr)
    {
        vga("DSDT CHECK: NULL POINTER", 0x04, 1);
        return false;
    }

    vga("DSDT CHECK: BYTE 0:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)table->signature[0], 0x0F);

    vga("DSDT CHECK: BYTE 1:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)table->signature[1], 0x0F);

    vga("DSDT CHECK: BYTE 2:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)table->signature[2], 0x0F);

    vga("DSDT CHECK: BYTE 3:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)table->signature[3], 0x0F);

    if(table->signature[0] != 'D')
    {
        vga("DSDT CHECK: BYTE 0 INVALID", 0x04, 1);
        return false;
    }

    if(table->signature[1] != 'S')
    {
        vga("DSDT CHECK: BYTE 1 INVALID", 0x04, 1);
        return false;
    }

    if(table->signature[2] != 'D')
    {
        vga("DSDT CHECK: BYTE 2 INVALID", 0x04, 1);
        return false;
    }

    if(table->signature[3] != 'T')
    {
        vga("DSDT CHECK: BYTE 3 INVALID", 0x04, 1);
        return false;
    }

    vga("DSDT CHECK: SIGNATURE VALID", 0x0A, 1);

    return true;
}

static ACPISDTHeader* getDSDT(uint32_t address)
{
    vga("================================", 0x0F, 1);
    vga("DSDT: FUNCTION START", 0x0A, 1);
    vga("================================", 0x0F, 1);

    vga("DSDT: INPUT ADDRESS:", 0x0F, 0);
    vgaHex(address, 0x0F);

    if(address == 0)
    {
        vga("DSDT: ADDRESS NULL", 0x04, 1);
        return nullptr;
    }

    vga("DSDT: ADDRESS VALID", 0x0A, 1);

    ACPISDTHeader* dsdt =
        (ACPISDTHeader*)address;

    vga("DSDT: POINTER CREATED", 0x0A, 1);

    vga("DSDT: READING SIGNATURE", 0x0F, 1);

    vga("DSDT: SIGNATURE[0]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->signature[0], 0x0F);

    vga("DSDT: SIGNATURE[1]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->signature[1], 0x0F);

    vga("DSDT: SIGNATURE[2]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->signature[2], 0x0F);

    vga("DSDT: SIGNATURE[3]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->signature[3], 0x0F);

    if(!isDSDT(dsdt))
    {
        vga("DSDT: INVALID SIGNATURE", 0x04, 1);
        return nullptr;
    }

    vga("DSDT: SIGNATURE VALID", 0x0A, 1);

    vga("DSDT: LENGTH:", 0x0F, 0);
    vgaHex(dsdt->length, 0x0F);

    vga("DSDT: REVISION:", 0x0F, 0);
    vgaHex(dsdt->revision, 0x0F);

    vga("DSDT: CHECKSUM:", 0x0F, 0);
    vgaHex(dsdt->checksum, 0x0F);

    vga("DSDT: OEM ID BYTE 0:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[0], 0x0F);

    vga("DSDT: OEM ID BYTE 1:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[1], 0x0F);

    vga("DSDT: OEM ID BYTE 2:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[2], 0x0F);

    vga("DSDT: OEM ID BYTE 3:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[3], 0x0F);

    vga("DSDT: OEM ID BYTE 4:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[4], 0x0F);

    vga("DSDT: OEM ID BYTE 5:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMID[5], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 0:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[0], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 1:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[1], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 2:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[2], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 3:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[3], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 4:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[4], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 5:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[5], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 6:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[6], 0x0F);

    vga("DSDT: OEM TABLE ID BYTE 7:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)dsdt->OEMTableID[7], 0x0F);

    if(dsdt->length < sizeof(ACPISDTHeader))
    {
        vga("DSDT: LENGTH TOO SMALL", 0x04, 1);
        return nullptr;
    }

    vga("DSDT: LENGTH VALID", 0x0A, 1);

    vga("DSDT: START CHECKSUM", 0x0F, 1);

    if(!validateSDTChecksum(dsdt))
    {
        vga("DSDT: CHECKSUM INVALID", 0x04, 1);
        return nullptr;
    }

    vga("DSDT: CHECKSUM VALID", 0x0A, 1);

    vga("DSDT: AML START ADDRESS:", 0x0F, 0);
    vgaHex(
        address + sizeof(ACPISDTHeader),
        0x0F
    );

    vga("DSDT: AML SIZE:", 0x0F, 0);

    vgaHex(
        dsdt->length - sizeof(ACPISDTHeader),
        0x0F
    );

    vga("DSDT: AML DATA AVAILABLE", 0x0A, 1);

    vga("DSDT: FUNCTION FINISHED", 0x0A, 1);

    return dsdt;
}

FADT* getFADT(uint32_t address)
{
    vga("================================", 0x0F, 1);
    vga("FADT: FUNCTION START", 0x0A, 1);
    vga("================================", 0x0F, 1);

    vga("FADT: INPUT ADDRESS:", 0x0F, 0);
    vgaHex(address, 0x0F);

    if(address == 0)
    {
        vga("FADT: ADDRESS NULL", 0x04, 1);
        return nullptr;
    }

    vga("FADT: ADDRESS VALID", 0x0A, 1);

    FADT* fadt =
        (FADT*)address;

    vga("FADT: POINTER CREATED", 0x0A, 1);

    vga("FADT: SIGNATURE[0]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)fadt->header.signature[0], 0x0F);

    vga("FADT: SIGNATURE[1]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)fadt->header.signature[1], 0x0F);

    vga("FADT: SIGNATURE[2]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)fadt->header.signature[2], 0x0F);

    vga("FADT: SIGNATURE[3]:", 0x0F, 0);
    vgaHex((uint32_t)(uint8_t)fadt->header.signature[3], 0x0F);

    if(fadt->header.signature[0] != 'F' ||
       fadt->header.signature[1] != 'A' ||
       fadt->header.signature[2] != 'C' ||
       fadt->header.signature[3] != 'P')
    {
        vga("FADT: INVALID SIGNATURE", 0x04, 1);
        return nullptr;
    }

    vga("FADT: SIGNATURE VALID", 0x0A, 1);
    vga("FADT FOUND", 0x0A, 1);

    vga("FADT: LENGTH:", 0x0F, 0);
    vgaHex(fadt->header.length, 0x0F);

    vga("FADT: REVISION:", 0x0F, 0);
    vgaHex(fadt->header.revision, 0x0F);

    vga("FADT: CHECKSUM:", 0x0F, 0);
    vgaHex(fadt->header.checksum, 0x0F);

    if(fadt->header.length < sizeof(ACPISDTHeader))
    {
        vga("FADT: LENGTH TOO SMALL", 0x04, 1);
        return nullptr;
    }

    vga("FADT: LENGTH VALID", 0x0A, 1);

    vga("FADT: VALIDATING CHECKSUM", 0x0F, 1);

    if(!validateSDTChecksum(&fadt->header))
    {
        vga("FADT: CHECKSUM INVALID", 0x04, 1);
        return nullptr;
    }

    vga("FADT: CHECKSUM VALID", 0x0A, 1);

    vga("FADT: FIRMWARE CONTROL:", 0x0F, 0);
    vgaHex(fadt->firmwareCtrl, 0x0F);

    vga("FADT: DSDT ADDRESS:", 0x0F, 0);
    vgaHex(fadt->dsdt, 0x0F);

    vga("FADT: SCI INTERRUPT:", 0x0F, 0);
    vgaHex((uint32_t)fadt->sciInterrupt, 0x0F);

    vga("FADT: SMI COMMAND PORT:", 0x0F, 0);
    vgaHex(fadt->smiCommandPort, 0x0F);

    vga("FADT: ACPI ENABLE:", 0x0F, 0);
    vgaHex((uint32_t)fadt->acpiEnable, 0x0F);

    vga("FADT: ACPI DISABLE:", 0x0F, 0);
    vgaHex((uint32_t)fadt->acpiDisable, 0x0F);

    vga("FADT: PM1A EVENT BLOCK:", 0x0F, 0);
    vgaHex(fadt->pm1aEventBlock, 0x0F);

    vga("FADT: PM1B EVENT BLOCK:", 0x0F, 0);
    vgaHex(fadt->pm1bEventBlock, 0x0F);

    vga("FADT: PM1A CONTROL BLOCK:", 0x0F, 0);
    vgaHex(fadt->pm1aControlBlock, 0x0F);

    vga("FADT: PM1B CONTROL BLOCK:", 0x0F, 0);
    vgaHex(fadt->pm1bControlBlock, 0x0F);

    vga("FADT: PM2 CONTROL BLOCK:", 0x0F, 0);
    vgaHex(fadt->pm2ControlBlock, 0x0F);

    vga("FADT: PM TIMER BLOCK:", 0x0F, 0);
    vgaHex(fadt->pmTimerBlock, 0x0F);

    vga("FADT: GPE0 BLOCK:", 0x0F, 0);
    vgaHex(fadt->gpe0Block, 0x0F);

    vga("FADT: GPE1 BLOCK:", 0x0F, 0);
    vgaHex(fadt->gpe1Block, 0x0F);

    vga("FADT: PM1 EVENT LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->pm1EventLength, 0x0F);

    vga("FADT: PM1 CONTROL LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->pm1ControlLength, 0x0F);

    vga("FADT: PM2 CONTROL LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->pm2ControlLength, 0x0F);

    vga("FADT: PM TIMER LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->pmTimerLength, 0x0F);

    vga("FADT: GPE0 LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->gpe0BlockLength, 0x0F);

    vga("FADT: GPE1 LENGTH:", 0x0F, 0);
    vgaHex((uint32_t)fadt->gpe1BlockLength, 0x0F);

    vga("FADT: BOOT ARCH FLAGS:", 0x0F, 0);
    vgaHex((uint32_t)fadt->bootArchitectureFlags, 0x0F);

    vga("FADT: FLAGS:", 0x0F, 0);
    vgaHex(fadt->flags, 0x0F);

    if(fadt->dsdt == 0)
    {
        vga("FADT: DSDT ADDRESS NULL", 0x04, 1);
        return fadt;
    }

    vga("FADT: DSDT ADDRESS VALID", 0x0A, 1);

    vga("FADT: PREPARING DSDT LOAD", 0x0F, 1);

    ACPISDTHeader* dsdt =
        getDSDT(fadt->dsdt);

    if(dsdt == nullptr)
    {
        vga("FADT: DSDT LOAD FAILED", 0x04, 1);
        return fadt;
    }

    vga("FADT: DSDT LOAD SUCCESS", 0x0A, 1);

    vga("FADT: DSDT ADDRESS CONFIRMED:", 0x0F, 0);
    vgaHex(fadt->dsdt, 0x0F);

    vga("================================", 0x0F, 1);
    vga("FADT: FUNCTION FINISHED", 0x0A, 1);
    vga("================================", 0x0F, 1);

    return fadt;
}
