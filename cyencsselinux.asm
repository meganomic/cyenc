default rel

section .text ;bits 64
global encode
global decode
align 16

encode:
	sub rsp, 8 ; Stack alignment
	push r12 ; save r12 and r13, I need those registers for stuff
	push r13
	push rbx

	sub rsp,16 ; 16 enough but want correct alignment
	movdqu [rsp], xmm6

	xor rbx, rbx
	xor r9, r9
	xor r11, r11

	movaps xmm6, [special4]
	movaps xmm5, [special3]
	movaps xmm4, [special2]
	movaps xmm3, [special1]

.encodeset:
	cmp rdx, 16
	jle .specialchar ; The last 8 or less characters need special treatment
	movdqu xmm0, [rdi]
	paddb xmm0, [const1] ; + 42

	pxor xmm1, xmm1
	movaps xmm7, xmm0 ; temporary copy
	pcmpeqb xmm7, xmm3
	por xmm1, xmm7
	movaps xmm7, xmm0
	pcmpeqb xmm7, xmm4
	por xmm1, xmm7
	movaps xmm7, xmm0
	pcmpeqb xmm7, xmm5
	por xmm1, xmm7
	movaps xmm7, xmm0
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
	movdqu [rsi], xmm0 ; Move encoded byte to output array
	add rsi, 16 ; increase output array pointer
	add rdi, 16 ; increase input pointer
	add r9, 16 ; Increase size of output
	add r11, 16 ; Increase line length
	sub rdx, 16 ; Done encoding 16 bytes
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
	mov byte [rsi], al ; Move encoded byte to output array
	add rsi, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	ror rax, 8
	sub rdx, 1
	jz .exitprogram
	cmp r11, 127
	jge .scnewlinemulti
	cmp r13, 8
	je .scmultientry
	jmp .scmulti

.scmulti2:
	add al, 64 ; This time we add 64
	mov byte [rsi], 61 ; Add escape character
	add rsi, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	jmp .scnextcharmulti

.nextset:
	add rdi, 16
	jmp .encodeset

.scnewlinemulti:
	mov word [rsi], 0x0A0D ; \r\n
	add rsi, 2 ; increase output array pointer
	add r9, 2 ; Increase size of output
	xor r11, r11
	cmp r13, 8
	je .scmultientry
	jmp .scmulti

.scnewline:
	mov word [rsi], 0x0A0D ; \r\n
	add rsi, 2 ; increase output array pointer
	add r9, 2 ; Increase size of output
	xor r11, r11

.scnextchar:
	add rdi, 1
	sub rdx, 1
	jz .exitprogram

.specialchar:
	add r13, 1
	mov r10b, byte [rdi] ; Move character from memory to register
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
	mov byte [rsi], 61 ; Add escape character
	add rsi, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length

.scoutputencoded:
	mov byte [rsi], r10b ; Move encoded byte to output array
	add rsi, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	add r11, 1 ; Increase line length
	cmp r11, 127
	jge .scnewline
	jmp .scnextchar

.exitprogram:
	mov rax, r9 ; Return output size
	movdqu xmm6, [rsp]
	add rsp,16
	pop rbx
	pop r13 ; restore some registers to their original state
	pop r12
	add rsp, 8 ; Stack alignment
	ret

decode:
	sub rsp, 8 ; Stack alignment
	push rbx
	movaps xmm3, [specialdecode1]
	movaps xmm4, [specialdecode2]
	movaps xmm5, [specialdecode3]
	xor rbx, rbx

.decodeset:
	cmp rdx, 16
	jle .decspecialchar ; The last 8 or less characters need special treatment
	pxor xmm1, xmm1
	movdqu xmm0, [rdi] ; Read from memory

	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, xmm3 ; Check for special chars
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm4
	por xmm1, xmm2
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm5
	por xmm1, xmm2
	movq r10, xmm1
	cmp r10, 0
	jne .decodemultientry ; Let's do special stuff!
	psrldq xmm1, 8
	movq r10, xmm1
	cmp r10, 0
	jne .decodemultientry ; Let's do special stuff!
	cmp bl, 1 ; Check if there was a = last in last batch
	je .decodemultientry
	psubb xmm0, [const1] ; - 42
	movdqu [rsi], xmm0 ; Move decoded byte to output array
	add rsi, 16 ; increase output array pointer
	add rdi, 16 ; increase input pointer
	add rcx, 16 ; Increase size of output
	sub rdx, 16 ; Done encoding 16 bytes
	jmp .decodeset ; Encode another 16 bytes

.decodemultientry:
	xor r11, r11
	movq rax, xmm0 ; Move to gpr so we can do stuff
	cmp rax, 0
	jz .decodenextset ; If it's zero it means we've already done all the bytes in xmm0
	psrldq xmm0, 8 ; Shift bytes

.decodemulti:
	add r11, 1
	cmp bl, 1
	je .decfixbreak
	cmp al, 61
	je .decodespecial
	cmp al, 10
	je .decskipbyte
	cmp al, 13
	je .decskipbyte

.decodenextcharmulti:
	sub al, 42 ; Decode
	mov byte [rsi], al ; Move decoded byte to output array
	add rsi, 1 ; increase output array pointer
	add rcx, 1 ; Increase size of output
	sub rdx, 1
	jz .decodeexitprogram
	cmp r11, 8
	je .decodemultientry
	ror rax, 8
	jmp .decodemulti

.decskipbyte:
	sub rdx, 1
	jz .decodeexitprogram
	cmp r11, 8
	je .decodemultientry
	ror rax, 8
	jmp .decodemulti

.decodespecial:
	sub rdx, 1
	jz .decodeexitprogram
	add bl, 1
	cmp r11, 8
	je .decodemultientry
	ror rax, 8
	add r11, 1

.decfixbreak:
	sub al, 64 ; Decode
	sub bl, 1
	jmp .decodenextcharmulti

.decodenextset:
	add rdi, 16
	jmp .decodeset

.decscnextchar:
	add rdi, 1
	sub rdx, 1
	jz .decodeexitprogram

.decspecialchar:
	mov r10b, byte [rdi] ; Move character from memory to register
	cmp r10b, 61
	je .decsc
	cmp r10b, 10
	je .decscnextchar
	cmp r10b, 13
	je .decscnextchar
	jmp .decscoutputencoded

.decsc:
	sub rdx, 1
	jz .decodeexitprogram
	add rdi, 1
	mov r10b, byte [rdi] ; Move character from memory to register
	sub r10b, 64 ; This time we sub 64

.decscoutputencoded:
	sub r10b, 42 ; Sub 42 before modulus
	mov byte [rsi], r10b ; Move encoded byte to output array
	add rsi, 1 ; increase output array pointer
	add rcx, 1 ; Increase size of output
	jmp .decscnextchar

.decodeexitprogram:
	mov rax, rcx ; Return output size
	pop rbx
	add rsp, 8 ; Stack alignment
	ret

section .data
align 16
special1:	times 2 dq 0x3D0D0A003D0D0A00
special2:	times 2 dq 0x0D0A003D0D0A003D
special3:	times 2 dq 0x0A003D0D0A003D0D
special4:	times 2 dq 0x003D0D0A003D0D0A
const1:		times 2 dq 0x2A2A2A2A2A2A2A2A
specialdecode1: times 2 dq 0x3D0A0D3D0A0D3D0A
specialdecode2: times 2 dq 0x0A0D3D0A0D3D0A0D
specialdecode3: times 2 dq 0x0D3D0A0D3D0A0D3D
