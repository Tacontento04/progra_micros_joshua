/*
 * EPROM.h
 *
 * Created: 5/18/2025 2:41:27 AM
 *  Author: joshu
 */ 


#ifndef EPROM_H_
#define EPROM_H_

#include <avr/io.h>

void writeEEPROM(uint8_t dato, uint16_t direcc);
uint8_t readEEPROM(uint16_t direcc);

#endif /* EPROM_H_ */