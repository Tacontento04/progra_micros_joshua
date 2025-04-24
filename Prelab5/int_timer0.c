/*
 * int_timer0.c
 *
 * Created: 4/20/2025 10:44:04 PM
 *  Author: joshu
 */ 
#include "Prelab5.h"
#include <avr/io.h>
#include <avr/interrupt.h>
void timer0_init(){
	// 1. Configuración de LEDs
	DDRD = 0xFF;
	PORTD = 0x00;
	// 4. Timer0 para antirrebote (~10ms con 16MHz)
	TCCR0A |= 0x00;
	TCCR0B |= (1 << CS02) | (1 << CS00);; // Prescaler de 8
	TIMSK0 = (1 << TOIE0)| (1 << OCIE0A);	
	
	sei();
}