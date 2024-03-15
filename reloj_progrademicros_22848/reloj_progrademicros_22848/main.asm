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

//.org 0x0020
//	JMP		ISR_TIMER0
.org 0x001A
	JMP		ISR_TIMER1

//Variables
.def ESTADO = R20


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


	//Interrupciones TIMER0
	//LDI		R16, 0
	//OUT		TCCR0A, R16			;Contador OPERACION NORMAL
	//LDI		R16, 5
	//OUT		TCCR0B, R16			;PRESCALER 1024
	//LDI		R16, 1				
	//STS		TIMSK0, R16			;Habilitar TOIE0
	//LDI		R16, 99				
	//OUT		TCNT0, R16			;Initial value

		//Interrupciones TIMER1
	LDI		R16, 0
	STS		TCCR1A, R16			;Contador OPERACION NORMAL
	LDI		R16, 5
	STS		TCCR1B, R16			;PRESCALER 1024
	LDI		R16, 1				
	STS		TIMSK1, R16			;Habilitar TOIE1
	LDI		R16, 0xC2				//32767
	STS		TCNT1H, R16			;Initial value
	LDI		R16, 0xF7				//32767
	STS		TCNT1L, R16			;Initial value

	//Interrupciones de botones
				;PB 4			;PB3		;PB2		  ;PB1			 ;PB0
	LDI R16, (1 << PCINT4)|(1 << PCINT3)|(1 << PCINT2)|(1 << PCINT1)|(1 << PCINT0)
	STS PCMSK0, R16

	LDI R16, (1 << PCIE0)
	STS PCICR, R16 ; Habilitamos la ISR PCINT[7:0]

	//Limpiamos variables
	LDI		R16, 0 //multiusos
	LDI		R17, 0 //
	LDI		R18, 0 //dirección de Z
	LDI		R19, 0 //
	LDI		R20, 0 //ESTADO
	LDI		R21, 0 //segundos en timer1
	LDI		R22, 0 //controlador de posición para unidades de minutos
	LDI		R23, 0// controlador de posición para decenas de minutos
	LDI		R24, 0 // controlador de que transistor esta encendido
	LDI		R25, 0 //controlador de posición para unidades de horas
	LDI		R26, 0 
	
	LPM		R18, Z
	OUT		PORTD, R18

	SEI
//******************************************************************************
//LOOP
//******************************************************************************
LOOP:
//Z
	CALL U_MIN
	CALL D_MIN
	CALL U_HORA
	CALL D_HORA
	
	//Uminutos
	CPI		R21, 1
	BRNE	LOOP	; SE CUMPLIO 1 MIN
	INC		R22		; Posición en la tabla Z
	LDI		R21, 0 
	//Dminutos
	CPI		R22, 10 ; display 0 llego a 10?
	BRNE	LOOP	; 
	INC		R23
	LDI		R22, 0	; si, se vuelve reinicia.
	//Uhora
	CPI		R23, 6	;ver si la decena de minuto llega a 6
	BRNE	LOOP	
	INC		R25		; incrementamos, llego a hora
	LDI		R23, 0	;reseteamos decena de minuto
	//Dhora
	CPI		R25, 10	; unidad de hora llego a 10?
	BRNE	LOOP
	INC		R26		; incrementamos, llego a decenas de hora
	LDI		R25, 0  ;reseteamos unidad de hora
	CPI		R26, 3
	BRNE	LOOP
	LDI		R26, 0
	JMP LOOP
	//dminutos

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
//ISR_TIMER0:
	//PUSH	R16					;Guardamos para no perder counter ni resultados
	//IN		R16, SREG			
	//PUSH	R16					
		
	//INC		R21					

	//LDI		R17, 99				
	//OUT		TCNT0, R17			;Initial Value

	//POP		R16					;Sacamos de la pila
	//OUT		SREG, R16			
	//POP		R16					
	//RETI

ISR_TIMER1:
	PUSH	R16					;Guardamos para no perder counter ni resultados
	IN		R16, SREG			
	PUSH	R16					
		
	INC		R21					

	LDI		R16, 0xC2				//32767
	STS		TCNT1H, R16			;Initial value
	LDI		R16, 0xF7				//32767
	STS		TCNT1L, R16			;Initial value

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

	JMP SALIR
ISR_ESTADO01:

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
U_MIN:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	
	MOV		R18, R22
	LDI		ZL, LOW(TABLA7SEG << 1)	 
	LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla
	ADD		ZL, R18
	LPM		R18, Z					; Cargar R18 la posición de z

	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3

	LDI		R24, 0b0000_0001
	OUT		PORTC, R24
	OUT		PORTD, R18				; SACAR A PORTD


	RET
D_MIN:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	
	MOV		R18, R23
	LDI		ZL, LOW(TABLA7SEG << 1)	 
	LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla
	ADD		ZL, R18
	LPM		R18, Z					; Cargar R18 la posición de z

	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3

	LDI		R24, 0b0000_0010
	OUT		PORTC, R24
	OUT		PORTD, R18				; SACAR A PORTD


	RET
U_HORA:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	
	MOV		R18, R25
	LDI		ZL, LOW(TABLA7SEG << 1)	 
	LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla
	ADD		ZL, R18
	LPM		R18, Z					; Cargar R18 la posición de z

	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3

	LDI		R24, 0b0000_0100
	OUT		PORTC, R24
	OUT		PORTD, R18				; SACAR A PORTD


	RET
D_HORA:
	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3
	
	MOV		R18, R26
	LDI		ZL, LOW(TABLA7SEG << 1)	 
	LDI		ZH, HIGH(TABLA7SEG << 1); Regresar al inicio de la tabla
	ADD		ZL, R18
	LPM		R18, Z					; Cargar R18 la posición de z

	CBI		PORTC, PC0
	CBI		PORTC, PC1
	CBI		PORTC, PC2
	CBI		PORTC, PC3

	LDI		R24, 0b0000_1000
	OUT		PORTC, R24
	OUT		PORTD, R18				; SACAR A PORTD

	RET