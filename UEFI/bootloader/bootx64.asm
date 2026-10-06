global efiMain
default rel

LOG_START_ROW equ 11
VISIBLE_ROWS  equ 14
LOG_LINE_MAX  equ 65536
LOG_BUF_WORDS equ 2097152
NAME_BUF_WORDS equ 128
LINE_SCRATCH_WORDS equ 256
AML_PKG_MAX equ 64

AML_IF_OP     equ 0xA0
AML_ELSE_OP   equ 0xA1
AML_WHILE_OP  equ 0xA2
AML_NOOP_OP   equ 0xA3
AML_RETURN_OP equ 0xA4
AML_BREAK_OP  equ 0xA5

%define AML_PARSE_METHOD_BODY 0

%define AML_TRACE_OPCODES   1   ; 0 = coupe les lignes "OPCODE AT:" (log beaucoup plus court)
%define AML_LOG_FIELD_NODES 0   ; 1 = une ligne NODE: par field unit (beaucoup de lignes)

; ---------------------------------------------------------------------
;  NAMESPACE : constantes
; ---------------------------------------------------------------------
AML_NODE_MAX      equ 8192
AML_SCOPE_MAX     equ 64
AML_NODE_SIZE     equ 48
AML_NODE_NONE     equ 0xFFFFFFFF
AML_PATH_MAX_SEGS equ 64

; offsets dans AML_NODE (48 octets)
AN_NAME   equ 0x00      ; 4 octets : NameSeg brut
AN_TYPE   equ 0x04      ; 1 octet  : AML_NODE_*
AN_VKIND  equ 0x05      ; 1 octet  : AML_VK_*
AN_AUX8   equ 0x06      ; 1 octet  : argcount / space / flags
AN_PARENT equ 0x08      ; 4 octets : index parent
AN_FIRST  equ 0x0C      ; 4 octets : premier enfant
AN_NEXT   equ 0x10      ; 4 octets : frere suivant
AN_LAST   equ 0x14      ; 4 octets : dernier enfant
AN_VALUE  equ 0x18      ; 8 octets : valeur
AN_AUX_A  equ 0x20      ; 8 octets : body_start / offset / bitoffset
AN_AUX_B  equ 0x28      ; 8 octets : body_end / length / width

AML_NODE_ROOT          equ 0
AML_NODE_SCOPE         equ 1
AML_NODE_DEVICE        equ 2
AML_NODE_METHOD        equ 3
AML_NODE_NAME          equ 4
AML_NODE_OPREGION      equ 5
AML_NODE_FIELD         equ 6
AML_NODE_INDEXFIELD    equ 7
AML_NODE_BANKFIELD     equ 8
AML_NODE_PROCESSOR     equ 9
AML_NODE_POWERRESOURCE equ 10
AML_NODE_THERMALZONE   equ 11
AML_NODE_MUTEX         equ 12
AML_NODE_EVENT         equ 13
AML_NODE_BUFFER        equ 14
AML_NODE_PACKAGE       equ 15
AML_NODE_VARPACKAGE    equ 16
AML_NODE_ALIAS         equ 17
AML_NODE_EXTERNAL      equ 18
AML_NODE_TYPE_COUNT    equ 19

AML_VK_NONE       equ 0
AML_VK_INT        equ 1
AML_VK_STRING     equ 2
AML_VK_BUFFER     equ 3
AML_VK_PACKAGE    equ 4
AML_VK_VARPACKAGE equ 5

; Emet une chaine ASCII en UTF-16 (sans terminateur)
%macro U16 1
%strlen %%len %1
%assign %%k 1
%rep %%len
%substr %%ch %1 %%k
	dw	%%ch
%assign %%k %%k+1
%endrep
%endmacro

; Entree de 32 octets (16 words) pour les tables de noms
%macro TYPENAME 1
%%s:
	U16	%1
	dw	0
	times 32 - ($ - %%s) db 0
%endmacro

section .text

efiMain:
	sub	rsp, 40
	mov	[saved_rsp], rsp
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
	jc	aml_error_truncated
	mov	r15, rax

	mov	[aml_table_start], r14
	mov	[aml_table_end], r15
	mov	dword [aml_pkg_depth], 0
	mov	byte [aml_error], 0

	lea	rdx, [amlParseStart]
	call	print_str

	call	aml_namespace_init            ; NEW : cree ROOT, affiche "NODE: ROOT \"

	call	aml_check_redraw

	call	aml_term_list_parse

	cmp	dword [aml_scope_depth], 0    ; NEW : la pile de scopes doit etre equilibree
	jne	aml_error_desync
	cmp	dword [aml_current_node], 0   ; NEW : on doit etre revenu a ROOT
	jne	aml_error_desync

	lea	rdx, [amlParseDone]
	call	print_str

	call	aml_check_redraw

	call	aml_namespace_dump            ; NEW : affiche l'arbre

	call	aml_check_redraw              ; NEW

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

	cmp	rax, [aml_table_end]
	ja	aml_error_truncated

	cmp	r14, [aml_table_start]
	jb	aml_error_truncated

	cmp	r15, [aml_table_end]
	ja	aml_error_desync

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
	test	r10d, 0x30
	jnz	aml_error_bad_package

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
	jc	aml_error_bad_package

	cmp	rax, r14
	jb	aml_error_bad_package

	cmp	rax, r15
	ja	aml_error_bad_package

	cmp	rax, [aml_table_end]
	ja	aml_error_bad_package

	mov	edx, [aml_pkg_depth]
	cmp	edx, AML_PKG_MAX
	jae	aml_error_depth

	lea	r10, [aml_pkg_stack]
	mov	[r10 + rdx * 8], r15
	inc	edx
	mov	[aml_pkg_depth], edx

	mov	r15, rax
	ret

