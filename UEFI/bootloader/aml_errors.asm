aml_error_truncated:
	mov	byte [aml_error_kind], 1
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_truncated]
	call	print_str
	jmp	enter_ui

aml_error_bad_package:
	mov	byte [aml_error_kind], 2
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_bad_package]
	call	print_str
	jmp	enter_ui

aml_error_desync:
	mov	byte [aml_error_kind], 3
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_desync]
	call	print_str
	jmp	enter_ui

aml_error_no_progress:
	mov	byte [aml_error_kind], 4
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_no_progress]
	call	print_str
	jmp	enter_ui

aml_error_bad_name:
	mov	byte [aml_error_kind], 5
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_bad_name]
	call	print_str
	jmp	enter_ui

aml_error_depth:
	mov	byte [aml_error_kind], 6
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_depth]
	call	print_str
	jmp	enter_ui

aml_error_ns_full:
	mov	byte [aml_error_kind], 7
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_ns_full]
	call	print_str
	jmp	enter_ui

aml_error_scope_ovf:
	mov	byte [aml_error_kind], 8
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_scope_ovf]
	call	print_str
	jmp	enter_ui

aml_error_scope_unf:
	mov	byte [aml_error_kind], 9
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_scope_unf]
	call	print_str
	jmp	enter_ui

aml_error_invalid_node:
	mov	byte [aml_error_kind], 10
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_invalid_node]
	call	print_str
	jmp	enter_ui

aml_unsupported_opcode:
	mov	byte [aml_error_kind], 11
	mov	[aml_error_offset], r14
	mov	edx, 0xA1
	mov	ecx, 2
	call	print_hex

	mov	rax, [aml_error_offset]
	movzx	edx, byte [rax]

	push	rdx
	lea	rdx, [aml_msg_unsupported_opcode]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex
	lea	rdx, [newline]
	call	print_str
	jmp	enter_ui

aml_unsupported_ext_opcode:
	mov	byte [aml_error_kind], 12
	mov	[aml_error_offset], r14
	mov	edx, 0xE2
	mov	ecx, 2
	call	print_hex

	mov	rax, [aml_error_offset]
	movzx	r10d, byte [rax + 1]
	movzx	edx, byte [rax]
	shl	edx, 8
	or	edx, r10d

	push	rdx
	lea	rdx, [aml_msg_unsupported_opcode]
	call	print_str
	pop	rdx

	mov	ecx, 4
	call	print_hex
	lea	rdx, [newline]
	call	print_str
	jmp	enter_ui

aml_unsupported_dataobject:
	mov	byte [aml_error_kind], 13
	mov	edx, 0xD0
	mov	ecx, 2
	call	print_hex
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_unsupported_data]
	call	print_str

	jmp	enter_ui
