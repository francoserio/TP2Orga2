extern free
extern malloc

section .data

ceroCinco: dd 0.5, 0.5, 0.5, 0.5
negativos: DD -1.0, -1.0, -1.0, -1.0
andprimeros4: DD 0x00000000, 0x00000000, 0x00000000, 0xFFFFFFFF
andsegundos4: DD 0x00000000, 0x00000000, 0xFFFFFFFF, 0x00000000
andterceros4: DD 0x00000000, 0xFFFFFFFF, 0x00000000, 0x00000000
andcuartos4: DD 0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000
primeroNegativo: DD -1.0, 1.0, 1.0, 1.0

section .text

%define offset_fluid_solver_N 0
%define offset_fluid_solver_dt 4
%define offset_fluid_solver_diff 8
%define offset_fluid_solver_visc 12
%define offset_fluid_solver_u 16
%define offset_fluid_solver_v 24
%define offset_fluid_solver_u_prev 32
%define offset_fluid_solver_v_prev 40
%define offset_fluid_solver_dens 48
%define offset_fluid_solver_dens_prev 56

global solver_set_bnd	;solver en rdi, b en esi, x en rdx
solver_set_bnd:
	push rbp				;alineada
	mov rsp, rbp
	push rbx				;desalineada
	push r12				;alineada
	push r13				;desalineada
	push r14				;alineada
	push r15				;desalineada
	sub rsp, 8				;alineada

	xor rbx, rbx
	xor r15, r15
	xor r14, r14
	xor r13, r13
	xor r12, r12
	xor r11, r11
	xor r10, r10
	xor r9, r9
	xor r8, r8
	;pongo en 0 rbx, r14, r13, r12, r11, r10, r9, r8

	pxor xmm11, xmm11
	pxor xmm4, xmm4
	movups xmm11, [ceroCinco]	;xmm11 = | 0.5 | 0.5 | 0.5 | 0.5 |
	movdqu xmm4, [negativos]									;xmm4 = | -1.0 | -1.0 | -1.0 | -1.0 |

	mov r15, rdx															;r15 = x

	mov ebx, [rdi + offset_fluid_solver_N]		;rbx = N
	mov r9d, ebx
	dec r9																		;r9 = N - 1
	mov r8, r15
	mov r13, rsi															;r13 = b

	pxor xmm1, xmm1
	mov r12, rbx
	shr r12, 2																;r12 = r12 / 4
	cmp r13, 1
	je .ciclo1					;b == 1
	cmp r13, 2
	je .ciclo2					;b == 2
.ciclo1:							;b == 1
	cmp r12, r11
	je .finCiclo1
	;ahora x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];
	pxor xmm0, xmm0
	mov r14, r15
	mov r10, r15
	lea r15, [r15 + rbx*4]
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mov r15, r14
	movdqu [r15], xmm0
	mov r15, r14
	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila
	xor rax, rax
	mov rax, r9
	mul ebx
	shl rax, 32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]		;voy a la anteultima fila
	pxor xmm0, xmm0
	mov r14, r15
	movdqu xmm0, [r15]				;| x[IX(i+3, N)] | x[IX(i+2, N)] | x[IX(i+1, N)] | x[IX(i, N)] |
	mov r15, r14
	lea r15, [r15 + rbx*4]
	movdqu [r15], xmm0
	mov r15, r10
	lea r15, [r15 + 16]
	inc r11
	jmp .ciclo1
.ciclo2:						;b == 2
	cmp r12, r11
	je .finCiclo2
	;x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];
	pxor xmm0, xmm0
	mov r14, r15
	mov r10, r15
	lea r15, [r15 + rbx*4]
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)]
	mulps xmm0, xmm4					;| -x[IX(i+3, 1)] | -x[IX(i+2, 1)] | -x[IX(i+1, 1)] | -x[IX(i, 1)] |
	mov r15, r14
	movdqu [r15], xmm0
	mov r15, r14
	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila
	xor rax, rax
	mov rax, r9						;r11 = r8
	mul ebx								;r11 = r8*r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]		;estoy en la anteultima fila
	pxor xmm0, xmm0
	mov r14, r15
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mov r15, r14
	lea r15, [r15 + rbx*4]
	movdqu [r15], xmm0
	mov r15, r10
	lea r15, [r15 + 16]
	inc r11
	jmp .ciclo2
