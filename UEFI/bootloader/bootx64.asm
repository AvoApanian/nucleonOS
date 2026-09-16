global efiMain
default rel

LOG_START_ROW equ 11
VISIBLE_ROWS  equ 14
LOG_LINE_MAX  equ 4096
LOG_BUF_WORDS equ 65536
NAME_BUF_WORDS equ 128
LINE_SCRATCH_WORDS equ 256

AML_IF_OP     equ 0xA0
AML_ELSE_OP   equ 0xA1
AML_WHILE_OP  equ 0xA2
AML_NOOP_OP   equ 0xA3
AML_RETURN_OP equ 0xA4
AML_BREAK_OP  equ 0xA5

section .text

efiMain:
	sub	rsp, 40
	mov	r12, rdx
	mov	r13, [r12 + 64]

	mov	dword [visible_rows_actual], VISIBLE_ROWS

	mov	rax, [r13 + 72]
	mov	eax, [rax + 4]
	cdqe
	mov	rdx, rax
	mov	rcx, r13
	lea	r8, [console_query_cols]
	lea	r9, [console_query_rows]
	mov	rax, [r13 + 24]
	sub	rsp, 40
	call	rax
	add	rsp, 40

	test	rax, rax
	jnz	console_rows_done

	mov	eax, [console_query_rows]
	cmp	eax, LOG_START_ROW + 1
	jbe	console_rows_done

	sub	eax, LOG_START_ROW
	cmp	eax, VISIBLE_ROWS
	jbe	console_rows_use

	mov	eax, VISIBLE_ROWS

console_rows_use:
	mov	[visible_rows_actual], eax

console_rows_done:
	lea	rax, [log_buffer]
	mov	[log_write_ptr], rax
	mov	[log_line_ptr], rax
	mov	dword [log_line_total], 1
	mov	dword [scroll_offset], 0
	mov	byte [log_full], 0
	mov	byte [redraw_pending], 0
	mov	byte [ui_mode], 0

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

	xor	eax, eax
	xor	ecx, ecx
rsdp_csum_loop:
	cmp	ecx, 20
	jae	rsdp_csum_done
	movzx	edx, byte [r14 + rcx]
	add	al, dl
	inc	ecx
	jmp	rsdp_csum_loop
rsdp_csum_done:
	test	al, al
	jnz	rsdp_invalid

	lea	rdx, [rsdpValid]
	call	print_str

	movzx	eax, byte [r14 + 15]
	cmp	eax, 2
	jb	rsdp_no_xsdt

	mov	eax, [r14 + 20]
	cmp	eax, 36
	jb	rsdp_no_xsdt

	cmp	eax, 0x00100000
	ja	rsdp_invalid

	mov	r10, r14
	mov	r11d, eax
	xor	eax, eax
	xor	ecx, ecx
rsdp_ext_csum_loop:
	cmp	ecx, r11d
	jae	rsdp_ext_csum_done
	movzx	edx, byte [r10 + rcx]
	add	al, dl
	inc	ecx
	jmp	rsdp_ext_csum_loop
rsdp_ext_csum_done:
	test	al, al
	jnz	rsdp_invalid

	mov	r15, [r14 + 24]

	cmp	dword [r15 + 0], 0x54445358
	jne	xsdt_invalid

	lea	rdx, [xsdtValid]
	call	print_str

	mov	eax, [r15 + 4]

	cmp	eax, 36
	jb	xsdt_invalid

	cmp	eax, 0x00100000
	ja	xsdt_invalid

	mov	r10, r15
	mov	r11d, eax
	xor	eax, eax
	xor	ecx, ecx
xsdt_csum_loop:
	cmp	ecx, r11d
	jae	xsdt_csum_done
	movzx	edx, byte [r10 + rcx]
	add	al, dl
	inc	ecx
	jmp	xsdt_csum_loop
xsdt_csum_done:
	test	al, al
	jnz	xsdt_invalid

	mov	eax, r11d
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

rsdp_no_xsdt:
	lea	rdx, [rsdpNoXsdt]
	call	print_str
	jmp	enter_ui

