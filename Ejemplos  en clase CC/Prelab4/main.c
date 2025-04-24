//**********************************************************
//Universidad del Valle de Guatemala
//IE2023 : Programación de Microcontroladores
//Test.asm
//
//Autor: Joshua Vásquez
//Proyecto: LAB4
//Hardware: ATMega328P
//Creado: 4/09/25
//Modificado :
//Descripcion: ADC ( AD carry)

//**************************************
//ENCABEZADO
//******************************************
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#define F_CPU 16000000

// Variables globales
volatile uint8_t counter = 0;
volatile uint8_t debounce_counters[2] = {0, 0};
volatile uint8_t last_state = 0x03;
volatile uint8_t mux_state = 0;  // Estado del multiplexado (0, 1, 2)
volatile uint8_t adc_value = 0;

// Tabla hexadesimal
const uint8_t tabla_7seg[16] = {
	0x40, // 0
	0x79, 
	0x24, 
	0x30, 
	0x19, 
	0x12, 
	0x02, 
	0x78, 
	0x00, 
	0x10, 
	0x08, 
	0x03, 
	0x46, 
	0x21, 
	0x06, 
	0x0E
};

void setup()
{
	// 1. Configuración de LEDs
	DDRD = 0xFF;
	PORTD = 0x00;
	
	// 2. Configuración de botones
	DDRC &= ~((1 << PORTB0) | (1 << PORTC1));
	PORTC |= (1 << PORTC0) | (1 << PORTC1);
	
	// 3. Configuración de PORTB para los transistores (PB0, PB1, PB2 como salidas)
	DDRB |= (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB3);
	//PORTB &= ~((1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB3) ); // Todos apagados inicialmente
	
	// 4. Timer0 para antirrebote (~10ms con 16MHz)
	TCCR0A = 0x00;
	TCCR0B = (1 << CS02) | (1 << CS00); // Prescaler 1024
	TIMSK0 = (1 << TOIE0);
	
	// 5. Timer2 para multiplexado rápido (~1kHz refresh rate)
	TCCR2A = 0x00;              // Modo normal
	TCCR2B = (1 << CS21);       // Prescaler 8 (16MHz/8 = 2MHz)
	TIMSK2 = (1 << TOIE2);      // Habilitar interrupción por overflow
	TCNT2 = 0;                  // Iniciar contador en 0
	
	// interrupcion del ADC
	initADC();
	ADCSRA	|= (1 << ADSC);

	// 6. Estado inicial
	counter = 0;
	//update_leds();
	sei();
}
void initADC()
{
	ADMUX = 0;
	ADMUX	|= (1<<REFS0);  // Se ponen los 5V como ref
	//ADMUX &= ~(1<< REFS1);
	ADMUX	|= (1 << ADLAR); // JUSTIF IZQ
	ADMUX	|= (1 << MUX2) | (1<< MUX1); //Seleccionar el ADC6
	// Por ultimo iniciar conversion
	
	ADCSRA	= 0;
	ADCSRA	|= (1 << ADPS1) | (1 << ADPS0); // Frecuencia de muestreo de 125kHz
	ADCSRA	|= (1 << ADIE); // Hab inter
	ADCSRA	|= (1 << ADEN); //
	
	//ADCSRA	|= (1<< ADSC);
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
		_delay_ms(10);
	}
}
// Interrupción para multiplexado RÁPIDO (Timer2)
ISR(TIMER2_OVF_vect) {
	// Apagar todos los transistores primero
	
	
	// Encender solo el transistor actual
	switch(mux_state) {
		case 0: // Decenas de segundos
		PORTB &= ~((1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2));
		PORTD = tabla_7seg[(adc_value >> 4) & 0x0F];
		PORTB |= (1 << PORTB0);
		break;
		case 1: //Unidades de segundo 
		PORTB &= ~((1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2));
		PORTD = tabla_7seg[adc_value & 0x0F];
		PORTB |= (1 << PORTB1);
		
		break;
		case 2: //LEDS
		PORTB &= ~((1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2));
		PORTB |= (1 << PORTB2);
		update_leds();
	
		break;
	}
	
	// Avanzar al siguiente estado
	mux_state = (mux_state + 1) % 3;
}

// Interrupción para antirrebote (Timer0 - original)
ISR(TIMER0_OVF_vect)
{
	static uint8_t stable_state = 0x03;
	uint8_t current_state = PINC & ((1 << PORTC0) | (1 << PORTC1));

	// Botón PC0 - Incrementar
	if (!(current_state & (1 << PORTC0))) {
		if (++debounce_counters[0] >= 5) {
			if (stable_state & (1 << PORTC0)) {
				counter++;
			}
			stable_state &= ~(1 << PORTC0);
		}
		} else {
		debounce_counters[0] = 0;
		stable_state |= (1 << PORTC0);
	}

	// Botón PC1 - Decrementar
	if (!(current_state & (1 << PORTC1))) {
		if (++debounce_counters[1] >= 5) {
			if (stable_state & (1 << PORTC1)) {
				counter--;
			}
			stable_state &= ~(1 << PORTC1);
		}
		} else {
		debounce_counters[1] = 0;
		stable_state |= (1 << PORTC1);
	}
}

ISR(ADC_vect)
{
	adc_value = ADCH; // Guardar el valor del ADC
	// Comparar con el contador
	if (adc_value > counter) {
		PORTB |= (1 << PORTB3);   
		} else {
		PORTB &= ~(1 << PORTB3); 
	}
	ADCSRA	|= (1<< ADSC);
}

	