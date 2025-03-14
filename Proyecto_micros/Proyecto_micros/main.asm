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
.equ	T0VALUE = 100
.equ	modos =		9
.equ	MAX_displayA	=	10
.equ	MAX_displayB	=	6
.equ	MAX_displayC	=	10
.equ	MAX_displayD	=	3


.def	COUNTER		=	R19
.def	COUNTER2	=	R25
.def	COUNTER3	=	R18
.def	MODE		=	R20
.def	displayA	=	R21
.def	displayB	=	R22
.def	displayC	=	R23
.def	displayD	=	R24

.CSEG	
.ORG	0x0000	
	JMP START
.ORG	PCI2addr
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

	//CONFIGURAMOS EL PUERTO B
	LDI		R16, 0xFF		 //Configuramos el purto B como salida
	OUT		DDRB, R16

	//CONFIGURAMOS EL PUERTO D
	LDI		R16, 0xFF		 //Configuramos el purto D como salida
	OUT		DDRD, R16

	//CONFIGURAMOS PUERTO C
	LDI		R16, 0x00		// Configuramos el puerto C como entrada 
	OUT		DDRC, R16
	LDI		R16, 0xFF		//Activamos pull up
	OUT		PORTC, R16

;**********************************
;CONFIGURACION DE TIMER 
;**********************************
	CALL	INIT_TMR0

;*********************************
;CONFIGURACION DE INTERRUPCIONES 
;**********************************
	LDI		R16, (1 << PCINT1) | (1 << PCINT0) 
	STS		PCMSK0, R16
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16
	// enable TOEIE1 to generate an interrupt
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16


// Configuracion para apagar los demas leds del arduino 
    ldi r16, 0x00
    sts UCSR0B, r16

;*********************************
;INICIANDO VARIAVLES 
;***********************************
	CLR		R20
	CLR		R21
	CLR		R22
	CLR		R23
	CLR		R24
	CLR		COUNTER
	CLR		COUNTER2
	CLR		COUNTER3

	// habilita interrupciones
	SEI

void_loop:
	OUT		PORTC, COUNTER

	CPI		MODE, 0
	BREQ	estado1
	CPI		MODE, 1
	BREQ	estado2
	CPI		MODE, 2
	BREQ	estado3
	RJMP	void_loop



estado1:
	SBRC	COUNTER, 0
	CALL	DISPLAY_UPDATEA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_UPDATEB
	SBRS	COUNTER, 0
	CALL	DISPLAY_UPDATEC
	SBRS	COUNTER, 0
	CALL	DISPLAY_UPDATED
	rjmp	void_loop

estado2:
RJMP	void_loop

estado3:
RJMP	void_loop

;*********************************
;SUB RUTINAS 
;*********************************
INIT_TMR0:		//configuramos el timer0
	LDI		R16, 0x00			
	OUT		TCCR0A, R16				//modo normal del timer0
	LDI		R16, (1 << CS01) | (1 << CS00)
	OUT		TCCR0B, R16			// configuramos el prescaler con 64
	LDI		R16, T0VALUE
	OUT		TCNT0, R16
	RET 

DISPLAY_UPDATEA:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R21				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB0
    RET

DISPLAY_UPDATEB:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R22				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB1
    RET

DISPLAY_UPDATEC:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R23				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB2
    RET

DISPLAY_UPDATED:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R24				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB3
    RET
;*********************************
;INTERRUPCIONES 
;*********************************
timer0_overflow:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	LDI		R16, T0VALUE
	OUT		TCNT0,	R16
	
	INC		COUNTER
	INC		COUNTER3


	CPI		COUNTER3, 50
	BRNE	EXIT_TMR0_ISR
	CLR		COUNTER3		


   SBI  PIND, 7  ; Alternar el estado del pin D7



	CPI		COUNTER, 100
	BRNE	EXIT_TMR0_ISR
	CLR		COUNTER		



	INC		COUNTER2



	CPI		COUNTER2, 60
	BRNE	EXIT_TMR0_ISR
	CLR		COUNTER2
	INC		displayA
	CPI		displayA, MAX_displayA
	BRNE	EXIT_TMR0_ISR
	CLR		displayA

	INC		displayB
	CPI		displayB, MAX_displayB
	BRNE	EXIT_TMR0_ISR
	CLR		displayB 

	INC		displayC
	CPI		displayC, MAX_displayC
	BRNE	check_24
	CLR		displayC 

	INC		displayD
	
check_24:
	CPI		displayD, 2
	BRNE	EXIT_TMR0_ISR
	CPI		displayC, 4
	BRNE	EXIT_TMR0_ISR
	
	CLR     displayD
    CLR     displayC
    CLR     displayB
    CLR     displayA


	RJMP	EXIT_TMR0_ISR


EXIT_TMR0_ISR:
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
	
INT_BOTONAZO:

//Revisamos si pasamos la cantidad maxima de modos (setear a 0 si si)
	LDI		R16, modos
	CPSE	MODE, R16
	RJMP	PC+2
	CLR		MODE 
	RETI 
	RETI 
;*************** TABLA DE BÚSQUEDA ***************
TABLE:
    .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E