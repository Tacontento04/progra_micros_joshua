;**********************************************************
;Universidad del Valle de Guatemala
;IE2023 : Programación de Microcontroladores
;Test.asm
;
;Autor: Joshua Vásquez
;Proyecto: LAB3
;Hardware: ATMega328P
;Creado: 21/02/2025
;Modificado :
;Descripcion: Este programa consiste en un contador binario de 4 bits interrupciones

;**************************************
;ENCABEZADO
;******************************************
.include "M328PDEF.inc"
.CSEG
.ORG	0x0000	
	JMP START
.ORG	PCI0addr
	JMP	INT_BOTONAZO
.ORG	OVF0addr
	JMP	timer0_overflow
;***************************************
; STACK POINTER
;****************************************
START:
LDI R16, LOW(RAMEND) 
OUT SPL, R16 
LDI R16, HIGH(RAMEND)
OUT SPH, R16

;***********************************************
;CONFIGURACION 
;***********************************************
SETUP:
CLI		// inabilitamos interrupciones
//			TIMER 0
//CONFIGURAMOS EL PRESCALER PRINCIPAL
	LDI		R16, (1 << CLKPCE)		// Habilitar cambio de prescaler
	STS		CLKPR, R16
	LDI		R16, (1 << CLKPS2)
	STS		CLKPR, R16				// CONFIGURAMOS PRESCALER A 16 F_CPU = 1Mhz
// CONFIGURACMOS EL TIMER0
	LDI		R16, 0x00
	OUT		TCCR0A, R16			// TCCR0A es el registro de control de TIMER0
// con 0x00 activamos el modo normal del timer0 
	LDI		R16, (1 << CS01) | (1 << CS00)	// PRESCALER DE 64
	OUT		TCCR0B, R16	
//ACTIVAMOS INTERRUMCION DE OVERFLOW
	LDI R16, (1 << TOIE0)
    STS TIMSK0, R16 

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

// CONFIGURACION DE INTERRUPCIONES 
	LDI		R16, (1 << PCINT1) | (1 << PCINT0) 
	STS		PCMSK0, R16
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16

// Configuracion para apagar los demas leds del arduino 
    ldi r16, 0x00
    sts UCSR0B, r16

// R20 contador de 4 bits 
	LDI		R20, 0x00

//	R18 CONTADOR DEL DISPLAY
	LDI		R18, 0x00

// Estado botones inicialmente encendidos 
	LDI		R23, 0xFF

	SEI

void_loop:
	CALL	DISPLAY_UPDATE
	RJMP	void_loop

// Interrupt routines 
INT_BOTONAZO:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	
	IN		R21, PINB
	MOV		R22, R21		//Guardamos el estado actual 
	SBRS	R22, 0
	CALL	aumento 
	SBRS	R22, 1
	CALL	decremento
	OUT		PORTC, R20
	LDI		R16, (1 << PCIF0)   ; Limpiar la bandera de interrupción de Pin Change
	STS		PCIFR, R16


	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

timer0_overflow:
	PUSH	R16
    IN		R16, SREG
    PUSH	R16

	CLI
    INC		R17         // Incrementamos el contador de interrupciones
	SEI
	CPI		R18, 0x0A
	BREQ	reset_display
    CPI		R17, 61     // 61 interumpiones 
    BRNE	END_ISR    // Si no, salir de la interrupción

    LDI		R17, 0x00   // Reiniciar el contador de interrupciones
    INC		R18         // Incrementar el contador de segundos

END_ISR:
    POP		R16
    OUT		SREG, R16
    POP		R16
    RETI

// SUBRUTINAS SIN INTERUPCIONES 
aumento: 
	CPI		R20, 0x0F		// Comparamaos si es igual a 0x0F si no saltamos
	BREQ	RESET			//reseteamos el contador
	INC		R20
	RET

decremento: 
	CPI		R20, 0x00		// Comparamos si es igual a 0 si restamos tenemos overflow
	BREQ	MAXEO
	DEC		R20
	RET

RESET:	
	LDI		R20, 0x00
	RET

reset_display:
	LDI		R18, 0x00
	RET	

MAXEO:					//REiniciamos a su valor maximo 
	LDI		R20, 0x0F
	RET

DISPLAY_UPDATE:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R18				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
    RET
	

;*************** TABLA DE BÚSQUEDA ***************
TABLE:
    .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E