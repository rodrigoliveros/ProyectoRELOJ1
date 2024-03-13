//******************************************************************************
//Encabezado
//******************************************************************************
//Universidad del Valle de Guatemala
// IE2023 Programación de Microcontroladores
// Autor: Rodrigo Oliveros
// Proyecto: RELOJ
// Descripción: Producir un reloj funcional que presente hora, cambio hora, fecha, y alarma personalizable.
// Hardware: ATMega328P
// Created:23/02/2024 17:00
//******************************************************************************
//Facilitadores
//******************************************************************************
.include "M328PDEF.INC"
.cseg 
.org 0x00
	JMP		MAIN

.org 0x0006
	JMP		ISR_PCINT0

.org 0x0020
	JMP		ISR_TIMER0

//Variables
.def MODO =  R19
.def ESTADO = R20
.def umin = R22
.def dmin = R23
.def uhora = R24
.def dhora = R25

//******************************************************************************
//Tabla 7 segmentos
//******************************************************************************
TABLA7SEG: .DB	 0x7E, 0xC, 0xB6, 0x9E, 0xCC, 0xDA, 0xFA, 0xE, 0xFF, 0xCE 
//******************************************************************************
//Configuracion
//******************************************************************************
MAIN:
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16 
	LDI		R17, HIGH(RAMEND)
	OUT		SPL, R17
//******************************************************************************
//SETUP
//******************************************************************************
SETUP:
	LDI		ZL, LOW(TABLA7SEG << 1)
	LDI		ZH, HIGH(TABLA7SEG << 1)
	
	//Oscilador
	LDI		R16, (1 << CLKPCE)	;Habilitamos el prescaler
	STS		CLKPR, R16 
	LDI		R16, 0				;16Hz
	STS		CLKPR, R16
	
	//Entradas y salidas
	LDI		R16, 0x00	
	STS		UCSR0B, R16			;Habilitamos RTx y Tx como pines digitales utiles
	LDI		R16, 0xFF	
	OUT		DDRD, R16			;PORTD salida
	LDI		R16, 0xFF	
	OUT		DDRC, R16			;PORTC salida

	//PULL-UPS

	SBI PORTB, PB0				; Habilitando PULL-UP en PB0
	CBI DDRB, PB0				; Habilitando PB0 como entrada

	SBI PORTB, PB1				; Habilitando PULL-UP en PB1
	CBI DDRB, PB1				; Habilitando PB1 como entrada

	SBI PORTB, PB2				; Habilitando PULL-UP en PB2
	CBI DDRB, PB2				; Habilitando PB2 como entrada

	SBI PORTB, PB3				; Habilitando PULL-UP en PB0
	CBI DDRB, PB3				; Habilitando PB0 como entrada

	SBI PORTB, PB4				; Habilitando PULL-UP en PB4
	CBI DDRB, PB4				; Habilitando PB4 como entrada


	//Interrupciones TIMER
	LDI		R16, 0
	OUT		TCCR0A, R16			;Contador
	LDI		R16, 5
	OUT		TCCR0B, R16			;PRE 1024
	LDI		R16, 1				
	STS		TIMSK0, R16			;Habilitar TOIE0
	LDI		R16, 99				
	OUT		TCNT0, R16			;Initial value

	//Interrupciones de botones
				;PB 4			;PB3		;PB2		  ;PB1			 ;PB0
	LDI R16, (1 << PCINT4)|(1 << PCINT3)|(1 << PCINT2)|(1 << PCINT1)|(1 << PCINT0)
	STS PCMSK0, R16

	LDI R16, (1 << PCIE0)
	STS PCICR, R16 ; Habilitamos la ISR PCINT[7:0]

	//Limpiamos variables
	LDI		R16, 0
	LDI		R17, 0
	LDI		R18, 0
	LDI		R19, 0
	LDI		R20, 0
	LDI		R21, 0
	LDI		R22, 0
	
	LPM		R18, Z
	OUT		PORTD, R18

	SEI
//******************************************************************************
//LOOP
//******************************************************************************
LOOP:

	//INC		ZL					; Significa que llegamos a MIN.

	//LPM		R18, Z					;LUEGO UN OUT
	//OUT		PORTD, R18
	//INC		R23
	//ADD		ZL, R23
	//LPM		R19, Z					; LUEGO UN OUT
	//LDI		ZL, LOW(TABLA7SEG << 1)	 
	//LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla

	//CPI		R23, 6					; LLEGO A 60?
	//BRNE	LOOP
	//LDI		R23, 0					; SE CUMPLIO MINUTO
	//LDI		ZL, LOW(TABLA7SEG << 1)	 
	//LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla


	//ADD		ZL, R23
	//LPM		R19, Z					; LUEGO UN OUT
	//LDI		ZL, LOW(TABLA7SEG << 1)	 
	//LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla

	//LPM		R18, Z					; Cargar R18 la posición de z
	//OUT		PORTD, R18				; SACAR A PORTD
	//LPM		R19, Z

	//RJMP	LOOP
	SBRS ESTADO, 0 ; Estado bit 0 = 1?
	JMP	ESTADOX0 ; bit 0 = 0
	JMP	ESTADOX1 ; bit 0 = 1

