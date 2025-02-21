; Configurar la velocidad del bus I2C (100 kHz con un reloj de 16 MHz)
LDI   R16, 72          ; TWBR = 72 para 100 kHz
STS   TWBR, R16
LDI   R16, (1 << TWEN) ; Habilitar el módulo TWI
STS   TWCR, R16
; Enviar comandos de inicialización
LDI   R17, 0x38        ; Modo 8 bits, 2 líneas
CALL  LCD_SEND_COMMAND
LDI   R17, 0x0C        ; Encender pantalla, cursor off
CALL  LCD_SEND_COMMAND
LDI   R17, 0x01        ; Limpiar pantalla
CALL  LCD_SEND_COMMAND
LDI   R17, 0x06        ; Modo de entrada (incrementar cursor)
CALL  LCD_SEND_COMMAND
; Subrutina para enviar un byte a través de I2C
I2C_SEND_BYTE:
    STS   TWDR, R17     ; Cargar el byte en el registro de datos
    LDI   R16, (1 << TWINT) | (1 << TWEN) ; Iniciar la transmisión
    STS   TWCR, R16
I2C_WAIT:
    LDS   R16, TWCR
    SBRS  R16, TWINT    ; Esperar a que se complete la transmisión
    RJMP  I2C_WAIT
    RET
	; Subrutina para escribir un string en la LCD
LCD_WRITE_STRING:
    LPM   R17, Z+       ; Cargar el siguiente carácter desde la memoria
    CPI   R17, 0        ; Verificar si es el final del string
    BREQ  LCD_WRITE_END
    CALL  LCD_SEND_DATA ; Enviar el carácter
    RJMP  LCD_WRITE_STRING
LCD_WRITE_END:
    RET

; Subrutina para enviar un carácter (dato) a la LCD
LCD_SEND_DATA:
    LDI   R16, 0x40     ; RS = 1 (modo datos)
    CALL  I2C_SEND_BYTE
    RET

; Subrutina para enviar un comando a la LCD
LCD_SEND_COMMAND:
    LDI   R16, 0x00     ; RS = 0 (modo comando)
    CALL  I2C_SEND_BYTE
    RET
	.INCLUDE "m328pdef.inc" ; Incluir definiciones del ATmega328P

.DEF    TEMP = R16
.DEF    DATA = R17

.CSEG
.ORG    0x0000
	RJMP  MAIN

MAIN:
    ; Configurar el stack pointer
    LDI   TEMP, HIGH(RAMEND)
    OUT   SPH, TEMP
    LDI   TEMP, LOW(RAMEND)
    OUT   SPL, TEMP

    ; Inicializar el TWI (I2C)
    CALL  I2C_INIT

    ; Inicializar la LCD
    CALL  LCD_INIT

    ; Escribir "Hola" en la pantalla
    LDI   ZL, LOW(2*MENSAJE)
    LDI   ZH, HIGH(2*MENSAJE)
    CALL  LCD_WRITE_STRING

    ; Bucle infinito
LOOP:
    RJMP  LOOP

; Mensaje a mostrar
MENSAJE:
    .DB   "Hola", 0

; Subrutinas (I2C_INIT, I2C_SEND_BYTE, LCD_INIT, LCD_WRITE_STRING, etc.)
; ...