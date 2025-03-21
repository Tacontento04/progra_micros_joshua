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

.def	MESES		=	R17
.def	COUNTER		=	R19
.def	COUNTER2	=	R25
.def	COUNTER3	=	R18
.def	MODE		=	R20
.def	displayA	=	R21
.def	displayB	=	R22
.def	displayC	=	R23
.def	displayD	=	R24
.def	alarmaA		=	R10
.def	alarmaB		=	R11
.def	alarmaC		=	R12
.def	alarmaD		=	R13
.def	fechaA		=	R5
.def	fechaB		=	R6
.def	fechaC		=	R7		//decena del mes
.def	fechaD		=	R8		//unidad del mes

.DSEG	
ESTADO_ANTERIORB1:	.BYTE 1
ESTADO_ACTUALB1:	.BYTE 1

.CSEG	
.ORG	0x0000	
	JMP START
.ORG	PCI1addr
	JMP	INT_BOTONAZOC
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
	LDI		R16, 0b11000111		// Configuramos el puerto C como entrada 
	OUT		DDRC, R16
	LDI		R16, 0b00111000			//Activamos pull up
	OUT		PORTC, R16

;**********************************
;CONFIGURACION DE TIMER 
;**********************************
	CALL	INIT_TMR0
	CALL	INIT_PORTC
;*********************************
;CONFIGURACION DE INTERRUPCIONES 
;**********************************

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
	CLR		MODE
	CLR 	alarmaA
	CLR		alarmaB
	CLR		alarmaC
	CLR		alarmaD
	CLR		R29
	LDI		R16, 0x01
	MOV		fechaA, R16
	CLR		fechaB
	CLR		fechaC
	MOV		fechaD, R16
	CLR		MESES
	CLR		R28
 
	// habilita interrupciones


;*************** TABLA DE BÚSQUEDA ***************
TABLE:
    .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E

dias_del_mes:  // mas 2 dias a todos los dias del mes por un bug del codigo
	.DB	0x33, 0x30, 0x33, 0x32, 0x33, 0x32, 0x33, 0x33, 0x32, 0x33, 0x32, 0x33
	// pero si te das cuenta si le restas 2 a cada uno da lo que deberia de ser 
		SEI

void_loop:


    CPI     MODE, 0
    BRNE    check1
    RJMP    estado1
check1:
    CPI     MODE, 1
    BRNE    check2
    RJMP    estado2
check2:
    CPI     MODE, 2
    BRNE    check3
    RJMP    estado3
check3:
    CPI     MODE, 3
    BRNE    check4
    RJMP    estado4
check4:
    CPI     MODE, 4
    BRNE    check5
    RJMP    estado5
check5:
    CPI     MODE, 5
    BRNE    check6
    RJMP    estado6
check6:
    CPI     MODE, 6
    BRNE    check7
    RJMP    estado7
check7:
    CPI     MODE, 7
    BRNE    check8
    RJMP    estado8
check8:
    CPI     MODE, 8
    BRNE    void_loop
    RJMP    estado9

RJMP    void_loop  ; Si no coincide con ningún estado, repetir el loop

estado1:	//Reloj normal
	
	//leds de modo
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2

	IN      R16, PINC          ; Leer el estado del puerto C
	ANDI    R16, 0b00011000    ; Filtrar solo A3 (C3) y A4 (C4)
	CPI     R16, 0b00011000    ; ¿Están ambos en 1? (ninguno presionado)
	BREQ    check_alarm        ; Si ambos están en 1, saltar (ningún botón presionado)
	CBI     PORTB, PB5         ; Si al menos uno está presionado, apagar B5

check_alarm:
	SBRC    R29, 0             ; Si el bit 0 de R29 es 1...
	CALL    ALARMA             ; Llamar a la subrutina ALARMA

	SBRC	COUNTER, 0
	CALL	DISPLAY_UPDATEA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_UPDATEB
	SBRC	COUNTER, 0
	CALL	DISPLAY_UPDATEC
	SBRS	COUNTER, 0
	CALL	DISPLAY_UPDATED
	rjmp	void_loop

