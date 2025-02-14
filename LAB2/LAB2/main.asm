;**********************************************************
;Universidad del Valle de Guatemala
;IE2023 : Programación de Microcontroladores
;Test.asm
;
;Autor: Joshua Vásquez
;Proyecto: LAB 2
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
	LDI		R16, 0xFF		 //Configuramos el purto C como salida
	OUT		DDRC, R16

	//CONFIGURAMOS EL PUERTO D
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRD, R16

	//CONFIGURAMOS PUERTO B
	LDI		R16, 0x00		// Configuramos el puerto B como entrada 
	OUT		DDRB, R16
	LDI		R16, 0xFF		//Activamos pull up
	OUT		PORTB, R16


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

	//R21	Contador del display 
	LDI		R20, 0x00

	// Estado botones inicialmente encendidos 
	LDI		R23, 0xFF

	//Encendemos el pin4 de c como el display es anodo comun 
	sbi PORTC, 4            ; Encender el pin C4


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

	LDI		R16, 26
ajuste_tiempo:
	DEC		R16
	BRNE	ajuste_tiempo

	INC		R17
	ANDI	R17, 0x0F

	OUT		PORTC, R17
	sbi	    PORTC, 4            ; Encender el pin C4	
	



	// ANTIREBOTES 	
	IN		R21, PINB		//Revisamos si el el boton fue presionad
	CP		R23, R21		// Si no hay cambio pasamos a void de nuevo
	BREQ	void_loop
	CALL	DELAY			// si hay cambio nos saltamos a BREQ y hacemos el delay
	IN		R21, PINB
	CP		R23, R21
	BREQ	void_loop		// hacemos lo mismo 2 veces si si hubo un cambio
	CALL	DELAY
	CALL	BOTONES
	CALL	DISPLAY_UPDATE
	RJMP	void_loop

BOTONES:
	IN		R21, PINB
	MOV		R22, R21		//Guardamos el estado actual 
	SBRS	R22, 0
	CALL	aumento 
	SBRS	R22, 1
	CALL	decremento
	RET

aumento:
	INC		R20
	RET
decremento: 
	DEC		R20
	RET	


DISPLAY_UPDATE:
    LDI ZH, HIGH(TABLE<<1)   ; Dirección alta de la tabla
    LDI ZL, LOW(TABLE<<1)    ; Dirección baja de la tabla
    ADD ZL, R20              ; Sumar el índice
    ADC ZH, R1               ; Propagar el acarreo en caso de ser necesario (R1 siempre es 0)
    LPM R16, Z               ; Leer el valor de la tabla
    OUT PORTD, R16           ; Enviar a PORTD para mostrar en el display
	CALL	DELAY 
    RJMP	void_loop

DELAY:
	LDI		R25, 0xFF
SUB_DELAY1:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY1
	LDI		R25, 0xFF
SUB_DELAY2:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY2
	LDI		R25, 0xFF
SUB_DELAY3:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY3
	RET

	

;*************** TABLA DE BÚSQUEDA ***************
TABLE:
    .DB 0x40  ; "0"
    .DB 0x79  ; "1"
    .DB 0x24  ; "2"
    .DB 0x30  ; "3"
    .DB 0x19  ; "4"
    .DB 0x12  ; "5"
    .DB 0x02  ; "6"
    .DB 0x38  ; "7"
    .DB 0x00  ; "8"
    .DB 0x10  ; "9"
    .DB 0x08  ; "A"
    .DB 0x03  ; "B"
    .DB 0x46  ; "C"
    .DB 0x21  ; "D"
    .DB 0x06  ; "E"
    .DB 0x0E  ; "F"
