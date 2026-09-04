#include "keyboard.hpp"

#include "../../kernel/types.hpp"
#include "../vga/vga.hpp"

#define PS2_DATA_PORT 0x60
#define PS2_STATUS_PORT 0x64

#define PS2_STATUS_OUTPUT_FULL 0x01
#define PS2_STATUS_AUX_DATA 0x20

#define SCANCODE_RELEASE_MASK 0x80

#define SCANCODE_W 0x11
#define SCANCODE_S 0x1F

static inline uint8_t inb(
	uint16_t port
)
{
	uint8_t value;

	asm volatile(
		"inb %1, %0"
		: "=a"(value)
		: "Nd"(port)
	);

	return value;
}

static uint8_t keyboardReadStatus()
{
	return inb(
		PS2_STATUS_PORT
	);
}

static uint8_t keyboardReadData()
{
	return inb(
		PS2_DATA_PORT
	);
}

static void keyboardHandleScancode(
	uint8_t scancode
)
{
	if(scancode & SCANCODE_RELEASE_MASK){

		return;
	}

	switch(scancode){

		case SCANCODE_W:

			vgaScrollView(-1);

			break;

		case SCANCODE_S:

			vgaScrollView(1);

			break;

		default:

			break;
	}
}

void keyboardInit()
{
	vga(
		"KEYBOARD: INIT",
		0x0A,
		1
	);
}

void keyboardPoll()
{
	uint8_t status =
		keyboardReadStatus();

	if(
		(status &
		 PS2_STATUS_OUTPUT_FULL)
		== 0
	){

		return;
	}

	if(
		status &
		PS2_STATUS_AUX_DATA
	){

		keyboardReadData();

		return;
	}

	uint8_t scancode =
		keyboardReadData();

	keyboardHandleScancode(
		scancode
	);
}
