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
	mov [rsp], rsi ;b esta en la pila
	sub rsp, 8
	mov dword [rsp], 0 ;k esta en la pila
	sub rsp, 8
	
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
	
loop:
	cmp dword [rsp+8], 20 ;for ( k=0 ; k<20 ; k++ )
	jge fin 
	
	mov r9, 1 ;i=1
loop1:cmp r9, [rbx+offset_fluid_solver_N] ;for ( i=1 ; i<solver->N ; i++ )
	jg fin1
	
	movups xmm4, [r12 + r9*4] ;xmm4= x[IX(i+3,0)] | x[IX(i+2,0)] | x[IX(i+1,0)] |x[IX(i,0)]
		
	mov r10, 1 ;j=1
loop2:
	cmp r10, [rbx+offset_fluid_solver_N] ;for ( j=1 ; j<solver->N ; j++ )
	jg fin2
	
	;traigo x(i,j+1)
	mov r8, r12 ;r8=comienzo de la matriz x
	xor rax, rax
	mov rax, [rbx+offset_fluid_solver_N] ;rax=solver->N
	add rax, 2 ;rax=(solver->N)+2
	mov r11, r10 ;r11=j
	inc r11 ;r11=j+1
	mul r11 ;rax=( (solver->N)+2 ) * (j+1)
	add rax, r9 ;rax=( (solver->N)+2 ) * (j+1) + i
	mul rax, 4 ;rax=(( (solver->N)+2 ) * (j+1) + i )*4
	add r8, rax ;r8=comienzo de la matriz x + lo necesario para ir a  la pos (i,j+1)
	movups xmm2, [r8] ;xmm6=x[IX(i+3,j+1)] | x[IX(i+2,j+1)] | x[IX(i+1,j+1)] | x[IX(i,j+1)]
	
	;traigo x(i+1,j)
	mov r8, r12 ;r8=comienzo de la matriz x
	xor rax, rax
	mov rax, [rbx+offset_fluid_solver_N] ;rax=solver->N
	add rax, 2 ;rax=(solver->N)+2
	mul r10 ;rax=( (solver->N)+2 ) * j
	mov r11, r9 ;r11=i
	inc r11 ;r9=i+1
	add rax, r11 ;rax=( (solver->N)+2 ) * j + (i+1)
	mul rax, 4 ;rax=(( (solver->N)+2 ) * j + (i+1) )*4
	add r8, rax ;r8=comienzo de la matriz x + lo necesario para ir a  la pos (i+1,j)
	movups xmm3, [r8] ;xmm6=x[IX(i+4,j)] | x[IX(i+3,j)] | x[IX(i+2,j)] | x[IX(i+1,j)]
	
	;traigo x(i-1,j)
	mov r8, r12 ;r8=comienzo de la matriz x
	xor rax, rax
	mov rax, [rbx+offset_fluid_solver_N] ;rax=solver->N
	add rax, 2 ;rax=(solver->N)+2
	mul r10 ;rax=( (solver->N)+2 ) * j
	mov r11, r9 ;r11=i
	dec r11 ;r9=i-1
	add rax, r11 ;rax=( (solver->N)+2 ) * j + (i-1)
	mul rax, 4 ;rax=(( (solver->N)+2 ) * j + (i-1) )*4
	add r8, rax ;r8=comienzo de la matriz x + lo necesario para ir a  la pos (i-1,j)
	movups xmm5, [r8] ;xmm6=x[IX(i+2,j)] | x[IX(i+1,j)] | x[IX(i,j)] | x[IX(i-1,j)]
	
	;traigo x0(i,j)
	mov r8, r13 ;r8=comienzo de la matriz x0
	xor rax, rax
	mov rax, [rbx+offset_fluid_solver_N] ;rax=solver->N
	add rax, 2 ;rax=(solver->N)+2
	mul r10 ;rax=( (solver->N)+2 ) * j
	add rax, r9 ;rax=( (solver->N)+2 ) * j + i
	mul rax, 4 ;rax=(( (solver->N)+2 ) * j + i )*4
	add r8, rax ;r8=comienzo de la matriz x0 + lo necesario para ir a  la pos (i,j)
	movups xmm6, [r8] ;xmm6=x0[IX(i+3,j)] | x0[IX(i+2,j)] | x0[IX(i+1,j)] | x0[IX(i,j)] 
	
	inc r10 ;j++
	jmp loop2
fin2:
	
	add r9, 4 ;i+=4
	jmp loop1
fin1:
	
	mov rdi, rbx ;rdi=solver
	mov rsi, [rsp+16] ;rsi=b
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
		
	inc dword [rsp+8] ;k++
	jmp loop
