#pragma once

#include "../../kernel/types.hpp"

void vga(
	const char* text,
	uint8_t color,
	uint8_t newline
);

void vgaHex(
	uint32_t value,
	uint8_t color
);

void vgaRender();

void vgaScrollView(
	int8_t direction
);
