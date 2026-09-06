global efiMain
default rel

LOG_START_ROW equ 11
VISIBLE_ROWS equ 14

section .text

efiMain:
	sub	rsp, 40
	mov	r12, rdx
	mov	r13, [r12 + 64]

	lea	rax, [log_buffer]
	mov	[log_write_ptr], rax
	mov	[log_line_ptr], rax
	mov	dword [log_line_total], 1
	mov	dword [scroll_offset], 0

	call	redraw_screen

	lea	rdx, [message]
	call	print_str

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

	lea	rdx, [acpiFound]
	call	print_str

	lea	rdx, [rsdpValid]
	call	print_str

	mov	r15, [r14 + 24]

	cmp	dword [r15 + 0], 0x54445358
	jne	xsdt_invalid

	lea	rdx, [xsdtValid]
	call	print_str

	mov	eax, [r15 + 4]

	cmp	eax, 36
	jb	xsdt_invalid

	sub	eax, 36
	shr	eax, 3
	mov	r14d, eax

	lea	rdx, [xsdtHeaderValid]
	call	print_str

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

	lea	rdx, [facpFound]
	call	print_str

	mov	rbx, [r15 + 140]

	cmp	rbx, 0
	jne	dsdt_address_ready

	mov	eax, [r15 + 40]
	mov	ebx, eax

	cmp	rbx, 0
	je	dsdt_not_found

dsdt_address_ready:
	mov	r14, rbx

	lea	rdx, [dsdtAddressFound]
	call	print_str

	cmp	dword [r14 + 0], 0x54445344
	jne	dsdt_invalid

	lea	rdx, [dsdtValid]
	call	print_str

	mov	r15d, [r14 + 4]

	cmp	r15d, 36
	jb	dsdt_length_invalid

	lea	rdx, [dsdtLengthLabel]
	call	print_str

	mov	edx, r15d
	mov	ecx, 8
	lea	rdi, [lengthBuf]
	call	hex_to_utf16

	lea	rdx, [lengthBuf]
	call	print_str

	lea	rdx, [newline]
	call	print_str

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

	lea	rdx, [dsdtChecksumValid]
	call	print_str

	lea	rbx, [r14 + 36]
	sub	r15d, 36

	lea	rdx, [amlAddressLabel]
	call	print_str

	mov	rdx, rbx
	mov	ecx, 16
	lea	rdi, [addrBuf]
	call	hex_to_utf16

	lea	rdx, [addrBuf]
	call	print_str

	lea	rdx, [newline]
	call	print_str

	lea	rdx, [amlSizeLabel]
	call	print_str

	mov	edx, r15d
	mov	ecx, 8
	lea	rdi, [sizeBuf]
	call	hex_to_utf16

	lea	rdx, [sizeBuf]
	call	print_str

	lea	rdx, [newline]
	call	print_str

	call	aml_dump

	jmp	enter_ui

next_entry:
	add	rbx, 24
	dec	rcx
	jmp	search_loop

acpi_not_found:
	lea	rdx, [acpiNotFound]
	call	print_str
	jmp	enter_ui

rsdp_invalid:
	lea	rdx, [rsdpInvalid]
	call	print_str
	jmp	enter_ui

xsdt_invalid:
	lea	rdx, [xsdtInvalid]
	call	print_str
	jmp	enter_ui

facp_not_found:
	lea	rdx, [facpNotFound]
	call	print_str
	jmp	enter_ui

dsdt_not_found:
	lea	rdx, [dsdtNotFound]
	call	print_str
	jmp	enter_ui

dsdt_invalid:
	lea	rdx, [dsdtInvalid]
	call	print_str
	jmp	enter_ui

dsdt_length_invalid:
	lea	rdx, [dsdtLengthInvalid]
	call	print_str
	jmp	enter_ui

dsdt_checksum_invalid:
	lea	rdx, [dsdtChecksumInvalid]
	call	print_str
	jmp	enter_ui

enter_ui:
	call	redraw_screen

