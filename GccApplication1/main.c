/*
 * GccApplication1.c
 *
 * Created: 5/16/2025 8:56:07 PM
 * Author : joshu
 */ 


#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
void initADC(){
	ADMUX = (1 << REFS0); // Referencia AVcc
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC, preescalador 128
}

void setup()
	{
	DDRC = 0x00;
	DDRB = 0xFF;
		
		
	}
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

uint16_t leerADC(uint8_t canal) {
	ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // Seleccionar canal
	ADCSRA |= (1 << ADSC); // Iniciar conversión
	while (ADCSRA & (1 << ADSC));
	return ADC; //
}


void PWM_init() {
	// Fast PWM, modo 14: TOP = ICR1
	TCCR1A |= (1 << COM1A1) | (1 << WGM11) | (1 << COM1B1);
	TCCR1B |= (1 << WGM13) | (1 << WGM12) | (1 << CS11); // prescaler 8

	ICR1 = 65000; // TOP = 20 ms con reloj de 16MHz y prescaler 8
	
	DDRB |= (1 << PORTB1) | (1 << PORTB2); // OC1A (D9) como salida
}

void PWM_init2() {
	// Configurar Timer2 para modo FASAT PWM PWM con TOP=0xFF
	TCCR2A |= (1 << COM2A1) | (1 << COM2B1) | (1 << WGM20) | (1 << WGM21); // Non-inverting en ambos canales
	TCCR2B |= (1 << CS22) | (1 << CS21) | (1 << CS20); // Prescaler de 1024 (ajustar según necesidades)

	DDRD |= (1 << PORTD3); // OC2B (PD3) como salida
	DDRB |= (1 << PORTB3);  // OC2A (PB3) como salida (en la mayoría de los ATmega)
}


void PWM_init0() {
	// Configurar Timer2 para modo FAST PWM top 0xFF
	TCCR0A |= (1 << COM0A1) | (1 << COM0B1) | (1 << WGM00) | (1 << WGM01); // Non-inverting en ambos canales
	TCCR0B |= (1 << CS02)  | (1 << CS00); // Prescaler de 1024 (ajustar según necesidades)

	DDRD |= (1 << PORTD6); // OC0A 
	DDRD |= (1 << PORTD5);  // OC0B
}

void PWM_setAngle(uint16_t angle) {
	OCR1A = angle;
}
void PWM_setAngle2(uint16_t mov) {
	OCR1B = mov;
}
void PWM_setAngle3(uint16_t tung) {
	OCR2A = tung;
}
void PWM_setAngle4(uint16_t cerati) {
	OCR2B = cerati;
}
void PWM_setAngle5(uint16_t angle5) {
	OCR0A = angle5;
}
void PWM_setAngle6(uint16_t angle6) {
	OCR0B = angle6;
}


int main(void)
{
	setup();
	initADC();
	PWM_init();
	PWM_init2();
	PWM_init0();
	//timer0_init();
   
    while (1) 
    {
		//EJE X  --- ADC 6
		// EJE Y --- ADC 7 
	
		
		uint16_t servo1 = leerADC(6); // 0 - 1023
		uint16_t angle = (servo1 * -1.96) + 2100.0; //30 grados 
		//servo 1---- D9
		PWM_setAngle(angle);
		
		
		uint16_t servo2 = leerADC(6); // 0 - 1023
		uint16_t mov = (servo2 * 1.96) + 1199.0; // 30 grados
		//servo 2---- D10
		PWM_setAngle2(mov);
		

		uint16_t lol = leerADC(6);
		uint16_t tung = (lol* 0.0137) + 9;  //90 grados
		//servo 6 --- D11
		PWM_setAngle3(tung);
		
		uint16_t caifanes = leerADC(7);
		uint16_t cerati = (caifanes*0.00684)+9; //45 Grados
		// servo 5 --- D3
		PWM_setAngle4(cerati);
		
		// CEJASSS
		uint16_t cejas = leerADC(0);
		uint16_t angle5 = (cejas*0.0039 )+9;
		//servo 3 --- D6
		PWM_setAngle5(angle5);
		
		uint16_t cejas2 = leerADC(0);
		uint16_t angle6 = (cejas2*-0.0039 )+13;
		//servo 4 --- D5
		PWM_setAngle6(angle6);
		
    }
}

