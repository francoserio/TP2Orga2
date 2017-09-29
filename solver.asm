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
negativos: dd -1.0, -1.0, -1.0, -1.0
andprimeros4: dd 0x00000000, 0x00000000, 0x00000000, 0xFFFFFFFF
andsegundos4: dd 0x00000000, 0x00000000, 0xFFFFFFFF, 0x00000000
andterceros4: dd 0x00000000, 0xFFFFFFFF, 0x00000000, 0x00000000
andcuartos4: dd 0xFFFFFFFF, 0x00000000, 0x00000000, 0x00000000
primeroNegativo: dd -1.0, 1.0, 1.0, 1.0

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

	pxor xmm11, xmm11
	movdqu xmm11, [ceroCinco]	;xmm11 = | 0.5 | 0.5 | 0.5 | 0.5 |
	mov r15, rdx				;r15 = x
	mov ebx, [rdi + offset_fluid_solver_N]		;ebx = N
	mov r9d, ebx
	inc r9d
	inc r9d						; r9d = N + 2
	mov r8d, ebx				
	inc r8d						; r8d = N + 1

	mov r13d, esi				;r13d = b
	pxor xmm4, xmm4
	xor r12, r12				;r12 = 0
	mov r12d, ebx
	shr r12d, 2					;r12 = r12 / 4
	movdqu xmm4, [negativos]	;xmm4 = | -1.0 | -1.0 | -1.0 | -1.0 |
	cmp r13d, 1					
	je .ciclo1					;b == 1
	cmp r13d, 2
	je .ciclo2
	jmp .fin					;b == 2	
.ciclo1:						;b == 1

	mov r11, r9d
	mul r11, r11
	cmp r15, r11
	je .fin

	;ahora x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];

	mov r10, r15					;backapeo puntero

	pxor xmm0, xmm0

	mov r14, r15
	lea r15, [r15 + r9d*4]
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mov r15, r14
	movdqu [r15], xmm0			

	;ahora x[IX(0  ,i)] = b==1 ? -x[IX(1,i)] : x[IX(1,i)];

	pxor xmm0, xmm0
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm3, xmm3

	pxor xmm5, xmm5
	pxor xmm6, xmm6
	pxor xmm7, xmm7
	pxor xmm8, xmm8

	pxor xmm10, xmm10
	movdqu xmm10, [primeroNegativo]	;xmm10 = | -1.0 | 1.0 | 1.0 | 1.0 |

	mov r15, r10

	lea r15, [r15 + 4]

	movdqu xmm0, [r15]				;xmm0 = | P4 | P3 | P2 | P1 |
	pslld xmm0, 12					;xmm0 = | P1 | 0 | 0 | 0 |
	psrld xmm0, 12					;xmm0 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm1, [r15]				;xmm1 = | P8 | P7 | P6 | P5 |
	pslld xmm1, 12					;xmm1 = | P5 | 0 | 0 | 0 |
	; psrld xmm1, 8
	psrld xmm1, 12					;xmm1 = | 0 | 0 | 0 | P5 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm2, [r15]				;xmm2 = | P12 | P11 | P10 | P9 |
	pslld xmm2, 12					;xmm2 = | P9 | 0 | 0 | 0 |
	; psrld xmm2,	4
	psrld xmm2, 12					;xmm2 = | 0 | 0 | 0 | P9 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm3, [r15]				;xmm3 = | P16 | P15 | P14 | P13 |
	pslld xmm3, 12					;xmm3 = | P13 | 0 | 0 | 0 |
	psrld xmm3, 12					;xmm3 = | 0 | 0 | 0 | P13 |

	; addps xmm0, xmm1
	; addps xmm0, xmm2
	; addps xmm0, xmm3

	mov r15, r10

	movdqu xmm5, [r15]
	movdqu xmm6, [andprimeros4]

	pandn xmm5, xmm6
	addps xmm0, xmm5
	mulps xmm0, xmm10
	movdqu [r15], xmm0

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm1, xmm5
	mulps xmm1, xmm10
	movdqu [r15], xmm1

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm2, xmm5
	mulps xmm2, xmm10
	movdqu [r15], xmm2

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm3, xmm5
	mulps xmm3, xmm10
	movdqu [r15], xmm3

	;ahora x[IX(N+1,i)] = b==1 ? -x[IX(N,i)] : x[IX(N,i)]; ultima columna

	mov r15, r10

	pxor xmm0, xmm0
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm3, xmm3

	pxor xmm5, xmm5
	pxor xmm6, xmm6
	pxor xmm7, xmm7
	pxor xmm8, xmm8

	pxor xmm10, xmm10
	movdqu xmm10, [primeroNegativo]	;xmm10 = | -1.0 | 1.0 | 1.0 | 1.0 |

	lea r15, [r15 + r9d*4]
	lea r15, [r15 - 16]

	movdqu xmm0, [r15]				;xmm0 = | P4 | P3 | P2 | P1 |
	pslld xmm0, 12					;xmm0 = | P1 | 0 | 0 | 0 |
	psrld xmm0, 12					;xmm0 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm1, [r15]				;xmm1 = | P8 | P7 | P6 | P5 |
	pslld xmm1, 12					;xmm1 = | P5 | 0 | 0 | 0 |
	; psrld xmm1, 8
	psrld xmm1, 12					;xmm1 = | 0 | 0 | 0 | P5 |

	lea r15, [r15 + r9d*4]			;subo una fila							
	movdqu xmm2, [r15]				;xmm2 = | P12 | P11 | P10 | P9 |
	pslld xmm2, 12					;xmm2 = | P9 | 0 | 0 | 0 |	
	; psrld xmm2,	4						
	psrld xmm2, 12					;xmm2 = | 0 | 0 | 0 | P9 |	

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm3, [r15]				;xmm3 = | P16 | P15 | P14 | P13 |
	pslld xmm3, 12					;xmm3 = | P13 | 0 | 0 | 0 |
	psrld xmm3, 12					;xmm3 = | 0 | 0 | 0 | P13 |

	; addps xmm0, xmm1
	; addps xmm0, xmm2
	; addps xmm0, xmm3

	mov r15, r10

	lea r15, [r15 + r9d*4]
	lea r15, [r15 - 16]

	movdqu xmm5, [r15]
	movdqu xmm6, [andultimos4]

	pandn xmm5, xmm6
	addps xmm0, xmm5
	mulps xmm0, xmm10
	movdqu [r15], xmm0

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm1, xmm5
	mulps xmm1, xmm10
	movdqu [r15], xmm1

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm2, xmm5
	mulps xmm2, xmm10
	movdqu [r15], xmm2

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm3, xmm5
	mulps xmm3, xmm10
	movdqu [r15], xmm3

	mov r15, r10

	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila

	lea r15, [r15 + r8d*r9d*4]		;voy a la anteultima fila

	pxor xmm0, xmm0

	mov r14, r15
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	mov r15, r14
	lea r15, [r15 + r9d*4]
	movdqu [r15], xmm0	

	mov r15, r10

	lea r15, [r15 + 4]

	jmp .ciclo1

