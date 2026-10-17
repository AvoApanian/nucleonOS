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

	call	aml_check_redraw_force

	call	aml_namespace_dump            ; NEW : affiche l'arbre

	call	aml_check_redraw              ; NEW

	ret

aml_check_redraw_force:                ; NEW : redessine a coup sur
	mov	dword [aml_redraw_tick], AML_REDRAW_MASK
	jmp	aml_check_redraw

aml_check_redraw:
	cmp	byte [redraw_pending], 0
	je	aml_check_redraw_done

	; ---- NEW : pendant le parse, ne redessine que 1 appel sur 1024 ----
	cmp	byte [ui_mode], 0
	jne	aml_check_redraw_run
	inc	dword [aml_redraw_tick]
	test	dword [aml_redraw_tick], AML_REDRAW_MASK
	jnz	aml_check_redraw_done
	; ---- fin NEW ----

aml_check_redraw_run:
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

	; ---- NEW : constantes isolees (Zero/One/Ones) entre deux declarations.
	;      Observe sur le vrai DSDT ASUS : octet 0x01 entre deux External.
	cmp	al, 0x00
	je	aml_do_const
	cmp	al, 0x01
	je	aml_do_const
	cmp	al, 0xFF
	je	aml_do_const
	; ---- fin NEW ----

	dec	r14
	jmp	aml_unsupported_opcode

aml_do_const:
	push	rax
	lea	rdx, [aml_msg_const]
	call	print_str
	pop	rdx
	movzx	edx, dl
	mov	ecx, 2
	call	print_hex
	lea	rdx, [newline]
	call	print_str
	ret

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

%if AML_EXTERNAL_CREATES_NODE
	mov	ecx, AML_NODE_EXTERNAL
	call	aml_ns_define_log
	mov	[aml_tmp_idx], eax
%endif

	call	aml_read_u8
%if AML_EXTERNAL_CREATES_NODE
	call	aml_ns_tmp_set8               ; type d'objet
%endif
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

	; ---- NEW : reference par nom (ex: OperationRegion (X, SystemMemory, PNVB, PNVL)) ----
	cmp	al, 0x5C
	je	aml_ti_name
	cmp	al, 0x5E
	je	aml_ti_name
	cmp	al, 0x2E
	je	aml_ti_name
	cmp	al, 0x2F
	je	aml_ti_name
	cmp	al, '_'
	je	aml_ti_name
	cmp	al, 'A'
	jb	aml_ti_notname
	cmp	al, 'Z'
	jbe	aml_ti_name
aml_ti_notname:
	; ---- build 4 : Local/Arg, logiques, DerefOf/SizeOf, CondRefOf ----
	cmp	al, 0x60
	jb	aml_ti_chk_ext
	cmp	al, 0x6E
	jbe	aml_ti_localarg
aml_ti_chk_ext:
	cmp	al, 0x5B
	je	aml_ti_extop
	cmp	al, 0x92                      ; LNot (aussi LNotEqual/LLessEqual/LGreaterEqual : 92 93..95)
	je	aml_ti_unary
	cmp	al, 0x83                      ; DerefOf
	je	aml_ti_unary
	cmp	al, 0x87                      ; SizeOf
	je	aml_ti_unary
	cmp	al, 0x88                      ; Index (2 operandes + target = meme forme que binop)
	je	aml_ti_binop
	cmp	al, 0x90                      ; LAnd
	je	aml_ti_logic2
	cmp	al, 0x91                      ; LOr
	je	aml_ti_logic2
	cmp	al, 0x93                      ; LEqual
	jb	aml_ti_chk_binop
	cmp	al, 0x95                      ; LGreater / LLess
	jbe	aml_ti_logic2
aml_ti_chk_binop:
	; ---- NEW : expressions binaires Add/Subtract/Multiply/Shift/And/Or/... ----
	cmp	al, 0x72
	je	aml_ti_binop
	cmp	al, 0x74
	je	aml_ti_binop
	cmp	al, 0x77
	je	aml_ti_binop
	cmp	al, 0x79
	jb	aml_ti_fail
	cmp	al, 0x7F
	jbe	aml_ti_binop

