hex_to_utf16:
	push	rax
	push	rcx
	push	rdx
	push	rsi
	push	rdi

	cmp	ecx, 1
	jb	hex_bad_width
	cmp	ecx, 16
	ja	hex_bad_width
	jmp	hex_width_ok

hex_bad_width:
	mov	ecx, 16

hex_width_ok:
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

print_str:
	push	rsi
	push	rdi

	cmp	byte [log_full], 0
	jne	print_str_done_noop

	mov	rsi, rdx
	mov	rdi, [log_write_ptr]

	lea	rax, [log_buffer]
	add	rax, LOG_BUF_WORDS * 2

print_str_loop:
	movzx	ecx, word [rsi]

	test	cx, cx
	jz	print_str_done

	cmp	rdi, rax
	jae	print_str_full

	mov	word [rdi], cx
	add	rdi, 2
	add	rsi, 2
	mov	byte [redraw_pending], 1

	cmp	cx, 10
	jne	print_str_loop

	mov	[log_write_ptr], rdi

	mov	eax, [log_line_total]
	cmp	eax, LOG_LINE_MAX - 1
	jae	print_str_full

	lea	rdx, [log_line_ptr]
	mov	[rdx + rax * 8], rdi
	inc	dword [log_line_total]
	mov	byte [redraw_pending], 1

	lea	rax, [log_buffer]
	add	rax, LOG_BUF_WORDS * 2
	jmp	print_str_loop

print_str_full:
	mov	[log_write_ptr], rdi
	mov	byte [log_full], 1

	pop	rdi
	pop	rsi
	ret

print_str_done:
	mov	[log_write_ptr], rdi

	pop	rdi
	pop	rsi
	ret

print_str_done_noop:
	pop	rdi
	pop	rsi
	ret

print_hex:
	push	rdi

	lea	rdi, [hex_scratch]
	call	hex_to_utf16

	lea	rdx, [hex_scratch]
	call	print_str

	pop	rdi
	ret
