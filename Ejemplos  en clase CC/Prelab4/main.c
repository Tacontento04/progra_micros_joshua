//**********************************************************
//Universidad del Valle de Guatemala
//IE2023 : Programación de Microcontroladores
//Test.asm
//
//Autor: Joshua Vásquez
//Proyecto: Proyecto 1
//Hardware: ATMega328P
//Creado: 01/03/2025
//Modificado :
//Descripcion: Es un reloj digital

//**************************************
//ENCABEZADO
//******************************************
#include <avr/io.h>
#include <avr/interrupt.h>

// Variables globales
volatile uint8_t counter = 0;
volatile uint8_t debounce_counters[2] = {0, 0};
volatile uint8_t last_state = 0x03;
volatile uint8_t mux_state = 0;  // Estado del multiplexado (0, 1, 2)

void setup()
{
	// 1. Configuración de LEDs
	DDRD = 0xFF;
	PORTD = 0x00;
	
	// 2. Configuración de botones
	DDRC &= ~((1 << PC0) | (1 << PC1));
	PORTC |= (1 << PC0) | (1 << PC1);
	
	// 3. Configuración de PORTB para los transistores (PB0, PB1, PB2 como salidas)
	DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2);
	PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2)); // Todos apagados inicialmente
	
	// 4. Timer0 para antirrebote (~10ms con 16MHz)
	TCCR0A = 0x00;
	TCCR0B = (1 << CS02) | (1 << CS00); // Prescaler 1024
	TIMSK0 = (1 << TOIE0);
	
	// 5. Timer2 para multiplexado rápido (~1kHz refresh rate)
	TCCR2A = 0x00;              // Modo normal
	TCCR2B = (1 << CS21);       // Prescaler 8 (16MHz/8 = 2MHz)
	TIMSK2 = (1 << TOIE2);      // Habilitar interrupción por overflow
	TCNT2 = 0;                  // Iniciar contador en 0
	
	// 6. Estado inicial
	counter = 0;
	update_leds();
	sei();
}

void update_leds()
{
	PORTD = counter;
}

int main(void)
{
	setup();
	
	while (1)
	{
		// El trabajo principal se hace en las interrupciones
	}
}
// Interrupción para multiplexado RÁPIDO (Timer2)
ISR(TIMER2_OVF_vect) {
	// Apagar todos los transistores primero
	PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2));
	
	// Encender solo el transistor actual
	switch(mux_state) {
		case 0:
		PORTB |= (1 << PB0);
		break;
		case 1:
		PORTB |= (1 << PB1);
		break;
		case 2:
		PORTB |= (1 << PB2);
		break;
	}
	
	// Avanzar al siguiente estado
	mux_state = (mux_state + 1) % 3;
}

// Interrupción para antirrebote (Timer0 - original)
ISR(TIMER0_OVF_vect)
{
	uint8_t current_state = PINC & ((1 << PC0) | (1 << PC1));
	uint8_t changes = current_state ^ last_state;
	last_state = current_state;
	
	// Procesar PC0 (incremento)
	if (!(current_state & (1 << PC0))) {
		debounce_counters[0]++;
		if (debounce_counters[0] >= 5) {
			counter++;
			update_leds();
			debounce_counters[0] = 0;
		}
		} else {
		debounce_counters[0] = 0;
	}
	
	// Procesar PC1 (decremento)
	if (!(current_state & (1 << PC1))) {
		debounce_counters[1]++;
		if (debounce_counters[1] >= 5) {
			counter--;
			update_leds();
			debounce_counters[1] = 0;
		}
		} else {
		debounce_counters[1] = 0;
	}
}
