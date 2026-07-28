org 0x7C00
bits 16
%include "config.inc"
start:
    cli
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov [bootDrive],dl
    call loadStage2
    call loadKernel
    lgdt [gdtDescriptor]
    mov eax,cr0
    or eax,1
    mov cr0,eax
    o32 jmp 0x08:protected_mode
bits 32
protected_mode:
    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov edi,0xB8000
    mov ecx,2000
clearScreen:
    mov word [edi],0x0020
    add edi,2
    loop clearScreen
    mov esi,message
    mov edi,0xB8000 + ((12*80+30)*2)
print:
    mov al,[esi]
    cmp al,0
    je stage2
    mov [edi],al
    mov byte [edi+1],0x0F
    add esi,1
    add edi,2
    jmp print
stage2:
    jmp 0x8000
message:
    db "NucleonOS Welcome :)",0
bits 16
gdStart:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
gdt_end:
gdtDescriptor:
    dw gdt_end - gdStart - 1
    dd gdStart
loadStage2:
    mov si,dap
    mov ah,0x42
    mov dl,[bootDrive]
    int 0x13
    jc diskError
    ret
loadKernel:
    mov si,kernelDap
    mov ah,0x42
    mov dl,[bootDrive]
    int 0x13
    jc diskError
    ret
diskError:
    cli
    hlt
    jmp diskError
dap:
    db 0x10
    db 0
    dw STAGE2_SECTORS
    dw 0x8000
    dw 0x0000
    dq 1
kernelDap:
    db 0x10
    db 0
    dw KERNEL_SECTORS
    dw 0x0000
    dw 0x1000
    dq KERNEL_LBA
bootDrive:
    db 0
times 510-($-$$) db 0
dw 0xAA55