facp_found:
	mov	r15, rax

	lea	rdx, [facpFound]
	call	print_str

	mov	r10d, [r15 + 4]
	cmp	r10d, 44
	jb	dsdt_not_found

	mov	rbx, 0

	cmp	r10d, 148
	jb	facp_use_32bit_dsdt

	mov	rbx, [r15 + 140]

facp_use_32bit_dsdt:
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

	cmp	r15d, 0x00800000
	ja	dsdt_length_invalid

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

	cmp	r15d, 0
	je	enter_ui

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
	mov	byte [ui_mode], 1
	call	redraw_screen

input_loop:
	mov	qword [key_buf], 0

	mov	rcx, [r12 + 48]
	lea	rdx, [key_buf]
	mov	rax, [rcx + 8]
	sub	rsp, 40
	call	rax
	add	rsp, 40

	mov	[dbg_status], rax

	cmp	rax, 0
	jne	input_loop

	movzx	ecx, word [key_buf]
	mov	[dbg_scancode], cx

	movzx	eax, word [key_buf + 2]
	mov	[dbg_unicode], ax

	cmp	eax, 0x77
	je	scroll_up

	cmp	eax, 0x57
	je	scroll_up

	cmp	eax, 0x73
	je	scroll_down

	cmp	eax, 0x53
	je	scroll_down

	call	redraw_screen
	jmp	input_loop

scroll_up:
	cmp	dword [scroll_offset], 0
	je	scroll_up_redraw

	dec	dword [scroll_offset]

scroll_up_redraw:
	call	redraw_screen
	jmp	input_loop

scroll_down:
	mov	eax, [log_line_total]
	cmp	eax, [visible_rows_actual]
	jbe	scroll_down_redraw

	sub	eax, [visible_rows_actual]

	cmp	[scroll_offset], eax
	jge	scroll_down_redraw

	inc	dword [scroll_offset]

scroll_down_redraw:
	call	redraw_screen
	jmp	input_loop

redraw_screen:
	sub	rsp, 40

	mov	rcx, r13
	mov	rax, [r13 + 48]
	call	rax

	mov	rcx, r13
	mov	rdx, 9
	mov	rax, [r13 + 40]
	call	rax

	add	rsp, 40
	call	draw_banner
	call	draw_debug_line
	sub	rsp, 40

	mov	rcx, r13
	mov	rdx, 7
	mov	rax, [r13 + 40]
	call	rax

	add	rsp, 40

	mov	eax, [scroll_offset]
	mov	[redraw_line], eax
	mov	dword [redraw_row], 0

redraw_loop:
	mov	eax, [redraw_row]
	cmp	eax, [visible_rows_actual]
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
	sub	rsp, 40

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

	add	rsp, 40
	ret

dbg_out:
	sub	rsp, 40
	mov	rcx, r13
	mov	rax, [r13 + 8]
	call	rax
	add	rsp, 40
	ret

draw_debug_line:
	sub	rsp, 40
	mov	rcx, r13
	xor	edx, edx
	mov	r8d, LOG_START_ROW - 1
	mov	rax, [r13 + 56]
	call	rax
	add	rsp, 40

	lea	rdx, [dbg_label_scan]
	call	dbg_out

	movzx	edx, word [dbg_scancode]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 4
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	lea	rdx, [dbg_label_uni]
	call	dbg_out

	movzx	edx, word [dbg_unicode]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 4
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	lea	rdx, [dbg_label_status]
	call	dbg_out

	mov	rdx, [dbg_status]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 16
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	lea	rdx, [dbg_label_off]
	call	dbg_out

	mov	edx, [scroll_offset]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 8
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	lea	rdx, [dbg_label_tot]
	call	dbg_out

	mov	edx, [log_line_total]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 8
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	lea	rdx, [dbg_label_vis]
	call	dbg_out

	mov	edx, [visible_rows_actual]
	lea	rdi, [debug_hex_scratch]
	mov	ecx, 8
	call	hex_to_utf16
	lea	rdx, [debug_hex_scratch]
	call	dbg_out

	ret

