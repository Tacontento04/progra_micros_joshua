/*
 * Prelab5.c
 *
 * Created: 4/10/2025 7:19:19 PM
 *  Author: joshu
 */ 
#include "Prelab5.h"

void PWM_init() {
	// Fast PWM, modo 14: TOP = ICR1
	TCCR1A = (1 << COM1A1) | (1 << WGM11);
	TCCR1B = (1 << WGM13) | (1 << WGM12) | (1 << CS11); // prescaler 8

	ICR1 = 40000; // TOP = 20 ms con reloj de 16MHz y prescaler 8
	DDRB |= (1 << PORTB1) ; // OC1A (D9) como salida
}

void PWM_setAngle(uint16_t angle) {
	OCR1A = angle;
}