fin:
	
	;restablecer stack
	add rsp, 8 ;desapilo k
	add rsp, 8 ;desapilo b
	pop r15
    	pop r14
    	pop r13
    	pop r12
	pop rbx
	pop rbp
	ret
	

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

	pxor xmm3, xmm3
	movdqu xmm3, [ceroCinco]	;xmm3 = | 0.5 | 0.5 | 0.5 | 0.5 |
	mov r15, rdx			;r15 = x
	mov ebx, [rdi + offset_fluid_solver_N]		;ebx = N
	mov r9d, ebx+2				; r9d = N + 2
	mov r8d, ebx+1				; r8d = N + 1

	;primer paso
	pxor xmm6, xmm6				;xmm6 = | 0 | 0 | 0 | 0 |
	pxor xmm7, xmm7				;xmm7 = | 0 | 0 | 0 | 0 |

	mov r11d, [r15 + 1]			;r11d = x[IX(1, 0)]
	insertps xmm6, r11d, 0		;xmm6 = | 0 | 0 | 0 | x[IX(1, 0)] |
	mov r11d, [r15 + r9d*r8d + 1];r11d = x[IX(1, N+1)]
	insertps xmm6, r11d, 32		;xmm6 = | 0 | 0 | x[IX(1, N+1)] | x[IX(1, 0)] |
	mov r11d, [r15 + ebx]		;r11d = x[IX(N, 0)]
	insertps xmm6, r11d, 64		;xmm6 = | 0 | x[IX(N, 0)] | x[IX(N, i)] | x[IX(1, i)] |
	mov r11d, [r15 + r9d*r8d + ebx];r11d = x[IX(N, N+1)]
	insertps xmm6, r11d, 96		;xmm6 = | x[IX(N, N+1)] | x[IX(i, 1)] | x[IX(N, i)] | x[IX(1, i)] 

	mulps xmm6, xmm3			;xmm6 = | 0.5*x[IX(N, N+1)] | 0.5*x[IX(i, 1)] | 0.5*x[IX(N, i)] | 0.5*x[IX(1, i)] 

	mov r11d, [r15 + r9d]			;r11d = x[IX(0, 1)]
	insertps xmm7, r11d, 0			;xmm7 = | 0 | 0 | 0 | x[IX(0, 1)] |
	mov r11d, [r15 + r9d*ebx]		;r11d = x[IX(0, N)]
	insertps xmm7, r11d, 32			;xmm7 = | 0 | 0 | x[IX(0, N)] | x[IX(1, 0)] |
	mov r11d, [r15 + r9d + r8d]		;r11d = x[IX(N+1, 1)]
	insertps xmm7, r11d, 64			;xmm7 = | 0 | x[IX(N+1, 1)] | x[IX(0, N)] | x[IX(1, 0)] |
	mov r11d, [r15 + r9d*ebx + r8d]	;r11d = x[IX(N+1, N)]
	insertps xmm7, r11d, 96			;xmm7 = | x[IX(N+1, N)] | x[IX(N+1, 1)] | x[IX(0, N)] | x[IX(1, 0)] |

	addps xmm6, xmm7				;xmm6 = | 0.5*x[IX(N, N+1)] + x[IX(N+1, N)] | 0.5*x[IX(i, 1)] + x[IX(N+1, 1)] | 0.5*x[IX(N, i)] + x[IX(0, N)] | 0.5*x[IX(1, i)]  + x[IX(1, 0)] |

	extractps [r15], xmm6, 0
	extractps [r15 + r9d*r8d], xmm6, 32
	extractps [r15 + r8d], xmm6, 64
	extractps [r15 + r9d*r8d + r8d], xmm6, 96

	;fin del primer paso (que en el codigo de la catedra esta a lo ultimo de la funcion)
	
	mov r13d, esi			;r13d = b
	pxor xmm4, xmm4
	pxor xmm5, xmm5
	xor r12d, r12d			;r12 = 0
	inc r12d							;r12 = 1
	movdqu xmm4, [negativosSeg]			; xmm4 = | -1.0 | -1.0 | 1.0 | 1.0 |
	movdqu xmm5, [negativosPrim]		; xmm5 = | 1.0 | 1.0 | -1.0 | -1.0 |
	cmp r13d, 1					
	je .ciclo1					;b == 1
	cmp r13d, 2
	je .ciclo2
	jmp .fin					;b == 2	
