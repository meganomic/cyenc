GLOBAL encode
	EXPORT encode

default rel

section .code bits 64
align 16

encode:
	push r12 ; save r12 and r13, I need those registers for stuff
	push r13
	push rbx
	xor rbx, rbx
	xor r9, r9
	xor r11, r11

	movdqa xmm6, [special4]
	movdqa xmm5, [special3]
	movdqa xmm4, [special2]
	movdqa xmm3, [special1]

.encodeset:
	cmp r8, 16
	jle .specialchar ; The last 8 or less characters need special treatment
	movdqu xmm0, [rcx]
	paddb xmm0, [const1] ; + 42

	pxor xmm1, xmm1
	movdqa xmm7, xmm0 ; temporary copy
	pcmpeqb xmm7, xmm3
	por xmm1, xmm7
	movdqa xmm7, xmm0
	pcmpeqb xmm7, xmm4
	por xmm1, xmm7
	movdqa xmm7, xmm0
	pcmpeqb xmm7, xmm5
	por xmm1, xmm7
	movdqa xmm7, xmm0
	pcmpeqb xmm7, xmm6
	por xmm1, xmm7
	movq r10, xmm1
	cmp r10, 0
	jne .scmultientry
	psrldq xmm1, 8
	movq r10, xmm1
	cmp r10, 0
	jne .scmultientry
	cmp r11, 111
	jge .scmultientry ; Need special handling if we go over line length limit
	movdqu [rdx], xmm0 ; Move encoded byte to output array
	add rdx, 16 ; increase output array pointer
	add rcx, 16 ; increase input pointer
	add r9, 16 ; Increase size of output
	add r11, 16 ; Increase line length
	sub r8, 16 ; Done encoding 16 bytes
	jmp .encodeset ; Encode another 8 bytes

.scmultientry:
	xor r13, r13
	movq rax, xmm0
	cmp rax, 0
	jz .nextset
	psrldq xmm0, 8
	
.scmulti:
	add r13, 1
	cmp al, 0 ; Check for illegal characters
	je .scmulti2
	cmp al, 10
	je .scmulti2
	cmp al, 13
	je .scmulti2
	cmp al, 61
	je .scmulti2

.scnextcharmulti:
	mov byte [rdx], al ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	ror rax, 8
	sub r8, 1
	jz .exitprogram
	cmp r11, 127
	jge .scnewlinemulti
	cmp r13, 8
	je .scmultientry
	jmp .scmulti

.scmulti2:
	add al, 64 ; This time we add 64
	mov byte [rdx], 61 ; Add escape character
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	jmp .scnextcharmulti

.nextset:
	add rcx, 16
	jmp .encodeset

.scnewlinemulti:
	mov word [rdx], 0x0A0D ; \r\n
	add rdx, 2 ; increase output array pointer
	add r9, 2 ; Increase size of output
	xor r11, r11
	cmp r13, 8
	je .scmultientry
	jmp .scmulti

.scnewline:
	mov word [rdx], 0x0A0D ; \r\n
	add rdx, 2 ; increase output array pointer
	add r9, 2 ; Increase size of output
	xor r11, r11

.scnextchar:
	add rcx, 1
	sub r8, 1
	jz .exitprogram

.specialchar:
	add r13, 1
	mov r10b, byte [rcx] ; Move character from memory to register
	add r10b, 42 ; Add 42 before modulus
	cmp r10b, 0 ; Check for illegal characters
	je .sc
	cmp r10b, 10
	je .sc
	cmp r10b, 13
	je .sc
	cmp r10b, 61
	je .sc
	jmp .scoutputencoded

.sc:
	add r10b, 64 ; This time we add 64
	mov byte [rdx], 61 ; Add escape character
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length

.scoutputencoded:
	mov byte [rdx], r10b ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	cmp r11, 127
	jge .scnewline
	jmp .scnextchar

.exitprogram:
	mov rax, r9 ; Return output size
	pop rbx
	pop r13 ; restore some registers to their original state
	pop r12
	ret

section .data
align 16
special1:	times 2 dq 0x3D0D0A003D0D0A00
align 16
special2:	times 2 dq 0x0D0A003D0D0A003D
align 16
special3:	times 2 dq 0x0A003D0D0A003D0D
align 16
special4:	times 2 dq 0x003D0D0A003D0D0A
align 16
const1:		times 2 dq 0x2A2A2A2A2A2A2A2A