estado2: //configurar reloj normal (MINUTOS)
	
	SBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2

	SBRC	COUNTER, 0
	CALL	DISPLAY_UPDATEA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_UPDATEB


	IN		R16, PINC		; Leer el estado de los botones
	MOV		R26, R16		; Copiar el valor a R26

	; Detectar botón de aumento con antirrebote
	SBRS	R15, 3 	; Si BUTTON_STATE[3] está en 0 (botón suelto)
	SBRS	R26, 3				; Si R26[3] está en 0 (botón presionado)
	CALL	aumento				; Llamar a la función de aumento

	; Detectar botón de decremento con antirrebote
	SBRS	R15, 4		; Si BUTTON_STATE[4] está en 0 (botón suelto)
	SBRS	R26, 4				; Si R26[4] está en 0 (botón presionado)
	CALL	decremento			; Llamar a la función de decremento

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura


RJMP	void_loop
estado3: // configurar reloj normal (HORAS)

	CBI		PORTC, PC0
	SBI		PORTC, PC1
	CBI		PORTC, PC2

	SBRS	COUNTER, 0
	CALL	DISPLAY_UPDATEC
	SBRC	COUNTER, 0
	CALL	DISPLAY_UPDATED

	IN		R16, PINC		; Leer el estado de los botones
	MOV		R26, R16		; Copiar el valor a R15

	; Detectar botón de aumento con antirrebote
	SBRS	R15, 3 	; Si BUTTON_STATE[3] está en 0 (botón suelto)
	SBRS	R26, 3				; Si R15[3] está en 0 (botón presionado)
	CALL	aumento2				; Llamar a la función de aumento

	; Detectar botón de decremento con antirrebote
	SBRS	R15, 4		; Si BUTTON_STATE[4] está en 0 (botón suelto)
	SBRS	R26, 4				; Si R15[4] está en 0 (botón presionado)
	CALL	decremento2			; Llamar a la función de decremento

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura

	rjmp	void_loop

estado4:  // ENSEÑAR ALARMA
	
	IN      R16, PINC          ; Leer el estado del puerto C
	ANDI    R16, 0b00011000    ; Filtrar solo A3 (C3) y A4 (C4)
	CPI     R16, 0b00011000    ; ¿Ambos están en 1? (ninguno presionado)
	BREQ    no_alarma          ; Si ninguno está presionado, saltar
	LDI     R29, 0x01          ; Si A3 o A4 están presionados, cargar 0x01 en R29

no_alarma:

	SBRC	COUNTER, 0
	CALL	DISPLAY_ALARMAA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_ALARMAB
	SBRC	COUNTER, 0
	CALL	DISPLAY_ALARMAC
	SBRS	COUNTER, 0
	CALL	DISPLAY_ALARMAD


	SBI		PORTC, PC0
	SBI		PORTC, PC1
	CBI		PORTC, PC2

	rjmp	void_loop

estado5: //	CONFIGURAR ALARMA AB (MINUTOS)

	CBI		PORTC, PC0
	CBI		PORTC, PC1
	SBI		PORTC, PC2

	SBRC	COUNTER, 0
	CALL	DISPLAY_ALARMAA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_ALARMAB

	IN		R16, PINC		; Leer el estado de los botones
	MOV		R26, R16		; Copiar el valor a R26

	; Detectar botón de aumento con antirrebote
	SBRS	R15, 3 	; Si BUTTON_STATE[3] está en 0 (botón suelto)
	SBRS	R26, 3				; Si R26[3] está en 0 (botón presionado)
	CALL	aumento3				; Llamar a la función de aumento

	; Detectar botón de decremento con antirrebote
	SBRS	R15, 4		; Si BUTTON_STATE[4] está en 0 (botón suelto)
	SBRS	R26, 4				; Si R26[4] está en 0 (botón presionado)
	CALL	decremento3			; Llamar a la función de decremento

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura

	rjmp	void_loop

