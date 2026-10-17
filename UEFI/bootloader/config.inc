LOG_START_ROW equ 11
VISIBLE_ROWS  equ 14
LOG_LINE_MAX  equ 131072
LOG_BUF_WORDS equ 4194304
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

%define AML_TRACE_OPCODES   0   ; 1 = lignes "OPCODE AT:" (log ENORME sur un vrai DSDT)
%define AML_EXTERNAL_CREATES_NODE 0   ; 0 = External() est une declaration: pas de node
%define AML_LOG_FIELD_NODES 0
AML_REDRAW_MASK   equ 0x3FF            ; redessine l'ecran 1 fois sur 1024 pendant le parse   ; 1 = une ligne NODE: par field unit (beaucoup de lignes)

; ---------------------------------------------------------------------
;  NAMESPACE : constantes
; ---------------------------------------------------------------------
AML_NODE_MAX      equ 32768
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
