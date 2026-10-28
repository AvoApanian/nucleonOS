aml_error_truncated:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_truncated]
	call	print_str
	jmp	enter_ui

aml_error_bad_package:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_bad_package]
	call	print_str
	jmp	enter_ui

aml_error_desync:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_desync]
	call	print_str
	jmp	enter_ui

aml_error_no_progress:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_no_progress]
	call	print_str
	jmp	enter_ui

aml_error_bad_name:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_bad_name]
	call	print_str
	jmp	enter_ui

aml_error_depth:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_depth]
	call	print_str
	jmp	enter_ui

aml_error_ns_full:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_ns_full]
	call	print_str
	jmp	enter_ui

aml_error_scope_ovf:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_scope_ovf]
	call	print_str
	jmp	enter_ui

aml_error_scope_unf:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_scope_unf]
	call	print_str
	jmp	enter_ui

aml_error_invalid_node:
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_invalid_node]
	call	print_str
	jmp	enter_ui

aml_unsupported_opcode:
	mov	edx, 0xA1
	mov	ecx, 2
	call	print_hex
	mov	[aml_error_offset], r14
	movzx	edx, byte [r14]

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
	mov	edx, 0xE2
	mov	ecx, 2
	call	print_hex
	mov	[aml_error_offset], r14
	movzx	edx, byte [r14 + 1]
	mov	r10d, edx
	movzx	edx, byte [r14]
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
	mov	edx, 0xD0
	mov	ecx, 2
	call	print_hex
	mov	[aml_error_offset], r14
	lea	rdx, [aml_msg_unsupported_data]
	call	print_str

	jmp	enter_ui
