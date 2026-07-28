OUTPUT_FORMAT("pei-x86-64")
ENTRY(efiMain)

SECTIONS
{
    . = 0x140000000 + 0x1000;

    .text : ALIGN(4096)
    {
        *(.text)
    }

    .data : ALIGN(4096)
    {
        *(.data)
        *(.rdata)
    }

    .pdata : ALIGN(4096)
    {
        *(.pdata)
    }

    .reloc : ALIGN(4096)
    {
        *(.reloc)
    }

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
    }
}
