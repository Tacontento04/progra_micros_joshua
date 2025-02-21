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
	LDI		R18, 10			// 10 ciclos de ~100ms (1s)
	CALL	DISPLAY_UPDATE 
esperar_100ms:
	LDI		R19, 6			// Esperar 6 desbordes de ~16.38ms

esperar_overflow:
	IN		R16, TIFR0		// Leer la bandera de interrupción del Timer0
	SBRS	R16, TOV0		// Si no está en 1, sigue esperando
	RJMP	esperar_overflow
	LDI		R16, (1 << TOV0)
	OUT		TIFR0, R16		// Borra la bandera de desbordamiento
	DEC		R19
	BRNE	esperar_overflow	// Espera hasta completar 6 desbordes (~100ms)
	DEC		R18
	BRNE	esperar_100ms		// Repite hasta completar 1
	INC		R17				// Incrementa el contador
	ANDI	R17, 0x0F		// Mantiene el valor dentro de 4 bits (0-15)
	IN		R16, PORTC
	ANDI	R16, 0xF0
	OR		R16, R17
	OUT		PORTC, R16
	call	BOTONES
	CALL	COMPARADOR 
Salto:
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

MAXEO:					//REiniciamos a su valor maximo 
	LDI		R20, 0x0F
	RET

DISPLAY_UPDATE:
    LDI		ZH, HIGH(TABLE<<1)   // ZH:ZL PUNTERO QUE APUNTA A LA TABLA 
    LDI		ZL, LOW(TABLE<<1)    
    ADD		ZL, R20				 // R20 es nuestro contador
    ADC		ZH, R1               // R1 siempre es 0 por lo que 0 + r20
    LPM		R16, Z               // Carga el byte Z en r16
    OUT		PORTD, R16			 // display del valor deseado
	CALL	DELAY 
    RET

COMPARADOR:
	CP		R17, R20		//Comparamos los registros de los contadores 
	BRNE	Salto			//Si no son iguales nos regresamos a lo que estabamos 
	SBIC    PINC, 5                 ; Saltar si el pin C5 está apagado
    CBI     PORTC, 5                ; Apagar el pin C5 si está encendido
    SBIS    PINC, 5                 ; Saltar si el pin C5 está encendido
    SBI     PORTC, 5                ; Encender el pin C5 si está apagado
	LDI		R26, 250		// Hacemos un loop de delays para que sea perceptible el encendido
Delay_loop:			// para que la led este encendida mas tiempo
	CALL	DELAY
	DEC		R26
	BRNE	Delay_loop

	LDI		R17, 0x00
	IN		R16, PORTC
	ANDI	R16, 0xF0
	OR		R16, R17
	OUT		PORTC, R16
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