.ciclo2:						;b == 2

	mov r11, r9d
	mul r11, r11
	cmp r15, r11
	je .fin
	;ahora x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];

	mov r10, r15					;backapeo puntero

	pxor xmm0, xmm0
	pxor xmm1, xmm1

	mov r14, r15
	lea r15, [r15 + r9d*4]
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	movdqu xmm1, [negativos]		;| -1.0 | -1.0 | -1.0 | -1.0 |
	mulps xmm0, xmm1				;| -x[IX(i+3, 1)] | -x[IX(i+2, 1)] | -x[IX(i+1, 1)] | -x[IX(i, 1)] |
	mov r15, r14
	movdqu [r15], xmm0			

	;ahora x[IX(0  ,i)] = b==1 ? -x[IX(1,i)] : x[IX(1,i)];

	pxor xmm0, xmm0
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm3, xmm3

	pxor xmm5, xmm5
	pxor xmm6, xmm6
	pxor xmm7, xmm7
	pxor xmm8, xmm8

	mov r15, r10

	lea r15, [r15 + 4]

	movdqu xmm0, [r15]				;xmm0 = | P4 | P3 | P2 | P1 |
	pslld xmm0, 12					;xmm0 = | P1 | 0 | 0 | 0 |
	psrld xmm0, 12					;xmm0 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm1, [r15]				;xmm1 = | P4 | P3 | P2 | P1 |
	pslld xmm1, 12					;xmm1 = | P1 | 0 | 0 | 0 |
	; psrld xmm1, 8
	psrld xmm1, 12					;xmm1 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]
	movdqu xmm2, [r15]
	pslld xmm2, 12
	; psrld xmm2,	4
	psrld xmm2, 12

	lea r15, [r15 + r9d*4]
	movdqu xmm3, [r15]
	pslld xmm3, 12
	psrld xmm3, 12

	; addps xmm0, xmm1
	; addps xmm0, xmm2
	; addps xmm0, xmm3

	mov r15, r10

	movdqu xmm5, [r15]
	movdqu xmm6, [andprimeros4]

	pandn xmm5, xmm6
	addps xmm0, xmm5
	movdqu [r15], xmm0

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm1, xmm5
	movdqu [r15], xmm1

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm2, xmm5
	movdqu [r15], xmm2

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm3, xmm5
	movdqu [r15], xmm3

	;ahora x[IX(N+1,i)] = b==1 ? -x[IX(N,i)] : x[IX(N,i)]; ultima columna

	mov r15, r10

	pxor xmm0, xmm0
	pxor xmm1, xmm1
	pxor xmm2, xmm2
	pxor xmm3, xmm3

	pxor xmm5, xmm5
	pxor xmm6, xmm6
	pxor xmm7, xmm7
	pxor xmm8, xmm8

	lea r15, [r15 + r9d*4]
	lea r15, [r15 - 16]

	movdqu xmm0, [r15]				;xmm0 = | P4 | P3 | P2 | P1 |
	pslld xmm0, 12					;xmm0 = | P1 | 0 | 0 | 0 |
	psrld xmm0, 12					;xmm0 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]			;subo una fila
	movdqu xmm1, [r15]				;xmm1 = | P4 | P3 | P2 | P1 |
	pslld xmm1, 12					;xmm1 = | P1 | 0 | 0 | 0 |
	; psrld xmm1, 8
	psrld xmm1, 12					;xmm1 = | 0 | 0 | 0 | P1 |

	lea r15, [r15 + r9d*4]
	movdqu xmm2, [r15]
	pslld xmm2, 12
	; psrld xmm2,	4
	psrld xmm2, 12

	lea r15, [r15 + r9d*4]
	movdqu xmm3, [r15]
	pslld xmm3, 12
	psrld xmm3, 12

	; addps xmm0, xmm1
	; addps xmm0, xmm2
	; addps xmm0, xmm3

	mov r15, r10

	lea r15, [r15 + r9d*4]
	lea r15, [r15 - 16]

	movdqu xmm5, [r15]
	movdqu xmm6, [andultimos4]

	pandn xmm5, xmm6
	addps xmm0, xmm5
	movdqu [r15], xmm0

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm1, xmm5
	movdqu [r15], xmm1

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm2, xmm5
	movdqu [r15], xmm2

	lea r15, [r15 + r9d*4]

	movdqu xmm5, [r15]
	pandn xmm5, xmm6
	addps xmm3, xmm5
	movdqu [r15], xmm3

	mov r15, r10

	;x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];	;ultima fila

	lea r15, [r15 + r8d*r9d*4]
	;estoy en la anteultima fila

	pxor xmm0, xmm0

	mov r14, r15
	movdqu xmm0, [r15]				;| x[IX(i+3, 1)] | x[IX(i+2, 1)] | x[IX(i+1, 1)] | x[IX(i, 1)] |
	movdqu xmm1, [negativos]		;| -1.0 | -1.0 | -1.0 | -1.0 |
	mulps xmm0, xmm1				;| -x[IX(i+3, 1)] | -x[IX(i+2, 1)] | -x[IX(i+1, 1)] | -x[IX(i, 1)] |
	mov r15, r14
	lea r15, [r15 + r9d*4]
	movdqu [r15], xmm0	

	mov r15, r10

	lea r15, [r15 + 4]
	jmp .ciclo2

.fin:

	pxor xmm0, xmm0
	pxor xmm1, xmm1

	mov r15, r10
	lea r15, [r15 + 4]
	mov r14, [r15]			;x[IX(1,0  )]
	insertps xmm0, r14, 0
	
	mov r15, r10
	lea r15, [r15 + r9d*4]
	mov r14, [r15]			;x[IX(0  ,1)]
	insertps xmm1, r14, 0
	
	mov r15, r10
	lea r15, [r15 + r8d*ebx*4]		
	mov r14, [r15]			;x[IX(0  ,N)]
	insertps xmm1, r14, 32
	
	mov r15, r10
	lea r15, [r15 + r8d*r9d*4 + 4]
	mov r14, [r15]			;x[IX(1,N+1)]
	insertps xmm0, r14, 32

	mov r15, r10
	lea r15, [r15 + ebx*4]
	mov r14, [r15]			;x[IX(N,0  )]
	insertps xmm0, r14, 64

	mov r15, r10
	lea r15, [r15 + ]
							;x[IX(N+1,1)]


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