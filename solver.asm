extern free
extern malloc

extern solver_set_bnd_c

section .data

ceroCinco: dd 0.5, 0.5, 0.5, 0.5
negativos: DD -1.0, -1.0, -1.0, -1.0
; andprimeros4: DD 0x00000000, 0x00000000, 0x00000000, 0xFFFFFFFF
; andsegundos4: DD 0x00000000, 0x00000000, 0xFFFFFFFF, 0x00000000
; andterceros4: DD 0x00000000, 0xFFFFFFFF, 0x00000000, 0x00000000
; andcuartos4: DD 0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000
; primeroNegativo: DD -1.0, 1.0, 1.0, 1.0

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

global solver_set_bnd_asm 		;solver en rdi, b en esi, x en rdx
solver_set_bnd_asm:
	push rbp				;alineada
	mov rbp, rsp
	push rbx				;desalineada
	push r12				;alineada
	push r13				;desalineada
	push r14				;alineada
	push r15				;desalineada
	sub rsp, 8			;alineada

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
	movups xmm11, [ceroCinco]									;xmm11 = | 0.5 | 0.5 | 0.5 | 0.5 |
	movups xmm4, [negativos]									;xmm4 = | -1.0 | -1.0 | -1.0 | -1.0 |

	mov r15, rdx															;r15 = x
	mov r8, r15
	mov ebx, [rdi + offset_fluid_solver_N]		;rbx = N
	mov r9d, ebx
	inc r9																		;r9 = N + 1
	inc r9																		;r9 = N + 2
	mov r13, rsi															;r13 = b
	lea r15, [r15 + 4]
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
	lea r15, [r15 + r9*4]
	movups xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mov r15, r14
	movups [r15], xmm0
	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila
	xor rax, rax
	mov rax, rbx
	mul r9
	shl rax, 32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]		;voy a la anteultima fila
	pxor xmm0, xmm0
	movups xmm0, [r15]				;| x[IX(i+3, N)] | x[IX(i+2, N)] | x[IX(i+1, N)] | x[IX(i, N)] |
	lea r15, [r15 + r9*4]
	movups [r15], xmm0
	mov r15, r10
	lea r15, [r15 + 16]
	inc r11
	jmp .ciclo1
.ciclo2:										;b == 2
	cmp r12, r11
	je .finCiclo2
	;x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];
	pxor xmm0, xmm0
	mov r14, r15
	mov r10, r15
	lea r15, [r15 + r9*4]
	movups xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)]
	mulps xmm0, xmm4					;| -x[IX(i+3, 1)] | -x[IX(i+2, 1)] | -x[IX(i+1, 1)] | -x[IX(i, 1)] |
	mov r15, r14
	movups [r15], xmm0
	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila
	xor rax, rax
	mov rax, rbx
	mul r9										;r11 = r8*r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]		;estoy en la anteultima fila
	pxor xmm0, xmm0
	movups xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mulps xmm0, xmm4					;| -x[IX(i+3, 1)] | -x[IX(i+2, 1)] | -x[IX(i+1, 1)] | -x[IX(i, 1)] |
	lea r15, [r15 + r9*4]
	movups [r15], xmm0
	mov r15, r10
	lea r15, [r15 + 16]
	inc r11
	jmp .ciclo2
.finCiclo1:
	cmp r13, 0
	je .finCiclo2
	xor r13, r13
	inc r13
	xor r11, r11
	xor r14, r14
	mov r15, r8
	lea r15, [r15 + r9*4]
	mov r14, r9
	dec r14
.primeraColumnaCiclo1:
	pxor xmm0, xmm0
	cmp r13, r14
	je .ultimaColumnaCiclo1
	mov r11, r15
	lea r15, [r15 + 4]
	insertps xmm0, [r15], 0
	mulps xmm0, xmm4
	mov r15, r11
	extractps [r15], xmm0, 0
	lea r15, [r15 + r9*4]
	inc r13
	jmp .primeraColumnaCiclo1
