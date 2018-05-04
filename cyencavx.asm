global encode
global decode

default rel

%ifidn __OUTPUT_FORMAT__, win64 ; Windows calling convention
	%define outputarray rcx
	%define inputarray rdx
	%define inputsize r8
%elifidn __OUTPUT_FORMAT__, elf64 ; Linux calling convention
	%define outputarray rdi
	%define inputarray rsi
	%define inputsize rdx
%endif

section .text
align 16
encode: ; encode(outputarray, inputarray, inputsize) returns the size of the output
	push r12 ; calling convention demands saving various registers
	push r13
	push r14
	push r15
	push rdi
	push rbx
	push rbp
	push rsi

	mov r9, outputarray ; Memory address of outputarray, will use this to get the size of the output later
	mov r11, 4 ; The maximum length of each line is 128 characters, 4 iterations will result in adequate results. 4*32=128

	%ifidn __OUTPUT_FORMAT__, win64 ; Windows calling convention
		mov rdi, outputarray ; Need to keep the address to the output memory location in RDI because of maskmovdqu
		%define outputarray rdi
	%endif
	

align 16
.encodeset:
	vmovaps ymm0, [inputarray] ; Read 32 bytes from memory
	vpaddb ymm0, ymm0, [const1] ; +42 as per yEnc spec

	vpcmpeqb ymm1, ymm0, [specialNull] ; 0x00
	vpcmpeqb ymm2, ymm0, [specialEqual] ; 0x3D
	vpcmpeqb ymm3, ymm0, [specialLF] ; 0x0A
	vpcmpeqb ymm4, ymm0, [specialCR] ; 0x0D
	vpor ymm1, ymm2 ; Merge compare results
	vpor ymm1, ymm3
	vpor ymm1, ymm4

	vptest ymm1, ymm1
	jnz .encodeillegalcharacters

	vmovdqu [outputarray], ymm0 ; Write to memory, no additional processing needed
	add outputarray, 32
	add inputarray, 32
	sub inputsize, 32
	jbe .done ; Yay! It's done!
	sub r11, 1
	jz .newline
	jmp .encodeset

align 16
.newline:
	mov word [outputarray], 0x0A0D ; \r\n
	add outputarray, 2 ; increase output array pointer
	mov r11, 4 ; Reset counter
	jmp .encodeset

align 16
.encodeillegalcharacters:
	pxor xmm10, xmm10
	pxor xmm11, xmm11
	pxor xmm12, xmm12
	
	vpand ymm9, ymm1, [specialdecode4]
	vpaddb ymm0, ymm0, ymm9

	vmovaps ymm7, [specialNull]
	vmovaps ymm5, [specialEqual] ; Escape character
	vpunpcklbw ymm5, ymm5, ymm0 ; Unpack lower half of data
	vpunpcklbw ymm7, ymm7, ymm1 ; Unpack lower half of mask
	vpsrldq ymm7, ymm7 ,1 ; Shift data register 1 byte to the right to align with [writebytes]
	vpor ymm6, ymm7, [writebytes] ; Add masks together

	;--------------------------- first split
	
	movq r12, xmm5
	movq r13, xmm6
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	
	psrldq xmm5, 8 ; Shift mask register 8 bytes to the right
	psrldq xmm6, 8 ; Shift mask register 8 bytes to the right
	movq r12, xmm5
	movq r13, xmm6
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	
	;--------------------------- second split
	
	vextracti128 xmm10, ymm5, 1
	vextracti128 xmm11, ymm6, 1
	movq r12, xmm10
	movq r13, xmm11
	pext rax, r12, r13
	;mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	;add outputarray, r10 ; add however many bytes were written
	
	psrldq xmm10, 8 ; Shift mask register 8 bytes to the right
	psrldq xmm11, 8 ; Shift mask register 8 bytes to the right
	movq r12, xmm10
	movq r13, xmm11
	pext rsi, r12, r13
	;mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r15, r14
	;add outputarray, r10 ; add however many bytes were written

	;---------------------------
	
	
	vmovaps ymm7, [specialNull]
	vmovaps ymm5, [specialEqual] ; Escape character
	vpunpckhbw ymm5, ymm5, ymm0 ; Unpack higher half of data
	vpunpckhbw ymm7, ymm7, ymm1 ; Unpack higher half of mask
	vpsrldq ymm7, 1 ; Shift data register 1 byte to the right to align with ymm6
	vpor ymm6, ymm7, [writebytes] ; Add masks together

	;--------------------------- first split
	
	movq r12, xmm5
	movq r13, xmm6
	pext rbx, r12, r13
	mov qword [outputarray], rbx
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt rbp, r14
	add outputarray, rbp ; add however many bytes were written
	
	psrldq xmm5, 8 ; Shift mask register 8 bytes to the right
	psrldq xmm6, 8 ; Shift mask register 8 bytes to the right
	movq r12, xmm5
	movq r13, xmm6
	pext rbx, r12, r13
	mov qword [outputarray], rbx
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt rbp, r14
	add outputarray, rbp ; add however many bytes were written
	
	
	;wtf cancer? it makes no sense
	; data is stored in a 1 3 2 4 order in the ymm register for some reason I can't figure out
	mov qword [outputarray], rax
	add outputarray, r10 ; add however many bytes were written
	mov qword [outputarray], rsi
	add outputarray, r15 ; add however many bytes were written
	
	
	;--------------------------- second split
	
	vextracti128 xmm10, ymm5, 1
	vextracti128 xmm11, ymm6, 1
	movq r12, xmm10
	movq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	
	psrldq xmm10, 8 ; Shift mask register 8 bytes to the right
	psrldq xmm11, 8 ; Shift mask register 8 bytes to the right
	movq r12, xmm10
	movq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	movq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written

	;---------------------------
	
	
	
	add inputarray, 32
	sub inputsize, 32
	jbe .done ; Yay! It's done!
	sub r11, 1
	jz .newline
	jmp .encodeset

align 16
.done:
	sub outputarray, r9 ; subtract original position from current and we get the size
	mov rax, outputarray ; Return output size
	add rax, inputsize ; correct for input not being a multiple of 16.
	pop rsi
	pop rbp
	pop rbx
	pop rdi
	pop r15
	pop r14
	pop r13 ; restore some registers to their original state
	pop r12
	ret

section .data align=32
specialNull:		times 4 dq 0x0000000000000000
specialEqual:		times 4 dq 0x3D3D3D3D3D3D3D3D
specialLF:			times 4 dq 0x0A0A0A0A0A0A0A0A
specialCR:			times 4 dq 0x0D0D0D0D0D0D0D0D
specialSpace:	times 4 dq 0x2020202020202020
writebytes:		times 4 dq 0xFF00FF00FF00FF00
const1:				times 4 dq 0x2A2A2A2A2A2A2A2A
specialdecode4:	times 4 dq 0x4040404040404040
decodeconst3:	dq 0x00000000000000FF
						dq 0x0000000000000000
decodeconst4:	dq 0xFFFFFFFFFFFFFF00
						dq 0xFFFFFFFFFFFFFFFF