.ciclo1:						;b == 1
	xor r11d, r11d
	cmp r12d, ebx
	je .fin
	pxor xmm0, xmm0				; | 0 | 0 | 0 | 0 |
	pxor xmm1, xmm1 			; | 0 | 0 | 0 | 0 |
	mov r9d, ebx+2				; r9d = N + 2
	mov r8d, ebx+1				; r8d = N + 1
	mov r11d, [r15 + r9d*r12d + 1]	;r11d = x[IX(1,i)]
	insertps xmm0, r11d, 0		;xmm0 = | 0 | 0 | 0 | x[IX(1,i)] |
	mov r11d, [r15 + r9d*r12d + ebx];r11d = x[IX(N,i)]
	insertps xmm0, r11d, 32		;xmm0 = | 0 | 0 | x[IX(N,i)] | x[IX(1,i)] |
	mov r11d, [r15 + r9d + r12d]	;r11d = x[IX(i,1)]
	insertps xmm0, r11d, 64		;xmm0 = | 0 | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	mov r11d, [r15 + r9d*ebx + r12d];r11d = x[IX(i,N)]
	insertps xmm0, r11d, 96		;xmm0 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] 
	;movdqu xmm1, xmm0			;xmm1 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	mulps xmm0, xmm5			;xmm0 = | x[IX(i,N)] | x[IX(i,1)] | -x[IX(N,i)] | -x[IX(1,i)] |

	extractps [r15 + r9d*ebx], xmm0, 0
	extractps [r15 + r9d*ebx + r8d], xmm0, 32
	extractps [r15 + ebx], xmm0, 64
	extractps [r15 + r9d*r8d + ebx], xmm0, 96

	inc r12d
	jmp .ciclo1

