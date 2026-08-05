global efiMain

default rel


section .text


efiMain:

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


	mov rcx, r13
	mov rax, [r13 + 8]

	lea rdx, [acpiFound]

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