ESTADOX0:
	SBRS ESTADO, 1 ; Estado bit 1 = 1?
	JMP ESTADO00 ; bit 1 = 0
	JMP ESTADO10 ; bit 1 = 1

ESTADOX1:
	SBRS ESTADO, 1 ; Estado bit 1 = 1?
	JMP ESTADO01 ; bit 1 = 0
	JMP ESTADO11 ; bit 1 = 1

ESTADO00:
	//SEGUNDOS
	CPI		R21, 100				; R21 = 100 (1 segundo)
	BRNE	LOOP					; Loop si no son iguales
	LDI		R21,0					; Iguales, reset
	INC		R22
	CPI		R22, 60					; LOOP SEGUNDOS.
	BRNE	LOOP
	//UNIDADES DE MIN
	LDI		R22, 0					;llegamos a minuto

	SBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	INC		ZL						; Mover en tabla
	LPM		R18, Z					; Cargar R18 con la posición de Z
	OUT		PORTD, R18				; SACAR A PORTD 

	CPI		R18, 0x0F				; Esta en el final?
	BRNE	LOOP					; Regresar a loop si no esta en el final
	LDI		ZL, LOW(TABLA7SEG << 1)	 
	LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla
	LPM		R18, Z					; Cargar R18 la posición de z
	OUT		PORTD, R18				; SACAR A PORTD
	RJMP	LOOP	
JMP LOOP
ESTADO01:

JMP LOOP
ESTADO10:

JMP LOOP
ESTADO11:

JMP LOOP		
//******************************************************************************
//SUBRUTINAS
//******************************************************************************

//Interrupción 1
ISR_TIMER0:
	PUSH	R16					;Guardamos para no perder counter ni resultados
	IN		R16, SREG			
	PUSH	R16					
		
	INC		R21					

	LDI		R17, 99				
	OUT		TCNT0, R17			;Initial Value

	POP		R16					;Sacamos de la pila
	OUT		SREG, R16			
	POP		R16					
	RETI

//Interrupción 2
ISR_PCINT0:
	PUSH	R16					;Guardamos para no perder counter ni resultados
	IN		R16, SREG			
	PUSH	R16	

	SBRS ESTADO, 0 ; Estado bit 0 = 1?
	JMP	ISR_ESTADOX0 ; bit 0 = 0
	JMP	ISR_ESTADOX1 ; bit 0 = 1

ISR_ESTADOX0:
	SBRS ESTADO, 1 ; Estado bit 1 = 1?
	JMP ISR_ESTADO00 ; bit 1 = 0
	JMP ISR_ESTADO10 ; bit 1 = 1

ISR_ESTADOX1:
	SBRS ESTADO, 1 ; Estado bit 1 = 1?
	JMP ISR_ESTADO01 ; bit 1 = 0
	JMP ISR_ESTADO11 ; bit 1 = 1

ISR_ESTADO00:
	IN R16, PINB
	SBRS R16, PB0	; PB0 = 1?
	DEC umin		; PB0 = 0
					; PB0 = 1
	SBRS R16, PB1	; PB1 = 1?
	INC umin	; PB1 = 0
					; PB1 = 1
	SBRS R16, PB4	; PB2 = 1?
	INC ESTADO		; PB5 = 0
					; PB5 = 1
	JMP SALIR
ISR_ESTADO01:
	IN R16, PINB
	SBRS R16, PB0	; PB0 = 1?
	DEC dmin		; PB0 = 0
					; PB0 = 1
	SBRS R16, PB1	; PB1 = 1?
	INC dmin	; PB1 = 0
					; PB1 = 1
	SBRS R16, PB4	; PB2 = 1?
	INC ESTADO		; PB5 = 0
					; PB5 = 1
	JMP SALIR

JMP SALIR
ISR_ESTADO10:

JMP SALIR
ISR_ESTADO11:

JMP SALIR

SALIR:
	POP		R16					;Salimos de la rutina
	OUT		SREG, R16			
	POP		R16					
	RETI


	// SBIS, BREG, utilizar segundos y decenas de segundos como solo un contador que muestra display en lugar de regristros. 
	// tambien realizar una estructura que sea como cuenta segundos sino minuntos sino horas sino dias sino calendarios
	//hacer las calls de alarma 

	//varias sub rutinas igual cuenta, hacemos cero, aumentamos al siguiente tiempo, sigue corriendo el codigo
	// hasta abajo muestra y regresa al loop.