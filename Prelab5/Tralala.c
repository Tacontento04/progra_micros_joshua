/*
 * Tralala.c
 *
 * Created: 4/10/2025 11:34:43 PM
 *  Author: joshu
 */ 

#include "Tralala.h"

void PWM_init2() {
	 // Configurar Timer2 para modo Phase Correct PWM con TOP=0xFF
	 TCCR2A = (1 << COM2B1) | (1 << WGM20); // Non-inverting, Phase Correct PWM
	 TCCR2B = (1 << CS22)|(1 << CS21)| (1 << CS20); // Prescaler de 1024 (ajustar según necesidades)
	 
	 DDRD |= (1 << PORTD3); // OC2B (PD3) como salida
 }

void PWM_setDuty2(uint8_t duty) {
	// Mapear ángulo (0-180) a ancho de pulso (ej. 5-25 para 50Hz)
	 OCR2B = duty;
}