estado6: // CONFIGURAR ALARMA CD (HORAS)

	SBI		PORTC, PC0
	CBI		PORTC, PC1
	SBI		PORTC, PC2

	SBRC	COUNTER, 0
	CALL	DISPLAY_ALARMAC
	SBRS	COUNTER, 0
	CALL	DISPLAY_ALARMAD

	IN		R16, PINC		; Leer el estado de los botones
	MOV		R26, R16		; Copiar el valor a R26

	; Detectar botón de aumento con antirrebote
	SBRS	R15, 3 	; Si BUTTON_STATE[3] está en 0 (botón suelto)
	SBRS	R26, 3				; Si R26[3] está en 0 (botón presionado)
	CALL	aumento4				; Llamar a la función de aumento

	; Detectar botón de decremento con antirrebote
	SBRS	R15, 4		; Si BUTTON_STATE[4] está en 0 (botón suelto)
	SBRS	R26, 4				; Si R26[4] está en 0 (botón presionado)
	CALL	decremento4		; Llamar a la función de decremento

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura

	RJMP	void_loop

estado7: //mostrar fecha
	CBI		PORTC, PC0
	SBI		PORTC, PC1
	SBI		PORTC, PC2

	SBRC	COUNTER, 0
	CALL	DISPLAY_fechaA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_fechaB
	SBRC	COUNTER, 0
	CALL	DISPLAY_fechaC
	SBRS	COUNTER, 0
	CALL	DISPLAY_fechaD

	

	RJMP	void_loop
estado8: // incrementar decrementar meses
	SBI		PORTC, PC0
	SBI		PORTC, PC1
	SBI		PORTC, PC2
	clr		R16

	IN		R16, PINC		
	MOV		R26, R16		

	
	SBRS	R15, 3 
	SBRS	R26, 3				
	CALL	incremento_mes		

	SBRS	R15, 4		
	SBRS	R26, 4				
	CALL	decremento_mes

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura

	SBRC	COUNTER, 0
	CALL	DISPLAY_fechaC
	SBRS	COUNTER, 0
	CALL	DISPLAY_fechaD



	RJMP	void_loop
estado9: //incrementar/ decrementar  dias

	SBRC	COUNTER, 0
	CALL	DISPLAY_fechaA
	SBRS	COUNTER, 0 
	CALL	DISPLAY_fechaB
	CLR		R16

	IN		R16, PINC		
	MOV		R26, R16		

	
	SBRS	R15, 3 
	SBRS	R26, 3				
	CALL	incremento_dia				

	SBRS	R15, 4		
	SBRS	R26, 4				
	CALL	decremento_dia

	MOV		R15, R26	; Guardar el estado actual del botón para la siguiente lectura


	CPI		COUNTER, 10
	BRNE	no_paso_nada

    SBI		PINC, 0 ; Alternar el estado del pin D7
	SBI		PINC, 1 ; Alternar el estado del pin D7
	SBI		PINC, 2 ; Alternar el estado del pin D7
no_paso_nada:

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

INIT_PORTC:
	LDI		R16, (1 << PCINT13) 
	STS		PCMSK1, R16
	LDI		R16, (1 << PCIE1)		// PING CHANCE PARA PORTC 
	STS		PCICR, R16
	RET

ALARMA:
	CPSE	displayA, alarmaA
	RET	
	CPSE	displayB, alarmaB
	RET	
	CPSE	displayC, alarmaC
	RET	
	CPSE	displayD, alarmaD
	RET
	SBI		PORTB, PB5
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

//DISPLAYC ALARMA

	
DISPLAY_ALARMAA:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, alarmaA				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    SBI		PORTB, PB0
	OUT		PORTD, R16			 // display del valor deseado
	
    RET

DISPLAY_ALARMAB:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, alarmaB				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB1
    RET

DISPLAY_ALARMAC:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, alarmaC				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB2
    RET

DISPLAY_ALARMAD:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, alarmaD				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB3
    RET

