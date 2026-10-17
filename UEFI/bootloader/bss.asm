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
alignb	4
aml_redraw_tick:     resd 1
aml_ti_depth:        resd 1
aml_dump_done:       resb 1
alignb	4

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