draw_log_line:
	mov	eax, [redraw_line]
	cmp	eax, [log_line_total]
	jae	draw_log_skip

	lea	rdx, [log_line_ptr]
	mov	rsi, [rdx + rax * 8]

	lea	rax, [log_buffer]
	cmp	rsi, rax
	jb	draw_log_skip

	lea	rax, [log_buffer]
	add	rax, LOG_BUF_WORDS * 2
	cmp	rsi, rax
	ja	draw_log_skip

	lea	rdi, [line_scratch]
	lea	r8, [line_scratch]
	add	r8, (LINE_SCRATCH_WORDS - 1) * 2

draw_log_copy:
	cmp	rdi, r8
	jae	draw_log_copy_done

	lea	r9, [log_buffer]
	add	r9, LOG_BUF_WORDS * 2
	cmp	rsi, r9
	jae	draw_log_copy_done

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

	sub	rsp, 40

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

	add	rsp, 40

draw_log_skip:
	ret

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

aml_dump:
	mov	r14, rbx
	mov	rax, r15
	add	rax, rbx
	mov	r15, rax

	lea	rdx, [amlParseStart]
	call	print_str

	call	aml_check_redraw

	call	aml_term_list_parse

	lea	rdx, [amlParseDone]
	call	print_str

	call	aml_check_redraw

	ret

aml_check_redraw:
	cmp	byte [redraw_pending], 0
	je	aml_check_redraw_done

	mov	byte [redraw_pending], 0

	cmp	byte [ui_mode], 0
	jne	aml_check_redraw_go

	mov	eax, [log_line_total]
	cmp	eax, [visible_rows_actual]
	jbe	aml_check_redraw_noclamp

	sub	eax, [visible_rows_actual]
	mov	[scroll_offset], eax
	jmp	aml_check_redraw_go

aml_check_redraw_noclamp:
	mov	dword [scroll_offset], 0

aml_check_redraw_go:
	call	redraw_screen

aml_check_redraw_done:
	ret

aml_require:
	mov	rax, r14
	add	rax, rcx
	jc	aml_error_truncated
	cmp	rax, r15
	ja	aml_error_truncated
	ret

aml_read_u8:
	push	rcx
	mov	rcx, 1
	call	aml_require
	pop	rcx
	movzx	eax, byte [r14]
	inc	r14
	ret

aml_read_u16:
	push	rcx
	mov	rcx, 2
	call	aml_require
	pop	rcx
	movzx	eax, word [r14]
	add	r14, 2
	ret

aml_read_u32:
	push	rcx
	mov	rcx, 4
	call	aml_require
	pop	rcx
	mov	eax, [r14]
	add	r14, 4
	ret

aml_read_u64:
	push	rcx
	mov	rcx, 8
	call	aml_require
	pop	rcx
	mov	rax, [r14]
	add	r14, 8
	ret

aml_read_pkg_length:
	call	aml_read_u8
	mov	r10d, eax
	mov	r11d, r10d
	shr	r11d, 6
	and	r10d, 0x3F

	test	r11d, r11d
	jnz	aml_pkg_multi

	mov	eax, r10d
	ret

aml_pkg_multi:
	cmp	r11d, 3
	ja	aml_error_bad_package

	and	r10d, 0x0F
	mov	r9d, r10d
	mov	r8d, 4

aml_pkg_byteloop:
	call	aml_read_u8
	mov	ecx, r8d
	shl	eax, cl
	or	r9d, eax
	add	r8d, 8
	dec	r11d
	jnz	aml_pkg_byteloop

	mov	eax, r9d
	ret

aml_enter_package:
	push	r14
	call	aml_read_pkg_length
	pop	rcx
	add	rax, rcx

	cmp	rax, r14
	jb	aml_error_bad_package

	cmp	rax, r15
	ja	aml_error_bad_package

	pop	r10
	push	r15
	mov	r15, rax
	jmp	r10

aml_leave_package:
	cmp	r14, r15
	ja	aml_error_desync

	pop	r10
	pop	r15
	jmp	r10