.finCiclo2:
	xor r14, r14
	xor r13, r13
	xor r11, r11
	inc r13
	mov r15, r8
	lea r15, [r15 + r9*4]
	mov r14, r9
	dec r14
.primeraColumnaCiclo2:
	pxor xmm0, xmm0
	cmp r13, r14
	je .ultimaColumnaCiclo2
	mov r11, r15
	lea r15, [r15 + 4]
	insertps xmm0, [r15], 0
	mov r15, r11
	extractps [r15], xmm0, 0
	lea r15, [r15 + r9*4]
	inc r13
	jmp .primeraColumnaCiclo2
.ultimaColumnaCiclo1:
	xor r14, r14
	xor r12, r12
	xor r11, r11
	xor r13, r13
	mov r14, r9
	dec r14
	mov r15, r8
	lea r15, [r15 + rbx*4]
.cicloUltimaColumna1:
	pxor xmm0, xmm0
	cmp r13, r14
	je .fin
	mov r11, r15
	insertps xmm0, [r15], 0
	mulps xmm0, xmm4
	lea r15, [r15 + 4]
	extractps [r15], xmm0, 0
	mov r15, r11
	lea r15, [r15 + r9*4]
	inc r13
	jmp .cicloUltimaColumna1
.ultimaColumnaCiclo2:
	xor r14, r14
	xor r13, r13
	xor r11, r11
	mov r14, r9
	dec r14
	mov r15, r8
	lea r15, [r15 + rbx*4]
.cicloUltimaColumna2:
	pxor xmm0, xmm0
	cmp r13, r14
	je .fin
	mov r11, r15
	insertps xmm0, [r15], 0
	lea r15, [r15 + 4]
	extractps [r15], xmm0, 0
	mov r15, r11
	lea r15, [r15 + r9*4]
	inc r13
	jmp .cicloUltimaColumna2
.fin:
	pxor xmm0, xmm0
	pxor xmm1, xmm1

	mov r15, r8
	lea r15, [r15 + 4]
	insertps xmm0, [r15], 0			;x[IX(1,0  )]

	mov r15, r8
	lea r15, [r15 + r9*4]
	insertps xmm1, [r15], 0			;x[IX(0  ,1)]

	mov r15, r8
	xor rax, rax
	mov rax, r9
	mul rbx
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	insertps xmm1, [r15], 32			;x[IX(0  ,N)]

	mov r15, r8
	xor rax, rax
	xor r13, r13
	mov r13, rbx
	inc r13
	mov rax, r13
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4 + 4]
	insertps xmm0, [r15], 32			;x[IX(1,N+1)]

	mov r15, r8
	lea r15, [r15 + rbx*4]
	insertps xmm0, [r15], 64			;x[IX(N,0  )]

	mov r15, r8
	lea r15, [r15 + r9*4]
	lea r15, [r15 + r13*4]
	insertps xmm1, [r15], 64			;x[IX(N+1,1)]

	mov r15, r8
	xor rax, rax
	mov rax, r13
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + rbx*4]
	insertps xmm0, [r15], 96			;x[IX(N,N+1)]

	mov r15, r8
	xor rax, rax
	mov rax, rbx
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + r13*4]
	insertps xmm1, [r15], 96			;x[IX(N+1,N)])

	addps xmm0, xmm1
	mulps xmm0, xmm11

	mov r15, r8
	extractps [r15], xmm0, 0

	mov r15, r8
	xor rax, rax
	mov rax, r13
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	extractps [r15], xmm0, 32

	mov r15, r8
	lea r15, [r15 + r13*4]
	extractps [r15], xmm0, 64

	mov r15, r8
	xor rax, rax
	mov rax, r13
	mul r9
	shl rax,32
	shrd rax,rdx,32
	lea r15, [r15 + rax*4]
	lea r15, [r15 + r13*4]
	extractps [r15], xmm0, 96

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret


