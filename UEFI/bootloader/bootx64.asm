global efiMain

default rel

section .text
efiMain:
	mov r8, rdx
    	mov rcx, [r8 + 64]
	mov rax, [rcx + 8]
	lea rdx, [message]
	
	call rax

.hang:
	hlt
	jmp .hang

section .data
message:
    dw 'U','E','F','I',' ','b','o','o','t',' ','s','u','c','c','e','s','s','f','u','l','l','y','!',0