aml_leave_package:
	cmp	r14, r15
	jne	aml_error_desync

	mov	edx, [aml_pkg_depth]
	test	edx, edx
	jz	aml_error_desync

	dec	edx
	mov	[aml_pkg_depth], edx

	lea	r10, [aml_pkg_stack]
	mov	r15, [r10 + rdx * 8]

	cmp	r14, r15
	ja	aml_error_desync

	ret

aml_skip_pkg_object:
	call	aml_enter_package

	lea	rdx, [aml_msg_end_eq]
	call	print_str

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

	push	r15
	mov	eax, [aml_pkg_depth]
	push	rax
	push	r14
	call	aml_parse_one_object
	pop	rax
	pop	rcx
	pop	rdx

	cmp	r14, rax
	jbe	aml_error_no_progress

	cmp	r15, rdx
	jne	aml_error_desync

	cmp	ecx, [aml_pkg_depth]
	jne	aml_error_desync

	cmp	r14, r15
	ja	aml_error_desync

	call	aml_check_redraw

	jmp	aml_tlp_loop

aml_tlp_done:
	call	aml_check_redraw
	ret

aml_parse_one_object:
%if AML_TRACE_OPCODES
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
%endif

	call	aml_read_u8

	cmp	al, 0x10
	je	aml_do_scope

	cmp	al, 0x08
	je	aml_do_name

	cmp	al, 0x14
	je	aml_do_method

	cmp	al, 0x5B
	je	aml_handle_ext_op

	cmp	al, 0x06
	je	aml_do_alias

	cmp	al, 0x15
	je	aml_do_external

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

	cmp	al, 0x01
	je	aml_do_mutex

	cmp	al, 0x02
	je	aml_do_event

	cmp	al, 0x83
	je	aml_do_processor

	cmp	al, 0x84
	je	aml_do_powerresource

	cmp	al, 0x85
	je	aml_do_thermalzone

	cmp	al, 0x86
	je	aml_do_indexfield

	cmp	al, 0x87
	je	aml_do_bankfield

	sub	r14, 2
	jmp	aml_unsupported_ext_opcode

aml_do_scope:
	call	aml_enter_package

	lea	rdx, [aml_msg_scope]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	; ---- NEW ----
	mov	ecx, [aml_path_count]
	call	aml_ns_walk                   ; Scope = find-or-create de tous les segments
	mov	ecx, eax
	lea	rdx, [aml_lbl_scope]
	call	aml_ns_debug_node_label       ; preserve rcx
	call	aml_scope_enter_node          ; push current; current = node
	; ---- fin NEW ----

	call	aml_term_list_parse

	call	aml_scope_pop                 ; NEW
	call	aml_leave_package
	ret

aml_do_device:
	call	aml_enter_package

	lea	rdx, [aml_msg_device]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_DEVICE          ; NEW
	call	aml_ns_define_log             ; NEW : ecx = nouvel index
	call	aml_scope_enter_node          ; NEW

	call	aml_term_list_parse

	call	aml_scope_pop                 ; NEW
	call	aml_leave_package
	ret

aml_do_processor:
	call	aml_enter_package

	lea	rdx, [aml_msg_processor]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_PROCESSOR       ; NEW
	call	aml_ns_define_log             ; NEW
	call	aml_scope_enter_node          ; NEW

	call	aml_read_u8
	call	aml_read_u32
	call	aml_read_u8

	call	aml_term_list_parse

	call	aml_scope_pop                 ; NEW
	call	aml_leave_package
	ret

aml_do_powerresource:
	call	aml_enter_package

	lea	rdx, [aml_msg_powerres]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_POWERRESOURCE   ; NEW
	call	aml_ns_define_log             ; NEW
	call	aml_scope_enter_node          ; NEW

	call	aml_read_u8
	call	aml_read_u16

	call	aml_term_list_parse

	call	aml_scope_pop                 ; NEW
	call	aml_leave_package
	ret

aml_do_thermalzone:
	call	aml_enter_package

	lea	rdx, [aml_msg_thermal]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_THERMALZONE     ; NEW
	call	aml_ns_define_log             ; NEW
	call	aml_scope_enter_node          ; NEW

	call	aml_term_list_parse

	call	aml_scope_pop                 ; NEW
	call	aml_leave_package
	ret

aml_do_alias:
	lea	rdx, [aml_msg_alias]
	call	print_str

	call	aml_name_string_read          ; source

	lea	rdx, [newline]
	call	print_str

	call	aml_name_string_read          ; nouveau nom => c'est lui qu'on definit

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_ALIAS           ; NEW
	call	aml_ns_define_log             ; NEW

	ret

aml_do_external:
	lea	rdx, [aml_msg_external]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_EXTERNAL        ; NEW
	call	aml_ns_define_log             ; NEW
	mov	[aml_tmp_idx], eax            ; NEW

	call	aml_read_u8
	call	aml_ns_tmp_set8               ; NEW : type d'objet
	call	aml_read_u8

	ret

aml_do_mutex:
	lea	rdx, [aml_msg_mutex]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_MUTEX           ; NEW
	call	aml_ns_define_log             ; NEW
	mov	[aml_tmp_idx], eax            ; NEW

	call	aml_read_u8
	call	aml_ns_tmp_set8               ; NEW : sync flags

	ret

aml_do_event:
	lea	rdx, [aml_msg_event]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_EVENT           ; NEW
	call	aml_ns_define_log             ; NEW

	ret