DISPLAY_FECHAA:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, fechaA				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
	OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB2
    RET

DISPLAY_FECHAB:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, fechaB				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB3
    RET

DISPLAY_FECHAC:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, fechaC				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB1
    RET

DISPLAY_FECHAD:
	CBI		PORTB,  PB3
	CBI		PORTB,  PB2
	CBI		PORTB,  PB1
	CBI		PORTB,  PB0	
	LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, fechaD				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	SBI		PORTB, PB0
    RET

//aumento y decremento PARA A Y B
aumento:



	INC		DISPLAYA
	LDI		R16, 0x0B
	CPSE	DISPLAYA, R16
	RJMP	SEGUIR1
	CALL	RESET
SEGUIR1:
	LDI		R16, 0x06
	CPSE	DISPLAYB, R16
	RJMP	SEGUIR2
	CALL	RESET2
SEGUIR2: 
	RET
	
RESET:
	CLR		DISPLAYA
	INC		DISPLAYB

	RJMP	estado2

RESET2:
	CLR		DISPLAYA
	CLR		DISPLAYB
	RJMP	estado2

decremento:	
	DEC		DISPLAYA				
	CPI		DISPLAYA, 0xFF			
	BREQ	DECDB					
	RET								

DECDB:
	LDI		DISPLAYA, 0x09			
	DEC		DISPLAYB				
	CPI		DISPLAYB, 0xFF			
	BREQ	MAXEO_59				
	RET								

MAXEO_59:
	LDI		DISPLAYA, 0x09			
	LDI		DISPLAYB, 0x05			
	RET



//aumento y decremento PARA d y C

aumento2:
	INC		DISPLAYC
	LDI		R16, 0x0B
	CPSE	DISPLAYC, R16
	RJMP	SEGUIR3
	CALL	RESETCD
SEGUIR3:
	LDI		R16, 0x02
	CPSE	DISPLAYD, R16
	RJMP	SEGUIR4
	CALL	chekeo_24
SEGUIR4: 
	RET
chekeo_24:
	LDI		R16, 0x05
	CPSE	DISPLAYC, R16
	RJMP	SEGUIR5
	CALL	RESET2CD
SEGUIR5:
	RET

RESETCD:
	CLR		DISPLAYC
	INC		DISPLAYD
	RJMP	void_loop

RESET2CD:
	CLR		DISPLAYC
	CLR		DISPLAYD
	RJMP	void_loop	
decremento2:	
	DEC		DISPLAYC				
	CPI		DISPLAYC, 0xFF			
	BREQ	decrement_CD			
	RET								

decrement_CD:
	LDI		DISPLAYC, 0x09			
	DEC		DISPLAYD				
	CPI		DISPLAYD, 0xFF			
	BREQ	MAXEO_23				
	RET								

MAXEO_23:
	LDI		DISPLAYC, 0x03			
	LDI		DISPLAYD, 0x02			 
	RET

// Aumento y decremento de la alarma A Y B (MInutos)
aumento3:
	INC		alarmaA
	LDI		R16, 0x0B
	CPSE	alarmaA, R16
	RJMP	SEGUIRA1
	CALL	RESETA
SEGUIRA1:
	LDI		R16, 0x06
	CPSE	alarmaB, R16
	RJMP	SEGUIRA2
	CALL	RESETA2
SEGUIRA2: 
	RET
	
RESETA:
	CLR		alarmaA
	INC		alarmaB

	RJMP	estado5

RESETA2:
	CLR		alarmaA
	CLR		alarmaB
	RJMP	estado5

decremento3:	
	DEC		alarmaA	
	MOV		R16, alarmaA			
	CPI		R16, 0xFF			
	BREQ	under_alarma					
	RET								

under_alarma:
	LDI		R16, 0x09		
	MOV		alarmaA, R16	
	DEC		alarmaB		
	MOV		R16, alarmaB		
	CPI		R16, 0xFF			
	BREQ	MAXEOA_59				
	RET								

