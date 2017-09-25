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

section .data 
ceroCinco: dd 0.5, 0.5, 0.5, 0.5
negativosSeg: dd 1.0, 1.0, -1.0, -1.0
negativosPrim: dd -1.0, -1.0, 1.0, 1.0

;global solver_lin_solve
solver_lin_solve:
	

;global solver_set_bnd 		;solver en rdi, b en esi, x en rdx
solver_set_bnd:
	push rbp				;alineada
	mov rsp, rbp
	push rbx				;desalineada
	push r12				;alineada
	push r13				;desalineada
	push r14				;alineada
	push r15				;desalineada
	sub rsp, 8				;alineada
	xor r12d, r12d			;r12 = 0
	; inc r12d				;r12 = 1
	mov r15, rdx			;r15 = x
	mov ebx, [rdi + offset_fluid_solver_N]		;ebx = N
	shr ebx, 2				;ebx = N/4
	mov r13d, esi			;r12d = b
	pxor xmm3, xmm3
	pxor xmm4, xmm4
	pxor xmm5, xmm5
	movdqu xmm3, [ceroCinco]	; | 0.5 | 0.5 | 0.5 | 0.5 |
	movdqu xmm4, [negativosPrim]	; | -1.0 | -1.0 | 1.0 | 1.0 |
	movdqu xmm5, [negativosSeg]		; | 1.0 | 1.0 | -1.0 | -1.0 |
	cmp r13d, 1					
	je .ciclo1					;b == 1
	cmp r13d, 2
	je .ciclo2					;b == 2	
.ciclo1:						;b == 1
	; xor r11d, r11d
	; cmp r12d, ebx
	; je .fin
	; pxor xmm0, xmm0				; | 0 | 0 | 0 | 0 |
	; pxor xmm1, xmm1 			; | 0 | 0 | 0 | 0 |
	; mov r9d, ebx+2				; r9d = N + 2
	; mov r8d, ebx+1				; r8d = N + 1

	; mov r11d, [r15 + r9d*r12d + 1]	;r11d = x[IX(1,i)]
	; insertps xmm0, r11d, 0		;xmm0 = | 0 | 0 | 0 | x[IX(1,i)] |
	; mov r11d, [r15 + r9d*r12d + ebx];r11d = x[IX(N,i)]
	; insertps xmm0, r11d, 32		;xmm0 = | 0 | 0 | x[IX(N,i)] | x[IX(1,i)] |
	; mov r11d, [r15 + r9d + r12d]	;r11d = x[IX(i,1)]
	; insertps xmm0, r11d, 64		;xmm0 = | 0 | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	; mov r11d, [r15 + r9d*ebx + r12d];r11d = x[IX(i,N)]
	; insertps xmm0, r11d, 96		;xmm0 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |

	; movdqu xmm1, xmm0			;xmm1 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	; mulps xmm1, xmm4			;xmm1 = | -x[IX(i,N)] | -x[IX(i,1)] | -x[IX(N,i)] | -x[IX(1,i)] |

	lea r12d, [r12d + 4]
	jmp .ciclo1

.fin:

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret

;global solver_project
solver_project:
	