aml_do_name:
	lea	rdx, [aml_msg_name]
	call	print_str

	call	aml_name_string_read

	mov	ecx, AML_NODE_NAME            ; NEW : cree AVANT que la valeur ne reutilise le buffer
	call	aml_ns_define                 ; NEW
	mov	[aml_tmp_idx], eax            ; NEW

	call	aml_parse_data_ref_object

	; ---- NEW ----
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	movzx	edx, byte [aml_last_vkind]
	mov	[rax + AN_VKIND], dl
	mov	rdx, [aml_last_value]
	mov	[rax + AN_VALUE], rdx
	; ---- fin NEW ----

	lea	rdx, [newline]
	call	print_str

	mov	ecx, [aml_tmp_idx]            ; NEW
	call	aml_ns_debug_node             ; NEW

	ret

aml_parse_data_ref_object:
	mov	byte [aml_error], 0
	mov	byte [aml_last_vkind], AML_VK_NONE     ; NEW
	mov	qword [aml_last_value], 0              ; NEW

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

	mov	[aml_last_value], rax                  ; NEW
	mov	byte [aml_last_vkind], AML_VK_INT      ; NEW

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

	mov	dl, AML_VK_BUFFER                      ; NEW (al = opcode, inchange)
	cmp	al, 0x12
	jne	aml_dro_k1
	mov	dl, AML_VK_PACKAGE
aml_dro_k1:
	cmp	al, 0x13
	jne	aml_dro_k2
	mov	dl, AML_VK_VARPACKAGE
aml_dro_k2:
	mov	[aml_last_vkind], dl                   ; NEW

	lea	rdx, [aml_msg_eq_data]
	call	print_str

	call	aml_skip_pkg_object
	ret

aml_dro_string:
	inc	r14
	mov	byte [aml_last_vkind], AML_VK_STRING   ; NEW

	lea	rdi, [aml_name_buf]
	lea	r11, [aml_name_buf]
	add	r11, (NAME_BUF_WORDS - 1) * 2

aml_dro_str_loop:
	cmp	r14, r15
	jae	aml_error_truncated

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

	mov	ecx, AML_NODE_BUFFER          ; NEW
	call	aml_ns_define_anon_log        ; NEW

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

	mov	ecx, AML_NODE_PACKAGE         ; NEW
	call	aml_ns_define_anon_log        ; NEW

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

	mov	ecx, AML_NODE_VARPACKAGE      ; NEW
	call	aml_ns_define_anon_log        ; NEW

	call	aml_leave_package
	ret

aml_do_opregion:
	lea	rdx, [aml_msg_opregion]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	mov	ecx, AML_NODE_OPREGION        ; NEW
	call	aml_ns_define                 ; NEW
	mov	[aml_tmp_idx], eax            ; NEW

	call	aml_read_u8
	call	aml_ns_tmp_set8               ; NEW : space

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
	call	aml_ns_tmp_seta               ; NEW : offset

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
	call	aml_ns_tmp_setb               ; NEW : length

	push	rax
	lea	rdx, [aml_msg_length]
	call	print_str
	pop	rdx

	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	mov	ecx, [aml_tmp_idx]            ; NEW
	call	aml_ns_debug_node             ; NEW

	ret

aml_do_field:
	call	aml_enter_package

	lea	rdx, [aml_msg_field]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8
	mov	[aml_field_flags], al                        ; NEW
	mov	byte [aml_field_unit_type], AML_NODE_FIELD   ; NEW

	push	rax
	lea	rdx, [aml_msg_flags]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_field_list_parse

	call	aml_leave_package
	ret

aml_do_indexfield:
	call	aml_enter_package

	lea	rdx, [aml_msg_indexfield]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_u8
	mov	[aml_field_flags], al                             ; NEW
	mov	byte [aml_field_unit_type], AML_NODE_INDEXFIELD   ; NEW

	push	rax
	lea	rdx, [aml_msg_flags]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_field_list_parse

	call	aml_leave_package
	ret

aml_do_bankfield:
	call	aml_enter_package

	lea	rdx, [aml_msg_bankfield]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_name_string_read

	lea	rdx, [newline]
	call	print_str

	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_unsupported_dataobject

	call	aml_read_u8
	mov	[aml_field_flags], al                            ; NEW
	mov	byte [aml_field_unit_type], AML_NODE_BANKFIELD   ; NEW

	push	rax
	lea	rdx, [aml_msg_flags]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	call	aml_field_list_parse

	call	aml_leave_package
	ret

aml_field_list_parse:
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
	mov	[aml_field_width], eax

	lea	rdx, [aml_msg_reserved]
	call	print_str

	mov	edx, [aml_field_width]
	mov	ecx, 8
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	mov	eax, [aml_field_width]
	add	[aml_field_bit_offset], eax
	jc	aml_error_bad_package

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
	lea	rdi, [aml_name_buf]
	lea	r11, [aml_name_buf]
	add	r11, (NAME_BUF_WORDS - 1) * 2

	mov	dword [aml_path_count], 0     ; NEW : reset du chemin structure
	mov	dword [aml_path_up], 0        ; NEW
	mov	byte [aml_path_root], 0       ; NEW

	call	aml_name_seg_emit

	mov	word [rdi], 0

	lea	rdx, [aml_name_buf]
	call	print_str

	lea	rdx, [aml_msg_bitoffset]
	call	print_str

	mov	edx, [aml_field_bit_offset]
	mov	ecx, 8
	call	print_hex

	call	aml_read_pkg_length
	mov	[aml_field_width], eax

	lea	rdx, [aml_msg_width]
	call	print_str

	mov	edx, [aml_field_width]
	mov	ecx, 8
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	; ---- NEW : un node par field unit ----
	movzx	ecx, byte [aml_field_unit_type]
	call	aml_ns_define
	mov	[aml_tmp_idx], eax
	call	aml_ns_field_unit_fill