MAXEOA_59:
	LDI		R16, 0x09	
	MOV		ALARMAA, R16		
	LDI		R16, 0x05	
	MOV		ALARMAB, R16		
	RET

// Aumento y decremento de la alarma C y D (HORAS)
aumento4:
	INC		alarmaC
	LDI		R16, 0x0B
	CPSE	alarmaC, R16
	RJMP	SEGUIRA3
	CALL	RESETACD
SEGUIRA3:
	LDI		R16, 0x02
	CPSE	alarmaD, R16
	RJMP	SEGUIRA4
	CALL	chekeo_24A
SEGUIRA4: 
	RET
chekeo_24A:
	LDI		R16, 0x05
	CPSE	alarmaC, R16
	RJMP	SEGUIRA5
	CALL	RESET2ACD
SEGUIRA5:
	RET

RESETACD:
	CLR		alarmaC
	INC		alarmaD
	RJMP	void_loop

RESET2ACD:
	CLR		alarmaC
	CLR		alarmaD
	RJMP	void_loop	
decremento4:	
	DEC		alarmaC		
	MOV		R16, alarmaC		
	CPI		r16, 0xFF			
	BREQ	decrementA_CD			
	RET								

decrementA_CD:
	LDI		R16, 0x09	
	MOV		alarmaC, R16		
	DEC		alarmaD
	MOV		R16, alarmaD			
	CPI		R16, 0xFF			
	BREQ	MAXEO_A23				
	RET								

MAXEO_A23: 
	LDI		R16, 0x03
	MOV		alarmaC, R16			
	LDI		R16, 0x02	
	MOV		alarmaD, R16		 
	RET

//subrutinas modo fecha y dia
incremento_dia:

	PUSH    R26           ; Guardar R17 en la pila
	PUSH    R30           ; Guardar R18 en la pila
	PUSH    R16           ; Guardar R16 en la pila

	MOV     R26, fechaC   ; Mover fechaC a un registro válido (R16-R31)
	LDI     R16, 10       ; Cargar 10 en R16 para multiplicar
	MUL     R26, R16      ; Multiplica fechaC * 10
	MOV     R30, R0       ; Guardar resultado en R18 (MESES temporal)
	CLR     R1            ; Limpiar R1 para evitar datos basura
	ADD     R30, fechaD   ; Sumar fechaD al resultado

	MOV     MESES, R30  ; Guardar el resultado en MESES

	POP     R16           ; Restaurar R16 desde la pila
	POP     R30           ; Restaurar R18 desde la pila
	POP     R26          ; Restaurar R17 desde la pila

	SUBI    MESES, 1         ; Restar 1 para ajustar índice a base 0
	INC		fechaA
	MOV		R16, fechaA
	CPI		R16, 0x0A
	BRNE	checkeo_limite
	CLR		fechaA
	INC		fechaB
	
	

	RET
checkeo_limite:
	LDI     ZL, LOW(dias_del_mes << 1)
    LDI     ZH, HIGH(dias_del_mes << 1)
    ADD     ZL, MESES
    LPM     R28, Z     

    MOV     R16, fechaB
    LSL     R16         
    LSL     R16
    LSL     R16
    LSL     R16
    ADD     R16, fechaA   
    CP      R16, R28
    BRLO    NO_OVERFLOW 
    CALL    OVER_DIA   
NO_OVERFLOW:
    RET
OVER_DIA:
	LDI		R16, 0x01
	MOV		fechaA, R16
    CLR     fechaB   
	RET

	
decremento_dia:
	MOV		R16, fechaB
	CPI		R16, 0x00
	BREQ	RESET_DIA
	DEC		fechaA
	MOV		R16, fechaA
	CPI		R16, 0xFF
	BREQ	DECDIA_REST
	RET
DECDIA_REST: 
	LDI		R16, 0x09
	MOV		fechaA, R16
	DEC		fechaB
	RET
RESET_DIA: 
	DEC		fechaA
	MOV		R16, fechaA
	CPI		R16, 0x00
	BREQ	UNDER_DIA
	RET
