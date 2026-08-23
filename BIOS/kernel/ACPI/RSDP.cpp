#include "../types.hpp"
#include "../../driver/string/string.hpp"
#include "../../driver/vga/vga.hpp"

#include "RSDP.hpp"
#include "RSDT.hpp"
#include "XSDT.hpp"

static uint32_t getXSDTAddress32(const RSDPDescriptor20* rsdp)
{
	uint32_t address = 0;

	address |= (uint32_t)rsdp->xsdtAddress[0];
	address |= (uint32_t)rsdp->xsdtAddress[1] << 8;
	address |= (uint32_t)rsdp->xsdtAddress[2] << 16;
	address |= (uint32_t)rsdp->xsdtAddress[3] << 24;

	return address;
}

RSDPDescriptor20* findRSDP()
{
	for(uint32_t address = 0xE0000;
		address < 0x100000;
		address += 16)
	{
		char* ptr = (char*)address;

		if(ptr[0] != 'R')
			continue;

		if(ptr[1] != 'S')
			continue;

		if(ptr[2] != 'D')
			continue;

		if(ptr[3] != ' ')
			continue;

		if(ptr[4] != 'P')
			continue;

		if(ptr[5] != 'T')
			continue;

		if(ptr[6] != 'R')
			continue;

		if(ptr[7] != ' ')
			continue;

		RSDPDescriptor20* rsdp =
			(RSDPDescriptor20*)address;

		vga("RSDP FOUND", 0x0F, 1);

		vga("RSDP ADDRESS:", 0x0F, 0);
		vgaHex(address, 0x0F);

		vga("REVISION:", 0x0F, 0);
		vgaHex(rsdp->revision, 0x0F);

		vga("RSDT:", 0x0F, 0);
		vgaHex(rsdp->rsdtAddress, 0x0F);

		if(rsdp->revision < 2)
		{
			vga("ACPI 1.0 - USING RSDT", 0x0F, 1);

			getRSDT(rsdp->rsdtAddress);

			return rsdp;
		}

		uint32_t xsdtAddress =
			getXSDTAddress32(rsdp);

		vga("XSDT:", 0x0F, 0);
		vgaHex(xsdtAddress, 0x0F);

		if(xsdtAddress == 0)
		{
			vga("XSDT ADDRESS NULL", 0x04, 1);

			return rsdp;
		}

		getXSDT(xsdtAddress);

		return rsdp;
	}

	vga("RSDP NOT FOUND", 0x04, 1);

	return nullptr;
}
