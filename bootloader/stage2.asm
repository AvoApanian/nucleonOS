org 0x8000

bits 32

protected_mode:

    mov edi,0xB8000

    ; caractère A
    mov byte [edi], 'A'

    ; couleur cyan
    mov byte [edi+1], 0x0B


halt:
    jmp halt