input_loop:
	mov	rcx, [r12 + 48]
	lea	rdx, [key_buf]
	mov	rax, [rcx + 8]
	call	rax

	cmp	rax, 0
	jne	input_loop

	movzx	eax, word [key_buf + 2]

	cmp	eax, 0x77
	je	scroll_up
	cmp	eax, 0x57
	je	scroll_up
	cmp	eax, 0x73
	je	scroll_down
	cmp	eax, 0x53
	je	scroll_down

	jmp	input_loop

scroll_up:
	cmp	dword [scroll_offset], 0
	je	input_loop
	dec	dword [scroll_offset]
	call	redraw_screen
	jmp	input_loop

scroll_down:
	mov	eax, [log_line_total]
	sub	eax, VISIBLE_ROWS
	cmp	eax, 0
	jle	input_loop
	cmp	[scroll_offset], eax
	jge	input_loop
	inc	dword [scroll_offset]
	call	redraw_screen
	jmp	input_loop

redraw_screen:
	mov	rcx, r13
	mov	rax, [r13 + 48]
	call	rax

	mov	rcx, r13
	mov	rdx, 9
	mov	rax, [r13 + 40]
	call	rax

	call	draw_banner

	mov	rcx, r13
	mov	rdx, 7
	mov	rax, [r13 + 40]
	call	rax

	mov	eax, [scroll_offset]
	mov	[redraw_line], eax
	mov	dword [redraw_row], 0

redraw_loop:
	mov	eax, [redraw_row]
	cmp	eax, VISIBLE_ROWS
	jae	redraw_done

	mov	eax, [redraw_line]
	cmp	eax, [log_line_total]
	jae	redraw_done

	call	draw_log_line

	inc	dword [redraw_line]
	inc	dword [redraw_row]
	jmp	redraw_loop

redraw_done:
	ret

draw_banner:
	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine1]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine2]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine3]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine4]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine5]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine6]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine7]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine8]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine9]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [bannerLine10]
	call	rax

	ret

draw_log_line:
	mov	eax, [redraw_line]
	lea	rdx, [log_line_ptr]
	mov	rsi, [rdx + rax * 8]

	lea	rdi, [line_scratch]

draw_log_copy:
	movzx	ecx, word [rsi]
	cmp	cx, 13
	je	draw_log_copy_done
	cmp	cx, 10
	je	draw_log_copy_done
	test	cx, cx
	jz	draw_log_copy_done
	mov	word [rdi], cx
	add	rdi, 2
	add	rsi, 2
	jmp	draw_log_copy

draw_log_copy_done:
	mov	word [rdi], 0

	mov	rcx, r13
	mov	edx, 0
	mov	r8d, [redraw_row]
	add	r8d, LOG_START_ROW
	mov	rax, [r13 + 56]
	call	rax

	mov	rcx, r13
	mov	rax, [r13 + 8]
	lea	rdx, [line_scratch]
	call	rax

	ret

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
	mov	r14, rbx
	mov	rax, r15
	add	rax, rbx
	mov	r15, rax

	lea	rdx, [amlParseStart]
	call	print_str

	call	aml_term_list_parse

	lea	rdx, [amlParseDone]
	call	print_str

	ret

aml_term_list_parse:
aml_tlp_loop:
	cmp	r14, r15
	jae	aml_tlp_done

	call	aml_parse_one_object

	jmp	aml_tlp_loop

aml_tlp_done:
	ret

aml_parse_one_object:
	movzx	eax, byte [r14]

	cmp	al, 0x10
	je	aml_do_scope

	cmp	al, 0x08
	je	aml_do_name

	cmp	al, 0x14
	je	aml_do_method

	cmp	al, 0x5B
	je	aml_handle_ext_op

	cmp	al, 0x11
	je	aml_do_bufferstmt

	cmp	al, 0x12
	je	aml_do_packagestmt

	cmp	al, 0x13
	je	aml_do_varpackagestmt

	jmp	aml_unsupported_opcode

aml_handle_ext_op:
	movzx	eax, byte [r14 + 1]

	cmp	al, 0x82
	je	aml_do_device

	cmp	al, 0x80
	je	aml_do_opregion

	cmp	al, 0x81
	je	aml_do_field

	jmp	aml_unsupported_opcode

