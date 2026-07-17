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
    mov eax,cr4
    or eax,1<<5
    mov cr4,eax
    mov eax,pdpt
    or eax,0b11
    mov dword [pml4],eax
    mov dword [pml4+4],0
    mov eax,pd
    or eax,0b11
    mov dword [pdpt],eax
    mov dword [pdpt+4],0
    mov eax,pt
    or eax,0b11
    mov dword [pd],eax
    mov dword [pd+4],0
    xor ecx,ecx
fillPt:
    mov eax,ecx
    shl eax,12
    or eax,0b11
    mov dword [pt + ecx*8], eax
    mov dword [pt + ecx*8 + 4], 0
    inc ecx
    cmp ecx,512
    jne fillPt
    mov eax,pml4
    mov cr3,eax
    mov ecx,0xC0000080
    rdmsr
    or eax,1<<8
    wrmsr
    lgdt [gdt64.Descriptor]
    mov eax,cr0
    or eax,1<<31
    mov cr0,eax
    jmp dword 0x08:longMode
bits 64
longMode:
    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov ss,ax
    xor eax,eax
    mov fs,ax
    mov gs,ax
    mov rsp,0x90000
    mov rsi,msgLong
    mov rdi,0xB8000 + 160
printLong:
    lodsb
    test al,al
    jz jumpKernel
    mov [rdi],al
    inc rdi
    mov byte [rdi],0x07
    inc rdi
    jmp printLong
jumpKernel:
    mov rax,0x10000
    jmp rax
msgProtected db "Protected Mode OK",0
msgLong db "Long Mode Activated",0
align 16
gdt64:
    dq 0
.code: equ $ - gdt64
    dq 0x00209A0000000000
.data: equ $ - gdt64
    dq 0x0000920000000000
.Descriptor:
    dw $ - gdt64 - 1
    dd gdt64
align 4096
pml4:
    times 512 dq 0
align 4096
pdpt:
    times 512 dq 0
align 4096
pd:
    times 512 dq 0
align 4096
pt:
    times 512 dq 0