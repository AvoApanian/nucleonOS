#pragma once

#include "../types.hpp"

struct ACPISDTHeader
{
	char signature[4];
	uint32_t length;
	uint8_t revision;
	uint8_t checksum;
	char OEMID[6];
	char OEMTableID[8];
	uint32_t OEMRevision;
	uint32_t creatorID;
	uint32_t creatorRevision;
};

ACPISDTHeader* getXSDT(uint32_t address);