aml_do_scope:
	inc	r14

	mov	rax, r14
	push	rax
	call	aml_pkglength_read
	pop	rcx
	add	rax, rcx

	push	r15
	mov	r15, rax

	lea	rdx, [aml_msg_scope]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	pop	r15
	ret

aml_do_device:
	add	r14, 2

	mov	rax, r14
	push	rax
	call	aml_pkglength_read
	pop	rcx
	add	rax, rcx

	push	r15
	mov	r15, rax

	lea	rdx, [aml_msg_device]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	pop	r15
	ret

aml_do_name:
	inc	r14

	lea	rdx, [aml_msg_name]
	call	print_str

	call	aml_name_string_read
	call	aml_parse_data_ref_object

	lea	rdx, [newline]
	call	print_str

	ret

aml_parse_data_ref_object:
	movzx	eax, byte [r14]

	cmp	al, 0x0D
	je	aml_dro_string

	cmp	al, 0x11
	je	aml_dro_skip_pkg

	cmp	al, 0x12
	je	aml_dro_skip_pkg

	cmp	al, 0x13
	je	aml_dro_skip_pkg

	call	aml_read_termarg_integer

	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	push	rax
	lea	rdx, [aml_msg_eq_hex]
	call	print_str
	pop	rdx

	mov	ecx, 16
	call	print_hex

	ret

aml_dro_skip_pkg:
	lea	rdx, [aml_msg_eq_data]
	call	print_str

	call	aml_skip_pkg_object

	ret

aml_dro_string:
	inc	r14

	lea	rdx, [aml_msg_eq_str]
	call	print_str

	lea	rdi, [aml_name_buf]

aml_dro_str_loop:
	movzx	eax, byte [r14]

	cmp	al, 0x00
	je	aml_dro_str_done

	mov	word [rdi], ax
	add	rdi, 2
	inc	r14

	jmp	aml_dro_str_loop

aml_dro_str_done:
	mov	word [rdi], 0
	inc	r14

	lea	rdx, [aml_name_buf]
	call	print_str

	ret

aml_skip_pkg_object:
	inc	r14

	mov	rax, r14
	push	rax
	call	aml_pkglength_read
	pop	rcx
	add	rax, rcx

	push	rax
	lea	rdx, [aml_msg_end_eq]
	call	print_str
	mov	rdx, [rsp]

	mov	ecx, 16
	call	print_hex

	pop	rax
	mov	r14, rax

	ret

aml_do_bufferstmt:
	lea	rdx, [aml_msg_bufferstmt]
	call	print_str

	call	aml_skip_pkg_object

	lea	rdx, [newline]
	call	print_str

	ret

aml_do_packagestmt:
	lea	rdx, [aml_msg_packagestmt]
	call	print_str

	call	aml_skip_pkg_object

	lea	rdx, [newline]
	call	print_str

	ret

aml_do_varpackagestmt:
	lea	rdx, [aml_msg_varpackagestmt]
	call	print_str

	call	aml_skip_pkg_object

	lea	rdx, [newline]
	call	print_str

	ret

aml_do_opregion:
	add	r14, 2

	lea	rdx, [aml_msg_opregion]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	movzx	eax, byte [r14]
	inc	r14

	push	rax
	lea	rdx, [aml_msg_space]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_read_termarg_integer

	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	push	rax
	lea	rdx, [aml_msg_offset]
	call	print_str
	pop	rdx

	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_read_termarg_integer

	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	push	rax
	lea	rdx, [aml_msg_length]
	call	print_str
	pop	rdx

	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	ret

aml_do_field:
	add	r14, 2

	mov	rax, r14
	push	rax
	call	aml_pkglength_read
	pop	rcx
	add	rax, rcx

	push	r15
	mov	r15, rax

	lea	rdx, [aml_msg_field]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	movzx	eax, byte [r14]
	inc	r14

	push	rax
	lea	rdx, [aml_msg_flags]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	mov	dword [aml_field_bit_offset], 0

aml_field_loop:
	cmp	r14, r15
	jae	aml_field_done

	movzx	eax, byte [r14]

	cmp	al, 0x00
	je	aml_field_reserved

	cmp	al, 0x01
	je	aml_field_access

	cmp	al, 0x03
	je	aml_field_extaccess

	cmp	al, 0x02
	je	aml_field_connect

	jmp	aml_field_named

