#pragma once

#include "../types.hpp"

struct RSDPDescriptor20
{
	char signature[8];
	uint8_t checksum;
	char OEMID[6];
	uint8_t revision;
	uint32_t rsdtAddress;
	uint32_t length;
	uint8_t xsdtAddress[8];
	uint8_t extendedChecksum;
	uint8_t reserved[3];
};

RSDPDescriptor20* findRSDP();