aml_ti_fail:
	mov	byte [aml_error], 1
	xor	eax, eax
	ret

aml_ti_name:                          ; valeur non resolue => 0 (a resoudre avec l'interpreteur)
	call	aml_skip_namestring
	xor	eax, eax
	ret

aml_ti_binop:
	mov	edx, [aml_ti_depth]
	cmp	edx, 16
	jae	aml_ti_fail
	inc	edx
	mov	[aml_ti_depth], edx
	inc	r14                           ; opcode
	call	aml_read_termarg_integer      ; operande 1
	cmp	byte [aml_error], 0
	jne	aml_ti_binop_out
	call	aml_read_termarg_integer      ; operande 2
	cmp	byte [aml_error], 0
	jne	aml_ti_binop_out
	call	aml_skip_target
aml_ti_binop_out:
	dec	dword [aml_ti_depth]
	xor	eax, eax
	ret

aml_ti_localarg:                      ; Local0-7 / Arg0-6 : 1 octet
	inc	r14
	xor	eax, eax
	ret

aml_ti_unary:                         ; 1 operande
	mov	edx, [aml_ti_depth]
	cmp	edx, 16
	jae	aml_ti_fail
	inc	edx
	mov	[aml_ti_depth], edx
	inc	r14
	call	aml_read_termarg_integer
	jmp	aml_ti_binop_out

aml_ti_logic2:                        ; 2 operandes, pas de target
	mov	edx, [aml_ti_depth]
	cmp	edx, 16
	jae	aml_ti_fail
	inc	edx
	mov	[aml_ti_depth], edx
	inc	r14
	call	aml_read_termarg_integer
	cmp	byte [aml_error], 0
	jne	aml_ti_binop_out
	call	aml_read_termarg_integer
	jmp	aml_ti_binop_out

aml_ti_extop:                         ; 5B xx : seulement CondRefOf (5B 12 SuperName Target)
	mov	rcx, 2
	call	aml_require
	cmp	byte [r14 + 1], 0x12
	jne	aml_ti_fail
	add	r14, 2
	call	aml_skip_target               ; SuperName
	call	aml_skip_target               ; Target
	xor	eax, eax
	ret

; Target : NullName (0x00), Local/Arg (0x60-0x6E) ou NameString
aml_skip_target:
	cmp	r14, r15
	jae	aml_error_truncated
	movzx	eax, byte [r14]
	test	al, al
	jz	aml_skip_target_1
	cmp	al, 0x60
	jb	aml_skip_namestring
	cmp	al, 0x6E
	ja	aml_skip_namestring
aml_skip_target_1:
	inc	r14
	ret

; saute un NameString sans rien afficher ni toucher aml_name_buf / aml_path_*
aml_skip_namestring:
	cmp	r14, r15
	jae	aml_error_truncated
	cmp	byte [r14], 0x5C
	jne	aml_sns_caret
	inc	r14
	jmp	aml_sns_seg
aml_sns_caret:
	cmp	byte [r14], 0x5E
	jne	aml_sns_seg
	inc	r14
	cmp	r14, r15
	jae	aml_error_truncated
	jmp	aml_sns_caret
aml_sns_seg:
	cmp	r14, r15
	jae	aml_error_truncated
	movzx	eax, byte [r14]
	cmp	al, 0x00
	je	aml_sns_null
	cmp	al, 0x2E
	je	aml_sns_dual
	cmp	al, 0x2F
	je	aml_sns_multi
	mov	rcx, 4
	call	aml_require
	add	r14, 4
	ret
aml_sns_null:
	inc	r14
	ret
aml_sns_dual:
	inc	r14
	mov	rcx, 8
	call	aml_require
	add	r14, 8
	ret
aml_sns_multi:
	inc	r14
	call	aml_read_u8
	test	eax, eax
	jz	aml_error_bad_name
	shl	eax, 2
	mov	ecx, eax
	call	aml_require
	add	r14, rcx
	ret
; ---- fin NEW ----

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
