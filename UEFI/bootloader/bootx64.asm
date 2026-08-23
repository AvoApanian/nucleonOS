global efiMain
default rel

section .text

efiMain:
	sub	rsp, 40
	mov	r12, rdx
	mov	r13, [r12 + 64]
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [message]
	call	rax
	mov	rcx, [r12 + 104]
	mov	rbx, [r12 + 112]

search_loop:
	cmp	rcx, 0
	je	acpi_not_found
	cmp	dword [rbx + 0], 0x8868E871
	jne	next_entry
	cmp	word [rbx + 4], 0xE4F1
	jne	next_entry
	cmp	word [rbx + 6], 0x11D3
	jne	next_entry
	cmp	byte [rbx + 8], 0xBC
	jne	next_entry
	cmp	byte [rbx + 9], 0x22
	jne	next_entry
	cmp	byte [rbx + 10], 0x00
	jne	next_entry
	cmp	byte [rbx + 11], 0x80
	jne	next_entry
	cmp	byte [rbx + 12], 0xC7
	jne	next_entry
	cmp	byte [rbx + 13], 0x3C
	jne	next_entry
	cmp	byte [rbx + 14], 0x88
	jne	next_entry
	cmp	byte [rbx + 15], 0x81
	jne	next_entry

	mov	r14, [rbx + 16]

	cmp	dword [r14 + 0], 0x20445352
	jne	rsdp_invalid
	cmp	dword [r14 + 4], 0x20525450
	jne	rsdp_invalid

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [acpiFound]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [rsdpValid]
	call	rax

	mov	r15, [r14 + 24]

	cmp	dword [r15 + 0], 0x54445358
	jne	xsdt_invalid

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [xsdtValid]
	call	rax

	mov	eax, [r15 + 4]
	cmp	eax, 36
	jb	xsdt_invalid

	sub	eax, 36
	shr	eax, 3
	mov	r14d, eax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [xsdtHeaderValid]
	call	rax

	cmp	r14d, 0
	je	facp_not_found

	lea	rbx, [r15 + 36]

xsdt_loop:
	mov	rax, [rbx]
	cmp	dword [rax + 0], 0x50434146
	je	facp_found
	add	rbx, 8
	dec	r14d
	cmp	r14d, 0
	jne	xsdt_loop
	jmp	facp_not_found

facp_found:
	mov	r15, rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [facpFound]
	call	rax

	mov	rbx, [r15 + 140]
	cmp	rbx, 0
	jne	dsdt_address_ready

	mov	eax, [r15 + 40]
	mov	ebx, eax
	cmp	rbx, 0
	je	dsdt_not_found

dsdt_address_ready:
	mov	r14, rbx

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtAddressFound]
	call	rax

	cmp	dword [r14 + 0], 0x54445344
	jne	dsdt_invalid

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtValid]
	call	rax

	mov	r15d, [r14 + 4]
	cmp	r15d, 36
	jb	dsdt_length_invalid

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtLengthLabel]
	call	rax

	mov	edx, r15d
	mov	ecx, 8
	lea	rdi, [lengthBuf]
	call	hex_to_utf16

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [lengthBuf]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [newline]
	call	rax

	xor	eax, eax
	xor	ecx, ecx

checksum_loop:
	cmp	ecx, r15d
	jae	checksum_done
	movzx	edx, byte [r14 + rcx]
	add	al, dl
	inc	ecx
	jmp	checksum_loop

checksum_done:
	test	al, al
	jnz	dsdt_checksum_invalid

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtChecksumValid]
	call	rax

	lea	rbx, [r14 + 36]
	sub	r15d, 36

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [amlAddressLabel]
	call	rax

	mov	rdx, rbx
	mov	ecx, 16
	lea	rdi, [addrBuf]
	call	hex_to_utf16

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [addrBuf]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [newline]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [amlSizeLabel]
	call	rax

	mov	edx, r15d
	mov	ecx, 8
	lea	rdi, [sizeBuf]
	call	hex_to_utf16

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [sizeBuf]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [newline]
	call	rax

	jmp	hang

next_entry:
	add	rbx, 24
	dec	rcx
	jmp	search_loop

acpi_not_found:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [acpiNotFound]
	call	rax
	jmp	hang