aml_skip_pkg_object:
	call	aml_enter_package

	push	r15
	lea	rdx, [aml_msg_end_eq]
	call	print_str
	pop	r15

	mov	rdx, r15
	mov	ecx, 16
	call	print_hex

	mov	r14, r15

	call	aml_leave_package
	ret

aml_term_list_parse:
aml_tlp_loop:
	cmp	r14, r15
	jae	aml_tlp_done

	push	r14
	call	aml_parse_one_object
	pop	rax

	cmp	r14, rax
	jbe	aml_error_no_progress

	call	aml_check_redraw

	jmp	aml_tlp_loop

aml_tlp_done:
	call	aml_check_redraw
	ret

aml_parse_one_object:
	lea	rdx, [aml_msg_opcode]
	call	print_str

	mov	rdx, r14
	mov	ecx, 16
	call	print_hex

	lea	rdx, [aml_msg_bytes]
	call	print_str

	xor	r10d, r10d
aml_dbg_bytes:
	cmp	r10d, 4
	jae	aml_dbg_bytes_done

	mov	rax, r14
	add	rax, r10
	cmp	rax, r15
	jae	aml_dbg_oob

	movzx	edx, byte [r14 + r10]
	mov	ecx, 2
	call	print_hex
	jmp	aml_dbg_next

aml_dbg_oob:
	lea	rdx, [aml_msg_oob]
	call	print_str

aml_dbg_next:
	inc	r10d
	jmp	aml_dbg_bytes

aml_dbg_bytes_done:
	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8

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

	cmp	al, AML_IF_OP
	je	aml_do_if

	cmp	al, AML_ELSE_OP
	je	aml_do_else

	cmp	al, AML_WHILE_OP
	je	aml_do_while

	cmp	al, AML_NOOP_OP
	je	aml_do_noop

	cmp	al, AML_RETURN_OP
	je	aml_do_return

	cmp	al, AML_BREAK_OP
	je	aml_do_break

	dec	r14
	jmp	aml_unsupported_opcode

aml_handle_ext_op:
	call	aml_read_u8

	cmp	al, 0x82
	je	aml_do_device

	cmp	al, 0x80
	je	aml_do_opregion

	cmp	al, 0x81
	je	aml_do_field

	sub	r14, 2
	jmp	aml_unsupported_ext_opcode

aml_do_scope:
	call	aml_enter_package

	lea	rdx, [aml_msg_scope]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_do_device:
	call	aml_enter_package

	lea	rdx, [aml_msg_device]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_do_name:
	lea	rdx, [aml_msg_name]
	call	print_str

	call	aml_name_string_read
	call	aml_parse_data_ref_object

	lea	rdx, [newline]
	call	print_str

	ret

aml_parse_data_ref_object:
	mov	byte [aml_error], 0

	cmp	r14, r15
	jae	aml_dro_truncated

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

aml_dro_truncated:
	jmp	aml_error_truncated

aml_dro_skip_pkg:
	inc	r14

	lea	rdx, [aml_msg_eq_data]
	call	print_str

	call	aml_skip_pkg_object
	ret

aml_dro_string:
	inc	r14

	lea	rdi, [aml_name_buf]
	lea	r11, [aml_name_buf]
	add	r11, (NAME_BUF_WORDS - 1) * 2

aml_dro_str_loop:
	cmp	r14, r15
	jae	aml_dro_str_done

	movzx	eax, byte [r14]

	cmp	al, 0x00
	je	aml_dro_str_terminated

	cmp	rdi, r11
	jae	aml_dro_str_skipchar

	mov	word [rdi], ax
	add	rdi, 2

aml_dro_str_skipchar:
	inc	r14
	jmp	aml_dro_str_loop

aml_dro_str_terminated:
	inc	r14

aml_dro_str_done:
	mov	word [rdi], 0

	lea	rdx, [aml_msg_eq_str]
	call	print_str

	lea	rdx, [aml_name_buf]
	call	print_str

	ret

