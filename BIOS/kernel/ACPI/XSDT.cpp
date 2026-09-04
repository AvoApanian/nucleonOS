#include "../types.hpp"
#include "../../driver/vga/vga.hpp"
#include "XSDT.hpp"
#include "FADT.hpp"

static uint32_t getTableSignature(const ACPISDTHeader* table)
{
	uint32_t signature = 0;

	vga("XSDT: GET SIGNATURE START", 0x0F, 1);

	signature |= (uint32_t)(uint8_t)table->signature[0];
	signature |= (uint32_t)(uint8_t)table->signature[1] << 8;
	signature |= (uint32_t)(uint8_t)table->signature[2] << 16;
	signature |= (uint32_t)(uint8_t)table->signature[3] << 24;

	vga("XSDT: SIGNATURE READ", 0x0A, 1);

	return signature;
}

ACPISDTHeader* getXSDT(uint32_t address)
{
	vga("XSDT: FUNCTION START", 0x0F, 1);

	vga("XSDT: INPUT ADDRESS:", 0x0F, 0);
	vgaHex(address, 0x0F);

	if(address == 0){

		vga("XSDT: ADDRESS IS NULL", 0x04, 1);
		return nullptr;
	}

	vga("XSDT: ADDRESS VALID", 0x0A, 1);

	ACPISDTHeader* xsdt =
		(ACPISDTHeader*)address;

	vga("XSDT: HEADER POINTER CREATED", 0x0A, 1);

	vga("XSDT: SIGNATURE BYTE 0:", 0x0F, 0);
	vgaHex((uint32_t)(uint8_t)xsdt->signature[0], 0x0F);

	vga("XSDT: SIGNATURE BYTE 1:", 0x0F, 0);
	vgaHex((uint32_t)(uint8_t)xsdt->signature[1], 0x0F);

	vga("XSDT: SIGNATURE BYTE 2:", 0x0F, 0);
	vgaHex((uint32_t)(uint8_t)xsdt->signature[2], 0x0F);

	vga("XSDT: SIGNATURE BYTE 3:", 0x0F, 0);
	vgaHex((uint32_t)(uint8_t)xsdt->signature[3], 0x0F);

	if(xsdt->signature[0] != 'X' ||
	   xsdt->signature[1] != 'S' ||
	   xsdt->signature[2] != 'D' ||
	   xsdt->signature[3] != 'T'){

		vga("XSDT: INVALID SIGNATURE", 0x04, 1);
		return nullptr;
	}

	vga("XSDT: SIGNATURE VALID", 0x0A, 1);
	vga("XSDT FOUND", 0x0A, 1);

	vga("XSDT: ADDRESS:", 0x0F, 0);
	vgaHex(address, 0x0F);

	vga("XSDT: LENGTH:", 0x0F, 0);
	vgaHex(xsdt->length, 0x0F);

	vga("XSDT: REVISION:", 0x0F, 0);
	vgaHex(xsdt->revision, 0x0F);

	vga("XSDT: CHECKSUM:", 0x0F, 0);
	vgaHex(xsdt->checksum, 0x0F);

	vga("XSDT: START CHECKSUM VALIDATION", 0x0F, 1);

	if(!validateSDTChecksum(xsdt)){

		vga("XSDT: CHECKSUM INVALID", 0x04, 1);
		return nullptr;
	}

	vga("XSDT: CHECKSUM VALID", 0x0A, 1);

	if(xsdt->length < sizeof(ACPISDTHeader)){

		vga("XSDT: LENGTH TOO SMALL", 0x04, 1);

		vga("XSDT: BAD LENGTH:", 0x04, 0);
		vgaHex(xsdt->length, 0x04);

		return nullptr;
	}

	vga("XSDT: LENGTH VALID", 0x0A, 1);

	uint32_t entriesSize =
		xsdt->length - sizeof(ACPISDTHeader);

	vga("XSDT: ENTRIES SIZE:", 0x0F, 0);
	vgaHex(entriesSize, 0x0F);

	uint32_t entryCount =
		entriesSize / 8;

	vga("XSDT: ENTRY COUNT:", 0x0F, 0);
	vgaHex(entryCount, 0x0F);

	if(entryCount == 0){

		vga("XSDT: NO ENTRIES", 0x04, 1);
		return xsdt;
	}

	vga("XSDT: ENTRIES FOUND", 0x0A, 1);

	uint8_t* entries =
		(uint8_t*)xsdt + sizeof(ACPISDTHeader);

	vga("XSDT: ENTRY ARRAY ADDRESS:", 0x0F, 0);
	vgaHex((uint32_t)entries, 0x0F);

	vga("XSDT: START ENTRY LOOP", 0x0A, 1);

	for(uint32_t i = 0; i < entryCount; i++){

		vga("XSDT: ----------------", 0x0F, 1);

		vga("XSDT: PROCESSING ENTRY:", 0x0F, 0);
		vgaHex(i, 0x0F);

		uint8_t* entry =
			entries + (i * 8);

		vga("XSDT: ENTRY ADDRESS:", 0x0F, 0);
		vgaHex((uint32_t)entry, 0x0F);

		uint32_t tableAddress = 0;

		tableAddress |= (uint32_t)entry[0];
		tableAddress |= (uint32_t)entry[1] << 8;
		tableAddress |= (uint32_t)entry[2] << 16;
		tableAddress |= (uint32_t)entry[3] << 24;

		uint32_t high = 0;

		high |= (uint32_t)entry[4];
		high |= (uint32_t)entry[5] << 8;
		high |= (uint32_t)entry[6] << 16;
		high |= (uint32_t)entry[7] << 24;

		vga("XSDT: ENTRY LOW:", 0x0F, 0);
		vgaHex(tableAddress, 0x0F);

		vga("XSDT: ENTRY HIGH:", 0x0F, 0);
		vgaHex(high, 0x0F);

		if(high != 0){

			vga("XSDT: 64BIT ADDRESS - SKIP", 0x04, 1);
			continue;
		}

		vga("XSDT: ENTRY IS 32BIT", 0x0A, 1);

		if(tableAddress == 0){

			vga("XSDT: TABLE ADDRESS NULL", 0x04, 1);
			continue;
		}

		vga("XSDT: TABLE ADDRESS VALID", 0x0A, 1);

		ACPISDTHeader* table =
			(ACPISDTHeader*)tableAddress;

		vga("XSDT: TABLE POINTER CREATED", 0x0A, 1);

		vga("XSDT: TABLE ADDRESS:", 0x0F, 0);
		vgaHex(tableAddress, 0x0F);

		vga("XSDT: READING TABLE SIGNATURE", 0x0F, 1);

		vga("XSDT: TABLE SIGNATURE:", 0x0F, 0);
		vgaHex(getTableSignature(table), 0x0F);

		vga("XSDT: TABLE LENGTH:", 0x0F, 0);
		vgaHex(table->length, 0x0F);

		vga("XSDT: TABLE REVISION:", 0x0F, 0);
		vgaHex(table->revision, 0x0F);

		vga("XSDT: VALIDATING TABLE CHECKSUM", 0x0F, 1);

		if(validateSDTChecksum(table)){

			vga("XSDT: TABLE CHECKSUM VALID", 0x0A, 1);
		}
		else{

			vga("XSDT: TABLE CHECKSUM INVALID", 0x04, 1);
		}

		vga("XSDT: CHECKING FOR FACP", 0x0F, 1);

		if(table->signature[0] == 'F' &&
		   table->signature[1] == 'A' &&
		   table->signature[2] == 'C' &&
		   table->signature[3] == 'P'){

			vga("XSDT: FACP DETECTED", 0x0A, 1);

			vga("XSDT: CALLING getFADT()", 0x0A, 1);

			getFADT(tableAddress);

			vga("XSDT: getFADT() RETURNED", 0x0A, 1);
		}
		else{

			vga("XSDT: TABLE IS NOT FACP", 0x0F, 1);
		}

		vga("XSDT: ENTRY FINISHED", 0x0A, 1);
	}

	vga("XSDT: ENTRY LOOP FINISHED", 0x0A, 1);
	vga("XSDT: ALL ENTRIES PROCESSED", 0x0A, 1);
	vga("XSDT: FUNCTION FINISHED", 0x0A, 1);

	return xsdt;
}
