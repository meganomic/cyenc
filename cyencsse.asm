GLOBAL encode
EXPORT encode
GLOBAL decode
EXPORT decode
GLOBAL debug_getlc
EXPORT debug_getlc
GLOBAL debug_setlc
EXPORT debug_setlc

default rel

%ifidn __OUTPUT_FORMAT__, win64 ; Windows calling convention
	%define outputarray rdx
	%define inputarray rcx
	%define inputsize r8
%elifidn __OUTPUT_FORMAT__, elf64 ; Linux calling convention
	%define outputarray rsi
	%define inputarray rdi
	%define inputsize rdx
%endif

section .text
align 16
encode:
	sub rsp, 8 ; Stack alignment
	push r12 ; calling convention demands saving various registers
	push r13

	mov r11, 127 ; The maximum length of each line

	movaps xmm3, [const1] ; 0x40
	mov r9, outputarray ; original position of outputarray, will use this to get the size later
	sub inputsize, 16 ; Subtract 16 so it jumps out of the loop when ~16 characters are left
align 16
.encodeset:
	movaps xmm0, [inputarray] ; Read 16 bytes from memory
	paddb xmm0, xmm3 ; +42

	pxor xmm1, xmm1 ; zero mask register
	movaps xmm2, xmm0 ; Need a temporary registers
	pcmpeqb xmm2, xmm1 ; 0x00
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, [special1] ; 0x3D
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, [special2] ; 0x0A
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, [special3] ; 0x0D
	por xmm1, xmm2 ; save compare results

	movq r10, xmm1 ; Copy lower 8 bytes of mask to r10
	movq rax, xmm0 ; Copy lower 8 bytes of data to rax
	cmp r10, 0 ; Check if rax contains any of the specialcharacters
	jne .scmultientry ; Jump if it does
	cmp r11, 8 ; Check if the length of the current line is 119 or higher
	jle .scmultientry ; Need special handling if we go over line length limit
	mov qword [outputarray], rax ; Otherwise just write the 8 bytes in rax to memory
	add outputarray, 8 ; Increase output pointer
	sub r11, 8 ; Keep track of line length

	psrldq xmm1, 8 ; Shift mask register 8 bytes to the right
	psrldq xmm0, 8 ; Shift data register 8 bytes to the right
	movq r10, xmm1 ; Copy the lower 8 bytes of mask register to r10
	movq rax, xmm0 ; Copy the lower 8 bytes of data register to rax
	cmp r10, 0 ; See if rax contains any special characters
	jne .scmultientryb ; Jump to another copy of scmultientry that is slightly different. 
	cmp r11, 8 ; Check if the length of the current line is 119 or higher
	jbe .scmultientryb ; Need special handling if we go over line length limit
	mov qword [outputarray], rax ; Write data to memory
	add inputarray, 16 ; Increase input pointer
	add outputarray, 8 ; Increase output pointer
	sub r11, 8 ; Keep track of line length
	sub inputsize, 16 ; See if we are on the last couple of characters.
	jbe .specialcharentry ; Jump if we are
	jmp .encodeset ; Encode another 16 bytes

align 16
.scmultientry:
	cmp r10b, 0x00
	je .scskip1
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip1:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1 ; Increase line length
	ja .scmultiskip1
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip1:
	cmp r10b, 0x00
	je .scskip2
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip2:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1 ; Increase line length
	ja .scmultiskip2
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip2:
	cmp r10b, 0x00
	je .scskip3
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip3:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip3
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip3:
	cmp r10b, 0x00
	je .scskip4
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip4:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip4
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip4:
	cmp r10b, 0x00
	je .scskip5
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip5:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip5
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip5:
	cmp r10b, 0x00
	je .scskip6
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip6:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip6
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip6:
	cmp r10b, 0x00
	je .scskip7
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip7:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip7
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip7:
	cmp r10b, 0x00
	je .scskip8
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip8:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip8
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip8:
	psrldq xmm1, 8
	psrldq xmm0, 8
	movq r10, xmm1
	movq rax, xmm0
	cmp r10, 0
	jne .scmultientryb
	cmp r11, 8
	jbe .scmultientryb ; Need special handling if we go over line length limit
	mov qword [outputarray], rax
	add inputarray, 16
	add outputarray, 8
	sub r11, 8
	sub inputsize, 16
	jbe .specialcharentry
	jmp .encodeset ; Encode another 8 bytes

align 16
.scmultientryb:
	cmp r10b, 0x00
	je .scskip1b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip1b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip1b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip1b:
	cmp r10b, 0x00
	je .scskip2b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip2b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip2b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip2b:
	cmp r10b, 0x00
	je .scskip3b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip3b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip3b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip3b:
	cmp r10b, 0x00
	je .scskip4b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip4b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip4b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip4b:
	cmp r10b, 0x00
	je .scskip5b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip5b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip5b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip5b:
	cmp r10b, 0x00
	je .scskip6b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip6b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip6b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip6b:
	cmp r10b, 0x00
	je .scskip7b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip7b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip7b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip7b:
	cmp r10b, 0x00
	je .scskip8b
	add al, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
.scskip8b:
	mov byte [outputarray], al ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	shr rax, 8
	shr r10, 8
	sub r11, 1
	ja .scmultiskip8b
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127
.scmultiskip8b:
	add inputarray, 16
	sub inputsize, 16
	jbe .specialcharentry
	jmp .encodeset

align 16
.specialcharentry:
	add inputsize, 16
	jmp .specialchar

.scnewline:
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 127

.scnextchar:
	add inputarray, 1
	sub inputsize, 1
	jz .exitprogram