%if AML_LOG_FIELD_NODES
	mov	ecx, [aml_tmp_idx]
	call	aml_ns_debug_node
%endif
	; ---- fin NEW ----

	mov	eax, [aml_field_width]
	add	[aml_field_bit_offset], eax
	jc	aml_error_bad_package

	jmp	aml_field_loop

aml_field_done:
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

	mov	ecx, AML_NODE_METHOD          ; NEW
	call	aml_ns_define_log             ; NEW
	mov	[aml_tmp_idx], eax            ; NEW

	call	aml_read_u8

	; ---- NEW (remplace "and eax, 0x07") ----
	push	rax                           ; flags bruts
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	pop	rcx
	mov	[rax + AN_VALUE], rcx         ; flags complets
	mov	edx, ecx
	and	edx, 0x07
	mov	[rax + AN_AUX8], dl           ; argcount
	mov	[rax + AN_AUX_A], r14         ; body_start
	mov	[rax + AN_AUX_B], r15         ; body_end
	mov	eax, edx                      ; eax = argcount, comme avant
	; ---- fin NEW ----

	push	rax
	lea	rdx, [aml_msg_argcount]
	call	print_str
	pop	rdx

	mov	ecx, 2
	call	print_hex

	lea	rdx, [newline]
	call	print_str

	lea	rdx, [aml_msg_bodyend]
	call	print_str

	mov	rdx, r15
	mov	ecx, 16
	call	print_hex

	lea	rdx, [newline]
	call	print_str

%if AML_PARSE_METHOD_BODY
	mov	ecx, [aml_tmp_idx]            ; NEW : le body vit dans le scope du METHOD
	call	aml_scope_enter_node
	call	aml_term_list_parse
	call	aml_scope_pop
%else
	mov	r14, r15
%endif

	call	aml_leave_package
	ret

aml_name_string_read:
	push	rdi
	push	r11

	mov	dword [aml_path_count], 0     ; NEW
	mov	dword [aml_path_up], 0        ; NEW
	mov	byte [aml_path_root], 0       ; NEW

	lea	rdi, [aml_name_buf]
	lea	r11, [aml_name_buf]
	add	r11, (NAME_BUF_WORDS - 1) * 2

	cmp	r14, r15
	jae	aml_ns_truncated

	cmp	byte [r14], 0x5C
	jne	aml_ns_check_parent

	call	aml_ns_emit_lit_bs
	mov	byte [aml_path_root], 1       ; NEW
	inc	r14

	jmp	aml_ns_segpath

aml_ns_check_parent:
	cmp	byte [r14], 0x5E
	jne	aml_ns_segpath

aml_ns_parent_loop:
	call	aml_ns_emit_lit_caret
	inc	dword [aml_path_up]           ; NEW
	inc	r14

	cmp	r14, r15
	jae	aml_ns_truncated

	cmp	byte [r14], 0x5E
	je	aml_ns_parent_loop

aml_ns_segpath:
	cmp	r14, r15
	jae	aml_ns_truncated

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
	jz	aml_error_bad_name

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

	; ---- NEW: copie brute du segment dans aml_path_segs ----
	push	rsi
	mov	eax, [aml_path_count]
	cmp	eax, AML_PATH_MAX_SEGS
	jae	aml_error_bad_name
	mov	edx, [r14]
	lea	rsi, [aml_path_segs]
	mov	[rsi + rax*4], edx
	inc	eax
	mov	[aml_path_count], eax
	pop	rsi
	; ---- fin NEW ----

	mov	ecx, 4

aml_nse_loop:
	movzx	eax, byte [r14]

	cmp	al, '_'
	je	aml_nse_char_ok

	cmp	al, 'A'
	jb	aml_nse_check_digit

	cmp	al, 'Z'
	jbe	aml_nse_char_ok

aml_nse_check_digit:
	cmp	ecx, 4
	je	aml_error_bad_name

	cmp	al, '0'
	jb	aml_error_bad_name

	cmp	al, '9'
	ja	aml_error_bad_name

aml_nse_char_ok:
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

; =====================================================================
;  NAMESPACE : primitives
; =====================================================================

; ecx = type, rsi = ptr 4 octets (ou 0) -> eax = index, rdi = adresse
; clobber: rdx. Erreur: NAMESPACE FULL
aml_namespace_alloc_node:
	mov	eax, [aml_node_count]
	cmp	eax, AML_NODE_MAX
	jae	aml_error_ns_full
	lea	edx, [rax + 1]
	mov	[aml_node_count], edx
	mov	edi, eax
	lea	rdi, [rdi + rdi*2]
	shl	rdi, 4
	lea	rdx, [aml_nodes]
	add	rdi, rdx
	mov	qword [rdi + 0], 0
	mov	qword [rdi + 8], -1          ; parent=NONE, first=NONE
	mov	qword [rdi + 16], -1         ; next=NONE,   last=NONE
	mov	qword [rdi + 24], 0
	mov	qword [rdi + 32], 0
	mov	qword [rdi + 40], 0
	mov	[rdi + AN_TYPE], cl
	test	rsi, rsi
	jz	aml_nsan_noname
	mov	edx, [rsi]
	mov	[rdi + AN_NAME], edx
aml_nsan_noname:
	ret