global solver_lin_solve_asm
solver_lin_solve_asm:
	;stack frame
	push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
	push r15

	mov rbx, rdi ;rbx=rdi=solver
	mov r12, rdx ;r12=rdx=x
    mov r13, rcx ;r13=rcx=x0
    extractps r14, xmm0, 0 ;r14=xmm0=a
	extractps r15, xmm1, 0 ;r15=xmm1=c
	;mov [rsp], rsi ;b esta en la pila
	;sub rsp, 8
	;mov dword [rsp], NULL ;k esta en la pila
	;sub rsp, 8
	sub rsp, 8 ;reservo memoria para b

	mov [rsp+1], esi ;b esta en la pila

	sub rsp, 8 ;reservo memoria para k
	mov dword [rsp+1], 0 ;k esta en la pila

	sub rsp, 8 ;ahora esta alineada la pila

	;xmm0=0|0|0|a y quiero que xmm0=a|a|a|a
	movups xmm7, xmm0 ;xmm7=0|0|0|a
	pslldq xmm7, 4 ;xmm7=0|0|a|0
	addps xmm0, xmm7 ;xmm0=0|0|a|a
	movups xmm7, xmm0 ;xmm7=0|0|a|a
	pslldq xmm7, 8 ;xmm7=a|a|0|0
	addps xmm0, xmm7 ;xmm0=a|a|a|a

	;xmm1=0|0|0|c y quiero que xmm1=c|c|c|c
	movups xmm7, xmm1 ;xmm7=0|0|0|c
	pslldq xmm7, 4 ;xmm7=0|0|c|0
	addps xmm1, xmm7 ;xmm1=0|0|c|c
	movups xmm7, xmm1 ;xmm7=0|0|c|c
	pslldq xmm7, 8 ;xmm7=c|c|0|0
	addps xmm1, xmm7 ;xmm1=c|c|c|c

loopIni:
	cmp dword [rsp+9], 20 ;for ( k=0 ; k<20  ; k++ )
	jge fin

	mov ecx, [rbx+offset_fluid_solver_N] ;ecx=solver->N
	xor r11, r11
	mov r11d, ecx ;r11=solver->N NO LO MODIFICO
	add ecx, 2 ;ecx=(solver->N)+2
	mov edx, ecx ;edx=(solver->N)+2 NO LO MODIFICO


	xor r9, r9
	inc r9;i=1
loop1:
	cmp r9, r11 ;for ( i=1 ; i<=solver->N ; i++ )
	jg fin1

	movups xmm4, [r12 + r9*4] ;xmm4= x[IX(i+3,0)] | x[IX(i+2,0)] | x[IX(i+1,0)] |x[IX(i,0)]

	add ecx, r9d ;rcx=( (solver->N)+2 ) + i
	xor rax, rax
	lea rax, [r12 + rcx*4] ;estoy en la pos(i,1) para x
	xor r8, r8
	lea r8, [r13 + rcx*4] ;estoy en la pos(i,1) para x0


	xor r10, r10
	inc r10 ;j=1
