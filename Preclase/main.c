/*
 * Preclase.c
 *
 * Created: 4/29/2025 11:15:11 PM
 * Author : joshu
 */ 


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
void initUART();
void writeChar(char caracter);
void writeString(char* texto);
void toggleLED1();
volatile char received_char;
volatile uint8_t new_data = 0;
//**************************************
//MAIN FUNCTION
//******************************************

int main(void) {
	setup();
	writeString("\nSistema listo\n");
	writeString("Envie '1' para encender LED1 o '0' para apagarlo\n");
	
	while (1) {
		// Control del LED1 por UART
		if (new_data) {
			new_data = 0;
			
			if (received_char == '1') {
				PORTB |= (1 << PORTB0); // Encender LED1
				writeString("LED1 encendido\n");
			}
			else if (received_char == '0') {
				PORTB &= ~(1 << PORTB0); // Apagar LED1
				writeString("LED1 apagado\n");
			}
		}
		
		// Control del LED2 por botón (con anti-rebote)
		if (!(PINC & (1 << PORTC0))) { // Si botón presionado (asumiendo pull-up)
			_delay_ms(50); // Anti-rebote
			if (!(PINC& (1 << PORTC0))) { // Verificar aún presionado
				PORTB ^= (1 << PORTB1); // Cambiar estado LED2
				writeString("LED2 cambiado\n");
				while (!(PIND & (1 << PORTC0))); // Esperar a soltar botón
				_delay_ms(50); // Anti-rebote al soltar
			}
		}
	}
}
//**************************************
//Subrutinas 
//******************************************
void setup() {
	cli(); // Deshabilitar interrupciones
	
	// Configurar LEDs como salidas
	DDRB |= (1 << PORTB1) | (1 << PORTB0);
	PORTB &= ~((1 << PORTB1) | (1 << PORTB0)); // Apagar ambos LEDs
	
	// Configurar botón como entrada con pull-up
	DDRC &= ~(1 << PORTC0);
	PORTC |= (1 << PORTC0);
	
	initUART(); // Inicializar comunicación UART
	
	sei(); // Habilitar interrupciones
}

void initUART() {
	DDRD |= (1 << DDD1); // TX como salida
	DDRD &= ~(1 << DDD0); // RX como entrada
	
	UCSR0A = 0;
	UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); // Habilitar RX, TX e interrupción RX
	UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); // 8 bits de datos, sin paridad, 1 bit de stop
	UBRR0 = 103; // 9600 baudios @16MHz
}

void writeChar(char caracter) {
	while (!(UCSR0A & (1 << UDRE0))); // Esperar hasta que el buffer esté vacío
	UDR0 = caracter;
}

void writeString(char* texto) {
	for (uint8_t i = 0; texto[i] != '\0'; i++) {
		writeChar(texto[i]);
	}
}
//**************************************
//Interrupciones 
//******************************************
ISR(USART_RX_vect) {
	received_char = UDR0;
	new_data = 1;
}