; eax = index -> rax = adresse. Valide l'index. clobber: rdx
aml_ns_node_addr:
	cmp	eax, [aml_node_count]
	jae	aml_error_invalid_node
	mov	eax, eax
	lea	rax, [rax + rax*2]
	shl	rax, 4
	lea	rdx, [aml_nodes]
	add	rax, rdx
	ret

; ecx = parent, edx = child. clobber: rax, rsi, r10, r11
aml_namespace_attach_child:
	cmp	ecx, edx
	je	aml_error_invalid_node
	mov	r10d, ecx
	mov	r11d, edx
	mov	eax, r10d
	call	aml_ns_node_addr
	mov	rsi, rax                      ; rsi = parent
	mov	eax, r11d
	call	aml_ns_node_addr
	mov	[rax + AN_PARENT], r10d
	mov	dword [rax + AN_NEXT], AML_NODE_NONE
	mov	eax, [rsi + AN_LAST]
	cmp	eax, AML_NODE_NONE
	jne	aml_nsac_tail
	mov	[rsi + AN_FIRST], r11d
	mov	[rsi + AN_LAST], r11d
	ret
aml_nsac_tail:
	call	aml_ns_node_addr              ; eax = ancien dernier
	mov	[rax + AN_NEXT], r11d
	mov	[rsi + AN_LAST], r11d
	ret

; ecx = parent, rsi = ptr nom (4 octets) -> eax = index ou NONE
; clobber: rdx, r8, r9, r10
aml_ns_lookup_child:
	mov	r8d, [rsi]
	mov	r10d, [aml_node_count]
	mov	eax, ecx
	call	aml_ns_node_addr
	mov	eax, [rax + AN_FIRST]
aml_nslc_loop:
	cmp	eax, AML_NODE_NONE
	je	aml_nslc_done
	sub	r10d, 1
	jc	aml_error_invalid_node        ; boucle/corruption
	mov	r9d, eax
	call	aml_ns_node_addr
	cmp	[rax + AN_NAME], r8d
	je	aml_nslc_found
	mov	eax, [rax + AN_NEXT]
	jmp	aml_nslc_loop
aml_nslc_found:
	mov	eax, r9d
aml_nslc_done:
	ret

; ecx = parent, rsi = ptr nom, edx = type si creation -> eax = index
aml_ns_find_or_create:
	push	rcx
	push	rdx
	push	rsi
	call	aml_ns_lookup_child
	pop	rsi
	pop	rdx
	pop	rcx
	cmp	eax, AML_NODE_NONE
	jne	aml_nsfc_ret
	mov	r8d, ecx
	mov	ecx, edx
	call	aml_namespace_alloc_node
	mov	r9d, eax
	mov	ecx, r8d
	mov	edx, eax
	call	aml_namespace_attach_child
	mov	eax, r9d
aml_nsfc_ret:
	ret

; -> eax = node de depart selon aml_path_root / aml_path_up / aml_current_node
aml_ns_resolve_start:
	cmp	byte [aml_path_root], 0
	je	aml_nsrs_rel
	xor	eax, eax                      ; "\" => root
	ret
aml_nsrs_rel:
	mov	eax, [aml_current_node]
	mov	ecx, [aml_path_up]
aml_nsrs_up:
	test	ecx, ecx
	jz	aml_nsrs_done
	test	eax, eax
	jz	aml_error_invalid_node        ; ^ au-dessus de root
	push	rcx
	call	aml_ns_node_addr
	pop	rcx
	mov	eax, [rax + AN_PARENT]
	dec	ecx
	jmp	aml_nsrs_up
aml_nsrs_done:
	ret

; ecx = N : descend les N premiers segments du chemin courant
; (find-or-create de type SCOPE) -> eax = node
aml_ns_walk:
	mov	[aml_walk_n], ecx
	mov	dword [aml_walk_i], 0
	call	aml_ns_resolve_start
	mov	[aml_walk_node], eax
aml_nsw_loop:
	mov	eax, [aml_walk_i]
	cmp	eax, [aml_walk_n]
	jae	aml_nsw_done
	lea	rsi, [aml_path_segs]
	lea	rsi, [rsi + rax*4]
	mov	ecx, [aml_walk_node]
	mov	edx, AML_NODE_SCOPE
	call	aml_ns_find_or_create
	mov	[aml_walk_node], eax
	inc	dword [aml_walk_i]
	jmp	aml_nsw_loop
aml_nsw_done:
	mov	eax, [aml_walk_node]
	ret

; ecx = type : cree un node DEFINI par le chemin courant -> eax = index
aml_ns_define:
	push	rcx
	mov	ecx, [aml_path_count]
	test	ecx, ecx
	jz	aml_error_bad_name            ; NullName ne peut pas definir un objet
	dec	ecx
	call	aml_ns_walk
	mov	[aml_def_parent], eax
	mov	eax, [aml_path_count]
	dec	eax
	lea	rsi, [aml_path_segs]
	lea	rsi, [rsi + rax*4]
	pop	rcx
	call	aml_namespace_alloc_node
	mov	[aml_def_idx], eax
	mov	ecx, [aml_def_parent]
	mov	edx, eax
	call	aml_namespace_attach_child
	mov	eax, [aml_def_idx]
	ret

; ecx = type -> eax = ecx = index (+ ligne NODE:)
aml_ns_define_log:
	call	aml_ns_define
	mov	ecx, eax
	call	aml_ns_debug_node
	mov	eax, ecx
	ret

; ecx = type : node anonyme (Buffer/Package orphelins) sous le scope courant
aml_ns_define_anon_log:
	xor	esi, esi
	call	aml_namespace_alloc_node
	mov	[aml_def_idx], eax
	mov	ecx, [aml_current_node]
	mov	edx, eax
	call	aml_namespace_attach_child
	mov	ecx, [aml_def_idx]
	call	aml_ns_debug_node
	ret

