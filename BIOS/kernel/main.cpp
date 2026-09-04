#include "../driver/vga/vga.hpp"
#include "../driver/keyboard/keyboard.hpp"

extern void findRSDP();

extern "C" void kernelMain()
{
	vga("Kernel is loading", 0x0F, 1);

	findRSDP();

	keyboardInit();

	while(1){

		keyboardPoll();
	}
}