.specialchar:
	add r13, 1
	mov r10b, byte [inputarray] ; Move character from memory to register
	add r10b, 42 ; Add 42
	cmp r10b, 0 ; Check for illegal characters
	je .sc
	cmp r10b, 10
	je .sc
	cmp r10b, 13
	je .sc
	cmp r10b, 61
	je .sc

.scoutputencoded:
	mov byte [outputarray], r10b ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
	jbe .scnewline
	jmp .scnextchar

.sc:
	add r10b, 64 ; This time we add 64
	mov byte [outputarray], 61 ; Add escape character
	add outputarray, 1 ; increase output array pointer
	sub r11, 1 ; Increase line length
	jmp .scoutputencoded

.exitprogram:
	sub outputarray, r9 ; subtract original position from current and we get the size
	mov rax, outputarray ; Return output size
	pop r13 ; restore some registers to their original state
	pop r12
	add rsp, 8
	ret

align 16
decode:
	sub rsp, 8
	push r12

	xor r11, r11
	;xor r9, r9

	mov r9, outputarray ; original position of outputarray

.decodeset:
	cmp inputsize, 16
	jbe .decspecialchar ; The last 8 or less characters need special treatment

	pxor xmm1, xmm1 ; zero mask register
	movaps xmm0, [inputarray] ; Read from memory

	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, [special2] ; Check for 0x0A
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, [special3] ; Check for 0x0D
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, [special1] ; Check for 0x3D

	movaps xmm3, xmm2 ; make a copy
	por xmm1, xmm2
	pslldq xmm2, 1

	cmp byte [lastchar], 0xFF
	jne .deccontinue
	pand xmm1, [decodeconst4] ; Make sure first byte isn't skipped
	por xmm2, [decodeconst3] ; The first byte require special math
	mov byte [lastchar], 0x00

.deccontinue:
	pand xmm2, [specialdecode4] ; 1s to 64s, I think
	psubb xmm0, [const1] ; -42 to all bytes
	psubb xmm0, xmm2 ; -64 to select bytes

	psrldq xmm3, 8
	movq r10, xmm3
	rol r10, 8
	cmp r10b, 0xFF ; Check if last byte is an escape character
	jne .cont2
	mov byte [lastchar], 0xFF

.cont2:
	mov r11b, 2
.retfromwset:
	movq r10, xmm1 ; List of bytes to skip
	movq rax, xmm0 ; Move to gpr so we can do stuff
	cmp r10, 0
	je .writeset
	mov r12b, 8
;.compactbytes: fully unrolled because it was faster on my cpu
	cmp r10b, 0xFF
	je .skipbyte
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte2
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte2:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte3
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte3:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte4
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte4:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte5
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte5:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte6
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte6:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte7
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte7:
	shr r10, 8
	shr rax, 8
	cmp r10b, 0xFF
	je .skipbyte8
	mov byte [outputarray], al
	add outputarray, 1
.skipbyte8:
	;shr r10, 8
	;shr rax, 8
	sub r12b, 8
	;jnz .compactbytes

	psrldq xmm1, 8
	psrldq xmm0, 8
	sub r11b, 1
	jnz .retfromwset

	add inputarray, 16 ; increase input pointer
	sub inputsize, 16 ; Done encoding 16 bytes
	jmp .decodeset ; Encode another 16 bytes

align 16
.writeset:
	mov qword [outputarray], rax
	add outputarray, 8
	psrldq xmm1, 8 ; right shift by 8 bytes
	psrldq xmm0, 8 ; right shift by 8 bytes
	sub r11b, 1
	jnz .retfromwset

	add inputarray, 16 ; increase input pointer
	sub inputsize, 16 ; Done encoding 16 bytes
	jmp .decodeset

.decscnextchar:
	add inputarray, 1
	sub inputsize, 1
	jz .decodeexitprogram

.decspecialchar:
	mov r10b, byte [inputarray] ; Move character from memory to register
	cmp byte [lastchar], 0xFF ; if the last character in the last batch was a escape character it requires special stuff
	je .decsc2
	cmp r10b, 61
	je .decsc
	cmp r10b, 10
	je .decscnextchar
	cmp r10b, 13
	je .decscnextchar
	jmp .decscoutputencoded

.decsc2:
	;sub inputsize, 1
	mov byte [lastchar], 0x00
	sub r10b, 64 ; This time we sub 64
	jmp .decscoutputencoded

.decsc:
	sub inputsize, 1
	jz .decodeexitprogram2
	add inputarray, 1
	mov r10b, byte [inputarray] ; Move character from memory to register
	sub r10b, 64 ; This time we sub 64

.decscoutputencoded:
	sub r10b, 42 ; -42
	mov byte [outputarray], r10b ; Move encoded byte to output array
	add outputarray, 1 ; increase output array pointer
	jmp .decscnextchar

.decodeexitprogram2:
	mov byte [lastchar], 0xFF ; if the last character is a escape character, that information needs to be saved

.decodeexitprogram:
	sub outputarray, r9 ; subtract original position from current and we get the size
	mov rax, outputarray ; Return output size
	pop r12
	add rsp, 8
	ret

debug_getlc:
	xor rax, rax
	mov al, byte [lastchar]
	ret
debug_setlc:
	mov byte [lastchar], cl
	ret

section .data align=16
special1:	times 2 dq 0x3D3D3D3D3D3D3D3D
special2:	times 2 dq 0x0A0A0A0A0A0A0A0A
special3:	times 2 dq 0X0D0D0D0D0D0D0D0D
const1:		times 2 dq 0x2A2A2A2A2A2A2A2A
specialdecode4:	times 2 dq 0x4040404040404040
decodeconst3:	dq 0x00000000000000FF
				dq 0x0000000000000000
decodeconst4:	dq 0xFFFFFFFFFFFFFF00
				dq 0xFFFFFFFFFFFFFFFF
lastchar:	db 0x00