; ---------------- pile de scopes (distincte de aml_pkg_stack) ---------
aml_scope_push:                       ; empile aml_current_node
	mov	edx, [aml_scope_depth]
	cmp	edx, AML_SCOPE_MAX
	jae	aml_error_scope_ovf
	lea	r10, [aml_scope_stack]
	mov	eax, [aml_current_node]
	mov	[r10 + rdx*4], eax
	inc	edx
	mov	[aml_scope_depth], edx
	ret

aml_scope_pop:                        ; current = depile
	mov	edx, [aml_scope_depth]
	test	edx, edx
	jz	aml_error_scope_unf
	dec	edx
	mov	[aml_scope_depth], edx
	lea	r10, [aml_scope_stack]
	mov	eax, [r10 + rdx*4]
	cmp	eax, [aml_node_count]
	jae	aml_error_invalid_node
	mov	[aml_current_node], eax
	ret

aml_scope_enter_node:                 ; ecx = node : push current; current = ecx
	cmp	ecx, [aml_node_count]
	jae	aml_error_invalid_node
	call	aml_scope_push
	mov	[aml_current_node], ecx
	ret

; ---------------- init ------------------------------------------------
aml_namespace_init:
	mov	dword [aml_node_count], 0
	mov	dword [aml_scope_depth], 0
	mov	dword [aml_current_node], 0
	mov	dword [aml_path_count], 0
	mov	dword [aml_path_up], 0
	mov	byte [aml_path_root], 0
	mov	ecx, AML_NODE_ROOT
	lea	rsi, [aml_root_name]
	call	aml_namespace_alloc_node
	test	eax, eax
	jnz	aml_error_invalid_node        ; root DOIT etre l'index 0
	mov	[aml_current_node], eax
	mov	ecx, eax
	call	aml_ns_debug_node
	ret

; ---------------- setters sur le node [aml_tmp_idx] -------------------
; (preservent rax et rdx)
aml_ns_tmp_set8:
	push	rax
	push	rdx
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	mov	rdx, [rsp + 8]
	mov	[rax + AN_AUX8], dl
	pop	rdx
	pop	rax
	ret

aml_ns_tmp_seta:
	push	rax
	push	rdx
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	mov	rdx, [rsp + 8]
	mov	[rax + AN_AUX_A], rdx
	pop	rdx
	pop	rax
	ret

aml_ns_tmp_setb:
	push	rax
	push	rdx
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	mov	rdx, [rsp + 8]
	mov	[rax + AN_AUX_B], rdx
	pop	rdx
	pop	rax
	ret

aml_ns_field_unit_fill:
	mov	eax, [aml_tmp_idx]
	call	aml_ns_node_addr
	mov	edx, [aml_field_bit_offset]
	mov	[rax + AN_AUX_A], rdx
	mov	edx, [aml_field_width]
	mov	[rax + AN_AUX_B], rdx
	movzx	edx, byte [aml_field_flags]
	mov	[rax + AN_AUX8], dl
	ret

; =====================================================================
;  DEBUG : "NODE: TYPE \chemin [= valeur]"
; =====================================================================

; eax = index -> aml_path_buf = "\_SB_.PCI0" (UTF-16). clobber: rcx, rdx, rsi, rdi, r8, r9
aml_ns_build_path:
	xor	ecx, ecx
aml_nsbp_collect:
	cmp	ecx, 128
	jae	aml_error_invalid_node
	lea	rdx, [aml_pathtmp]
	mov	[rdx + rcx*4], eax
	inc	ecx
	test	eax, eax
	jz	aml_nsbp_emit
	push	rcx
	call	aml_ns_node_addr
	pop	rcx
	mov	eax, [rax + AN_PARENT]
	jmp	aml_nsbp_collect

aml_nsbp_emit:
	lea	rdi, [aml_path_buf]
	mov	word [rdi], '\'
	add	rdi, 2
	dec	ecx                           ; saute root (dernier collecte)
	mov	r9d, 1                        ; "premier segment" => pas de '.'
aml_nsbp_node:
	test	ecx, ecx
	jz	aml_nsbp_done
	dec	ecx
	lea	rdx, [aml_pathtmp]
	mov	eax, [rdx + rcx*4]
	push	rcx
	call	aml_ns_node_addr
	pop	rcx
	mov	esi, [rax + AN_NAME]
	test	r9d, r9d
	jnz	aml_nsbp_nosep
	mov	word [rdi], '.'
	add	rdi, 2
aml_nsbp_nosep:
	xor	r9d, r9d
	test	esi, esi
	jnz	aml_nsbp_chars
	mov	word [rdi + 0], '<'
	mov	word [rdi + 2], 'a'
	mov	word [rdi + 4], 'n'
	mov	word [rdi + 6], 'o'
	mov	word [rdi + 8], 'n'
	mov	word [rdi + 10], '>'
	add	rdi, 12
	jmp	aml_nsbp_node
aml_nsbp_chars:
	mov	r8d, 4
aml_nsbp_ch:
	mov	eax, esi
	and	eax, 0xFF
	mov	[rdi], ax
	add	rdi, 2
	shr	esi, 8
	dec	r8d
	jnz	aml_nsbp_ch
	jmp	aml_nsbp_node
aml_nsbp_done:
	mov	word [rdi], 0
	ret

