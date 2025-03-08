;**********************************************************
;Universidad del Valle de Guatemala
;IE2023 : Programación de Microcontroladores
;Test.asm
;
;Autor: Joshua Vásquez
;Proyecto: Proyecto 1
;Hardware: ATMega328P
;Creado: 01/03/2025
;Modificado :
;Descripcion: Es un reloj digital 

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
;CONFIGURACION S
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
	OUT		DDRB, R16

	//CONFIGURAMOS EL PUERTO D
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRD, R16

	//CONFIGURAMOS PUERTO B
	LDI		R16, 0x00		// Configuramos el puerto B como entrada 
	OUT		DDRC, R16
	LDI		R16, 0xFF		//Activamos pull up
	OUT		PORTC, R16

// CONFIGURACION DE INTERRUPCIONES 
	LDI		R16, (1 << PCINT1) | (1 << PCINT0) 
	STS		PCMSK0, R16
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16

// Configuracion para apagar los demas leds del arduino 
    ldi r16, 0x00
    sts UCSR0B, r16

	LDI		R21, 0x00
	
// R20 contador de 4 bits 
	LDI		R20, 0x00

//	R18 CONTADOR DEL DISPLAY
	LDI		R18, 0x00

// Estado botones inicialmente encendidos 
	LDI		R23, 0xFF

// R19 contador para el display B
	LDI		R19, 0x00
	SEI

void_loop:
	CALL	displayA		//display de segundos 
	CALL	DELAY 
	CALL	displayB		//display de decenas de segundos
	CALL	DELAY 
	CALL	displayC
	CALL	DELAY
	CALL	displayD
	CALL	DELAY 
	RJMP	void_loop

// Interrupt routines 
INT_BOTONAZO:
	PUSH	R16				//guardasmos la bandera SREG antes de las interrupciones
	IN		R16, SREG
	PUSH	R16
	
	IN		R21, PINC
	MOV		R22, R21		//Guardamos el estado actual 
	SBRS	R22, 4
	CALL	aumento 
	SBRS	R22, 3
	CALL	decremento
	
	LDI		R16, (1 << PCIF0)   //Limpiar la bandera de interrupción de Pin Change
	STS		PCIFR, R16


	POP		R16
	OUT		SREG, R16		//Sacamos el estado donde estabamos
	POP		R16
	RETI

timer0_overflow:
	PUSH	R16
    IN		R16, SREG
    PUSH	R16


    INC		R17         // Incrementamos el contador de interrupciones
	//CPI		R18, 0x0A
	//BREQ	reset_display
	LDI		R27, 0x0A
	CPSE	R18, R27	//Si son iguales salta 
	RJMP	SEGUIR1
	CALL	reset_display1

SEGUIR1:
	//CPI		R19, 0x06
	//BREQ	RESET_TOTAL
	LDI		R27, 0x06
    CPSE	R19, R27		//Si son iguales salta
	RJMP	SEGUIR2
	CALL	RESET_TOTAL
SEGUIR2:
	LDI		R27, 0x0A
	CPSE	R20, R27
	RJMP	SEGUIR3
	CALL	reset_display2
SEGUIR3:
	LDI		R27, 0x06
	CPSE	R21, R27
	RJMP	SEGUIR4
	CALL	RESET_TOTAL2
SEGUIR4:
	CPI		R17, 61     // 61 interumpiones, contamos cada 16.3ms * 61 =994.3ms
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
	CPI		R18, 0x0F		// Comparamaos si es igual a 0x0F si no saltamos
	BREQ	RESET			//reseteamos el contador
	INC		R18
	RET

decremento: 
	CPI		R18, 0x00		// Comparamos si es igual a 0 si restamos tenemos overflow
	BREQ	MAXEO
	DEC		R18
	LDI		R27, 0x00
	CPSE	R18, R27	//Si son iguales salta 
	RJMP	SEGUIR5
	CALL	decremento_DB
SEGUIR5:
	RET

decremento_DB:
	DEC		R19
	RET

RESET:	
	LDI		R18, 0x00
	RET

reset_display1:
	INC		R19
	LDI		R18, 0x00
	RET	

reset_display2:
	INC		R21
	LDI		R20, 0x00
	RET	

MAXEO:					//REiniciamos a su valor maximo 
	LDI		R20, 0x0F
	RET

displayA:
	CBI		PORTB,	1			//apagamos el pin 1
	SBI		PORTB,	0			//encendemos el pin 0
	CBI		PORTB,	2
	CBI		PORTB,	3 
	CALL	DISPLAY_UPDATEA		// mostramos los segundos
	RET
displayB:
	CBI		PORTB,	0			// apagamos el bit 0
	SBI		PORTB,	1			//encendemos el bit 1
	CBI		PORTB,	2
	CBI		PORTB,	3 
	CALL	DISPLAY_UPDATEB		//mostramos las decenas de segundos
	RET

displayC:
	CBI		PORTB,	0			// apagamos el bit 0
	SBI		PORTB,	2			//encendemos el bit 1
	CBI		PORTB,	1
	CBI		PORTB,	3 
	CALL	DISPLAY_UPDATEC		//mostramos las decenas de segundos
	RET

displayD:
	CBI		PORTB,	0			// apagamos el bit 0
	SBI		PORTB,	3			//encendemos el bit 1
	CBI		PORTB,	2
	CBI		PORTB,	1 
	CALL	DISPLAY_UPDATED	//mostramos las decenas de segundos
	RET

	
RESET_TOTAL:
	LDI		R19, 0x00
	LDI		R18, 0x00
	INC		R20
	RET

	
RESET_TOTAL2:
	LDI		R20, 0x00
	LDI		R21, 0x00
	RET

DISPLAY_UPDATEA:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R18				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
    RET
	

DISPLAY_UPDATEB:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R19				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R26, Z               // Carga el byte Z en r16
    OUT		PORTD, R26			 // display del valor deseado
    RET

DISPLAY_UPDATEC:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R20				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R26, Z               // Carga el byte Z en r16
    OUT		PORTD, R26			 // display del valor deseado
    RET

DISPLAY_UPDATED:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R21			 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R26, Z               // Carga el byte Z en r16
    OUT		PORTD, R26			 // display del valor deseado
    RET

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
SUB_DELAY4:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY4
	RET
SUB_DELAY5:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY5
	RET
SUB_DELAY6:
	DEC		R25
	CPI		R25, 0
	BRNE	SUB_DELAY6
	RET

;*************** TABLA DE BÚSQUEDA ***************
TABLE:
    .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E