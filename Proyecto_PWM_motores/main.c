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
#define F_CPU 16000000
#include <util/delay.h>

//**************************************
//Prototipos de funciones
//******************************************
void setup();
void initADC();
void PWM_motor1();
void PWM_motor3();

void control_motor(uint16_t X, uint16_t Y);

void Joystick_X(uint16_t lectura);
void Joystick_Y(uint16_t readADC2);
void rotacion(uint16_t readADC4);
void PWM_setVel(uint16_t velocidad);
void PWM_setVel2(uint16_t vel2);
void PWM_setVel3(uint16_t vel3);
void PWM_setVel4(uint16_t vel4);
uint16_t leerADC(uint8_t canal);
//**************************************
//MAIN FUNCTION
//******************************************

int main(void)
{
	
	setup();
	initADC();
    while (1) 

	
    {
		//PORTC |= (1 << PORTC1); // Encender LED
		
	//PINES DE MOTOR A
		//PORTB |= (1 << PORTB5);
		//PORTC |= (0 << PORTC2); // aPAGAR LED
	//PINES DE MOTOR B
		//PORTC |= (1 << PORTC3); // Encender LED
		//PORTC |= (0 << PORTC4); // aPAGAR LED
		//controlando motor A
		PWM_motor1();
		/*
		uint16_t lectura = leerADC(0);
		
		Joystick_X(lectura);
		_delay_ms(30);
		//Controlando motor B
		uint16_t readADC2 = leerADC(1);
		Joystick_Y(readADC2);
		_delay_ms(30);
		*/
		//uint8_t vel2 = (uint8_t)(readADC2 * 255.0 / 1023.0);  // Convertir a 8 bits
		//PWM_setVel2(vel2);
		//Controlando motor 3
			uint16_t lectura = leerADC(0);
			uint16_t readADC2 = leerADC(1);
			control_motor(lectura, readADC2);
			Joystick_X(lectura);
			Joystick_Y(readADC2);
		
		
		PWM_motor3();
		uint16_t readADC3 = leerADC(7);
		uint8_t vel3 = (uint8_t)(readADC3 * 255.0 / 1023.0);  // Convertir a 8 bits
		PWM_setVel3(vel3);
		//Controlando motor 4
		
		uint16_t readADC4 = leerADC(6);
		rotacion(readADC4);
		
    }
}

//**************************************
//Subrutinas
//******************************************
void setup(){
	cli();
	DDRB = 0xFF;
	DDRC = 0xFC;
	DDRD |= (1 << PORTD4) | (1 << PORTD5);  // D4 Y D5 como salidas
	//DIDR0 |= (1 << ADC0D) | (1 << ADC1D);  // Deshabilitar buffer digital en ADC0 y ADC1 (ejemplo)
	sei();
}

void initADC(){
	ADMUX = (1 << REFS0); // Referencia AVcc
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC, preescalador 128
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

void PWM_setVel2(uint16_t vel2) {
	OCR1B = vel2;
}

void PWM_setVel3(uint16_t vel3) {
	OCR2B = vel3;
}
void PWM_setVel4(uint16_t vel4) {
	OCR2A = vel4;
}

void control_motor(uint16_t X, uint16_t Y){
	
	if (Y >= 0 && Y < 480){
		
		//AVANZAR PARA ENFRENTE
		PORTB |= (1 << PORTB5);
		PORTC |= (1 << PORTC3);    // Enciende PORTC3
		PORTC &= ~((1 << PORTC2) | (1 << PORTC4));  // Apaga PORTC2 y PORTC4
		
		} else if( Y > 520 && Y < 1023){
		
		//PARA ATRAS
		PORTB &= ~(1 << PORTB5);

		PORTC |= (1 << PORTC2) | (1 << PORTC4);  // Encender PORTC2 y PORTC4
		PORTC &= ~(1 << PORTC3);                  // Apagar PORTC3
		
	
		}else {
			
		if(X >= 0 && X < 480){
			//AVANZAR PARA la izquierda
			PORTB |= (1 << PORTB5);
			PORTC &= ~((1 << PORTC2) | (1 << PORTC3));  // Apagar PORTC2 y PORTC3
			PORTC |= (1 << PORTC4);                     // Encender PORTC4
			
			
		}else if( X > 520 && X < 1023){
			
			//AVANZAR PARA la derecha
			PORTB &= ~(1 << PORTB5);
			PORTC |= (1 << PORTC2) | (1 << PORTC3);  // Encender bits 2 y 3
			PORTC &= ~(1 << PORTC4);                   // Apagar bit 4
			
		}else {	
			
		//motor sin moverse
		PORTB &= ~(1 << PORTB5);
		PORTC &= ~(1 << PORTC2); // aPAGAR LED
		PORTC &= ~(1 << PORTC3); // aPAGAR LED
		PORTC &= ~(1 << PORTC4); // aPAGAR LED
		}
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
		PORTD |= (1 << PORTD4);   // Encender PORTD4 
		
		//Mandamos el mapeo de joystick abajo
		uint8_t mov2 = (readADC4 * 255.0 / 503.0) - 263.62;  // Convertir a 8 bits
		PWM_setVel4(mov2);
		
		}else {
		//motor sin moverse
		PORTD &= ~((1 << PORTD5) | (1 << PORTD4));  // Apagar solo PORTD5 y PORTD4
	}
	
	
}
//**************************************
//Interrupciones
//******************************************