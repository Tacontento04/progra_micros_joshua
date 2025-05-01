//**********************************************************
//Universidad del Valle de Guatemala
//IE2023 : Programación de Microcontroladores
//Test.asm
//
//Autor: Joshua Vásquez
//Proyecto: LAB6
//Hardware: ATMega328P
//Creado: 4/25/25
//Modificado :
//Descripcion: UART

//**************************************
//ENCABEZADO
//******************************************
#include <avr/io.h>
#include <avr/interrupt.h>

/****************************************/
// Function prototypes
void setup();
void initUART();
void menu();
void initADC();
uint16_t leerADC(uint8_t canal);
void writeChar(char caracter);
void writeString(char* texto);
void enviarNumero(uint8_t valor);

volatile char received_char;
volatile uint8_t new_data = 0;
volatile uint8_t modo_asqi = 0;

/****************************************/
// Main Function
int main(void) {
    setup(); 
    //writeChar('B'); // Mensaje inicial
	//writeString("Bienvenidos a la cripta");
	
// MENU:
    menu();
    while (1) {
	
	if(new_data){
	new_data = 0;
	
//modo menu
	if(modo_asqi==0){
		// Modo POTENCIOMETRO
		if (received_char == '0') { 
			writeString("Modo Potenciometro\n");
			uint16_t lectura = leerADC(0);
			uint8_t valor = (lectura * 255UL) / 1023;  // Convertir a 8 bits
			//uint8_t valor = lectura;
			 // Mostrar en LEDs con sus máscaras
			 PORTB = valor & 0x1F; // bits 0-4 a PORTB
			 PORTD = (PORTD & 0x1F) | (valor & 0xE0); // bits 5-7 a PD5-PD7
			writeString("ADC0 (10 bits): ");
			writeChar(lectura);
			writeString(" -> 8 bits: ");
			enviarNumero(lectura);
			writeString("\n");
			  

			 menu();		
		}
		// menu ascii
		else if (received_char == '1') {  
			writeString("Modo ascii\n");
			writeString("\nIngrese un caracter para hacerlo ASCII: ");
			modo_asqi=1;
			new_data = 0; //ESPERAMOS A QUE NOS MANDEN ALGO NUEVO
		}
		else{	//una opcion valida
			writeString("INSERTAR OPCION VALIDA.\n");
			menu();
		}
	}
	//Modo Ascii
	else if (modo_asqi = 1){ 
		 PORTB = received_char & 0x1F; 
		 PORTD = (PORTD & 0x1F) | ((received_char & 0xE0) >> 3); 
		  writeString("\nCaracter recibido: ");
		  writeChar(received_char);
		  writeString("\n");
		  
		  modo_asqi = 0; // Volver al menú
		  menu();

		
				}
		}
    }
}

/****************************************/
// NON-Interrupt subroutines
void setup() {
    cli(); // Deshabilitar interrupciones
    
    // Configurar LEDs:
    DDRB |= 0x1F; // PB0-PB4 como salida (0b00011111)
    DDRD |= (1 << DDD5) | (1 << DDD6) | (1 << DDD7); // PD5-PD7 como salida
    
    PORTB = 0x00; // LEDs apagados inicialmente
    PORTD &= ~((1 << PORTD5) | (1 << PORTD6) | (1 << PORTD7)); // Apagar PD5-PD7
    initADC();
    initUART(); // Configurar UART
    sei(); // Habilitar interrupciones
}

void initUART() {
    // P1: Configurar PD1 (TX) como salida y PD0 (RX) como entrada
    DDRD |= (1 << DDD1); // TX (Salida)
    DDRD &= ~(1 << DDD0); // RX (Entrada)
    
    // P2: Configurar UCSR0A (Modo normal)
    UCSR0A = 0; 
    
    // P3: Habilitar TX, RX e interrupción por RX
    UCSR0B = (1 << RXCIE0) | (1 << RXEN0) | (1 << TXEN0); 
    
    // P4: Configurar formato: 8 bits, sin paridad, 1 stop bit
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00); 
    
    // P5: Baud rate a 9600 (@16MHz)
    UBRR0 = 103;
}
void menu(){
	writeString("\nSistema listo\n");
	writeString("Envie '0' para leer potenciometro o '1' para enviar ascii\n");
	
}

void initADC() {
	ADMUX = (1 << REFS0); // Referencia AVcc
	ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // Habilitar ADC, preescalador 128
}

uint16_t leerADC(uint8_t canal) {
	 ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // Seleccionar canal
	 ADCSRA |= (1 << ADSC); // Iniciar conversión
	 while (ADCSRA & (1 << ADSC));
	 return ADC >> 2; // Convertir a 8 bits

	
}	
void writeChar(char caracter) {
    while ((UCSR0A & (1 << UDRE0)) == 0); // Esperar buffer TX vacío
    UDR0 = caracter; // Enviar carácter
}

void writeString(char*texto){
	for (uint8_t i = 0; *(texto + i) != '\0'; i++)
	{
		writeChar(*(texto+i));
	}
	
}

void enviarNumero(uint8_t numero) {
	if (numero >= 100) {
		writeChar('0' + (numero / 100));
	}
	if (numero >= 10) {
		writeChar('0' + ((numero / 10) % 10));
	}
	writeChar('0' + (numero % 10));
}
/****************************************/
// Interrupt routines
ISR(USART_RX_vect) {
    received_char = UDR0; // Leer carácter recibido
    new_data = 1;
    // Mostrar en LEDs:
   // PORTB = (received_char & 0x1F); // Bits 0-4 en PB0-PB4
   // PORTD = (PORTD & 0x1F) | ((received_char & 0xE0) >> 2); // Bits 5-7 en PD5-PD7
    
    // Opcional: Eco en terminal
   // writeChar(received_char); 
}