//**********************************************************
//Universidad del Valle de Guatemala
//IE2023 : Programación de Microcontroladores
//Test.asm
//
//Autor: Joshua Vásquez
//Proyecto: PROYECTO 2
//Hardware: ATMega328P
//Creado: 2/5/25
//Modificado :
//Descripcion: MOTORESSS

//**************************************
//ENCABEZADO
//******************************************
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdbool.h>
#define F_CPU 16000000
#include <util/delay.h>

#include "UART.h"
#include "EPROM.h"

#define zona_reposo 50  // rango pote quieto
#define center 512      // centro del potenciometro
#define DEAD_ZONE 70// Ajusta según necesidad
#define CENTER 512    // Valor central del joystick
#define CMD_BUFFER_SIZE 16

//Definimos los modos
typedef enum {
	MODO_FISICO,
	MODO_EPROM,
	MODO_SERIAL,
	MODO_BLUTUTH
	} ModoOperacion;

typedef struct {
	volatile uint8_t* pwm_reg;   // Registro PWM (OCR1A, etc.)
	volatile uint8_t* port_in1;  // Puerto dirección 1
	volatile uint8_t* port_in2;  // Puerto dirección 2
	uint8_t pin_in1;            // Pin dirección 1
	uint8_t pin_in2;            // Pin dirección 2
} MotorControl;

MotorControl motors[4] = {
	{&OCR1A, &PORTB, &PORTC, PORTB5, PORTC2}, // Motor 1
	{&OCR1B, &PORTC, &PORTC, PORTC3, PORTC4}, // Motor 2
	{&OCR2A, &PORTD, &PORTD, PORTD5, PORTD4}, // Motor 3
	{&OCR2B, &PORTD, &PORTD, PORTD4, PORTD3}  // Motor 4
};

uint8_t current_direction = 0; // 0=stop, 1=forward, etc.

volatile ModoOperacion modo_actual = MODO_FISICO;
//**************************************
//Prototipos de funciones
//******************************************
void setup();
void initADC();
void PWM_motor1();
void PWM_motor3();

void cambiar_modo();
uint8_t boton_presionado();
uint8_t escribir = 0;
uint8_t direccion = 0;
uint8_t paqueton = 0;

void control_motor(uint16_t X, uint16_t Y);

void Joystick_X(uint16_t lectura);
void Joystick_Y(uint16_t readADC2);
void rotacion(uint16_t readADC4);
void PWM_setVel(uint16_t velocidad);
void PWM_setVel1(uint16_t vel);
void PWM_setVel2(uint16_t vel2);
void PWM_setVel3(uint16_t vel3);
void PWM_setVel4(uint16_t vel4);
uint16_t leerADC(uint8_t canal);

void setMotorSpeed(uint8_t motor_num, uint8_t speed);
void setMotorDirection(uint8_t motr_num, uint8_t dir);
void processSerialCommand(char*cmd);

volatile char received_char;
volatile uint8_t new_data = 0;

char cmd_buffer[CMD_BUFFER_SIZE];
uint8_t cmd_index = 0;


//**************************************
//MAIN FUNCTION
//******************************************