.ciclo2:						;b == 2
	xor r11d, r11d
	cmp r12d, ebx
	je .fin
	pxor xmm0, xmm0				; | 0 | 0 | 0 | 0 |
	pxor xmm1, xmm1 			; | 0 | 0 | 0 | 0 |
	mov r9d, ebx+2				; r9d = N + 2
	mov r8d, ebx+1				; r8d = N + 1
	mov r11d, [r15 + r9d*r12d + 1]	;r11d = x[IX(1,i)]
	insertps xmm0, r11d, 0		;xmm0 = | 0 | 0 | 0 | x[IX(1,i)] |
	mov r11d, [r15 + r9d*r12d + ebx];r11d = x[IX(N,i)]
	insertps xmm0, r11d, 32		;xmm0 = | 0 | 0 | x[IX(N,i)] | x[IX(1,i)] |
	mov r11d, [r15 + r9d + r12d]	;r11d = x[IX(i,1)]
	insertps xmm0, r11d, 64		;xmm0 = | 0 | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	mov r11d, [r15 + r9d*ebx + r12d];r11d = x[IX(i,N)]
	insertps xmm0, r11d, 96		;xmm0 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] 
	;movdqu xmm1, xmm0			;xmm1 = | x[IX(i,N)] | x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |
	mulps xmm0, xmm4			;xmm1 = | -x[IX(i,N)] | -x[IX(i,1)] | x[IX(N,i)] | x[IX(1,i)] |

	extractps [r15 + r9d*ebx], xmm0, 0
	extractps [r15 + r9d*ebx + r8d], xmm0, 32
	extractps [r15 + ebx], xmm0, 64
	extractps [r15 + r9d*r8d + ebx], xmm0, 96

	inc r12d
	jmp .ciclo2

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

	push rbp				;alineada
	mov rsp, rbp	
	push r13				;desalineada
	push r14				;alineada
	push r15				;desalineada	
	sub rsp, 24				;alineada

	mov r15, rdi ; solver
	mov r14, rsi ; p
	mov r13, rdx ; div	
	mov r12, [r15 + offset_fluid_solver_N] ; N	
	sar r12, 4 ; divido N por 4 columnas
	mov [rsp + 8], r12 ; cantidad de filas
	mov [rsp + 16], r12 ; cantidad de columnas
	mov r12, 1 ; contador de filas
	mov r11, 1 ; contador de columnas

	pxor xmm3, xmm3
	movdqu xmm3, [ceroCinco]	;xmm3 = | 0.5 | 0.5 | 0.5 | 0.5 |
	
	pxor xmm4, xmm4
	movdqu xmm4, [r15 + offset_fluid_solver_N]
	movdqu xmm5, xmm4
	pslldq xmm5, 4
	paddusb xmm4, xmm5
	pslldq xmm5, 4
	paddusb xmm4, xmm5
	pslldq xmm5, 4
	paddusb xmm4, xmm5 ;xmm4 = | N | N | N | N |

	pxor xmm5, xmm5
	pxor xmm6, xmm6
	pxor xmm7, xmm7
	pxor xmm8, xmm8


	mov r10, [rsp + 8]
	.primerCiclo:
	; FOR_EACH_CELL
	; 	div[IX(i,j)] = -0.5f * (solver->u[IX(i+1,j)] - solver->u[IX(i-1,j)] + solver->v[IX(i,j+1)] - solver->v[IX(i,j-1)]) / solver->N;
	; 	p[IX(i,j)] = 0;
	; END_FOR
	.colCicloP:
	movdqu xmm0, [r15] ; celdas actuales
	sub r15, r10
	movdqu xmm1, [r15] ; celdas fila anterior
	add r15, r10
	add r15, r10
	movdqu xmm2, [r15] ; celdas fila siguiente

	cmp r11, 1
	jne .compararFin
	; comienzo de fila
	; b b b b - - - - - - - - 
	; a a a a d d d d - - - -
	; c c c c - - - - - - - -
	; - - - - - - - - - - - -
	; c - b
	
	.compararFin:
	cmp r11, [rsp + 16]
	je .finFilaPC
	; ciclo
	; - - - - x x x x - - - - 
	; x x x x a a a a x x x x
	; - - - - x x x x - - - -
	; - - - - - - - - - - - -
	.finFilaPC:
	; fin de fila
	; - - - - - - - - x x x x
	; - - - - x x x x a a a a
	; - - - - - - - - x x x x
	; - - - - - - - - - - - -
	.finColCicloP:
	inc [rsp + 16]
	cmp r11, [rsp + 16]
	jg .finPrimerCiclo		
	jmp .colCicloP
	.finPrimerCiclo:
	inc [rsp + 8]
	cmp r12, [rsp + 8]
	jg .siguiente
	mov [rsp + 16], 0
	jmp .primerCiclo

	.siguiente:

	; 	solver_set_bnd ( solver, 0, div ); 
	mov rdi, r15
	mov rsi, 0
	mov rdx, r13
	call solver_set_bnd
	; 	solver_set_bnd ( solver, 0, p );
	mov rdi, r15
	mov rsi, 0
	mov rdx, r14
	; 	solver_lin_solve ( solver, 0, p, div, 1, 4 );
	mov rdi, r15
	mov rsi, 0
	mov rdx, r14
	mov rcx, r13
	mov r8, 1
	mov r9, 4
	call solver_lin_solve
	
	
	.segundoCiclo:
	; FOR_EACH_CELL	
	; 	solver->u[IX(i,j)] -= 0.5f * solver->N * (p[IX(i+1,j)] - p[IX(i-1,j)]);
	; mascaras:
	; 	solver->v[IX(i,j)] -= 0.5f * solver->N * (p[IX(i,j+1)] - p[IX(i,j-1)]);
	; END_FOR	
	.colCicloS:
	movdqu xmm0, [r15] ; celdas actuales
	sub r15, r10
	movdqu xmm1, [r15] ; celdas fila anterior
	add r15, r10
	add r15, r10
	movdqu xmm2, [r15] ; celdas fila siguiente

	cmp r11, 1
	jne .compararFinS
	; comienzo de fila
	; b b b b - - - - - - - - 
	; a a a a d d d d - - - -
	; c c c c - - - - - - - -
	; - - - - - - - - - - - -
	; c - b
	
	.compararFinS:
	cmp r11, [rsp + 16]
	je .finFilaSC
	; ciclo
	; - - - - x x x x - - - - 
	; x x x x a a a a x x x x
	; - - - - x x x x - - - -
	; - - - - - - - - - - - -
	.finFilaSC:
	; fin de fila
	; - - - - - - - - x x x x
	; - - - - x x x x a a a a
	; - - - - - - - - x x x x
	; - - - - - - - - - - - -
	.finColCicloS:
	inc [rsp + 16]
	cmp r11, [rsp + 16]
	jg .finsegundoCiclo		
	jmp .colCicloS
	.finsegundoCiclo:
	inc [rsp + 8]
	cmp r12, [rsp + 8]
	jg .siguiente
	mov [rsp + 16], 0
	jmp .segundoCiclo



	; solver_set_bnd ( solver, 1, solver->u );
	mov rdi, r15
	mov rsi, 1
	mov rdx, [rdi + offset_fluid_solver_u]
	call solver_set_bnd 
	; solver_set_bnd ( solver, 2, solver->v );
	mov rdi, r15
	mov rsi, 1
	mov rdx, [rdi + offset_fluid_solver_v]
	call solver_set_bnd 

	add rsp, 24
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
