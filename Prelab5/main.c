//**********************************************************
//Universidad del Valle de Guatemala
//IE2023 : Programación de Microcontroladores
//Test.asm
//
//Autor: Joshua Vásquez
//Proyecto: LAB5
//Hardware: ATMega328P
//Creado: 4/10/25         
//Modificado :
//Descripcion: Servo Motorsss

//**************************************
//ENCABEZADO
//******************************************
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "Prelab5.h"
#include "Tralala.h"
#include "int_timer0.h"

volatile uint8_t mux_state = 0;
volatile  state = 0; 
volatile uint8_t toggle_led = 0;

void ADC_init() {
	ADMUX = 0;
	ADMUX = (1 << REFS0); // Poner los 5V como referencia
	ADMUX	|= (1 << MUX2) | (1<< MUX1); //Seleccionar el ADC6
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); // velodidad de muestreo de factor de division de 8
}

void ADC_init2() {  // correcto
	ADMUX = 0;
	ADMUX = (1 << REFS0); // Poner los 5V como referencia (AVcc)
	ADMUX |= (1 << MUX1) | (1 << MUX0); // Seleccionar el ADC3 (PC3)
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); //  velocidad de muestreo de 8
	
}

void ADC_init3() {  // correcto
	ADMUX = 0;
	ADMUX = (1 << REFS0); // Poner los 5V como referencia (AVcc)
	ADMUX |= (1 << MUX1); //PC2
	ADCSRA = (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); //  velocidad de muestreo de 8
	
}


uint16_t ADC_read() {
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC)); // Esperar a que termine
	return ADC; // Leer el resultado
}



int main(void) {
		timer0_init();
		OCR0A = 128;
	
	while (1) {
		//servo 1
		
		ADC_init();
		PWM_init();
		uint16_t adc = ADC_read(); // 0 - 1023
		uint16_t angle = (adc * 3.5229) + 1199.0; // Mapear a 0-180 grados
		PWM_setAngle(angle);
		_delay_ms(10);
		//servo 2
		ADC_init2();
		PWM_init2();
		uint16_t adcarry = ADC_read(); // 0 - 1023
		uint16_t duty = (adcarry * 283.0/10000.0)+9.0; // Mapear a 0-180 grados
		PWM_setDuty2(duty);
		_delay_ms(10);
		//logica led
		ADC_init3();
		uint16_t led = ADC_read()*255.0/1023.0;
		OCR0A = led; 
	}
}

//Rutina de interrupcion (timer0)
ISR(TIMER0_OVF_vect)
{
	PORTD |= (1 << PORTD2); // Encender LED
	/*
	toggle_led ^= 1; // Alternar entre 0 y 1 (XOR)
	
	if (toggle_led) {
		PORTD |= (1 << PORTD2); // Encender LED
		} else {
		PORTD &= ~(1 << PORTD2); // Apagar LED
	}
	*/
}

ISR(TIMER0_COMPA_vect){
	
	PORTD &= ~(1 << PORTD2); // Encender LED
	
}