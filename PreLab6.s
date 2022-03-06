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
  
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    tempw:		DS 1
    temp_status:	DS 1
   
PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL main	    ; Cambio de pagina
    GOTO    main
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
push:
    MOVWF   tempw	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   temp_status    ; Guardamos STATUS
    
isr:
    
    BTFSC  TMR2IF
    CALL   aumentar
    
pop:
    SWAPF   temp_status, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   tempw, F	    
    SWAPF   tempw, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
aumentar:
    BCF  TMR2IF
    MOVLW 0x01
    XORWF PORTD
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posición 100h para el codigo
 
;------------- CONFIGURACION ------------
main:
    CALL    configio	    ; Configuración de I/O
    CALL    configwatch    ; Configuración de Oscilador
    CALL    configtmr2   ; Configuración de TMR0
    CALL    configint	    ; Configuración de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
loop:
    ; Código que se va a estar ejecutando mientras no hayan interrupciones
    GOTO   loop	    
    
;------------- SUBRUTINAS ---------------
    
configwatch:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 101 2MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 50ms
configtmr2:
    BANKSEL PR2
    MOVLW   244
    MOVWF   PR2	    ; 500ms retardo
    BANKSEL T2CON	    ; cambiamos de banco
    BSF	    T2CKPS1		    ; prescaler a TMR2
    BSF	    T2CKPS0		    ; PS<1:0> -> 1x prescaler 1 : 16
    
    BSF	    TOUTPS3		    ; TMR2 postscaler 
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0		    ; PS<3:0> 1111 postescaler 1:16
    BSF	    TMR2ON		    ; Enciende el TMR2
    
   RETURN 
 configio:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	        ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISD	    ; PORTD como salida
    BANKSEL PORTD
    CLRF    PORTD	    ; Apagamos PORTD
    RETURN
    
configint:
    BANKSEL PIE1 
    BSF	    TMR2IE
    BANKSEL INTCON
    BSF	    PEIE	    ; Habilitamos interrupciones
    BSF	    GIE		    ; Habilitamos interrupcion TMR0
    BCF	    TMR2IF
    RETURN
    
END