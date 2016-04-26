    LIST P=16F877A, R=DEC   
    #include "P16F877A.INC"  ; 
    __config _LVP_OFF & _WDT_OFF & _PWRTE_ON & _BODEN_ON & _XT_OSC
    
    CBLOCK 0x20             ; Declare variable addresses starting at 0x20 
	dataL 
    ENDC

    ORG    0x000            ; Program starts at 0x000 
    
    
; 
; -------------------------------- 
; SET ANALOG/DIGITAL INPUTS PORT A 
; -------------------------------- 
; 
	BSF STATUS, RP0 ;SELECT BANK 01
	MOVLW B'10000000'
	MOVWF ADCON1

	BCF STATUS, RP0 ;SELECT BANK 00

	;FOSC/8, ADON=1
	MOVLW B'01000001'
	MOVWF ADCON0


     
; ---------------- 
; INITIALIZE PORTS 
; ---------------- 
; 
        
        movlw b'00000000'       ; set up portA 
        movwf PORTA

        movlw b'01000000'       ; RC6(TX)=1 others are 0 
        movwf PORTC

        bsf STATUS,RP0          ; RAM PAGE 1

        movlw 0xFF 
        movwf TRISA             ; portA all pins input

        movlw b'10111111'       ; RB7-RB4 and RB1(RX)=input, others output 
        movwf TRISC
	
; ------------------------------------ 
; SET BAUD RATE TO COMMUNICATE WITH PC 
; ------------------------------------ 
; Boot Baud Rate = 9600, No Parity, 1 Stop Bit 
; 
        movlw 0x19              ; 0x19=9600 bps (0x0C=19200 bps) 
        movwf SPBRG 
        movlw b'00100100'       ; brgh = high (2) 
        movwf TXSTA             ; enable Async Transmission, set brgh
        bcf STATUS,RP0          ; RAM PAGE 0
        movlw b'10010000'       ; enable Async Reception 
        movwf RCSTA 	
; 
; ------------------------------------ 
; PROVIDE A SETTLING TIME FOR START UP 
; ------------------------------------ 
; 
        clrf dataL 
settle  decfsz dataL,F 
        goto settle
        movf RCREG,W 
        movf RCREG,W 
        movf RCREG,W            ; flush receive buffer 
; 
; --------- 
; MAIN LOOP 
; --------- 
; 
        
loop    call ADC_READ 
	call message           
        goto loop 
; 	
	
; 
; ------------------------------------------------------------- 
; SEND CHARACTER IN W VIA RS232 AND WAIT UNTIL FINISHED SENDING 
; ------------------------------------------------------------- 
; 
send    movwf TXREG             ; send data in W

TransWt bsf STATUS,RP0          ; RAM PAGE 1 
WtHere  btfss TXSTA,TRMT        ; (1) transmission is complete if hi 
        goto WtHere

        bcf STATUS,RP0          ; RAM PAGE 0 
        return 
; 
; ------- 
; MESSAGE 
; ------- 
; 
message movwf ADRESH
        call	send 
        movlw ADRESL 
        call	send 
        movlw  0x0D ; CR 
        call send 
        movlw  0x0A ; LF 
        call send 
        return

ADC_READ 
	BCF STATUS, 5 ;SELECT BANK 00

	BSF ADCON0, 2 ;START CONVERTION PROCESS (WE SET THE GO BIT)
WAIT	BTFSC ADCON0, 2
	GOTO WAIT
	RETURN
	
END