aml_field_reserved:
	inc	r14

	call	aml_pkglength_read

	push	rax
	lea	rdx, [aml_msg_reserved]
	call	print_str
	pop	rdx

	mov	ecx, 8
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	add	dword [aml_field_bit_offset], eax

	jmp	aml_field_loop

aml_field_access:
	add	r14, 3

	lea	rdx, [aml_msg_access]
	call	print_str

	jmp	aml_field_loop

aml_field_extaccess:
	add	r14, 4

	lea	rdx, [aml_msg_access]
	call	print_str

	jmp	aml_field_loop

aml_field_connect:
	lea	rdx, [aml_msg_connect_unsupported]
	call	print_str

	jmp	aml_field_done

aml_field_named:
	lea	rdi, [aml_name_buf]
	mov	ecx, 4

aml_field_nameseg_loop:
	movzx	eax, byte [r14]
	mov	word [rdi], ax
	add	rdi, 2
	inc	r14
	dec	ecx
	jnz	aml_field_nameseg_loop

	mov	word [rdi], 0

	lea	rdx, [aml_name_buf]
	call	print_str

	lea	rdx, [aml_msg_bitoffset]
	call	print_str

	mov	edx, [aml_field_bit_offset]
	mov	ecx, 8
	call	print_hex

	call	aml_pkglength_read
	mov	r10d, eax

	lea	rdx, [aml_msg_width]
	call	print_str

	mov	edx, eax
	mov	ecx, 8
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	add	dword [aml_field_bit_offset], r10d

	jmp	aml_field_loop

aml_field_done:
	pop	r15
	ret

aml_do_method:
	inc	r14

	mov	rax, r14
	push	rax
	call	aml_pkglength_read
	pop	rcx
	add	rax, rcx

	push	rax

	lea	rdx, [aml_msg_method]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	movzx	eax, byte [r14]
	inc	r14
	and	eax, 0x07

	push	rax
	lea	rdx, [aml_msg_argcount]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	mov	rdx, [rsp]
	push	rdx

	lea	rdx, [aml_msg_bodyend]
	call	print_str

	pop	rdx

	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	pop	rax
	mov	r14, rax

	ret

aml_name_string_read:
	push	rdi

	lea	rdi, [aml_name_buf]

	cmp	byte [r14], 0x5C
	jne	aml_ns_check_parent

	mov	word [rdi], '\'
	add	rdi, 2
	inc	r14

	jmp	aml_ns_segpath

aml_ns_check_parent:
	cmp	byte [r14], 0x5E
	jne	aml_ns_segpath

aml_ns_parent_loop:
	mov	word [rdi], '^'
	add	rdi, 2
	inc	r14

	cmp	byte [r14], 0x5E
	je	aml_ns_parent_loop

aml_ns_segpath:
	movzx	eax, byte [r14]

	cmp	al, 0x00
	je	aml_ns_null

	cmp	al, 0x2E
	je	aml_ns_dual

	cmp	al, 0x2F
	je	aml_ns_multi

	call	aml_name_seg_emit
	jmp	aml_ns_finish

aml_ns_dual:
	inc	r14

	call	aml_name_seg_emit

	mov	word [rdi], '.'
	add	rdi, 2

	call	aml_name_seg_emit

	jmp	aml_ns_finish

aml_ns_multi:
	inc	r14

	movzx	r8d, byte [r14]
	inc	r14

aml_ns_multi_loop:
	call	aml_name_seg_emit

	dec	r8d
	jz	aml_ns_finish

	mov	word [rdi], '.'
	add	rdi, 2

	jmp	aml_ns_multi_loop

aml_ns_null:
	inc	r14

	jmp	aml_ns_finish

aml_ns_finish:
	mov	word [rdi], 0

	lea	rdx, [aml_name_buf]
	call	print_str

	pop	rdi
	ret

aml_name_seg_emit:
	mov	ecx, 4

aml_nse_loop:
	movzx	eax, byte [r14]
	mov	word [rdi], ax
	add	rdi, 2
	inc	r14
	dec	ecx
	jnz	aml_nse_loop

	ret

