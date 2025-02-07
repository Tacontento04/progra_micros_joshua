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
	//Configuracion de pines de entrada y salida (DDRx, Portx, PINX)
	// PORTD con entrada pull-up habilitado 
	LDI		R16, 0b1111_0000		 //Queremos activar los pines d0, d1, d2 d3 como entradas y el resto como salidas
	OUT		DDRD, R16
	LDI		R16, 0b0000_1111		 //Cambiamos R16 para que ahora sean pull-ups el port d0, d1, d2, d3
	OUT		PORTD, R16
	
	// Usamos R17 para guardar el estado de los botones inicialmente encendidos
	LDI R17, 0xFF

	// Usamos r19 como nuestro contador 
	LDI R19, 0x00

;********************************************
;LOOP INFINITO 
;******************************************
void_loop:
	IN		R16, PIND		//Revisamos si el el boton fue presionado
	CP		R17, R16		// Si no hay cambio basamos a void de nuevo
	BREQ	void_loop
	CALL	DELAY			// si hay cambio nos saltamos a BREQ y hacemos el delay
	IN		R16, PIND
	CP		R17, R16
	BREQ	void_loop		// hacemos lo mismo 2 veces si si hubo un cambio 


	sbrs	R16, PIND0 // Este pin sera el boton de decrementar
	CALL	DECREMENTAR	// si el boton esta en set saltamos 
	SBRS	R16, PIND1	// Este pin sera el boton de aumentar
	CALL	AUMENTAR	// llamamos a aumentar
	RJMP	void_loop


DECREMENTAR:
	CPI		R19, 0x00	// Comparamos si es igual a 0 no hacemos nada
	BREQ	void_loop	
	dec		r17
	out		PORTD,	r17
	ret

AUMENTAR:
	CPI	R19, 0x0F		// Comparamos para ver si es 15 si lo es entonces saltamos
	BREQ RESETEO		// reseteamos el registro
	inc r17
	out	PORTD, R17
	RET

RESETEO:
	LDI	R19, 0x00		// reseteamos el registro
	RJMP void_loop			// regresamos a main

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

	



	