int main(void)
{
	
	setup();
	initADC();
    PWM_motor1();
	while (1) 	
    {
		cambiar_modo();
		switch(modo_actual){
			case MODO_FISICO:
			PWM_motor1();
			
			//leds de modo
			PORTD |= (1 << PORTD7);
			PORTC &= ~(1 << PORTC5);
			uint16_t lectura = leerADC(1);
			uint16_t readADC2 = leerADC(0);
			control_motor(lectura, readADC2);
				//Joystick_X(lectura);
				//Joystick_Y(readADC2);
		
		
				PWM_motor3();
				uint16_t readADC3 = leerADC(7);
				uint8_t vel3 = (uint8_t)(readADC3 * 255.0 / 1023.0);  // Convertir a 8 bits
				PWM_setVel3(vel3);
				//Controlando motor 4
		
				uint16_t readADC4 = leerADC(6);
				rotacion(readADC4);
				
				if(escribir == 1 && paqueton <=5)
				{
					// Motor 1 (OCR1A + bits de control)
					writeEEPROM(OCR1A, direccion++);
					writeEEPROM((PORTB & (1 << PORTB5)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTB5
					writeEEPROM((PORTC & (1 << PORTC2)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTC2
					
					// Motor 2 (OCR1B + bits de control)
					writeEEPROM(OCR1B, direccion++);
					writeEEPROM((PORTC & (1 << PORTC3)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTC3
					writeEEPROM((PORTC & (1 << PORTC4)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTC4
					
					// Motor 3 (OCR2A + bits de control)
					writeEEPROM(OCR2A, direccion++);
					writeEEPROM((PORTD & (1 << PORTD5)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTD5
					writeEEPROM((PORTD & (1 << PORTD4)) ? 1 : 0, direccion++);  // Guarda 1 o 0 para PORTD4
					
					// Motor 4 (OCR2B)
					writeEEPROM(OCR2B, direccion++);
					
					paqueton++;
					escribir = 0;
				}
				
			break;
			case MODO_EPROM:
			
			//leds de modo
			PORTD &= ~(1 << PORTD7);
			PORTC |= (1 << PORTC5);
			
			if (escribir >= 1 && escribir <= 4){
				
				uint8_t paquetito = (escribir - 1)* 10;
				
				 // Motor 1 (OCR1A + bits de control)
				 OCR1A = readEEPROM(paquetito);
				 
				 if (readEEPROM(paquetito + 1)) PORTB |= (1 << PORTB5);   // Si es 1, enciende el bit
				 else PORTB &= ~(1 << PORTB5);                            // Si es 0, apágalo
				 
				 if (readEEPROM(paquetito + 2)) PORTC |= (1 << PORTC2);
				 else PORTC &= ~(1 << PORTC2);
				 
				 // Motor 2 (OCR1B + bits de control)
				 OCR1B = readEEPROM(paquetito + 3);
				 
				 if (readEEPROM(paquetito + 4)) PORTC |= (1 << PORTC3);
				 else PORTC &= ~(1 << PORTC3);
				 
				 if (readEEPROM(paquetito + 5)) PORTC |= (1 << PORTC4);
				 else PORTC &= ~(1 << PORTC4);
				 
				 // Motor 3 (OCR2A + bits de control)
				 OCR2A = readEEPROM(paquetito + 6);
				 
				 if (readEEPROM(paquetito + 7)) PORTD |= (1 << PORTD5);
				 else PORTD &= ~(1 << PORTD5);
				 
				 if (readEEPROM(paquetito + 8)) PORTD |= (1 << PORTD4);
				 else PORTD &= ~(1 << PORTD4);
				 
				 // Motor 4 (OCR2B)
				 OCR2B = readEEPROM(paquetito + 9);
				
				/*
				OCR2B = readEEPROM( paquetito);
				OCR2A = readEEPROM(paquetito + 1);
				OCR1B = readEEPROM(paquetito + 2);
				OCR1A = readEEPROM(paquetito + 3);
				*/
				
				
			}	
			
			
			
			break;
			case MODO_SERIAL:
			
				PORTD |= (1 << PORTD7);
				PORTC |= (1 << PORTC5);
			if(new_data) {
				new_data = 0;
				
				// Comando de velocidad (ej. "v1125")
				if(cmd_buffer[0] == 'v' && cmd_index >= 3) {
					uint8_t motor = cmd_buffer[1] - '0';
					uint16_t velocidad = 0;
					
					for(uint8_t i=2; i<cmd_index; i++) {
						if(cmd_buffer[i] >= '0' && cmd_buffer[i] <= '9') {
							velocidad = velocidad*10 + (cmd_buffer[i]-'0');
						}
					}
					
					if(motor >=1 && motor <=4 && velocidad <=255) {
						setMotorSpeed(motor, velocidad);
					}
					cmd_index = 0;
				}
				// Comandos de dirección (0-6)
				else if(cmd_index == 1) {
					switch(received_char) {
						case '0': // Adelante
						PORTB |= (1 << PORTB5);    // Motor 1: IN1=HIGH
						PORTC &= ~(1 << PORTC2);   // Motor 1: IN2=LOW
						PORTC |= (1 << PORTC3);    // Motor 2: IN1=HIGH
						PORTC &= ~(1 << PORTC4);   // Motor 2: IN2=LOW
						break;
						case '1': // Atrás
						 PORTB &= ~(1 << PORTB5);   // Motor 1: IN1=LOW
						 PORTC |= (1 << PORTC2);    // Motor 1: IN2=HIGH
						 PORTC &= ~(1 << PORTC3);   // Motor 2: IN1=LOW
						 PORTC |= (1 << PORTC4);    // Motor 2: IN2=HIGH
						 break;
						case '2': //ARRIBA LA IZQUIERDA
						 PORTB |= (1 << PORTB5);    // Motor 1: IN1=HIGH (adelante)
						 PORTC &= ~(1 << PORTC2);   // Motor 1: IN2=LOW
						 PORTC &= ~(1 << PORTC3);   // Motor 2: IN1=LOW
						 PORTC |= (1 << PORTC4);    // Motor 2: IN2=HIGH (atrás)
						 break;
						case '3':  // Giro derecha (motor izquierdo adelante, derecho atrás)
						PORTB &= ~(1 << PORTB5);   // Motor 1: IN1=LOW
						PORTC |= (1 << PORTC2);    // Motor 1: IN2=HIGH (atrás)
						PORTC |= (1 << PORTC3);    // Motor 2: IN1=HIGH (adelante)
						PORTC &= ~(1 << PORTC4);   // Motor 2: IN2=LOW
						break;
						case '4':
						PORTD |= (1 << PORTD5);    // Enciende PORTD5
						PORTD &= ~(1 << PORTD4);   // Apaga PORTD4
						break;
						case '5':
						PORTD &= ~(1 << PORTD5);  // Apagar PORTD5
						PORTD |= (1 << PORTD4);
						break;
						case '6':
						PORTD &= ~((1 << PORTD5) | (1 << PORTD4));  // Apagar solo PORTD5 y PORTD4
						break;
						case '7':
						PWM_setVel3(255);
						break;
						case '8':
						PWM_setVel3(0);
						break;
						
						
						case 's': // Stop
						for(uint8_t i=1; i<=4; i++) setMotorDirection(i, 0);
						break;
						
					}
					cmd_index = 0;
				}
			}
			
	
			case MODO_BLUTUTH:
			
			if(new_data){
				new_data = 0;
				
				//modo adelante
				if (received_char == '0'){
					// AVANZAR
					PORTB |= (1 << PORTB5);
					PORTC |= (1 << PORTC3);
					PORTC &= ~((1 << PORTC2) | (1 << PORTC4));
					PWM_setVel(255);
				}
				else if(received_char == '1'){
					// RETROCEDER
					PORTB &= ~(1 << PORTB5);
					PORTC |= (1 << PORTC2) | (1 << PORTC4);
					PORTC &= ~(1 << PORTC3);
					PWM_setVel(255);
					}else if(received_char == '2'){
					//AVANZAR PARA la izquierda
					PORTB |= (1 << PORTB5);
					PORTC &= ~((1 << PORTC2) | (1 << PORTC3));  // Apagar PORTC2 y PORTC3
					PORTC |= (1 << PORTC4);
					PWM_setVel(255);
					}else if(received_char == '3'){
					//AVANZAR PARA la derecha
					PORTB &= ~(1 << PORTB5);
					PORTC |= (1 << PORTC2) | (1 << PORTC3);  // Encender bits 2 y 3
					PORTC &= ~(1 << PORTC4);                   // Apagar bit 4
					PWM_setVel(255);
					}else if(received_char == 's'){
					PORTB &= ~(1 << PORTB5);
					PORTC &= ~((1 << PORTC2) | (1 << PORTC3) | (1 << PORTC4));
					}else if(received_char == '4'){
					PWM_motor3();
					//giRAR A LA IZQUIERDA
					PORTD |= (1 << PORTD5);    // Enciende PORTD5
					PORTD &= ~(1 << PORTD4);   // Apaga PORTD4
					PWM_setVel4(255);
					}else if(received_char == '5'){
					PWM_motor3();
					PORTD &= ~(1 << PORTD5);  // Apagar PORTD5
					PORTD |= (1 << PORTD4);   // Encender PORTD4 z
					PWM_setVel4(255);
					}else if (received_char == '6'){
					//APAGAR
					//motor sin moverse
					PORTD &= ~((1 << PORTD5) | (1 << PORTD4));  // Apagar solo PORTD5 y PORTD4
				}
				{
				}
			}
			
			
			break;
		}
    }
}

//**************************************
//Subrutinas
//******************************************
void setup(){
	cli();
	DDRB = 0xFF;
	DDRC = 0xFC;
	DDRD |= (1 << PORTD4) | (1 << PORTD5) | (1 << PORTD7);  // D4 Y D5 como salidas
	DDRC |= (1 << PORTC5);
	// Configura D2 y D6 como entradas (DDRD en 0) y activa pull-up (PORTD en 1)
	DDRD &= ~((1 << PORTD2) | (1 << PORTD6));  // Pines como entradas
	PORTD |= (1 << PORTD2) | (1 << PORTD6);    // Activa pull-up

	PCMSK2 |= (1 << PIND6);
	PCICR |= (1 << PCIE2);

	
	
	//DDRD &= ~(1 << PORTD2);    
	//PORTD |= (1 << PORTD2);     
	//DIDR0 |= (1 << ADC0D) | (1 << ADC1D);  // Deshabilitar buffer digital en ADC0 y ADC1 (ejemplo)
	initUART();
	sei();
}

void initADC(){
	ADMUX = (1 << REFS0); // Referencia AVcc
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC, preescalador 128
}

uint8_t boton_presionado() {
	if (!(PIND & (1 << PORTD2))) { // Si el botón está presionado (LOW)
		_delay_ms(20);         // Espera para anti-rebote
		if (!(PIND & (1 << PORTD2))) { // Verifica nuevamente
			return 1; // Botón realmente presionado
		}
	}
	return 0; // Botón no presionado
}

void cambiar_modo() {
	if (boton_presionado()) {
		// Espera hasta que se suelte el botón
		while (!(PIND & (1 << PORTD2)));
		_delay_ms(20); // Anti-rebote al soltar
		
		// Cambia al siguiente modo
		modo_actual = (modo_actual + 1) % 3;
	}
}


uint16_t leerADC(uint8_t canal) {
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // Seleccionar canal
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC));
	return ADC; //	
}

void PWM_motor1() {
	  // Configuración correcta para PWM dual en modo 14 (ICR1 como TOP)
	  TCCR1A = (1 << COM1A1) | (1 << COM1B1) | (1 << WGM11);	// Habilitar ambos canales PWM (no invertidos)
																// Parte del modo 14 (Fast PWM con ICR1)
	  
	  TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS12)| (1 << CS10); // Resto del modo 14 y Prescaler 1024
	  
	  ICR1 = 255;  // TOP value (define el rango PWM: 0-399)
	  
	  // Establecer duty cycles (¡esto es esencial!)
	  //OCR1A = 200;  // 50% duty cycle para canal A
	  //OCR1B = 100;  // 25% duty cycle para canal B
	  
	  // Configurar pines como salidas
	  DDRB |= (1 << PORTB1) | (1 << PORTB2);  // PB1 (OC1A) y PB2 (OC1B) como salidas
  }

void PWM_motor3(){
	// Configurar Timer2 para modo Phase Correct PWM con TOP=0xFF
	TCCR2A = (1 << COM2A1) | (1 << COM2B1) | (1 << WGM20); // Non-inverting en ambos canales, Phase Correct PWM
	TCCR2B = (1 << CS22) | (1 << CS21) | (1 << CS20); // Prescaler de 1024 (ajustar según necesidades)

	DDRD |= (1 << PORTD3); // OC2B (PD3) como salida
	DDRB |= (1 << PORTB3);  // OC2A (PB3) como salida (en la mayoría de los ATmega)
}

void PWM_setVel(uint16_t velocidad) {
	OCR1A = velocidad;
	OCR1B = velocidad;
}
void PWM_setVel1(uint16_t velocidad) {
	OCR1A = velocidad;
}

void PWM_setVel2(uint16_t vel2) {
	OCR1B = vel2;
}

void PWM_setVel3(uint16_t vel3) {
	OCR2B = vel3;
}
void PWM_setVel4(uint16_t vel4) {
	OCR2A = vel4;
}

void control_motor(uint16_t X, uint16_t Y) {
	// Primero determinamos si estamos en zona muerta para Y
	bool y_active = (Y < (CENTER - DEAD_ZONE)) || (Y > (CENTER + DEAD_ZONE));
	
	// Luego para X
	bool x_active = (X < (CENTER - DEAD_ZONE)) || (X > (CENTER + DEAD_ZONE));

	// Movimiento principal basado en Y (avance/retroceso)
	if (y_active) {
		if (Y < (CENTER - DEAD_ZONE)) {
			// AVANZAR
			
			PORTB |= (1 << PORTB5);
			PORTC |= (1 << PORTC3);
			PORTC &= ~((1 << PORTC2) | (1 << PORTC4));
			uint8_t vel2 = (uint8_t)(Y * -255.0 / 480.0)+255.0;  // Convertir a 8 bits
			PWM_setVel(vel2);
			
			} else {
				
				
			// RETROCEDER
			PORTB &= ~(1 << PORTB5);
			PORTC |= (1 << PORTC2) | (1 << PORTC4);
			PORTC &= ~(1 << PORTC3);
			//Mandamos el mapeo de joystick abajo
			uint8_t vel2 = (Y * 255.0 / 503.0) -263.62;  // Convertir a 8 bits
			PWM_setVel(vel2);
		}
	}
	
	// Giro basado en X (solo si no hay movimiento en Y o para combinaciones)
	if (x_active && !y_active) {
		if (X < (CENTER - DEAD_ZONE)) {
			// GIRO IZQUIERDA (motor derecho adelante, izquierdo atrás)
			//AVANZAR PARA la izquierda
			PORTB |= (1 << PORTB5);
			PORTC &= ~((1 << PORTC2) | (1 << PORTC3));  // Apagar PORTC2 y PORTC3
			PORTC |= (1 << PORTC4);                     // Encender PORTC4
			uint8_t valor = (uint8_t)(X* -255.0 / 480.0)+255.0;  // Convertir a 8 bits
			PWM_setVel(valor);
			
			} else {
			
				//AVANZAR PARA la derecha
				PORTB &= ~(1 << PORTB5);
				PORTC |= (1 << PORTC2) | (1 << PORTC3);  // Encender bits 2 y 3
				PORTC &= ~(1 << PORTC4);                   // Apagar bit 4
				uint8_t valor = (X * 255.0 / 503.0) -263.62;  // Convertir a 8 bits
				PWM_setVel(valor);
			
		}
	}
	/*
	// Combinación de movimientos (ejemplo: diagonal)
	if (x_active && y_active) {
		// Implementa lógica para movimientos combinados
		// Por ejemplo, avance con giro suave
	}
	*/
	// Detener si no hay movimiento
	if (!x_active && !y_active) {
		PORTB &= ~(1 << PORTB5);
		PORTC &= ~((1 << PORTC2) | (1 << PORTC3) | (1 << PORTC4));
	}
}

void Joystick_X(uint16_t lectura){
	uint16_t X = lectura; 
	
	//IR A LA IZQUIERDA
	if (X >= 0 && X < 480) {
/*	//AVANZAR PARA la izquierda
	PORTB |= (1 << PORTB5);
	PORTC &= ~((1 << PORTC2) | (1 << PORTC3));  // Apagar PORTC2 y PORTC3
	PORTC |= (1 << PORTC4);                     // Encender PORTC4
*/	
	// Le mandamos el valor del mapeo
		uint8_t valor = (uint8_t)(lectura * -255.0 / 480.0)+255.0;  // Convertir a 8 bits
		PWM_setVel(valor);
		//PORTC = (1 << PORTC3); // Encender LED
		//PORTC = (0 << PORTC4); // aPAGAR LED
		
		//PWM_setVel2(valor);
	} else if ( X > 520 && X < 1023) {
/*
	//AVANZAR PARA la derecha
	PORTB &= ~(1 << PORTB5);
	PORTC |= (1 << PORTC2) | (1 << PORTC3);  // Encender bits 2 y 3
	PORTC &= ~(1 << PORTC4);                   // Apagar bit 4
*/	
	uint8_t valor = (lectura * 255.0 / 503.0) -263.62;  // Convertir a 8 bits
	PWM_setVel(valor);
	//PORTC = (0 << PORTC3); // Encender LED
	//PORTC = (1 << PORTC4); // aPAGAR LED
	
	//PWM_setVel2(valor);
	} else {
/*		//motor sin moverse 
	PORTB &= ~(1 << PORTB5);
	PORTC &= ~(1 << PORTC2); // aPAGAR LED
	PORTC &= ~(1 << PORTC3); // aPAGAR LED
	PORTC &= ~(1 << PORTC4); // aPAGAR LED
	*/
	}
	
	
}	
void Joystick_Y(uint16_t readADC2){
	uint16_t Y = readADC2; 
	if (Y >= 0 && Y < 480){
	/*	
		//AVANZAR PARA ENFRENTE
		PORTB |= (1 << PORTB5);  
		PORTC |= (1 << PORTC3);    // Enciende PORTC3 
		PORTC &= ~((1 << PORTC2) | (1 << PORTC4));  // Apaga PORTC2 y PORTC4
*/		
// MANDAMOS El mapeo para joystick enfrente
		uint8_t vel2 = (uint8_t)(readADC2 * -255.0 / 480.0)+255.0;  // Convertir a 8 bits
		PWM_setVel(vel2);
		//PWM_setVel2(vel2);
	} else if( Y > 520 && Y < 1023){
	/*	
		//PARA ATRAS
		PORTB &= ~(1 << PORTB5);

		PORTC |= (1 << PORTC2) | (1 << PORTC4);  // Encender PORTC2 y PORTC4
		PORTC &= ~(1 << PORTC3);                  // Apagar PORTC3
	*/	
//Mandamos el mapeo de joystick abajo		
		uint8_t vel2 = (readADC2 * 255.0 / 503.0) -263.62;  // Convertir a 8 bits
		PWM_setVel(vel2);
		//PWM_setVel2(vel2);
	}else {
/*		
	//motor sin moverse
	PORTB &= ~(1 << PORTB5);
	PORTC &= ~(1 << PORTC2); // aPAGAR LED
	PORTC &= ~(1 << PORTC3); // aPAGAR LED
	PORTC &= ~(1 << PORTC4); // aPAGAR LED
	*/
}
	
	
}

void rotacion(uint16_t readADC4){
	uint16_t potenciometro = readADC4;
	if (potenciometro >= 0 && potenciometro < 480){
		
		//AVANZAR PARA ENFRENTE
		
		PORTD |= (1 << PORTD5);    // Enciende PORTD5 
		PORTD &= ~(1 << PORTD4);   // Apaga PORTD4 
		
	
		// MANDAMOS El mapeo para joystick enfrente
		uint8_t mov = (uint8_t)(readADC4 * -255.0 / 480.0)+255.0;  // Convertir a 8 bits
		PWM_setVel4(mov);
	
		} else if( potenciometro > 520 && potenciometro < 1023){
		
		PORTD &= ~(1 << PORTD5);  // Apagar PORTD5 
		PORTD |= (1 << PORTD4);   // Encender PORTD4 z
		
		//Mandamos el mapeo de joystick abajo
		uint8_t mov2 = (readADC4 * 255.0 / 503.0) - 263.62;  // Convertir a 8 bits
		PWM_setVel4(mov2);
		
		}else {
		//motor sin moverse
		PORTD &= ~((1 << PORTD5) | (1 << PORTD4));  // Apagar solo PORTD5 y PORTD4
		 PWM_setVel4(0);
	}  
	
	
}

void setMotorSpeed(uint8_t motor_num, uint8_t speed) {
	if(motor_num >= 1 && motor_num <= 4) {
		*motors[motor_num-1].pwm_reg = speed;
	}
}

void setMotorDirection(uint8_t motor_num, uint8_t dir) {
	if(motor_num >= 1 && motor_num <= 4) {
		switch(dir) {
			case 0: // Stop
			*motors[motor_num-1].port_in1 &= ~(1 << motors[motor_num-1].pin_in1);
			*motors[motor_num-1].port_in2 &= ~(1 << motors[motor_num-1].pin_in2);
			break;
			case 1: // Forward
			*motors[motor_num-1].port_in1 |= (1 << motors[motor_num-1].pin_in1);
			*motors[motor_num-1].port_in2 &= ~(1 << motors[motor_num-1].pin_in2);
			break;
			case 2: // Backward
			*motors[motor_num-1].port_in1 &= ~(1 << motors[motor_num-1].pin_in1);
			*motors[motor_num-1].port_in2 |= (1 << motors[motor_num-1].pin_in2);
			break;
		}
	}
}
		
		// Añade más casos según tus necesidades
	


//**************************************
//Interrupciones
//******************************************
ISR(USART_RX_vect) {
	  received_char = UDR0;
	  new_data = 1;
	  
	  writeChar(received_char);
	  
	  if(received_char == '\n' || received_char == '\r') {
		  cmd_buffer[cmd_index] = '\0';
		  cmd_index = 0;
	  }
	  else if(cmd_index < CMD_BUFFER_SIZE-1) {
		  cmd_buffer[cmd_index++] = received_char;
	  }
  }



ISR(PCINT2_vect){
	
	 if (!(PIND & (1 << PORTD6))){
		escribir++;
		if (escribir == 5)
		{
			escribir = 0;
		}
		
		
	}

	
	
}
