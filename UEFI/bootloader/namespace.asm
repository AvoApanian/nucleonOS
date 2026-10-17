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

	; ---- NEW : si un Scope() anterieur a deja cree ce nom (placeholder
	;      de type SCOPE), on le promeut au vrai type au lieu de dupliquer ----
	pop	rcx                           ; ecx = type demande
	push	rcx
	push	rsi
	mov	ecx, [aml_def_parent]
	call	aml_ns_lookup_child           ; rsi = nom -> eax = idx ou NONE
	pop	rsi
	pop	rdx                           ; edx = type demande
	mov	r8d, edx
	cmp	eax, AML_NODE_NONE
	je	aml_nsdf_new
	cmp	r8d, AML_NODE_SCOPE
	je	aml_nsdf_new
	mov	r9d, eax
	call	aml_ns_node_addr              ; rax = adresse (clobber rdx)
	cmp	byte [rax + AN_TYPE], AML_NODE_SCOPE
	jne	aml_nsdf_new
	mov	[rax + AN_TYPE], r8b          ; promotion
	mov	eax, r9d
	mov	[aml_def_idx], eax
	ret
aml_nsdf_new:
	mov	ecx, r8d
	; ---- fin NEW ----
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

; ligne de diagnostic : offset AML (dans le bloc AML) ou le parse s'est arrete
aml_print_stop_line:
	lea	rdx, [aml_msg_stop_at]
	call	print_str
	mov	rdx, r14
	sub	rdx, [aml_table_start]
	mov	ecx, 8
	call	print_hex
	lea	rdx, [aml_msg_stop_nodes]
	call	print_str
	mov	edx, [aml_node_count]
	mov	ecx, 8
	call	print_hex
	lea	rdx, [newline]
	call	print_str

	; ---- octets autour de l'arret : 8 avant, '|' puis l'octet fautif et la suite ----
	lea	rdx, [aml_msg_stop_bytes]
	call	print_str
	mov	rsi, r14
	sub	rsi, 8
	cmp	rsi, [aml_table_start]
	jae	aml_psl_start_ok
	mov	rsi, [aml_table_start]
aml_psl_start_ok:
	mov	r10d, 20
aml_psl_loop:
	cmp	rsi, [aml_table_end]
	jae	aml_psl_done
	cmp	rsi, r14
	jne	aml_psl_nomark
	lea	rdx, [aml_msg_stop_mark]
	call	print_str
aml_psl_nomark:
	movzx	edx, byte [rsi]
	mov	ecx, 2
	call	print_hex
	lea	rdx, [aml_nd_space]
	call	print_str
	inc	rsi
	dec	r10d
	jnz	aml_psl_loop
aml_psl_done:
	lea	rdx, [newline]
	call	print_str
	ret

; =====================================================================
;  DUMP de l'arbre (iteratif : pas de recursion, pas de pile CPU)
;  Parcours preordre via first_child / next_sibling / parent.
; =====================================================================
aml_namespace_dump:
	mov	byte [aml_dump_done], 1       ; NEW
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
