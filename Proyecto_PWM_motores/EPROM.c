/*
 * EPROM.c
 *
 * Created: 5/18/2025 2:41:40 AM
 *  Author: joshu
 */ 
#include "EPROM.h"

void writeEEPROM(uint8_t dato, uint16_t direcc)
{
	while (EECR &(1<<EEPE));
	EEAR = direcc;
	EEDR = dato;
	EECR |= (1<<EEMPE);
	EECR |= (1<<EEPE);
	
}

uint8_t readEEPROM(uint16_t direcc)
{
	while (EECR &(1<<EEPE));
	EEAR = direcc;
	EECR |= (1<<EERE);
	return EEDR;
	
}