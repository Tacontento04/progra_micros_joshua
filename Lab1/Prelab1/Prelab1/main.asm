;**********************************************************
;Universidad del Valle de Guatemala
;IE2023 : Programación de Microcontroladores
;Test.asm
;
;Autor: Joshua Vásquez
;Proyecto: Prelab 1
;Hardware: ATMega328P
;Creado: 5/2/2025
;Modificado :
;Descripcion: Este programa consiste en un contador binario de 4 bits.  

;**************************************
;ENCABEZADO
;******************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x0000	

;***************************************
; STACK POINTER
;****************************************
LDI R16, LOW(RAMEND) 
OUT SPL, R16 
LDI R16, HIGH(RAMEND)
OUT SPH, R16

;***********************************************
;CONFIGURACION 
;***********************************************
SETUP:
	//CONFIGURAMOS EL PRESCALER PRINCIPAL
	LDI		R16, (1 << CLKPCE)		// Habilitar cambio de prescaler
	STS		CLKPR, R16
	LDI		R16, (1 << CLKPS2)
	STS		CLKPR, R16				// CONFIGURAMOS PRESCALER A 16 F_CPU = 1Mhz

	//Configuracion de pines de entrada y salida (DDRx, Portx, PINX)
	// PORTD con entrada pull-up habilitado 
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRD, R16
	
	LDI		R16, 0xFF		 //Configuramos el purto C como salida
	OUT		DDRC, R16

	
	LDI		R16, 0x00		// Configuramos el puerto B como entrada 
	OUT		DDRB, R16
	LDI		R16, 0xFF		//Activamos pull up
	OUT		PORTB, R16

	// Usamos R17 para guardar el estado de los botones inicialmente encendidos
	LDI	R17, 0xFF

	// Usamos r19 como nuestro contador 
	LDI R19, 0x00

	// Usamos R20 como contador
	LDI R20, 0x00

;********************************************
;LOOP INFINITO 
;******************************************
void_loop:
	IN		R16, PINB		//Revisamos si el el boton fue presionad
	CP		R17, R16		// Si no hay cambio pasamos a void de nuevo
	BREQ	void_loop
	CALL	DELAY			// si hay cambio nos saltamos a BREQ y hacemos el delay
	IN		R16, PINB
	CP		R17, R16
	BREQ	void_loop		// hacemos lo mismo 2 veces si si hubo un cambio
	MOV		R17, R16		// Guardamos el estado nuevo 
	
	SBRS	R16, 2
	CALL	PINND
	SBRS	R16, 3
	CALL	PINND 	

	SBRS	R16, 0
	CALL	PINNC
	SBRS	R16, 1
	CALL	PINNC
	SBRS	R16, 4
	CALL	SUMADOR 
	CALL	UPDATE_PORTD
	RJMP	void_loop	
		


PINNC:
	sbrs	R16, 0 // Este pin sera el boton de decrementar
	CALL	DECREMENTO	// si el boton esta en set saltamos 
	SBRS	R16, 1	// Este pin sera el boton de aumentar
	CALL	AUMENTO	// llamamos a aumentar
	RET


DECREMENTO:
	CPI		R20, 0x00	// Comparamos si es igual a 0 no hacemos nada
	BREQ	void_loop	
	dec		r20
	out		PORTD,	r20
	ret

AUMENTO:
	CPI		R20, 0x0F		// Comparamos para ver si es 15 si lo es entonces saltamos
	BREQ	RESET		// reseteamos el registro
	inc		r20
	out		PORTD, R20
	RET

RESET:
	LDI	R20, 0x00		// reseteamos el registro
	RJMP void_loop			// regresamos a main


PINND: 
	sbrs	R16, 2 // Este pin sera el boton de decrementar
	CALL	DECREMENTAR	// si el boton esta en set saltamos 
	SBRS	R16, 3	// Este pin sera el boton de aumentar
	CALL	AUMENTAR	// llamamos a aumentar
	RET


DECREMENTAR:
	CPI		R19, 0x0F	// Comparamos si es igual a 0 no hacemos nada
	BREQ	void_loop	
	dec		r19
	out		PORTD, r21
	ret

AUMENTAR:
	CPI		R19, 0xFF		// Comparamos para ver si es 15 si lo es entonces saltamos
	BREQ	RESETEO
	inc		r19
	CALL	UPDATE_PORTD
	RET

RESETEO:
	LDI	R19, 0x00		// reseteamos el registro
	RJMP void_loop			// regresamos a main

UPDATE_PORTD:
	MOV		R21, R19
	ANDI	R21, 0x0F
    SWAP    R21            
	OR		R21, R20
	OUT		PORTD, R21
    RET

SUMADOR: 
    LDI     R22, 0x00 
    MOV     R22, R19
    ANDI    R22, 0x0F    
    ANDI    R20, 0x0F    
    ADD     R22, R20     

    ; Guardar el resultado antes de modificar PORTC
       
    OUT     PORTC, R22  

    RET

DELAY:
	LDI		R18, 0xFF
SUB_DELAY1:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY1
	LDI		R18, 0xFF
SUB_DELAY2:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY2
	LDI		R18, 0xFF
SUB_DELAY3:
	DEC		R18
	CPI		R18, 0
	BRNE	SUB_DELAY3
	RET

	



	