aml_pkglength_read:
	movzx	ecx, byte [r14]
	inc	r14

	mov	edx, ecx
	shr	edx, 6
	and	ecx, 0x3F

	test	edx, edx
	jnz	aml_pkg_multi

	movzx	eax, cl
	ret

aml_pkg_multi:
	and	ecx, 0x0F
	mov	eax, ecx
	mov	r8d, 4

aml_pkg_byteloop:
	movzx	r9d, byte [r14]
	inc	r14

	mov	ecx, r8d
	shl	r9d, cl
	or	eax, r9d

	add	r8d, 8
	dec	edx
	jnz	aml_pkg_byteloop

	ret

aml_read_termarg_integer:
	mov	byte [aml_error], 0
	movzx	eax, byte [r14]

	cmp	al, 0x00
	je	aml_ti_zero

	cmp	al, 0x01
	je	aml_ti_one

	cmp	al, 0xFF
	je	aml_ti_ones

	cmp	al, 0x0A
	je	aml_ti_byte

	cmp	al, 0x0B
	je	aml_ti_word

	cmp	al, 0x0C
	je	aml_ti_dword

	cmp	al, 0x0E
	je	aml_ti_qword

	mov	byte [aml_error], 1
	xor	eax, eax
	ret

aml_ti_zero:
	inc	r14
	xor	eax, eax
	ret

aml_ti_one:
	inc	r14
	mov	eax, 1
	ret

aml_ti_ones:
	inc	r14
	mov	rax, -1
	ret

aml_ti_byte:
	inc	r14
	movzx	eax, byte [r14]
	inc	r14
	ret

aml_ti_word:
	inc	r14
	movzx	eax, word [r14]
	add	r14, 2
	ret

aml_ti_dword:
	inc	r14
	mov	eax, [r14]
	add	r14, 4
	ret

aml_ti_qword:
	inc	r14
	mov	rax, [r14]
	add	r14, 8
	ret

print_str:
	push	rsi
	push	rdi

	mov	rsi, rdx
	mov	rdi, [log_write_ptr]

print_str_loop:
	movzx	ecx, word [rsi]
	test	cx, cx
	jz	print_str_done

	mov	word [rdi], cx
	add	rdi, 2
	add	rsi, 2

	cmp	cx, 10
	jne	print_str_loop

	mov	[log_write_ptr], rdi

	mov	eax, [log_line_total]
	lea	rdx, [log_line_ptr]
	mov	[rdx + rax * 8], rdi
	inc	dword [log_line_total]

	jmp	print_str_loop

print_str_done:
	mov	[log_write_ptr], rdi

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

aml_unsupported_opcode:
	push	rax

	lea	rdx, [aml_msg_unsupported_opcode]
	call	print_str

	pop	rdx

	and	edx, 0xFF
	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	jmp	enter_ui

aml_unsupported_dataobject:
	lea	rdx, [aml_msg_unsupported_data]
	call	print_str

	jmp	enter_ui

section .data

bannerLine1:
	dw	'#',' ',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#','#','#','#','#',' ',' ',' ','#','#','#',' ',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ',' ','#','#','#','#',13,10,0

bannerLine2:
	dw	'#',' ',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#','#','#','#','#',' ',' ',' ','#','#','#',' ',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ',' ','#','#','#','#',13,10,0

bannerLine3:
	dw	'#','#',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#','#',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',13,10,0

bannerLine4:
	dw	'#','#',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#','#',' ',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',13,10,0

bannerLine5:
	dw	'#',' ','#',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#','#','#',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ','#',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',13,10,0

bannerLine6:
	dw	'#',' ','#',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#','#','#',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ','#',' ','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',13,10,0

bannerLine7:
	dw	'#',' ',' ','#','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ','#','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',13,10,0

bannerLine8:
	dw	'#',' ',' ','#','#',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',' ',' ',' ','#',' ',' ','#',' ',' ','#','#',' ',' ','#',' ',' ',' ','#',' ',' ',' ',' ',' ',' ','#',13,10,0

bannerLine9:
	dw	'#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ',' ','#','#','#','#',' ',' ','#','#','#','#','#',' ',' ','#','#','#','#','#',' ',' ',' ','#','#','#',' ',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ','#','#','#','#',' ',13,10,0