.finCiclo1:
	xor r13, r13
	mov r15, r8
.primeraColumnaCiclo1:
	cmp r13, rbx
	je .ultimaColumnaCiclo1
	mov r11, r15
	lea r15, [r15 + 4]
	mov r12, [r15]
	xor rax, rax
	mov rax, -1
	mul r12
	mov [r11], r12
	lea r15, [r15 + rbx*4]
	inc r13
	jmp .primeraColumnaCiclo1
.finCiclo2:
	xor r13, r13
	mov r15, r8
.primeraColumnaCiclo2:
	cmp r13, rbx
	je .ultimaColumnaCiclo2
	mov r11, r15
	lea r15, [r15 + 4]
	mov r12, [r15]
	mov [r11], r12
	lea r15, [r15 + rbx*4]
	inc r13
	jmp .primeraColumnaCiclo2
.ultimaColumnaCiclo1:
	xor r13, r13
	mov r15, r8
.cicloUltimaColumna1:
	cmp r13, rbx
	je .fin
	lea r15, [r15 + r9*4]
	mov r12, [r15]
	lea r15, [r15 + 4]
	xor rax, rax
	mov rax, -1
	mul r12
	mov [r15], r12
	inc r13
	lea r15, [r15 + rbx*4]
	jmp .cicloUltimaColumna1
.ultimaColumnaCiclo2:
	xor r13, r13
	mov r15, r8
.cicloUltimaColumna2:
	cmp r13, rbx
	je .fin
	lea r15, [r15 + r9*4]
	mov r12, [r15]
	lea r15, [r15 + 4]
	mov [r15], r12
	lea r15, [r15 + rbx*4]
	inc r13
	jmp .cicloUltimaColumna2
.fin:
	pxor xmm0, xmm0
	pxor xmm1, xmm1

	mov r15, r8
	lea r15, [r15 + 4]
	mov r14, [r15]			;x[IX(1,0  )]
	vpinsrq xmm0, r14, 0

	mov r15, r8
	lea r15, [r15 + rbx*4]
	mov r14, [r15]			;x[IX(0  ,1)]
	vpinsrq xmm1, r14, 0

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul rbx
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	mov r14, [r15]			;x[IX(0  ,N)]
	vpinsrq xmm1, r14, 32

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	inc r9
	inc r9
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4 + 4]
	mov r14, [r15]			;x[IX(1,N+1)]
	vpinsrq xmm0, r14, 32

	mov r15, r8
	lea r15, [r15 + rbx*4]
	mov r14, [r15]			;x[IX(N,0  )]
	vpinsrq xmm0, r14, 64

	mov r15, r8
	lea r15, [r15 + rbx*4]
	lea r15, [r15 + r9*4]
	mov r14, [r15]			;x[IX(N+1,1)]
	vpinsrq xmm1, r14, 64

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + rbx*4]
	mov r14, [r15]			;x[IX(N,N+1)]
	vpinsrq xmm0, r14, 96

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul rbx
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + r9*4]
	mov r14, [r15]			;x[IX(N+1,N)])
	vpinsrq xmm1, r14, 96

	mulps xmm0, xmm11
	mulps xmm1, xmm11
	addps xmm0, xmm1

	mov r15, r8
	extractps r14, xmm0, 0
	mov [r15], r14

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	extractps r14, xmm0, 32
	mov [r15], r14

	mov r15, r8
	lea r15, [r15 + r9*4]
	extractps r14, xmm0, 64
	mov [r15], r14

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + r9*4]
	extractps r14, xmm0, 96
	mov [r15], r14

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