rsdp_invalid:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [rsdpInvalid]
	call	rax
	jmp	hang

xsdt_invalid:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [xsdtInvalid]
	call	rax
	jmp	hang

facp_not_found:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [facpNotFound]
	call	rax
	jmp	hang

dsdt_not_found:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtNotFound]
	call	rax
	jmp	hang

dsdt_invalid:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtInvalid]
	call	rax
	jmp	hang

dsdt_length_invalid:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtLengthInvalid]
	call	rax
	jmp	hang

dsdt_checksum_invalid:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [dsdtChecksumInvalid]
	call	rax
	jmp	hang

hang:
	hlt
	jmp	hang

hex_to_utf16:
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	mov	word [rdi], '0'
	add	rdi, 2

	mov	word [rdi], 'x'
	add	rdi, 2

	mov	esi, ecx
	dec	esi
	shl	esi, 2

hex_loop:
	mov	rax, rdx
	mov	ecx, esi
	shr	rax, cl
	and	al, 0x0F
	cmp	al, 10
	jb	hex_digit_09

	add	al, 'A' - 10
	jmp	hex_store

hex_digit_09:
	add	al, '0'

hex_store:
	movzx	eax, al
	mov	word [rdi], ax
	add	rdi, 2
	sub	esi, 4
	jns	hex_loop

	mov	word [rdi], 0

	pop	rdi
	pop	rsi
	pop	rdx
	pop	rcx
	pop	rax
	ret
aml_dump:
	mov r10,rbx
	


section .data

message:
	dw	'U','E','F','I',' ','b','o','o','t',' ','s','u','c','c','e','s','s','!',13,10,0

acpiFound:
	dw	'A','C','P','I',' ','F','O','U','N','D',13,10,0

acpiNotFound:
	dw	'A','C','P','I',' ','N','O','T',' ','F','O','U','N','D',13,10,0

rsdpValid:
	dw	'R','S','D','P',' ','V','A','L','I','D',13,10,0

rsdpInvalid:
	dw	'R','S','D','P',' ','I','N','V','A','L','I','D',13,10,0

xsdtValid:
	dw	'X','S','D','T',' ','V','A','L','I','D',13,10,0

xsdtInvalid:
	dw	'X','S','D','T',' ','I','N','V','A','L','I','D',13,10,0

xsdtHeaderValid:
	dw	'X','S','D','T',' ','H','E','A','D','E','R',' ','V','A','L','I','D',13,10,0

facpFound:
	dw	'F','A','C','P',' ','F','O','U','N','D',13,10,0

facpNotFound:
	dw	'F','A','C','P',' ','N','O','T',' ','F','O','U','N','D',13,10,0

dsdtAddressFound:
	dw	'D','S','D','T',' ','A','D','D','R','E','S','S',' ','F','O','U','N','D',13,10,0

dsdtValid:
	dw	'D','S','D','T',' ','V','A','L','I','D',13,10,0

dsdtNotFound:
	dw	'D','S','D','T',' ','N','O','T',' ','F','O','U','N','D',13,10,0

dsdtInvalid:
	dw	'D','S','D','T',' ','I','N','V','A','L','I','D',13,10,0

dsdtLengthLabel:
	dw	'D','S','D','T',' ','L','E','N','G','T','H',':',' ',0

dsdtLengthInvalid:
	dw	'D','S','D','T',' ','L','E','N','G','T','H',' ','I','N','V','A','L','I','D',' ','(','<',' ','3','6',')',13,10,0

dsdtChecksumValid:
	dw	'D','S','D','T',' ','C','H','E','C','K','S','U','M',':',' ','V','A','L','I','D',13,10,0

dsdtChecksumInvalid:
	dw	'D','S','D','T',' ','C','H','E','C','K','S','U','M',':',' ','I','N','V','A','L','I','D',13,10,0

amlAddressLabel:
	dw	'A','M','L',' ','A','D','D','R','E','S','S',':',' ',0

amlSizeLabel:
	dw	'A','M','L',' ','S','I','Z','E',':',' ',0

newline:
	dw	13,10,0

section .bss

lengthBuf:
	resw	12

sizeBuf:
	resw	12

addrBuf:
	resw	20
