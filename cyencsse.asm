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

	xor rbx, rbx
	xor r9, r9
	xor r11, r11

	movaps xmm3, [const1] ; 0x40
	mov r9, rdx ; original position of outputarray
	sub r8, 16
align 16
.encodeset:
	;cmp r8, 16
	;jle .specialchar ; The last 8 or less characters need special treatment
	movaps xmm0, [rcx]
	paddb xmm0, xmm3 ; +42

	pxor xmm1, xmm1 ; zero mask register
	movaps xmm2, xmm0
	pcmpeqb xmm2, xmm1 ; 0x00
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0 ; temporary copy
	pcmpeqb xmm2, [special1] ; 0x3D
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0
	pcmpeqb xmm2, [special2] ; 0x0A
	por xmm1, xmm2 ; save compare results
	movaps xmm2, xmm0
	pcmpeqb xmm2, [special3] ; 0x0D
	por xmm1, xmm2 ; save compare results

	movd r10, xmm1
	movd rax, xmm0
	mov rbx, 1
	cmp r10, 0
	jne .scmultientry
	cmp r11, 119
	jge .scmultientry ; Need special handling if we go over line length limit
	mov qword [rdx], rax
	add rcx, 8
	add rdx, 8
	add r11, 8
	;sub r8, 8
align 16
.parttwo:
	mov rbx, 0
	psrldq xmm1, 8
	psrldq xmm0, 8
	movd r10, xmm1
	movd rax, xmm0
	cmp r10, 0
	jne .scmultientry
	cmp r11, 119
	jge .scmultientry ; Need special handling if we go over line length limit
	mov qword [rdx], rax
	add rcx, 8
	add rdx, 8
	add r11, 8
	sub r8, 16
	jbe .specialcharentry
	jmp .encodeset ; Encode another 8 bytes

align 16
.parttwocheck:
	add rcx, 8
	cmp rbx, 1
	je .parttwo
	sub r8, 16
	jbe .specialcharentry
	jmp .encodeset

align 16
.scmultientry:
	mov r13, 9

.scmulti:
	sub r13, 1
	jz .parttwocheck
	cmp r10b, 0xFF
	je .scmulti2

.scnextcharmulti:
	mov byte [rdx], al ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r11, 1 ; Increase line length
	shr rax, 8
	shr r10, 8
	cmp r11, 127
	jge .scnewlinemulti
	jmp .scmulti

align 16
.scmulti2:
	add al, 64 ; This time we add 64
	mov byte [rdx], 61 ; Add escape character
	add rdx, 1 ; increase output array pointer
	add r11, 1 ; Increase line length
	jmp .scnextcharmulti

align 16
.scnewlinemulti:
	mov word [rdx], 0x0A0D ; \r\n
	add rdx, 2 ; increase output array pointer
	xor r11, r11
	jmp .scmulti
align 16
.specialcharentry:
	add r8, 16
	jmp .specialchar

.scnewline:
	mov word [rdx], 0x0A0D ; \r\n
	add rdx, 2 ; increase output array pointer
	xor r11, r11

.scnextchar:
	add rcx, 1
	sub r8, 1
	jz .exitprogram

.specialchar:
	add r13, 1
	mov r10b, byte [rcx] ; Move character from memory to register
	add r10b, 42 ; Add 42
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
	add r11, 1 ; Increase line length

.scoutputencoded:
	mov byte [rdx], r10b ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r11, 1 ; Increase line length
	cmp r11, 127
	jge .scnewline
	jmp .scnextchar

.exitprogram:
	sub rdx, r9 ; subtract original position from current and we get the size
	mov rax, rdx ; Return output size
	pop rdi
	pop rbx
	pop r13 ; restore some registers to their original state
	pop r12
	add rsp, 8
	ret

align 16
decode:
	sub rsp, 8
	push rbx

	xor rbx, rbx
	xor r11, r11

.decodeset:
	cmp r8, 16
	jle .decspecialchar ; The last 8 or less characters need special treatment

	pxor xmm1, xmm1 ; zero mask register
	movaps xmm0, [rcx] ; Read from memory

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
	movd r10, xmm3
	rol r10, 8
	cmp r10b, 0xFF ; Check if last byte is an escape character
	jne .cont2
	mov byte [lastchar], 0xFF

.cont2:
	mov r11b, 2
.retfromwset:
	movd r10, xmm1 ; List of bytes to skip
	movd rax, xmm0 ; Move to gpr so we can do stuff
	cmp r10, 0
	je .writeset
	mov r12b, 8
.compactbytes:
	cmp r10b, 0xFF
	je .skipbyte
	mov byte [rdx], al
	add r9, 1
	add rdx, 1

.skipbyte:
	shr r10, 8
	shr rax, 8
	sub r12b, 1
	jnz .compactbytes

	psrldq xmm1, 8
	psrldq xmm0, 8
	sub r11b, 1
	jnz .retfromwset

	add rcx, 16 ; increase input pointer
	sub r8, 16 ; Done encoding 16 bytes
	jmp .decodeset ; Encode another 16 bytes

align 16
.writeset:
	mov qword [rdx], rax
	add r9, 8
	add rdx, 8
	psrldq xmm1, 8 ; right shift by 8 bytes
	psrldq xmm0, 8 ; right shift by 8 bytes
	sub r11b, 1
	jnz .retfromwset

	add rcx, 16 ; increase input pointer
	sub r8, 16 ; Done encoding 16 bytes
	jmp .decodeset

.decscnextchar:
	add rcx, 1
	sub r8, 1
	jz .decodeexitprogram

.decspecialchar:
	mov r10b, byte [rcx] ; Move character from memory to register
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
	;sub r8, 1
	mov byte [lastchar], 0x00
	sub r10b, 64 ; This time we sub 64
	jmp .decscoutputencoded

.decsc:
	sub r8, 1
	jz .decodeexitprogram2
	add rcx, 1
	mov r10b, byte [rcx] ; Move character from memory to register
	sub r10b, 64 ; This time we sub 64

.decscoutputencoded:
	sub r10b, 42 ; -42
	mov byte [rdx], r10b ; Move encoded byte to output array
	add rdx, 1 ; increase output array pointer
	add r9, 1 ; Increase size of output
	jmp .decscnextchar

.decodeexitprogram2:
	mov byte [lastchar], 0xFF ; if the last character is a escape character, that information needs to be saved

.decodeexitprogram:
	mov rax, r9 ; Return output size
	pop rbx
	add rsp, 8
	ret

section .data align=16
special1:	times 2 dq 0x3D3D3D3D3D3D3D3D
special2:	times 2 dq 0x0A0A0A0A0A0A0A0A
special3:	times 2 dq 0X0D0D0D0D0D0D0D0D
const1:		times 2 dq 0x2A2A2A2A2A2A2A2A
specialdecode4:	times 2 dq 0x4040404040404040
decodeconst3:	ddq	0x000000000000000000000000000000FF
decodeconst4:	ddq	0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00
lastchar:	db 0x00