loop2:
	cmp r10, r11;for ( j=1 ; j<=solver->N ; j++ )
	jg fin2


	;traigo x(i,j+1)
	xor rsi, rsi
	lea rsi, [rax + rdx*4] ;rsi=IX(i,j+1)
	movups xmm2, [rsi] ;xmm2=x[IX(i+3,j+1)] | x[IX(i+2,j+1)] | x[IX(i+1,j+1)] | x[IX(i,j+1)]

	;traigo x(i+1,j)
	xor rdi, rdi
	lea rdi, [rax + 4] ;rdi=(i+1,j)
	movups xmm3, [rdi] ;xmm3=x[IX(i+4,j)] | x[IX(i+3,j)] | x[IX(i+2,j)] | x[IX(i+1,j)]

	;traigo x(i-1,j)
	xor rdi, rdi
	lea rdi, [rax - 4] ;rdi=(i-1,j)
	movups xmm5, [rdi] ;xmm5=x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)] | x[IX(i-1,j)]

	;traigo x0(i,j)
		movups xmm6, [r8] ;xmm6=x0[IX(i+3,j)] | x0[IX(i+2,j)] | x0[IX(i+1,j)] | x0[IX(i,j)]


	;multiplico por "a" y divido por "c" a cada float
	mulps xmm2, xmm0 ;xmm2=a*x[IX(i+3,j+1)] | a*x[IX(i+2,j+1)] | a*x[IX(i+1,j+1)] | a*x[IX(i,j+1)]
	divps xmm2, xmm1 ;xmm2=a*x[IX(i+3,j+1)]/c | a*x[IX(i+2,j+1)]/c | a*x[IX(i+1,j+1)]/c | a*x[IX(i,j+1)]/c

	mulps xmm3, xmm0 ;xmm3=a*x[IX(i+4,j)] | a*x[IX(i+3,j)] | a*x[IX(i+2,j)] | a*x[IX(i+1,j)]
	divps xmm3, xmm1 ;xmm3=a*x[IX(i+4,j)]/c | a*x[IX(i+3,j)]/c | a*x[IX(i+2,j)]/c | a*x[IX(i+1,j)]/c

	mulps xmm4, xmm0 ;xmm4=a*x[IX(i+3,j-1)] | a*x[IX(i+2,j-1)] | a*x[IX(i+1,j-1)] | a*x[IX(i,j-1)]
	divps xmm4, xmm1 ;xmm4=a*x[IX(i+3,j-1)]/c | a*x[IX(i+2,j-1)]/c | a*x[IX(i+1,j-1)]/c | a*x[IX(i,j-1)]/c

	divps xmm6, xmm1 ;xmm6=x0[IX(i+3,j)]/c | x0[IX(i+2,j)]/c | x0[IX(i+1,j)]/C | x0[IX(i,j)]/c

	;a cada x0 le sumo el de arriba, el de la derecha y el de abajo
	addps xmm6, xmm2 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c | x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c | x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c | x0[IX(i,j)] + a*x[IX(i,j+1)]/c
	addps xmm6, xmm3 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c|
					 ;x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c + a*x[IX(i+2,j)]/c| x0[IX(i,j)] + a*x[IX(i,j+1)]/c +a*x[IX(i+1,j)]/c
	addps xmm6, xmm4 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c
					 ;x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c + a*x[IX(i+2,j)]/c + a*x[IX(i+1,j-1)]/c| x0[IX(i,j)] + a*x[IX(i,j+1)]/c +a*x[IX(i+1,j)]/c + a*x[IX(i,j-1)]/c

	;al valor de la posicion (i-1,j) lo multiplico por a y divido por c, lo obtenido lo sumo para obtener x[IX(i,j)]
	mulss xmm5, xmm0 ;xmm5=x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)] | a*x[IX(i-1,j)]
	divss xmm5, xmm1 ;xmm5=x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)] | a*x[IX(i-1,j)]/c

	addss xmm6, xmm5 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c
					 ;x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c + a*x[IX(i+2,j)]/c + a*x[IX(i+1,j-1)]/c| x0[IX(i,j)] + a*x[IX(i,j+1)]/c +a*x[IX(i+1,j)]/c + a*x[IX(i,j-1)]/c + a*x[IX(i-1,j)]/c
					 ;la pos (i,j) ya esta modificada

	;al valor de la posicion (i,j) lo multiplico por a y divido por c, lo obtenido lo sumo para obtener x[IX(i+1,j)]
	movups xmm7, xmm6 ;xmm7=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c
					  ;x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c + a*x[IX(i+2,j)]/c + a*x[IX(i+1,j-1)]/c| x[IX(i,j)]
	pslldq xmm7, 12 ;xmm7=x[IX(i,j)]| 0 | 0 | 0
	psrldq xmm7, 12 ;xmm7=0 | 0 | 0 | x[IX(i,j)]
	mulss xmm7, xmm0 ;xmm7=0 | 0 | 0 | a*x[IX(i,j)]
	divss xmm7, xmm1 ;xmm7=0 | 0 | 0 | a*x[IX(i,j)]/c
	pslldq xmm7, 4 ;xmm7=0 | 0 | a*x[IX(i,j)]/c | 0
	addps xmm6 , xmm7 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c
					  ;x0[IX(i+1,j)] + a*x[IX(i+1,j+1)]/c + a*x[IX(i+2,j)]/c + a*x[IX(i+1,j-1)]/c + a*x[IX(i,j)]/c| x[IX(i,j)]
					  ;la pos (i+1,j) ya esta modificada

	;al valor de la posicion (i+1,j) lo multiplico por a y divido por c, lo obtenido lo sumo para obtener x[IX(i+2,j)]
	movups xmm7, xmm6 ;xmm7=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c
					  ;x[IX(i+1,j)] | x[IX(i,j)]
	pslldq xmm7, 8 ;xmm7=x[IX(i+1,j)]| x[IX(i,j)] | 0 | 0
	psrldq xmm7, 12 ;xmm7=0 | 0 | 0 | x[IX(i+1,j)]
	mulss xmm7, xmm0 ;xmm7=0 | 0 | 0 | a*x[IX(i+1,j)]
	divss xmm7, xmm1 ;xmm7=0 | 0 | 0 | a*x[IX(i+1,j)]/c
	pslldq xmm7, 8 ;xmm7=0 | a*x[IX(i+1,j)]/c | 0 | 0
	addps xmm6 , xmm7 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x0[IX(i+2,j)] + a*x[IX(i+2,j+1)]/c + a*x[IX(i+3,j)]/c| + a*x[IX(i+2,j-1)]/c + a*x[IX(i+1,j)]/c
					  ;x[IX(i+1,j)] | x[IX(i,j)]
					  ;la pos (i+2,j) ya esta modificada

	;al valor de la posicion (i+2,j) lo multiplico por a y divido por c, lo obtenido lo sumo para obtener x[IX(i+3,j)]
	movups xmm7, xmm6 ;xmm7=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c| x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)]
	pslldq xmm7, 4 ;xmm7=x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)] | 0
	psrldq xmm7, 12 ;xmm7=0 | 0 | 0 | x[IX(i+2,j)]
	mulss xmm7, xmm0 ;xmm7=0 | 0 | 0 | a*x[IX(i+2,j)]
	divss xmm7, xmm1 ;xmm7=0 | 0 | 0 | a*x[IX(i+2,j)]/c
	pslldq xmm7, 12 ;xmm7=a*x[IX(i+2,j)]/c | 0 | 0 | 0
	addps xmm6 , xmm7 ;xmm6=x0[IX(i+3,j)] + a*x[IX(i+3,j+1)]/c + a*x[IX(i+4,j)]/c + a*x[IX(i+3,j-1)]/c + a*x[IX(i+2,j)]/c| x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)]
					  ;la pos (i+3,j) ya esta modificada

	;busco x(i,j) y ahi guardo los 4 float calculados
	movups [rax], xmm6 ;guardo en la matriz los valores calculados
	movups xmm4, xmm6 ;xmm4=x[IX(i+3,j)] | x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)]

	;ahora rax va a ir a la fila de arriba
	lea rax, [rax + rdx*4] ;me movi una fila arriba y estoy en la pos (i,j+1) para x
	lea r8, [r8 + rdx*4] ;me movi una fila arriba y estoy en la pos (i,j+1) para x0

	inc r10 ;j++
	jmp loop2