aml_do_bufferstmt:
	call	aml_enter_package

	lea	rdx, [aml_msg_bufferstmt]
	call	print_str

	mov	byte [aml_error], 0
	cmp	r14, r15
	jae	aml_buffer_no_size

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_buffer_no_size

	push	rax
	lea	rdx, [aml_msg_buffersize]
	call	print_str
	pop	rdx
	mov	ecx, 16
	call	print_hex
	jmp	aml_buffer_body

aml_buffer_no_size:
	mov	byte [aml_error], 0
	lea	rdx, [aml_msg_eq_data]
	call	print_str

aml_buffer_body:
	mov	r14, r15

	lea	rdx, [newline]
	call	print_str

	call	aml_leave_package
	ret

aml_do_packagestmt:
	call	aml_enter_package

	lea	rdx, [aml_msg_packagestmt]
	call	print_str

	cmp	r14, r15
	jae	aml_package_no_count

	call	aml_read_u8
	push	rax
	lea	rdx, [aml_msg_numelements]
	call	print_str
	pop	rdx
	mov	ecx, 2
	call	print_hex
	jmp	aml_package_body

aml_package_no_count:
	lea	rdx, [aml_msg_eq_data]
	call	print_str

aml_package_body:
	mov	r14, r15

	lea	rdx, [newline]
	call	print_str

	call	aml_leave_package
	ret

aml_do_varpackagestmt:
	call	aml_enter_package

	lea	rdx, [aml_msg_varpackagestmt]
	call	print_str

	mov	byte [aml_error], 0
	cmp	r14, r15
	jae	aml_varpackage_no_count

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_varpackage_no_count

	push	rax
	lea	rdx, [aml_msg_numelements]
	call	print_str
	pop	rdx
	mov	ecx, 16
	call	print_hex
	jmp	aml_varpackage_body

aml_varpackage_no_count:
	mov	byte [aml_error], 0
	lea	rdx, [aml_msg_eq_data]
	call	print_str

aml_varpackage_body:
	mov	r14, r15

	lea	rdx, [newline]
	call	print_str

	call	aml_leave_package
	ret

aml_do_opregion:
	lea	rdx, [aml_msg_opregion]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8

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
	call	aml_enter_package

	lea	rdx, [aml_msg_field]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8

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

	call	aml_read_pkg_length

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
	mov	rcx, 3
	call	aml_require
	add	r14, 3

	lea	rdx, [aml_msg_access]
	call	print_str

	jmp	aml_field_loop

aml_field_extaccess:
	mov	rcx, 4
	call	aml_require
	add	r14, 4

	lea	rdx, [aml_msg_access]
	call	print_str

	jmp	aml_field_loop

aml_field_connect:
	inc	r14

	cmp	r14, r15
	jae	aml_field_connect_truncated

	movzx	eax, byte [r14]

	cmp	al, 0x11
	je	aml_field_connect_buffer

	lea	rdx, [aml_msg_connect_name]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	jmp	aml_field_loop

aml_field_connect_buffer:
	lea	rdx, [aml_msg_connect_buffer]
	call	print_str

	inc	r14
	call	aml_skip_pkg_object

	lea	rdx, [newline]
	call	print_str

	jmp	aml_field_loop

aml_field_connect_truncated:
	lea	rdx, [aml_msg_connect_unsupported]
	call	print_str

	mov	r14, r15
	jmp	aml_field_done

aml_field_named:
	mov	rcx, 4
	call	aml_require

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

	call	aml_read_pkg_length
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
	call	aml_leave_package
	ret

aml_do_if:
	call	aml_enter_package

	lea	rdx, [aml_msg_if]
	call	print_str

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_do_else:
	call	aml_enter_package

	lea	rdx, [aml_msg_else]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_do_while:
	call	aml_enter_package

	lea	rdx, [aml_msg_while]
	call	print_str

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_do_noop:
	lea	rdx, [aml_msg_noop]
	call	print_str
	ret

aml_do_return:
	lea	rdx, [aml_msg_return]
	call	print_str

	cmp	r14, r15
	jae	aml_return_none

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	lea	rdx, [newline]
	call	print_str
	ret

