extern free
extern malloc

extern solver_set_bnd_c

section .data

ceroCinco: dd 0.5, 0.5, 0.5, 0.5
negativos: DD -1.0, -1.0, -1.0, -1.0
floatUnos: DD 1.0, 1.0, 1.0, 1.0
floatCuatros: DD 4.0, 4.0, 4.0, 4.0
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
	call solver_set_bnd_asm ;solver_set_bnd ( solver, b, x )

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

global solver_project_asm
solver_project_asm:

	push rbp				;alineada
	mov rbp, rsp
	push rbx
	push r12
	push r13				;desalineada
	push r14				;alineada
	push r15				;desalineada
	sub rsp, 8				;alineada

	mov r15, rdi ; solver
	mov r13, rsi ; p
	mov rbx, rdx ; div
	mov r12, [r15 + offset_fluid_solver_u] ; U
	mov r14, [r15 + offset_fluid_solver_v] ; V


	mov ecx, [r15 + offset_fluid_solver_N] ;ecx=solver->N
	
	xor r11, r11	
	mov r11d, ecx ; R11  N
	
	
	mov [rsp + 8], r11 ; cantidad de filas
	add r11, 2
	
	xor r9, r9
	inc r9 ; r9 = 1 columna
	xor r10, r10
	inc r10 ; r10 = 1 fila

	pxor xmm3, xmm3
	movupd xmm3, [ceroCinco]	;xmm3 = | 0.5 | 0.5 | 0.5 | 0.5 |
	

	movdqu xmm2, xmm3 ;xmm2 = | 0.5 | 0.5 | 0.5 | 0.5 |

	pxor xmm4, xmm4
	;movss xmm4, [r15 + offset_fluid_solver_N]
	cvtsi2ss xmm4, [r15 + offset_fluid_solver_N]
	pshufd xmm4, xmm4, 00000000b
	

	divps xmm2, xmm4 ; xmm2 = | 0.5 / N | 0.5 / N | 0.5 / N | 0.5 / N 
	movupd xmm1, [negativos] ; xmm1 -1.0 | -1.0 | -1.0 | -1.0
	mulps xmm2, xmm1 ; xmm2 = | -0.5 / N | -0.5 / N | -0.5 / N | -0.5 / N 
	.primerCiclo:
	; FOR_EACH_CELL
	; 	div[IX(i,j)] = - 0.5f * (solver->u[IX(i+1,j)] - solver->u[IX(i-1,j)] + solver->v[IX(i,j+1)] - solver->v[IX(i,j-1)]) / solver->N;
	; 	p[IX(i,j)] = 0;
	; END_FOR
	.colCicloP:
	
	
	sal r9, 2

	xor r11, r11
	inc r10 ; voy a la fila siguiente
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9 ; fila * (n+2) * 4 + columna*4


 	movups xmm7, [r14 + r11] ; v[IX(i+3,j+1)] | v[IX(i+2,j+1)] | v[IX(i+1,j+1)] | v[IX(i,j+1)]
	dec r10 ; vuelvo a la fila actual
	dec r10 ; voy a la fila anterior

	xor r11, r11
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9 ; fila * (n+2) * 4 + columna*4

	movups xmm6, [r14 + r11] ; v[IX(i+3,j-1)] | v[IX(i+2,j-1)] | v[IX(i+3,j-1)] | v[IX(i,j-1)]
	
	inc r10 ; vuelvo a la fila actual
	
	subps xmm7, xmm6 ; xmm7 = solver->v[IX(i+3,j+1)] - solver->v[IX(i+3,j-1)] | solver->v[IX(i+2,j+1)] - solver->v[IX(i+2,j-1)] | solver->v[IX(i+1,j+1)] - solver->v[IX(i+1,j-1)] | solver->v[IX(i,j+1)] - solver->v[IX(i,j-1)]

	xor r11, r11
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9

	movups xmm5, [r12 + r11] ; u[IX(i+3,j)] | u[IX(i+2,j)] | u[IX(i+1,j)] | u[IX(i,j)]
	movdqu xmm8, xmm5 ; u[IX(i+3,j)] | u[IX(i+2,j)] | u[IX(i+1,j)] | u[IX(i,j)]
	psrldq xmm8, 4 ; 0 | u[IX(i+3,j)] | u[IX(i+2,j)] | u[IX(i+1,j)]
	
	add r11, 16
	
	movups xmm6, [r12 + r11] ;u[IX(i+7,j)] | u[IX(i+6,j)] | u[IX(i+5,j)] | u[IX(i+4,j)]
	pslldq xmm6, 12 ; u[IX(i+4,j)] | 0 | 0 | 0
	addps xmm8, xmm6 ; u[IX(i+4,j)] | u[IX(i+3,j)] | u[IX(i+2,j)] | u[IX(i+1,j)]
	movdqu xmm6, xmm5 ; u[IX(i+3,j)] | u[IX(i+2,j)] | u[IX(i+1,j)] | u[IX(i,j)]
	pslldq xmm6, 4 ; u[IX(i+2,j)] | u[IX(i+1,j)] | u[IX(i,j)] | 0
	
	sub r11, 32 ; vuelvo a las 4 columnas anteriores
	movups xmm5, [r12 + r11] ;u[IX(i-1,j)] | u[IX(i-2,j)] | u[IX(i-3,j)] | u[IX(i-4,j)]
	
	add r11, 16 ; vuelvo a las columnas actuales
	
	psrldq xmm5, 12 ; 0 | 0 | 0 | u[IX(i-1,j)]
	addps xmm5, xmm6 ; u[IX(i+2,j)] | u[IX(i+1,j)] | u[IX(i,j)] | u[IX(i-1,j)]

	subps xmm8, xmm5  ; solver->u[IX(i+1,j)] - solver->u[IX(i-1,j)]


	addps xmm7, xmm8 ; (solver->u[IX(i,j+1)] - solver->u[IX(i,j-1)] + solver->v[IX(i+1,j)] - solver->v[IX(i-1,j)])
	; movdqu xmm7, xmm8
	mulps xmm7, xmm2
	;mulps xmm7, xmm2 ; -0.5f * (solver->u[IX(i,j+1)] - solver->u[IX(i,j-1)] + solver->v[IX(i+1,j)] - solver->v[IX(i-1,j)]) / solver->N;
	
	
	
	pxor xmm11, xmm11
	movdqu [r13 + r11], xmm11 ; p[IX(i+3,j)] = 0 | p[IX(i+2,j)] = 0 | p[IX(i+1,j)] = 0; | p[IX(i,j)] = 0

	sar r9, 2

	.finColCicloP:
	movups [rbx + r11], xmm7 ; div[IX(i,j)] = -0.5f * (solver->u[IX(i,j+1)] - solver->u[IX(i,j-1)] + solver->v[IX(i+1,j)] - solver->v[IX(i-1,j)]) / solver->N;
	add r9, 4
	cmp r9, [rsp + 8] ; comparar con n
	jg .avanzoFila
	jmp .primerCiclo

	.avanzoFila:
	mov r9, 1
	inc r10
	cmp r10, [rsp + 8] ; comparar con n
	jg .siguiente
	jmp .primerCiclo
	.siguiente:

	; solver_set_bnd ( solver, 0, div );
	mov rdi, r15
	mov rsi, 0
	mov rdx, rbx
	call solver_set_bnd_asm
	; 	solver_set_bnd ( solver, 0, p );
	mov rdi, r15
	mov rsi, 0
	mov rdx, r13
	call solver_set_bnd_asm
	; 	solver_lin_solve ( solver, 0, p, div, 1, 4 );
	mov rdi, r15
	mov rsi, 0
	mov rdx, r13
	mov rcx, rbx
	movss xmm0, [floatUnos]
	movss xmm1, [floatCuatros]
	call solver_lin_solve_asm


	mulps xmm4, xmm3 ; xmm4 0.5*N | 0.5*N | 0.5*N | 0.5*N
	
	xor r10, r10
	inc r10 ; fila 1
	xor r9, r9
	inc r9 ; columna 1

	.segundoCiclo:
	; FOR_EACH_CELL
	; 	; solver->u[IX(i,j)] -= 0.5f*solver->N*(p[IX(i+1,j)] - p[IX(i-1,j)]);
	;	; solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)] - p[IX(i,j-1)]);
	; END_FOR

	; U COLUMNA R12
	; V FILA R14

	sal r9, 2

	xor r11, r11
	inc r10 ; voy a la fila siguiente
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9 ; fila * (n+2) * 4 + columna*4


 	movups xmm7, [r13 + r11] ; p[IX(i+3,j+1)] | p[IX(i+2,j+1)] | p[IX(i+1,j+1)] | p[IX(i,j+1)]
	dec r10 ; vuelvo a la fila actual
	dec r10 ; voy a la fila anterior

	xor r11, r11
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9 ; fila * (n+2) * 4 + columna*4

	movups xmm6, [r13 + r11] ; p[IX(i+3,j-1)] | p[IX(i+2,j-1)] | p[IX(i+3,j-1)] | p[IX(i,j-1)]
	
	inc r10 ; vuelvo a la fila actual
	
	subps xmm7, xmm6 ; xmm7 = solver->p[IX(i+3,j+1)] - solver->p[IX(i+3,j-1)] | solver->p[IX(i+2,j+1)] - solver->p[IX(i+2,j-1)] | solver->p[IX(i+1,j+1)] - solver->p[IX(i+1,j-1)] | solver->p[IX(i,j+1)] - solver->p[IX(i,j-1)]

	mulps xmm7, xmm4 ; xmm7 = 0.5 * N * (solver->p[IX(i+3,j+1)] - solver->p[IX(i+3,j-1)]) | 0.5 * N * (solver->p[IX(i+2,j+1)] - solver->p[IX(i+2,j-1)] | 0.5 * N * (solver->p[IX(i+1,j+1)] - solver->p[IX(i+1,j-1)] | 0.5 * N * (solver->p[IX(i,j+1)] - solver->p[IX(i,j-1)]

	xor r11, r11
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9 ; fila * (n+2) * 4 + columna*4

	movups xmm6, [r14 + r11] ; v[IX(i+3,j)] | v[IX(i+2,j)] | v[IX(i+3,j)] | v[IX(i,j)]

	subps xmm6, xmm7 ; solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)]-p[IX(i,j-1)]);

	movups [r14 + r11], xmm6 ; solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)]-p[IX(i,j-1)]);




	xor r11, r11
	mov r11, r10
	mov rax, [rsp + 8]
	add rax, 2
	mul r11 ; fila * (n+2)
	mov r11, rax
	sal r11, 2 ; fila * (n+2) * 4
	add r11, r9

	movups xmm5, [r13 + r11] ; p[IX(i+3,j)] | p[IX(i+2,j)] | p[IX(i+1,j)] | p[IX(i,j)]
	movdqu xmm8, xmm5 ; p[IX(i+3,j)] | p[IX(i+2,j)] | p[IX(i+1,j)] | p[IX(i,j)]
	psrldq xmm8, 4 ; 0 | p[IX(i+3,j)] | p[IX(i+2,j)] | p[IX(i+1,j)]
	
	add r11, 16
	
	movups xmm6, [r13 + r11] ;p[IX(i+7,j)] | p[IX(i+6,j)] | p[IX(i+5,j)] | p[IX(i+4,j)]
	pslldq xmm6, 12 ; p[IX(i+4,j)] | 0 | 0 | 0
	addps xmm8, xmm6 ; p[IX(i+4,j)] | p[IX(i+3,j)] | p[IX(i+2,j)] | p[IX(i+1,j)]
	movdqu xmm6, xmm5 ; p[IX(i+3,j)] | p[IX(i+2,j)] | p[IX(i+1,j)] | p[IX(i,j)]
	pslldq xmm6, 4 ; p[IX(i+2,j)] | p[IX(i+1,j)] | p[IX(i,j)] | 0
	
	sub r11, 32 ; vuelvo a las 4 columnas anteriores
	movups xmm5, [r13 + r11] ;p[IX(i-1,j)] | p[IX(i-2,j)] | p[IX(i-3,j)] | p[IX(i-4,j)]
	
	add r11, 16 ; vuelvo a las columnas actuales
	
	psrldq xmm5, 12 ; 0 | 0 | 0 | p[IX(i-1,j)]
	addps xmm5, xmm6 ; p[IX(i+2,j)] | p[IX(i+1,j)] | p[IX(i,j)] | p[IX(i-1,j)]

	subps xmm8, xmm5  ; solver->p[IX(i+1,j)] - solver->p[IX(i-1,j)]

	mulps xmm8, xmm4 ; 0.5 * N * (solver->p[IX(i+1,j)] - solver->p[IX(i-1,j)])

	
	movups xmm6, [r12 + r11] ; v[IX(i+3,j)] | v[IX(i+2,j)] | v[IX(i+3,j)] | v[IX(i,j)]

	subps xmm6, xmm8 ; solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)]-p[IX(i,j-1)]);

	movups [r12 + r11], xmm6 ; solver->v[IX(i,j)] -= 0.5f*solver->N*(p[IX(i,j+1)]-p[IX(i,j-1)]);

	sar r9, 2
	add r9, 4
	cmp r9, [rsp + 8] ; comparar con n
	jg .avanzoFilaS
	jmp .segundoCiclo

	.avanzoFilaS:
	mov r9, 1
	inc r10
	cmp r10, [rsp + 8] ; comparar con n
	jg .fin
	jmp .segundoCiclo




	.fin:
	; solver_set_bnd ( solver, 1, solver->u );
	mov rdi, r15
	mov rsi, 1
	mov rdx, r12
	call solver_set_bnd_asm
	; solver_set_bnd ( solver, 2, solver->v );
	mov rdi, r15
	mov rsi, 2
	mov rdx, r14
	call solver_set_bnd_asm
	
	mov rdx, rbx
	mov rdi, r15 ; solver
	mov rsi, r13 ; p
	

	add rsp, 8
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret