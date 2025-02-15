;**********************************************************
;Universidad del Valle de Guatemala
;IE2023 : Programación de Microcontroladores
;Test.asm
;
;Autor: Joshua Vásquez
;Proyecto: Prelab 2
;Hardware: ATMega328P
;Creado: 2/13/2025
;Modificado :
;Descripcion: Contador binario de 4 bits cada 100ms

;**************************************
;ENCABEZADO
;******************************************
.include "M328PDEF.inc"
.CSEG
.ORG 0x0000	
rjmp setup

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

	//CONFIGURAMOS EL PUERTO C
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRC, R16

	//CONFIGURAMOS EL PUERTO D
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRD, R16

	// CONFIGURACMOS EL TIMER0
	LDI		R16, 0x00
	OUT		TCCR0A, R16			// TCCR0A es el registro de control de TIMER0
	// con 0x00 activamos el modo normal del timer0 
	LDI		R16, (1 << CS01) | (1 << CS00)	// PRESCALER DE 64  
	OUT		TCCR0B, R16	
	
	// Configuracion para apagar los demas leds del arduino 
    ldi r16, 0x00
    sts UCSR0B, r16

	// R17 contador de 4 bits 
	LDI		R17, 0x00
	
	

void_loop:
	LDI		R16, 0x00
	OUT		TCNT0, R16		// Reiniciamos el contador 
	LDI		R18, 6			// Vamos a repetir el proceso 6 veces

esperar_100ms:
	IN		R16, TIFR0		// lee la bandera de interrupcion del timer0
	SBRS	R16, TOV0		// Salta a la siguiente si el bit de desborde no es set
	RJMP	esperar_100ms

	LDI		R16, (1 << TOV0)
	OUT		TIFR0, R16		// Borra la bandera de desborde

	DEC		R18
	BRNE	esperar_100ms		// vuelve a 100ms hasta que r18 sea cero


	INC		R17
	ANDI	R17, 0x0F

	OUT		PORTC, R17
	RJMP	void_loop