aml_return_none:
	lea	rdx, [newline]
	call	print_str
	ret

aml_do_break:
	lea	rdx, [aml_msg_break]
	call	print_str
	ret

aml_do_method:
	call	aml_enter_package

	lea	rdx, [aml_msg_method]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8
	and	eax, 0x07

	push	rax
	lea	rdx, [aml_msg_argcount]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	push	r15
	lea	rdx, [aml_msg_bodyend]
	call	print_str
	pop	r15

	mov	rdx, r15
	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_term_list_parse

	call	aml_leave_package
	ret

aml_name_string_read:
	push	rdi
	push	r11

	lea	rdi, [aml_name_buf]
	lea	r11, [aml_name_buf]
	add	r11, (NAME_BUF_WORDS - 1) * 2

	cmp	r14, r15
	jae	aml_ns_truncated

	cmp	byte [r14], 0x5C
	jne	aml_ns_check_parent

	call	aml_ns_emit_lit_bs
	inc	r14

	jmp	aml_ns_segpath

aml_ns_check_parent:
	cmp	byte [r14], 0x5E
	jne	aml_ns_segpath

aml_ns_parent_loop:
	call	aml_ns_emit_lit_caret
	inc	r14

	cmp	r14, r15
	jae	aml_ns_finish

	cmp	byte [r14], 0x5E
	je	aml_ns_parent_loop

aml_ns_segpath:
	cmp	r14, r15
	jae	aml_ns_finish

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
	call	aml_ns_emit_lit_dot
	call	aml_name_seg_emit

	jmp	aml_ns_finish

aml_ns_multi:
	inc	r14

	call	aml_read_u8
	mov	r8d, eax

	test	r8d, r8d
	jz	aml_ns_finish

aml_ns_multi_loop:
	call	aml_name_seg_emit

	dec	r8d
	jz	aml_ns_finish

	call	aml_ns_emit_lit_dot

	jmp	aml_ns_multi_loop

aml_ns_null:
	inc	r14
	jmp	aml_ns_finish

aml_ns_truncated:
	jmp	aml_error_truncated

aml_ns_finish:
	mov	word [rdi], 0

	lea	rdx, [aml_name_buf]
	call	print_str

	pop	r11
	pop	rdi
	ret

aml_ns_emit_lit_bs:
	cmp	rdi, r11
	jae	aml_ns_lit_skip
	mov	word [rdi], '\'
	add	rdi, 2
aml_ns_lit_skip:
	ret

aml_ns_emit_lit_caret:
	cmp	rdi, r11
	jae	aml_ns_lit_skip2
	mov	word [rdi], '^'
	add	rdi, 2
aml_ns_lit_skip2:
	ret

aml_ns_emit_lit_dot:
	cmp	rdi, r11
	jae	aml_ns_lit_skip3
	mov	word [rdi], '.'
	add	rdi, 2
aml_ns_lit_skip3:
	ret

aml_name_seg_emit:
	mov	rcx, 4
	call	aml_require

	mov	ecx, 4

aml_nse_loop:
	movzx	eax, byte [r14]

	cmp	rdi, r11
	jae	aml_nse_skip

	mov	word [rdi], ax
	add	rdi, 2

aml_nse_skip:
	inc	r14
	dec	ecx
	jnz	aml_nse_loop

	ret

aml_read_termarg_integer:
	mov	byte [aml_error], 0

	cmp	r14, r15
	jae	aml_ti_truncated

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

aml_ti_truncated:
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
	call	aml_read_u8
	ret

aml_ti_word:
	inc	r14
	call	aml_read_u16
	ret

aml_ti_dword:
	inc	r14
	call	aml_read_u32
	ret

aml_ti_qword:
	inc	r14
	call	aml_read_u64
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

rsdpNoXsdt:
	dw	'R','S','D','P',' ','I','S',' ','A','C','P','I',' ','1','.','0',' ','(','N','O',' ','X','S','D','T',')',13,10,0

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
	dw	'D','S','D','T',' ','L','E','N','G','T','H',' ','I','N','V','A','L','I','D',13,10,0

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

