#include "vga.hpp"

static volatile uint16_t* video = (uint16_t*)0xB8000;
static uint16_t cursor = 320;


void vga(const char* text, uint8_t color, uint8_t newline)
{
    for(int i = 0; text[i] != '\0'; i++)
    {
        video[cursor / 2] = ((uint16_t)color << 8) | text[i];

        cursor += 2;
    }


    if(newline == 1)
    {
        cursor += 160 - (cursor % 160);
    }
}



void vgaHex(uint64_t value, uint8_t color){
    char buffer[17];
    const char* hex = "0123456789ABCDEF";
    buffer[16] = '\0';


    for(int i = 15; i >= 0; i--) {
        buffer[i] = hex[value & 0xF];
        value >>= 4;
    }


    vga("0x", color, 0);
    vga(buffer, color, 1);
}
