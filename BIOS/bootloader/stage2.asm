org 0x8000
bits 32
protected_mode:
    mov esi,msgProtected
    mov edi,0xB8000
printProtected:
    lodsb
    test al,al
    jz protectedDone
    mov [edi],al
    inc edi
    mov byte [edi],0x07
    inc edi
    jmp printProtected
protectedDone:
    jmp 0x10000
msgProtected db "Protected Mode OK",0
