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
