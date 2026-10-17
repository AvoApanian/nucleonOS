aml_error_truncated:
	lea	rdx, [aml_msg_truncated]
	call	print_str
	jmp	enter_ui

aml_error_bad_package:
	lea	rdx, [aml_msg_bad_package]
	call	print_str
	jmp	enter_ui

aml_error_desync:
	lea	rdx, [aml_msg_desync]
	call	print_str
	jmp	enter_ui

aml_error_no_progress:
	lea	rdx, [aml_msg_no_progress]
	call	print_str
	jmp	enter_ui

aml_error_bad_name:
	lea	rdx, [aml_msg_bad_name]
	call	print_str
	jmp	enter_ui

aml_error_depth:
	lea	rdx, [aml_msg_depth]
	call	print_str
	jmp	enter_ui

aml_error_ns_full:
	lea	rdx, [aml_msg_ns_full]
	call	print_str
	jmp	enter_ui

aml_error_scope_ovf:
	lea	rdx, [aml_msg_scope_ovf]
	call	print_str
	jmp	enter_ui

aml_error_scope_unf:
	lea	rdx, [aml_msg_scope_unf]
	call	print_str
	jmp	enter_ui

aml_error_invalid_node:
	lea	rdx, [aml_msg_invalid_node]
	call	print_str
	jmp	enter_ui

aml_unsupported_opcode:
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
	lea	rdx, [aml_msg_unsupported_data]
	call	print_str

	jmp	enter_ui