fin2:

	mov ecx, edx;ecx=(solver->N)+2 )

	add r9, 4 ;i+=4
	jmp loop1
fin1:

	mov rdi, rbx ;rdi=solver
	mov esi, [rsp+17] ;rsi=b
	mov rdx, r12 ;rdx=x
	call solver_set_bnd ;solver_set_bnd ( solver, b, x )

	;reocordar que r14=a y r15=c donde el float esta en la parte baja del registro
	pxor xmm0, xmm0
	movq xmm0, r14 ;xmm0=0|0|0|a el valor de r14 va a la parte baja de xmm0
	pxor xmm1, xmm1
	movq xmm1, r15 ;xmm1=0|0|0|c el valor de r15 va a la parte baja de xmm1

	;xmm0=0|0|0|a y quiero que xmm0=a|a|a|a
	movups xmm7, xmm0 ;xmm7=0|0|0|a
	pslldq xmm7, 4 ;xmm7=0|0|a|0
	addps xmm0, xmm7 ;xmm0=0|0|a|a
	movups xmm7, xmm0 ;xmm7=0|0|a|a
	pslldq xmm7, 8 ;xmm7=a|a|0|0
	addps xmm0, xmm7 ;xmm0=a|a|a|a

	;xmm1=0|0|0|c y quiero que xmm1=c|c|c|c
	movups xmm7, xmm1 ;xmm7=0|0|0|c
	pslldq xmm7, 4 ;xmm7=0|0|c|0
	addps xmm1, xmm7 ;xmm1=0|0|c|c
	movups xmm7, xmm1 ;xmm7=0|0|c|c
	pslldq xmm7, 8 ;xmm7=c|c|0|0
	addps xmm1, xmm7 ;xmm1=c|c|c|c

	inc dword [rsp+9] ;k++
	jmp loopIni
