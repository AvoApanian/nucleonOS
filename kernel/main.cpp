extern "C" void kernelMain()
{
    volatile char* video = (char*)0xB8000;

    const char* msg = "kernel is loading";
    int row = 4;
    int offset = row * 80 * 2;

    for (int i = 0; msg[i] != '\0'; i++)
    {
        video[offset + i*2]     = msg[i];
        video[offset + i*2 + 1] = 0x0F;
    }

    while(1)
    {
        asm volatile("hlt");
    }
}