dbg_label_scan:
	dw	'S','C','=',0

dbg_label_uni:
	dw	' ','U','C','=',0

dbg_label_status:
	dw	' ','S','T','=',0

dbg_label_off:
	dw	' ','O','F','=',0

dbg_label_tot:
	dw	' ','T','L','=',0

dbg_label_vis:
	dw	' ','V','R','=',0

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

aml_msg_if:
	dw	'I','F',':',' ',0

aml_msg_else:
	dw	'E','L','S','E',':',' ',0

aml_msg_while:
	dw	'W','H','I','L','E',':',' ',0

aml_msg_noop:
	dw	'N','O','O','P',13,10,0

aml_msg_return:
	dw	'R','E','T','U','R','N',':',' ',0

aml_msg_break:
	dw	'B','R','E','A','K',13,10,0

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
	dw	' ',' ','(','c','o','n','n','e','c','t',' ','f','i','e','l','d',',',' ','t','r','u','n','c','a','t','e','d',')',13,10,0

aml_msg_connect_name:
	dw	' ',' ','(','c','o','n','n','e','c','t',' ','-','>',' ',')',0

aml_msg_connect_buffer:
	dw	' ',' ','(','c','o','n','n','e','c','t',' ','b','u','f','f','e','r',')',' ',0

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

aml_msg_buffersize:
	dw	' ',' ','s','i','z','e','=','0','x',0

aml_msg_packagestmt:
	dw	'P','A','C','K','A','G','E',':',' ',0

aml_msg_varpackagestmt:
	dw	'V','A','R','P','A','C','K','A','G','E',':',' ',0

aml_msg_numelements:
	dw	' ',' ','n','u','m','E','l','e','m','e','n','t','s','=','0','x',0

aml_msg_unsupported_opcode:
	dw	'U','N','S','U','P','P','O','R','T','E','D',' ','O','P','C','O','D','E',':',' ','0','x',0

aml_msg_unsupported_data:
	dw	'U','N','S','U','P','P','O','R','T','E','D',' ','D','A','T','A',' ','O','B','J','E','C','T',',',' ','S','T','O','P','P','I','N','G',13,10,0

aml_msg_opcode:
	dw	'O','P','C','O','D','E',' ','A','T',':',' ',0

aml_msg_bytes:
	dw	' ','B','Y','T','E','S',':',' ',0

aml_msg_oob:
	dw	'-','-',0

aml_msg_bad_package:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','P','k','g','L','e','n','g','t','h',' ','e','x','c','e','e','d','s',' ','b','o','u','n','d','a','r','y',13,10,0

aml_msg_desync:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','D','E','S','Y','N','C',13,10,0

aml_msg_no_progress:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','P','A','R','S','E','R',' ','D','I','D',' ','N','O','T',' ','A','D','V','A','N','C','E',13,10,0

aml_msg_truncated:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','T','R','U','N','C','A','T','E','D',' ','/',' ','O','U','T',' ','O','F',' ','B','O','U','N','D','S',13,10,0

section .bss

lengthBuf:
	resw	12

sizeBuf:
	resw	12

addrBuf:
	resw	20

aml_name_buf:
	resw	NAME_BUF_WORDS

hex_scratch:
	resw	20

aml_error:
	resb	1

aml_field_bit_offset:
	resd	1

log_buffer:
	resw	LOG_BUF_WORDS

log_write_ptr:
	resq	1

log_line_ptr:
	resq	LOG_LINE_MAX

log_line_total:
	resd	1

log_full:
	resb	1

redraw_pending:
	resb	1

ui_mode:
	resb	1

visible_rows_actual:
	resd	1

console_query_cols:
	resq	1

console_query_rows:
	resq	1

scroll_offset:
	resd	1

redraw_row:
	resd	1

redraw_line:
	resd	1

key_buf:
	resb	8

dbg_scancode:
	resw	1

dbg_unicode:
	resw	1

dbg_status:
	resq	1

debug_hex_scratch:
	resw	20

line_scratch:
	resw	LINE_SCRATCH_WORDS