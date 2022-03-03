; Universidad del Valle de Guatemala
; Programación de microcontroladores
; Archivo: newAsmTemplate.s
; Autor: Andrea Rodriguez Zea - 19429
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Multiples Displays
; Hardware: LEDs, botones y contadores de 7 segmentos
;
; Creado: 23 de febrero, 2022
; Última modificación: 26 de febrero, 2022

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
; -------------- MACROS --------------- 
  ; Macro para reiniciar el valor del TMR0
  ; *Recibe el valor a configurar en TMR_VAR*
  RESET_TMR1 MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H
    MOVWF   TMR1H	    ; 50ms retardo
    MOVLW   TMR1_L	    ; limpiamos bandera de interrupción
    MOVWF   TMR1L
    BCF	    TMR1IF
    ENDM
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
PSECT udata_bank0	    ;banco de variables
    segundos:      DS 1
PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL MAIN	    ; Cambio de pagina
    GOTO    MAIN
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    
    BTFSC   TMR1IF
    CALL    AUMENTO
    
    ;--------------------------------------------------------------------
    ; En caso de tener habilitadas varias interrupciones hay que evaluarel estado de todas las banderas de las interrupciones habilitadas
    ;	para identificar que interrupción fue la que se activó.
    
    ;BTFSC   T0IF	    ; Fue interrupción del TMR0? No=0 Si=1
    ;CALL    INT_TMR0	    ; Si -> Subrutina o macro con codigo a ejecutar
			    ;	cuando se active interrupción de TMR0
    
    ;BTFSC   RBIF	    ; Fue interrupción del PORTB? No=0 Si=1
    ;CALL    INT_PORTB	    ; Si -> Subrutina o macro con codigo a ejecutar
			    ;	cuando se active interrupción de PORTB
    ;---------------------------------------------------------------------
    
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
AUMENTO:
    RESET_TMR1 0x0B, 0xCD
    INCF segundos
    MOVF segundos, W
    MOVWF  PORTC
    RETURN
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
;------------- CONFIGURACION ------------
MAIN:
    CALL    CONFIG_IO	    ; Configuración de I/O
    CALL    CONFIG_RELOJ    ; Configuración de Oscilador
    CALL    CONFIG_TMR1	    ; Configuración de TMR0
    CALL    CONFIG_INT	    ; Configuración de interrupciones
    BANKSEL PORTC	    ; Cambio a banco 00
    
LOOP:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    GOTO    LOOP	    
    
;------------- SUBRUTINAS ---------------
CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 101 2MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 50ms
CONFIG_TMR1:
    BANKSEL T1CON	    ; cambiamos de banco
    BCF	    TMR1GE	    ; TMR1 Siempre cuenta
    BSF	    T1CKPS1		    ; prescaler a TMR1
    BSF	    T1CKPS0		    ; PS<2:0> -> 11 prescaler 1 : 8
    BCF	    T1OSCEN		    ; OSC tmr1 desactivado
    BCF	    TMR1CS
    BSF	    TMR1ON
    
    RESET_TMR1 0x0B, 0xCD
    RETURN 

; Cada vez que se cumple el tiempo del TMR0 es necesario reiniciarlo.
; * Comentado porque lo cambiamos de subrutina a macro *
/*RESET_TMR0:
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   61
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return*/
    
 CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	        ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISC	    ; PORTC como salida
    BANKSEL PORTC
    CLRF    PORTC	    ; Apagamos PORTC
    RETURN
    
CONFIG_INT:
    BANKSEL PIE1 
    BSF	    TMR1IE
    BANKSEL INTCON
    BSF	    PEIE	    ; Habilitamos interrupciones
    BSF	    GIE		    ; Habilitamos interrupcion TMR0
    BCF	    TMR1IF
    RETURN