bannerLine10:
	dw	'#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ',' ','#','#','#','#',' ',' ','#','#','#','#','#',' ',' ','#','#','#','#','#',' ',' ',' ','#','#','#',' ',' ',' ','#',' ',' ',' ','#',' ',' ',' ','#','#','#',' ',' ',' ','#','#','#','#',' ',13,10,0

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

amlParseStart:
	dw	'A','M','L',' ','P','A','R','S','E',' ','S','T','A','R','T',13,10,0

amlParseDone:
	dw	'A','M','L',' ','P','A','R','S','E',' ','D','O','N','E',13,10,0

aml_msg_scope:
	dw	'S','C','O','P','E',':',' ',0

aml_msg_device:
	dw	'D','E','V','I','C','E',':',' ',0

aml_msg_name:
	dw	'N','A','M','E',':',' ',0

aml_msg_opregion:
	dw	'O','P','R','E','G','I','O','N',':',' ',0

aml_msg_field:
	dw	'F','I','E','L','D',':',' ',0

aml_msg_method:
	dw	'M','E','T','H','O','D',':',' ',0

aml_msg_eq_hex:
	dw	' ','=',' ','0','x',0

aml_msg_space:
	dw	' ',' ','s','p','a','c','e','=','0','x',0

aml_msg_offset:
	dw	' ',' ','o','f','f','s','e','t','=','0','x',0

aml_msg_length:
	dw	' ',' ','l','e','n','g','t','h','=','0','x',0

aml_msg_flags:
	dw	' ',' ','f','l','a','g','s','=','0','x',0

aml_msg_argcount:
	dw	' ',' ','a','r','g','c','o','u','n','t','=','0','x',0

aml_msg_bodyend:
	dw	' ',' ','b','o','d','y','E','n','d','=','0','x',0

aml_msg_reserved:
	dw	' ',' ','(','r','e','s','e','r','v','e','d',')',' ','w','i','d','t','h','=','0','x',0

aml_msg_access:
	dw	' ',' ','(','a','c','c','e','s','s',' ','f','i','e','l','d',')',13,10,0

aml_msg_connect_unsupported:
	dw	' ',' ','(','c','o','n','n','e','c','t',' ','f','i','e','l','d',',',' ','u','n','s','u','p','p','o','r','t','e','d',')',' ','s','t','o','p','p','i','n','g',13,10,0

aml_msg_bitoffset:
	dw	' ',' ','b','i','t','o','f','f','s','e','t','=','0','x',0

aml_msg_width:
	dw	' ',' ','w','i','d','t','h','=','0','x',0

aml_msg_eq_str:
	dw	' ','=',' ','S','T','R',':',' ',0

aml_msg_eq_data:
	dw	' ','=',' ','<','b','u','f','f','e','r','/','p','a','c','k','a','g','e','>',0

aml_msg_end_eq:
	dw	' ','e','n','d','=','0','x',0

aml_msg_bufferstmt:
	dw	'B','U','F','F','E','R',':',' ',0

aml_msg_packagestmt:
	dw	'P','A','C','K','A','G','E',':',' ',0

aml_msg_varpackagestmt:
	dw	'V','A','R','P','A','C','K','A','G','E',':',' ',0

aml_msg_unsupported_opcode:
	dw	'U','N','S','U','P','P','O','R','T','E','D',' ','O','P','C','O','D','E',':',' ','0','x',0

aml_msg_unsupported_data:
	dw	'U','N','S','U','P','P','O','R','T','E','D',' ','D','A','T','A',' ','O','B','J','E','C','T',',',' ','S','T','O','P','P','I','N','G',13,10,0

section .bss

lengthBuf:
	resw	12

sizeBuf:
	resw	12

addrBuf:
	resw	20

aml_name_buf:
	resw	64

hex_scratch:
	resw	20

aml_error:
	resb	1

aml_field_bit_offset:
	resd	1

log_buffer:
	resw	65536

log_write_ptr:
	resq	1

log_line_ptr:
	resq	4096

log_line_total:
	resd	1

scroll_offset:
	resd	1

redraw_row:
	resd	1

redraw_line:
	resd	1

key_buf:
	resb	8

line_scratch:
	resw	256
