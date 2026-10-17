global efiMain
default rel

%include "config.inc"
%include "macros.inc"

section .text

efiMain:
    sub	rsp, 40
    mov	[saved_rsp], rsp
    mov	r12, rdx
    mov	r13, [r12 + 64]

    mov	rax, [r12 + 96]
    xor	ecx, ecx
    xor	edx, edx
    xor	r8d, r8d
    xor	r9d, r9d
    call	[rax + 256]

    mov	dword [visible_rows_actual], VISIBLE_ROWS

    mov	rax, [r13 + 72]
    mov	eax, [rax + 4]
    cdqe
    mov	rdx, rax
    mov	rcx, r13
    lea	r8, [console_query_cols]
    lea	r9, [console_query_rows]
    mov	rax, [r13 + 24]
    call	rax

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

    test	r15, r15
    jz	xsdt_invalid

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

    test	rax, rax
    jz	xsdt_next

    cmp	dword [rax + 0], 0x50434146
    je	facp_found

xsdt_next:
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
    mov	rsp, [saved_rsp]

    cmp	byte [aml_dump_done], 0
    jne	enter_ui_view
    cmp	dword [aml_node_count], 0
    je	enter_ui_view
    call	aml_print_stop_line
    call	aml_namespace_dump
    call	aml_print_stop_line
enter_ui_view:
    mov	eax, [log_line_total]
    cmp	eax, [visible_rows_actual]
    jbe	enter_ui_top
    sub	eax, [visible_rows_actual]
    mov	[scroll_offset], eax
    jmp	enter_ui_draw
enter_ui_top:
    mov	dword [scroll_offset], 0
enter_ui_draw:
    mov	byte [ui_mode], 1
    call	redraw_screen

input_loop:
    mov	qword [key_buf], 0

    mov	rcx, [r12 + 48]
    lea	rdx, [key_buf]
    mov	rax, [rcx + 8]
    call	rax

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

    cmp	cx, 0x09
    je	scroll_pgup
    cmp	cx, 0x0A
    je	scroll_pgdn
    cmp	cx, 0x05
    je	scroll_home
    cmp	cx, 0x06
    je	scroll_end

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

scroll_pgup:
    mov	eax, [scroll_offset]
    sub	eax, [visible_rows_actual]
    jae	scroll_pgup_set
    xor	eax, eax
scroll_pgup_set:
    mov	[scroll_offset], eax
    call	redraw_screen
    jmp	input_loop

scroll_pgdn:
    mov	eax, [scroll_offset]
    add	eax, [visible_rows_actual]
    mov	edx, [log_line_total]
    sub	edx, [visible_rows_actual]
    jae	scroll_pgdn_max
    xor	edx, edx
scroll_pgdn_max:
    cmp	eax, edx
    jbe	scroll_pgdn_set
    mov	eax, edx
scroll_pgdn_set:
    mov	[scroll_offset], eax
    call	redraw_screen
    jmp	input_loop

scroll_home:
    mov	dword [scroll_offset], 0
    call	redraw_screen
    jmp	input_loop

scroll_end:
    mov	eax, [log_line_total]
    sub	eax, [visible_rows_actual]
    jae	scroll_end_set
    xor	eax, eax
scroll_end_set:
    mov	[scroll_offset], eax
    call	redraw_screen
    jmp	input_loop

redraw_screen:
    push	rbp
    mov	rbp, rsp
    sub	rsp, 32
    and	rsp, -16

    mov	rcx, r13
    mov	rax, [r13 + 48]
    call	rax

    mov	rcx, r13
    mov	rdx, 9
    mov	rax, [r13 + 40]
    call	rax

    call	draw_banner
    call	draw_debug_line

    mov	rcx, r13
    mov	rdx, 7
    mov	rax, [r13 + 40]
    call	rax

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
    mov	rsp, rbp
    pop	rbp
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

    add	rsp, 40
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


%include "logging.asm"
%include "aml_parse.asm"
%include "namespace.asm"
%include "aml_errors.asm"
%include "data.asm"
%include "bss.asm"
