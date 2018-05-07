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
	sub rsp, 8 ; Align the stack to 16, I do not understand why it's not already align to 16. 
	push r12 ; calling convention demands saving various registers
	push r13
	push r14
	push r15

	%ifidn __OUTPUT_FORMAT__, win64 ; Windows calling convention
		sub rsp, 160
		vmovdqa [rsp+16*0], xmm6
		vmovdqa [rsp+16*1], xmm7
		vmovdqa [rsp+16*2], xmm8
		vmovdqa [rsp+16*3], xmm9
		vmovdqa [rsp+16*4], xmm10
		vmovdqa [rsp+16*5], xmm11
		vmovdqa [rsp+16*6], xmm12
		vmovdqa [rsp+16*7], xmm13
		vmovdqa [rsp+16*8], xmm14
		vmovdqa [rsp+16*9], xmm15
	%endif

	mov r9, outputarray ; Memory address of outputarray, will use this to get the size of the output later
	mov r11, 4 ; The maximum length of each line is 128 characters, 4 iterations will result in adequate results. 4*32=128

align 16
.encodeset:
	vmovaps ymm0, [inputarray] ; Read 32 bytes from memory
	vpaddb ymm0, [const1] ; +42 as per yEnc spec

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
.encodeillegalcharacters:
	vpxor xmm10, xmm10
	vpxor xmm11, xmm11
	vpxor xmm12, xmm12
	
	; Add 64 to every byte in the mask
	vpand ymm9, ymm1, [specialEncode]
	vpaddb ymm0, ymm9

	vpxor ymm7, ymm7 ; Need some zeroes
	vpbroadcastb ymm5, [specialEqual] ; Escape character
	vpunpcklbw ymm5, ymm0 ; Unpack lower half of data
	vpunpcklbw ymm7, ymm1 ; Unpack lower half of mask
	vpsrldq ymm7, 1 ; Shift data register 1 byte to the right to align with [writebytes]
	vpor ymm6, ymm7, [writebytes] ; Add masks together

	;--------------------------- Lower 8 bytes of the *low* part of ymm5 --- START
	
	vmovq r12, xmm5
	vmovq r13, xmm6
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--
	vpsrldq xmm14, xmm5, 8 ; Shift mask register 8 bytes to the right
	vpsrldq xmm15, xmm6, 8 ; Shift mask register 8 bytes to the right
	vmovq r12, xmm14
	vmovq r13, xmm15
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--------------------------- Lower 8 bytes of the *low* part of ymm5 --- END
	
	;--------------------------- Lower 8 bytes of the *high* part of ymm5 --- START SAVE DATA
	; Seems simpler to just save the data here and process/write the data in order later
	; If nothing else, it skips on having to keep track of a bunch of extra registers
	vextracti128 xmm10, ymm5, 1
	vextracti128 xmm11, ymm6, 1
	;--------------------------- Lower 8 bytes of the *high* part of ymm5 --- END SAVE DATA
	
	vmovaps ymm7, [specialNull]
	vmovaps ymm5, [specialEqual] ; Escape character
	vpunpckhbw ymm5, ymm5, ymm0 ; Unpack higher half of data
	vpunpckhbw ymm7, ymm7, ymm1 ; Unpack higher half of mask
	vpsrldq ymm7, 1 ; Shift data register 1 byte to the right to align with ymm6
	vpor ymm6, ymm7, [writebytes] ; Add masks together

	;--------------------------- Higher 8 bytes of the *low* part of ymm5 --- START
	vmovq r12, xmm5
	vmovq r13, xmm6
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--
	vpsrldq xmm14, xmm5, 8 ; Shift mask register 8 bytes to the right
	vpsrldq xmm15, xmm6, 8 ; Shift mask register 8 bytes to the right
	vmovq r12, xmm14
	vmovq r13, xmm15
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--------------------------- Higher 8 bytes of the *low* part of ymm5 --- END
	
	;--------------------------- Lower 8 bytes of the *high* part of ymm5 --- START PROCESSING
	vmovq r12, xmm10
	vmovq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--
	vpsrldq xmm10, 8 ; Shift mask register 8 bytes to the right
	vpsrldq xmm11, 8 ; Shift mask register 8 bytes to the right
	vmovq r12, xmm10
	vmovq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--------------------------- Lower 8 bytes of the *high* part of ymm5 --- END PROCESSING
	
	;--------------------------- Higher 8 bytes of the *high* part of ymm5 --- START
	vextracti128 xmm10, ymm5, 1
	vextracti128 xmm11, ymm6, 1
	vmovq r12, xmm10
	vmovq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--
	vpsrldq xmm10, 8 ; Shift mask register 8 bytes to the right
	vpsrldq xmm11, 8 ; Shift mask register 8 bytes to the right
	vmovq r12, xmm10
	vmovq r13, xmm11
	pext rax, r12, r13
	mov qword [outputarray], rax
	
	vmovq xmm12, r13
	vpmovmskb r14, xmm12
	popcnt r10, r14
	add outputarray, r10 ; add however many bytes were written
	;--------------------------- Higher 8 bytes of the *high* part of ymm5 --- END

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
.done:
	sub outputarray, r9 ; subtract original position from current and we get the size
	mov rax, outputarray ; Return output size
	add rax, inputsize ; correct for input not being a multiple of 16.

	%ifidn __OUTPUT_FORMAT__, win64 ; Windows calling convention
		vmovdqa xmm6, [rsp+16*0]
		vmovdqa xmm7, [rsp+16*1]
		vmovdqa xmm8, [rsp+16*2]
		vmovdqa xmm9, [rsp+16*3]
		vmovdqa xmm10, [rsp+16*4]
		vmovdqa xmm11, [rsp+16*5]
		vmovdqa xmm12, [rsp+16*6]
		vmovdqa xmm13, [rsp+16*7]
		vmovdqa xmm14, [rsp+16*8]
		vmovdqa xmm15, [rsp+16*9]
		add rsp, 160
	%endif

	pop r15
	pop r14
	pop r13 ; restore some registers to their original state
	pop r12
	add rsp, 8 ; Reset
	ret

section .data align=32
specialNull:		times 4 dq 0x0000000000000000
specialEqual:		times 4 dq 0x3D3D3D3D3D3D3D3D
specialLF:			times 4 dq 0x0A0A0A0A0A0A0A0A
specialCR:			times 4 dq 0x0D0D0D0D0D0D0D0D
specialSpace:	times 4 dq 0x2020202020202020
writebytes:		times 4 dq 0xFF00FF00FF00FF00
const1:				times 4 dq 0x2A2A2A2A2A2A2A2A
specialEncode:	times 4 dq 0x4040404040404040
decodeconst3:	dq 0x00000000000000FF
						dq 0x0000000000000000
decodeconst4:	dq 0xFFFFFFFFFFFFFF00
						dq 0xFFFFFFFFFFFFFFFF