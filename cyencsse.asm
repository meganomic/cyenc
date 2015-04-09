GLOBAL encode
EXPORT encode
GLOBAL decode
EXPORT decode

default rel

section .code
align 16

encode:
	sub rsp, 8 ; Stack alignment
	push r12 ; save r12 and r13, I need those registers for stuff
	push r13
	push rbx
	push rdi

	sub rsp,16 ; need space for xmm6
	movdqu [rsp], xmm6

	xor rbx, rbx
	xor r9, r9
	xor r11, r11

	movaps xmm6, [special4]
	movaps xmm5, [special3]
	movaps xmm4, [special2]
	movaps xmm3, [special1]

.encodeset:
	cmp r8, 16
	jle .specialchar ; The last 8 or less characters need special treatment
	movaps xmm0, [rcx]
	paddb xmm0, [const1] ; + 42

	pxor xmm1, xmm1
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, xmm3
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm4
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm5
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm6
	por xmm1, xmm2
	movq r10, xmm1
	movq rax, xmm0
	mov rbx, 1
	cmp r10, 0
	jne .scmultientry
	cmp r11, 119
	jge .scmultientry ; Need special handling if we go over line length limit
	mov qword [rdx], rax
	add rcx, 8
	add rdx, 8
	add r9, 8
	add r11, 8
	sub r8, 8

.parttwo:
	mov rbx, 0
	psrldq xmm1, 8
	psrldq xmm0, 8
	movq r10, xmm1
	movq rax, xmm0
	cmp r10, 0
	jne .scmultientry
	cmp r11, 119
	jge .scmultientry ; Need special handling if we go over line length limit
	mov qword [rdx], rax
	add rcx, 8
	add rdx, 8
	add r9, 8
	add r11, 8
	sub r8, 8
	jmp .encodeset ; Encode another 8 bytes

.parttwocheck:
	add rcx, 8
	sub r8, 8
	cmp rbx, 1
	je .parttwo
	jmp .encodeset

.scmultientry:
	mov r13, 9

.scmulti:
	sub r13, 1
	jz .parttwocheck
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
	cmp r11, 127
	jge .scnewlinemulti
	jmp .scmulti

.scmulti2:
	add al, 64 ; This time we add 64
	mov byte [rdx], 61 ; Add escape character
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	jmp .scnextcharmulti

.scnewlinemulti:
	mov word [rdx], 0x0A0D ; \r\n
	add rdx, 2 ; increase output array pointer
	add r9, 2 ; Increase size of output
	xor r11, r11
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
	movdqu xmm6, [rsp]
	add rsp,16
	pop rdi
	pop rbx
	pop r13 ; restore some registers to their original state
	pop r12
	add rsp, 8
	ret

decode:
	sub rsp, 8
	push rbx
	sub rsp,16 ; need space for xmm6
	movdqu [rsp], xmm6
	sub rsp,16 ; need space for xmm6
	movdqu [rsp], xmm7
	sub rsp,16 ; need space for xmm6
	movdqu [rsp], xmm8

	movaps xmm3, [specialdecode1] ; 0x3D
	movaps xmm4, [specialdecode2]
	movaps xmm5, [specialdecode3]
	movaps xmm6, [decodeconst1] ; 0xFF
	movaps xmm7, [specialdecode4] ; 0x40
	xor rbx, rbx
	xor r11, r11

.decodeset:
	cmp r8, 16
	jle .decspecialchar ; The last 8 or less characters need special treatment
	pxor xmm1, xmm1 ; zero mask register
	movdqu xmm0, [rcx] ; Read from memory
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, xmm4 ; Check for 0x0A0D
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm5 ; Check for 0x0D0A
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm3 ; Check for 0x3D
	
	movaps xmm8, xmm2 ; make a copy
	por xmm1, xmm2
	pslldq xmm2, 1

	cmp bx, [decodeconst2]
	jne .deccontinue
	pand xmm1, [decodeconst4] ; Make sure first byte isn't skipped
	por xmm2, [decodeconst3]
	mov bx, 0

.deccontinue:
	pand xmm2, xmm7 ; 1s to 64s, I think
	psubb xmm0, xmm2 ; -64 to select bytes
	psubb xmm0, [const1] ; -42 to all bytes

	psrldq xmm8, 8
	movq r10, xmm8
	rol r10, 8
	cmp r10b, 0xFF ; Check if last byte is an escape character
	cmove bx, [decodeconst2] ; set bl to 0xff if it is

	mov r11b, 2
.retfromwset:
	movq r10, xmm1 ; List of bytes to skip
	movq rax, xmm0 ; Move to gpr so we can do stuff
	cmp r10, 0
	je .writeset
	mov r12b, 8
.compactbytes:
	cmp r10b, 0xFF
	je .skipbyte
	mov byte [rdx], al
	add rdx, 1
	add r9, 1
.skipbyte:
	ror r10, 8
	ror rax, 8
	sub r12b, 1
	jnz .compactbytes

	psrldq xmm1, 8
	psrldq xmm0, 8
	movq r10, xmm1
	movq rax, xmm0
	mov r12b, 8
	sub r11b, 1
	jnz .compactbytes

	add rcx, 16 ; increase input pointer
	sub r8, 16 ; Done encoding 16 bytes
	jmp .decodeset ; Encode another 16 bytes

.writeset:
	mov qword [rdx], rax
	add rdx, 8
	add r9, 8
	psrldq xmm1, 8
	psrldq xmm0, 8
	sub r11b, 1
	jnz .retfromwset

	add rcx, 16 ; increase input pointer
	;add r9, 16 ; Increase size of output
	sub r8, 16 ; Done encoding 16 bytes
	jmp .decodeset

.decscnextchar:
	add rcx, 1
	sub r8, 1
	jz .decodeexitprogram

.decspecialchar:
	mov r10b, byte [rcx] ; Move character from memory to register
	cmp r10b, 61
	je .decsc
	cmp r10b, 10
	je .decscnextchar
	cmp r10b, 13
	je .decscnextchar
	jmp .decscoutputencoded

.decsc:
	sub r8, 1
	jz .decodeexitprogram
	add rcx, 1
	mov r10b, byte [rcx] ; Move character from memory to register
	sub r10b, 64 ; This time we sub 64

.decscoutputencoded:
	sub r10b, 42 ; Sub 42 before modulus
	mov byte [rdx], r10b ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	jmp .decscnextchar

.decodeexitprogram:
	mov rax, r9 ; Return output size
	movdqu xmm8, [rsp]
	add rsp, 16
	movdqu xmm7, [rsp]
	add rsp, 16
	movdqu xmm6, [rsp]
	add rsp, 16
	pop rbx
	add rsp, 8
	ret

section .data
align 16
special1:	times 2 dq 0x3D0D0A003D0D0A00
special2:	times 2 dq 0x0D0A003D0D0A003D
special3:	times 2 dq 0x0A003D0D0A003D0D
special4:	times 2 dq 0x003D0D0A003D0D0A
const1:		times 2 dq 0x2A2A2A2A2A2A2A2A
specialdecode1:	times 2 dq 0x3D3D3D3D3D3D3D3D
specialdecode2:	times 2 dq 0x0A0D0A0D0A0D0A0D
specialdecode3:	times 2 dq 0x0D0A0D0A0D0A0D0A
specialdecode4:	times 2 dq 0x4040404040404040
decodeconst3:	ddq	0x000000000000000000000000000000FF
decodeconst4:	ddq	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00
decodeconst1:	 dq 0xFFFFFFFFFFFFFFFF
decodeconst2:	 db 0x000000FF