UNDER_DIA: 
	LDI		ZL, LOW(dias_del_mes << 1)
	LDI		ZH, HIGH(dias_del_mes << 1)
	ADD		ZL, MESES
	LPM		R28, Z
	MOV		fechaB, R28
	//SWAP	R6	//POSIBLE CAMBIO
	LSL		fechaB
	LSL		fechaB
	LSL		fechaB
	LSL		fechaB
	ANDI	R26, 0x0F
	MOV		fechaA, R28
	RET

//subrutinas para aumentar/decementar el mes

incremento_mes:
	INC		fechaD
	LDI		R16, 0x0B
	CPSE	fechaD, R16
	RJMP	SEGUIRA3M
	CALL	RESETACDM
SEGUIRA3M:
	LDI		R16, 0x01
	CPSE	fechaC, R16		//decena del mes
	RJMP	SEGUIRA4M
	CALL	chekeo_12
SEGUIRA4M: 
	RET
chekeo_12:
	LDI		R16, 0x04
	CPSE	fechaD, R16
	RJMP	SEGUIRA5M
	CALL	RESET2ACDM
SEGUIRA5M:
	RET

RESETACDM:
	CLR		fechaD
	INC		fechaC
	RJMP	void_loop

RESET2ACDM:
	CLR		fechaD
	CLR		fechaC
	RJMP	void_loop	

decremento_mes:	
	DEC		fechaD		
	MOV		R16, fechaD	
	CPI		r16, 0x00			
	BREQ	decrementA_CDM		
	RET								

decrementA_CDM:
	LDI		R16, 0x09	
	MOV		fechaD, R16		
	DEC		fechaC
	MOV		R16, fechaC		
	CPI		R16, 0xFF			
	BREQ	MAXEO_12			
	RET								

MAXEO_12: 
	LDI		R16, 0x02
	MOV		fechaD, R16			
	LDI		R16, 0x01	
	MOV		fechaC, R16		 
	RET


;*********************************
;INTERRUPCIONES 
;*********************************
timer0_overflow:
	CLI	
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

    SBI		PINB, 4 ; Alternar el estado del pin D7

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
	INC		fechaA
	
	MOV		R16, fechaA
	CPI		R16, 2
	BRNE	EXIT_TMR0_ISR
	
	MOV		R16, fechaB
	CPI		R16, 3
	BRNE	EXIT_TMR0_ISR

	INC		fechaD
	CLR		fechaA
	CLR		fechaB

	MOV		R16, fechaD
	CPI		R16, 3
	BRNE	EXIT_TMR0_ISR
	
	MOV		R16, fechaC
	CPI		R16, 1
	BRNE	EXIT_TMR0_ISR


//FELIZ AÑO NUEVO
	ldi		R16, 0x01
	MOV		fechaD, R16
	CLR		fechaC
	CLR		fechaB
	LDI		R16, 0x01
	MOV		fechaA, R16
	SBI		PORTB, PB5

	RJMP	EXIT_TMR0_ISR


EXIT_TMR0_ISR:
	POP		R16
	OUT		SREG, R16
	POP		R16
	SEI
	RETI
	

INT_BOTONAZOC:

	PUSH	R16
	IN		R16,	SREG
	PUSH	R16

	CBI     PORTB, PB5         ; Si al menos uno está presionado, apagar B5
	IN      R16, PINC         ; Leer el estado del puerto C
	ANDI    R16, 0b00100000   ; Filtrar solo C5
	CPI     R16, 0b00000000   ; Verificar si C5 está en 0 (presionado)
	BRNE    WAKWAKK           ; Si no está presionado, salta
	INC     MODE              ; Si está presionado, incrementa MODE


//Revisamos si pasamos la cantidad maxima de modos (setear a 0 si si)
	LDI		R16, modos
	CPI		MODE, modos
	BRLO	WAKWAKK
	CLR		MODE 
	// Que modo estamos
	WAKWAKK:                  ; Etiqueta de salto
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI 


