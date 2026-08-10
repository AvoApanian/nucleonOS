global efiMain

default rel

section .text

efiMain:

	sub rsp, 40

	mov r12, rdx

	mov r13, [r12 + 64]

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [message]

	call rax

	mov rcx, [r12 + 104]
	mov rbx, [r12 + 112]

search_loop:

	cmp rcx, 0
	je acpi_not_found

	cmp dword [rbx + 0], 0x8868E871
	jne next_entry

	cmp word [rbx + 4], 0xE4F1
	jne next_entry

	cmp word [rbx + 6], 0x11D3
	jne next_entry

	cmp byte [rbx + 8], 0xBC
	jne next_entry

	cmp byte [rbx + 9], 0x22
	jne next_entry

	cmp byte [rbx + 10], 0x00
	jne next_entry

	cmp byte [rbx + 11], 0x80
	jne next_entry

	cmp byte [rbx + 12], 0xC7
	jne next_entry

	cmp byte [rbx + 13], 0x3C
	jne next_entry

	cmp byte [rbx + 14], 0x88
	jne next_entry

	cmp byte [rbx + 15], 0x81
	jne next_entry

	mov r14, [rbx + 16]

	cmp dword [r14 + 0], 0x20445352
	jne rsdp_invalid

	cmp dword [r14 + 4], 0x20525450
	jne rsdp_invalid

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [acpiFound]

	call rax

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [rsdpValid]

	call rax

	mov r15, [r14 + 24]

	cmp dword [r15 + 0], 0x54445358
	jne xsdt_invalid

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [xsdtValid]

	call rax

	mov eax, [r15 + 4]

	cmp eax, 36
	jb xsdt_invalid

	sub eax, 36
	shr eax, 3

	mov r14d, eax

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [xsdtHeaderValid]

	call rax

	cmp r14d, 0
	je facp_not_found

	lea rbx, [r15 + 36]

xsdt_loop:

	mov rax, [rbx]

	cmp dword [rax + 0], 0x50434146
	je facp_found

	add rbx, 8

	dec r14d

	cmp r14d, 0
	jne xsdt_loop

	jmp facp_not_found

facp_found:

	mov r15, rax

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [facpFound]

	call rax

	mov rbx, [r15 + 140]

	cmp rbx, 0
	jne dsdt_address_ready

	mov eax, [r15 + 40]

	mov ebx, eax

	cmp rbx, 0
	je dsdt_not_found

dsdt_address_ready:

	mov r14, rbx

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [dsdtAddressFound]

	call rax

	cmp dword [r14 + 0], 0x54445344
	jne dsdt_invalid

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [dsdtValid]

	call rax

	jmp hang

next_entry:

	add rbx, 24

	dec rcx

	jmp search_loop

acpi_not_found:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [acpiNotFound]

	call rax

	jmp hang

rsdp_invalid:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [rsdpInvalid]

	call rax

	jmp hang

xsdt_invalid:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [xsdtInvalid]

	call rax

	jmp hang

facp_not_found:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [facpNotFound]

	call rax

	jmp hang

dsdt_not_found:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [dsdtNotFound]

	call rax

	jmp hang

dsdt_invalid:

	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [dsdtInvalid]

	call rax

	jmp hang

hang:

	hlt
	jmp hang

section .data

message:

	dw 'U','E','F','I',' ','b','o','o','t',' ','s','u','c','c','e','s','s','!',13,10,0

acpiFound:

	dw 'A','C','P','I',' ','F','O','U','N','D',13,10,0

acpiNotFound:

	dw 'A','C','P','I',' ','N','O','T',' ','F','O','U','N','D',13,10,0

rsdpValid:

	dw 'R','S','D','P',' ','V','A','L','I','D',13,10,0

rsdpInvalid:

	dw 'R','S','D','P',' ','I','N','V','A','L','I','D',13,10,0

xsdtValid:

	dw 'X','S','D','T',' ','V','A','L','I','D',13,10,0

xsdtInvalid:

	dw 'X','S','D','T',' ','I','N','V','A','L','I','D',13,10,0

xsdtHeaderValid:

	dw 'X','S','D','T',' ','H','E','A','D','E','R',' ','V','A','L','I','D',13,10,0

facpFound:

	dw 'F','A','C','P',' ','F','O','U','N','D',13,10,0

facpNotFound:

	dw 'F','A','C','P',' ','N','O','T',' ','F','O','U','N','D',13,10,0

dsdtAddressFound:

	dw 'D','S','D','T',' ','A','D','D','R','E','S','S',' ','F','O','U','N','D',13,10,0

dsdtValid:

	dw 'D','S','D','T',' ','V','A','L','I','D',13,10,0

dsdtNotFound:

	dw 'D','S','D','T',' ','N','O','T',' ','F','O','U','N','D',13,10,0

dsdtInvalid:

	dw 'D','S','D','T',' ','I','N','V','A','L','I','D',13,10,0
