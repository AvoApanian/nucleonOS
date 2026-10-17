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
	dw	'U','N','S','U','P','P','O','R','T','E','D',' ','O','P','C','O','D','E',':',' ',0

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
aml_msg_stop_at:
	U16 "AML PARSE STOPPED [build 4] at AML offset "
	dw 0
aml_msg_const:
	U16 "CONST (ignore): "
	dw 0
aml_msg_stop_bytes:
	U16 "BYTES: "
	dw 0
aml_msg_stop_mark:
	U16 "| "
	dw 0
aml_msg_stop_nodes:
	U16 "  NODES="
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
	U16 "ACPI NAMESPACE (build 4)"
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