; rax = adresse node : affiche " = 0x..." pour NAME, " = <buffer>" etc.
aml_ns_print_value:
	movzx	edx, byte [rax + AN_VKIND]
	test	edx, edx
	jz	aml_npv_ret
	cmp	edx, AML_VK_INT
	je	aml_npv_int
	cmp	edx, AML_VK_VARPACKAGE
	ja	aml_npv_ret
	shl	edx, 5
	lea	rcx, [aml_vk_names]
	add	rdx, rcx
	call	print_str
aml_npv_ret:
	ret
aml_npv_int:
	push	rax
	lea	rdx, [aml_nd_eq]
	call	print_str
	pop	rax
	mov	rdx, [rax + AN_VALUE]
	mov	ecx, 8
	mov	rax, rdx
	shr	rax, 32
	jz	aml_npv_w
	mov	ecx, 16
aml_npv_w:
	call	print_hex
	ret

; ecx = index, rdx = label UTF-16. Preserve rcx.
aml_ns_debug_node_label:
	push	rcx
	push	rdx
	lea	rdx, [aml_nd_prefix]
	call	print_str
	pop	rdx
	call	print_str
	lea	rdx, [aml_nd_space]
	call	print_str
	mov	eax, [rsp]
	call	aml_ns_build_path
	lea	rdx, [aml_path_buf]
	call	print_str
	mov	eax, [rsp]
	call	aml_ns_node_addr
	cmp	byte [rax + AN_TYPE], AML_NODE_NAME
	jne	aml_ndl_nl
	call	aml_ns_print_value
aml_ndl_nl:
	lea	rdx, [newline]
	call	print_str
	pop	rcx
	ret

; ecx = index : le label est le nom du type du node. Preserve rcx.
aml_ns_debug_node:
	push	rcx
	mov	eax, ecx
	call	aml_ns_node_addr
	movzx	eax, byte [rax + AN_TYPE]
	cmp	eax, AML_NODE_TYPE_COUNT
	jae	aml_error_invalid_node
	shl	eax, 5
	lea	rdx, [aml_type_names]
	add	rdx, rax
	pop	rcx
	jmp	aml_ns_debug_node_label

; =====================================================================
;  DUMP de l'arbre (iteratif : pas de recursion, pas de pile CPU)
;  Parcours preordre via first_child / next_sibling / parent.
; =====================================================================
aml_namespace_dump:
	lea	rdx, [aml_msg_ns_hdr]
	call	print_str
	cmp	dword [aml_node_count], 0
	je	aml_error_invalid_node
	mov	dword [aml_dump_node], 0
	mov	dword [aml_dump_depth], 0
	mov	dword [aml_dump_steps], 0

aml_nsd_visit:
	mov	eax, [aml_dump_steps]
	inc	eax
	mov	[aml_dump_steps], eax
	cmp	eax, [aml_node_count]
	ja	aml_error_invalid_node        ; plus de visites que de nodes => cycle

	call	aml_ns_dump_line

	mov	eax, [aml_dump_node]
	call	aml_ns_node_addr
	mov	eax, [rax + AN_FIRST]
	cmp	eax, AML_NODE_NONE
	je	aml_nsd_up
	mov	[aml_dump_node], eax
	inc	dword [aml_dump_depth]
	jmp	aml_nsd_visit

aml_nsd_up:
	mov	eax, [aml_dump_node]
	test	eax, eax
	jz	aml_nsd_done                  ; on est remonte jusqu'a root
	call	aml_ns_node_addr
	mov	edx, [rax + AN_NEXT]
	cmp	edx, AML_NODE_NONE
	jne	aml_nsd_sibling
	mov	eax, [rax + AN_PARENT]
	mov	[aml_dump_node], eax
	dec	dword [aml_dump_depth]
	jmp	aml_nsd_up
aml_nsd_sibling:
	mov	[aml_dump_node], edx
	jmp	aml_nsd_visit
aml_nsd_done:
	ret

; affiche le node [aml_dump_node] avec indentation [aml_dump_depth]
aml_ns_dump_line:
	lea	rdi, [aml_path_buf]
	mov	ecx, [aml_dump_depth]
	cmp	ecx, 60
	jbe	aml_nsdl_indent
	mov	ecx, 60
aml_nsdl_indent:
	add	ecx, ecx
	jz	aml_nsdl_name
aml_nsdl_sp:
	mov	word [rdi], ' '
	add	rdi, 2
	dec	ecx
	jnz	aml_nsdl_sp
aml_nsdl_name:
	mov	eax, [aml_dump_node]
	call	aml_ns_node_addr
	mov	esi, [rax + AN_NAME]
	movzx	r9d, byte [rax + AN_TYPE]
	cmp	r9d, AML_NODE_TYPE_COUNT
	jae	aml_error_invalid_node
	test	esi, esi
	jnz	aml_nsdl_chars
	mov	word [rdi + 0], '<'
	mov	word [rdi + 2], 'a'
	mov	word [rdi + 4], 'n'
	mov	word [rdi + 6], 'o'
	mov	word [rdi + 8], 'n'
	mov	word [rdi + 10], '>'
	add	rdi, 12
	jmp	aml_nsdl_after
aml_nsdl_chars:
	mov	r8d, 4
aml_nsdl_ch:
	mov	eax, esi
	and	eax, 0xFF
	jz	aml_nsdl_after                ; root = "\" puis zeros
	mov	[rdi], ax
	add	rdi, 2
	shr	esi, 8
	dec	r8d
	jnz	aml_nsdl_ch
aml_nsdl_after:
	mov	word [rdi + 0], ' '
	mov	word [rdi + 2], '['
	add	rdi, 4
	shl	r9d, 5
	lea	rdx, [aml_type_names]
	add	rdx, r9
