;======================================================
;
; NOTE / Jan 11th, 2025 @thetrung:
;
; * This was my attempt to summarize PIC-AS usage today 
;   on MPLAB X IDE 6.20 & pic-as v2.50 on Ubuntu 24.10.
;
; * Debugged on Simulator of PIC18F45K50 just fine.
; 
; * Key problem during debugging was how the linker
;   didn't link the code properly with ORG directive.
;
;   - PSECT : this is now required for linker
;     to link every parts correctly. 
    
;     And 'space' argument let us access :
;     space=0 : program memory
;     space=1 : data memory
;     space=3 : reserved
;     space=3 : eeprom
;     Which is quite critical usage on memory.
    
;   - #include <xc.inc> : for stuffs like TRISA, LATA...
;
; ** 23th March 2025 **
; I come back to verify my delusion about PIC !
; 
; PICAS v3.00: doesn't have CMP instruction :
; - CPFSEQ REGISTER : to compare a register value with W-reg.
; - BTFSC STATUS, Z : to test if previous XORLW 0x00 result in zero.
;
;======================================================    

    PROCESSOR 18F45K50         ; Specify the PIC microcontroller
    #include <xc.inc>         ; Include XC8 definitions for PIC-AS like TRISA/PORTA
    
    GLOBAL main		       ; declare global symbol "main"

;======================================================
;
; CONFIG
;
;======================================================    
    CONFIG FOSC = INTOSCIO     ; Internal oscillator
    CONFIG WDTEN = OFF         ; Disable Watchdog Timer
    CONFIG LVP = OFF           ; Disable Low Voltage Programming

;=======================================================
;
; Bank/page selection
; when accessing memory it's important to select the correct page/bank
; banksel(addr) is used to select the bank of the address
; pagesel(addr) is used in the same way, but for ROM
;
;=======================================================
;banksel(100h) ; select the bank of 100h
;pagesel($) ; this selects the current page
 
;=======================================================
;
; MOVLW : move value [0x00-0xFF] -> WREG
; MOVWF : move value in WREG     -> address
; 
; * Wreg/address only work in 8-bit range [0x00-0xFF]
;
; ADD-WREG 
; * Add W-Register with 'content of register' 0x then store.
; * The Carry Flag (C) in the STATUS register will be updated 
;   based on the result of the addition indicating 
;   if there was a carry out from the addition.
;
;=======================================================
;addwf 0x100, w ; add w+[0x100] => stored in w
;addwf 0x100, f ; add w+[0x100] => stored in f
;movwf 0x001    ; [0x001] = w
;movlw 0x100    ; w = 0x100
;addwf 0x001, w ; w= [0x001] + w 
;
;=======================================================
;
; JUMP
; use fcall and ljmp for long calls/jumps.
;
;=======================================================
;
; Creates a new PSECT called: eeprom.
;
; - class=EEDATA : which means eeprom data.
; - noexec: specifies that the section cannot be exectued
; - space: refers to the type of data memory this is:
;   0 - program memory
;   1 - data memory
;   2 - reserved
;   3 - eeprom
;
;=======================================================
;psect eeprom, class=EEDATA, noexec, space=3
 
;=======================================================
;
; * Previous MPASM way to reset vector won't work.
; ORG was skipped on PIC-AS, so pretty useless.
;
;   ORG 0x0000
;   GOTO main
;
; The reason your code doesn't work without PSECT is likely 
; related to how the memory layout and the reset vector 
; are handled in assembly for the PIC microcontroller.
;
; PSECT 
; is used to define specific sections of the program memory.
; - class=CODE: designates the section as containing executable code.
; - reloc=2 ensures that the section respects a 2-byte memory boundary.
; - global: tells the linker to merge this section with 
;           other sections of the same name.
; - delta=2: assume size of address unit :
;            for 16-bit it will be 2
;            for 32-bit it will be 4
;
;=======================================================
; ANY CODE BEFORE THIS LINE IS NOT INCLUDED TO EXECUTE.
psect code, space=0 
; Define Constants ::
DELAY_VALUE EQU 0x02 ; We may have like DELAY * 256 * 256
MAX_COUNT EQU 0xFF   ; we will count 0 -> 255
EMPTY EQU 0x00       ; befor reset value -> 0 
COUNTER1 EQU 0x10    ; REG::Counter-1
COUNTER2 EQU 0x20    ; REG::Counter-2
COUNTER3 EQU 0x30    ; REG::Counter-3

main:
    ; Setup PORTA pins ::
    BANKSEL TRISA          ; Select bank for TRISA
    CLRF TRISA             ; Set RA0 as output
    ; Reset PortA pins :: 
    BANKSEL LATA           ; Select bank LATA (instead PORTA)
    CLRF LATA              ; Clear all PORTA pins (turn off LEDs
blink_loop:                ; Toggle RA0 ::
    BTG LATA, 0            ; BTG = Bit-Toggle bit'0' (RA0) of PORTA
    CALL delay             ; Call delay routine
    GOTO blink_loop        ; Repeat the loop
delay:                     ; Simple Delay Routine
    MOVLW MAX_COUNT	   ; [W] << [MAX_ROUND] 
    MOVWF COUNTER1         ; COUNTER1 << [W]
    MOVWF COUNTER2         ; COUNTER2 << [W]
    MOVLW DELAY_VALUE      ; [W] << [DELAY_COUNT]
    MOVWF COUNTER3         ; COUNTER3 << [w]
    
delay_start:
    MOVLW MAX_COUNT
    MOVWF COUNTER1         ; reset COUNTER1

delay_loop:
    DECFSZ COUNTER1, F     ; --[COUNTER1] register, skip if zero
    GOTO delay_loop        ; Continue loop
    
next_delay_1:
    DECFSZ COUNTER2, F     ; --[COUNTER2]
    GOTO delay_start
    MOVLW MAX_COUNT
    MOVWF COUNTER2         ; reset COUNTER2
    
next_delay_2:
    DECFSZ COUNTER3, F     ; --[COUNTER3]
    GOTO delay_start       ; restart.
    RETURN                 ; Return from delay routine