fin:

	;restablecer stack
	add rsp, 8
	add rsp, 8 ;desapilo k
	add rsp, 8 ;desapilo b
	pop r15
    pop r14
    pop r13
    pop r12
	pop rbx
	pop rbp
	ret

;global solver_project
;solver_project:

	;push rbp				;alineada
	;mov rsp, rbp
	;push r13				;desalineada
	;push r14				;alineada
	;push r15				;desalineada
	;sub rsp, 24				;alineada

	;mov r15, rdi ; solver
	;mov r14, rsi ; p
	;mov r13, rdx ; div
	;mov r12, [r15 + offset_fluid_solver_N] ; N
	;sar r12, 4 ; divido N por 4 columnas
	;mov [rsp + 8], r12 ; cantidad de filas
	;mov [rsp + 16], r12 ; cantidad de columnas
	;mov r12, 1 ; contador de filas
	;mov r11, 1 ; contador de columnas

	;pxor xmm3, xmm3
	;movdqu xmm3, [ceroCinco]	;xmm3 = | 0.5 | 0.5 | 0.5 | 0.5 |

	;pxor xmm4, xmm4
	;movdqu xmm4, [r15 + offset_fluid_solver_N]
	;movdqu xmm5, xmm4
	;pslldq xmm5, 4
	;paddusb xmm4, xmm5
	;pslldq xmm5, 4
	;paddusb xmm4, xmm5
	;pslldq xmm5, 4
	;paddusb xmm4, xmm5 ;xmm4 = | N | N | N | N |

	;pxor xmm5, xmm5
	;pxor xmm6, xmm6
	;pxor xmm7, xmm7
	;pxor xmm8, xmm8


	;mov r10, [rsp + 8]
	;.primerCiclo:
	;; FOR_EACH_CELL
	;; 	div[IX(i,j)] = -0.5f * (solver->u[IX(i+1,j)] - solver->u[IX(i-1,j)] + solver->v[IX(i,j+1)] - solver->v[IX(i,j-1)]) / solver->N;
	;; 	p[IX(i,j)] = 0;
	;; END_FOR
	;.colCicloP:
	;movdqu xmm0, [r15] ; celdas actuales
	;sub r15, r10
	;movdqu xmm1, [r15] ; celdas fila anterior
	;add r15, r10
	;add r15, r10
	;movdqu xmm2, [r15] ; celdas fila siguiente

	;cmp r11, 1
	;jne .compararFin
	;; comienzo de fila
	;; b b b b - - - - - - - -
	;; a a a a d d d d - - - -
	;; c c c c - - - - - - - -
	;; - - - - - - - - - - - -
	;; c - b

	;.compararFin:
	;cmp r11, [rsp + 16]
	;je .finFilaPC
	;; ciclo
	;; - - - - x x x x - - - -
	;; x x x x a a a a x x x x
	;; - - - - x x x x - - - -
	;; - - - - - - - - - - - -
	;.finFilaPC:
	;; fin de fila
		;; - - - - - - - - x x x x
	;; - - - - x x x x a a a a
	;; - - - - - - - - x x x x
	;; - - - - - - - - - - - -
	;.finColCicloP:
	;inc byte [rsp + 16]
	;cmp r11, [rsp + 16]
	;jg .finPrimerCiclo
	;jmp .colCicloP
	;.finPrimerCiclo:
	;inc byte [rsp + 8]
	;cmp r12, [rsp + 8]
	;jg .siguiente
	;mov dword [rsp + 16], 0
	;jmp .primerCiclo

	;.siguiente:

	;; 	solver_set_bnd ( solver, 0, div );
	;mov rdi, r15
	;mov rsi, 0
	;mov rdx, r13
	;call solver_set_bnd
	;; 	solver_set_bnd ( solver, 0, p );
	;mov rdi, r15
	;mov rsi, 0
	;mov rdx, r14
	;; 	solver_lin_solve ( solver, 0, p, div, 1, 4 );
	;mov rdi, r15
	;mov rsi, 0
	;mov rdx, r14
	;mov rcx, r13
	;mov r8, 1
	;mov r9, 4
	;call solver_lin_solve


	;.segundoCiclo:
	;; FOR_EACH_CELL
	;; 	solver->u[IX(i,j)] -= 0.5f * solver->N * (p[IX(i+1,j)] - p[IX(i-1,j)]);
	;; mascaras:
	;; 	solver->v[IX(i,j)] -= 0.5f * solver->N * (p[IX(i,j+1)] - p[IX(i,j-1)]);
	;; END_FOR
	;.colCicloS:
	;movdqu xmm0, [r15] ; celdas actuales
	;sub r15, r10
	;movdqu xmm1, [r15] ; celdas fila anterior
	;add r15, r10
	;add r15, r10
	;movdqu xmm2, [r15] ; celdas fila siguiente

	;cmp r11, 1
	;jne .compararFinS
	;; comienzo de fila
	;; b b b b - - - - - - - -
	;; a a a a d d d d - - - -
	;; c c c c - - - - - - - -
	;; - - - - - - - - - - - -
	;; c - b

	;.compararFinS:
	;cmp r11, [rsp + 16]
	;je .finFilaSC
	;; ciclo
	;; - - - - x x x x - - - -
	;; x x x x a a a a x x x x
	;; - - - - x x x x - - - -
	;; - - - - - - - - - - - -
	;.finFilaSC:
	;; fin de fila
	;; - - - - - - - - x x x x
	;; - - - - x x x x a a a a
	;; - - - - - - - - x x x x
	;; - - - - - - - - - - - -
	;.finColCicloS:
	;inc byte [rsp + 16]
	;cmp r11, [rsp + 16]
	;jg .finsegundoCiclo
	;jmp .colCicloS
	;.finsegundoCiclo:
	;inc byte [rsp + 8]
	;cmp r12, [rsp + 8]
	;jg .siguiente
	;mov dword [rsp + 16], 0
	;jmp .segundoCiclo



	;; solver_set_bnd ( solver, 1, solver->u );
	;mov rdi, r15
	;mov rsi, 1
	;mov rdx, [rdi + offset_fluid_solver_u]
	;call solver_set_bnd
	;; solver_set_bnd ( solver, 2, solver->v );
	;mov rdi, r15
	;mov rsi, 1
	;mov rdx, [rdi + offset_fluid_solver_v]
	;call solver_set_bnd

	;add rsp, 24
	;pop r15
	;pop r14
	;pop r13
	;pop r12
	;pop rbx
	;pop rbp
	;ret