aml_nsdl_tn:
	movzx	eax, word [rdx]
	test	eax, eax
	jz	aml_nsdl_tn_done
	mov	[rdi], ax
	add	rdi, 2
	add	rdx, 2
	jmp	aml_nsdl_tn
aml_nsdl_tn_done:
	mov	word [rdi + 0], ']'
	mov	word [rdi + 2], 13
	mov	word [rdi + 4], 10
	mov	word [rdi + 6], 0
	lea	rdx, [aml_path_buf]
	call	print_str
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

aml_msg_alias:
	dw	'A','L','I','A','S',':',' ',0

aml_msg_external:
	dw	'E','X','T','E','R','N','A','L',':',' ',0

aml_msg_mutex:
	dw	'M','U','T','E','X',':',' ',0

aml_msg_event:
	dw	'E','V','E','N','T',':',' ',0

aml_msg_processor:
	dw	'P','R','O','C','E','S','S','O','R',':',' ',0

aml_msg_powerres:
	dw	'P','O','W','E','R','R','E','S','O','U','R','C','E',':',' ',0

aml_msg_thermal:
	dw	'T','H','E','R','M','A','L','Z','O','N','E',':',' ',0

aml_msg_indexfield:
	dw	'I','N','D','E','X','F','I','E','L','D',':',' ',0

aml_msg_bankfield:
	dw	'B','A','N','K','F','I','E','L','D',':',' ',0

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

aml_msg_bad_name:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','I','N','V','A','L','I','D',' ','N','A','M','E','S','E','G',13,10,0

aml_msg_depth:
	dw	'A','M','L',' ','E','R','R','O','R',':',' ','P','A','C','K','A','G','E',' ','D','E','P','T','H',13,10,0

; ---------------------------------------------------------------------
;  NAMESPACE : donnees
; ---------------------------------------------------------------------
aml_root_name:
	db	'\', 0, 0, 0

aml_type_names:               ; DOIT suivre l'ordre des AML_NODE_*
	TYPENAME "ROOT"
	TYPENAME "SCOPE"
	TYPENAME "DEVICE"
	TYPENAME "METHOD"
	TYPENAME "NAME"
	TYPENAME "OPREGION"
	TYPENAME "FIELD"
	TYPENAME "INDEXFIELD"
	TYPENAME "BANKFIELD"
	TYPENAME "PROCESSOR"
	TYPENAME "POWERRESOURCE"
	TYPENAME "THERMALZONE"
	TYPENAME "MUTEX"
	TYPENAME "EVENT"
	TYPENAME "BUFFER"
	TYPENAME "PACKAGE"
	TYPENAME "VARPACKAGE"
	TYPENAME "ALIAS"
	TYPENAME "EXTERNAL"

aml_vk_names:                 ; ordre AML_VK_*
	TYPENAME ""
	TYPENAME ""
	TYPENAME " = <string>"
	TYPENAME " = <buffer>"
	TYPENAME " = <package>"
	TYPENAME " = <varpackage>"

aml_lbl_scope:
	U16 "SCOPE"
	dw 0
aml_nd_prefix:
	U16 "NODE: "
	dw 0
aml_nd_space:
	dw ' ', 0
aml_nd_eq:
	U16 " = "
	dw 0
aml_msg_ns_hdr:
	dw 13,10
	U16 "ACPI NAMESPACE"
	dw 13,10,13,10,0
aml_msg_ns_full:
	U16 "AML ERROR: NAMESPACE FULL"
	dw 13,10,0
aml_msg_scope_ovf:
	U16 "AML ERROR: SCOPE STACK OVERFLOW"
	dw 13,10,0
aml_msg_scope_unf:
	U16 "AML ERROR: SCOPE STACK UNDERFLOW"
	dw 13,10,0
aml_msg_invalid_node:
	U16 "AML ERROR: INVALID NODE"
	dw 13,10,0

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

alignb	4

aml_field_bit_offset:
	resd	1

aml_field_width:
	resd	1

aml_pkg_depth:
	resd	1

alignb	8

aml_table_start:
	resq	1

aml_table_end:
	resq	1

saved_rsp:
	resq	1

aml_pkg_stack:
	resq	AML_PKG_MAX

; ---------------------------------------------------------------------
;  NAMESPACE : BSS
; ---------------------------------------------------------------------
alignb	4
aml_node_count:      resd 1
aml_current_node:    resd 1
aml_scope_depth:     resd 1
aml_path_count:      resd 1
aml_path_up:         resd 1
aml_walk_n:          resd 1
aml_walk_i:          resd 1
aml_walk_node:       resd 1
aml_def_parent:      resd 1
aml_def_idx:         resd 1
aml_tmp_idx:         resd 1
aml_dump_node:       resd 1
aml_dump_depth:      resd 1
aml_dump_steps:      resd 1
aml_path_root:       resb 1
aml_last_vkind:      resb 1
aml_field_flags:     resb 1
aml_field_unit_type: resb 1
alignb	8
aml_last_value:      resq 1
aml_scope_stack:     resd AML_SCOPE_MAX        ; pile des scopes (independante de aml_pkg_stack)
aml_path_segs:       resd AML_PATH_MAX_SEGS    ; 4 octets bruts par segment
aml_pathtmp:         resd 128
aml_path_buf:        resw 1024
alignb	8
aml_nodes:           resb AML_NODE_SIZE * AML_NODE_MAX

log_buffer:
	resw	LOG_BUF_WORDS

alignb	8

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

alignb	4

visible_rows_actual:
	resd	1

alignb	8

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

alignb	8

dbg_status:
	resq	1

debug_hex_scratch:
	resw	20

line_scratch:
	resw	LINE_SCRATCH_WORDS
	