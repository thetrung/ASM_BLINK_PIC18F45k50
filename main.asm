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
;   - PSECT : this is now required for linker to link
;     every parts correctly. 
;     And 'space' argument let us access :
;     space=0 : program memory
;     space=1 : data memory
;     space=3 : reserved
;     space=3 : eeprom
;     Which is quite critical usage on memory.
;   - BANKSEL : to select the bank of address.
;   - #include <xc.inc> : for stuffs like TRISA, PORTA
;
;======================================================    

    PROCESSOR 18F45K50         ; Specify the PIC microcontroller
    #include <xc.inc>          ; Include XC8 definitions for PIC-AS like TRISA/PORTA
    
    GLOBAL main		       ; declare global symbol "main"

;======================================================
;
; CONFIG
;
;======================================================    
    CONFIG FOSC = INTOSCIO     ; Internal oscillator
    CONFIG WDTEN = OFF         ; Disable Watchdog Timer
    CONFIG LVP = OFF           ; Disable Low Voltage Programming

;    
;======================================================
;
; Optimizations
; OPT ASMOPT_ON and OPT ASMOPT_OFF can be used.
;
;======================================================
    OPT ASMOPT_ON
 
;=======================================================
;
; Define Constants
;
;=======================================================
    DELAY_COUNT EQU 0x05 ; Define a constant for delay count
    COUNTER EQU 0x20     ; Counter Register
    EMPTY EQU 0x00       ; Reset WREG 

;=======================================================
;
; ADD-WREG 
; * Add W-Register with 'content of register' 0x then store.
; * The Carry Flag (C) in the STATUS register will be updated 
;   based on the result of the addition indicating 
;   if there was a carry out from the addition.
;
;=======================================================
addwf 0x100, w ; add w+[0x100] => stored in w
addwf 0x100, f ; add w+[0x100] => stored in f
movwf 0x001    ; [0x001] = w
movlw 0x100    ; w = 0x100
addwf 0x001, w ; w= [0x001] + w 

;=======================================================
;
; Bank/page selection
; when accessing memory it's important to select the correct page/bank
; banksel(addr) is used to select the bank of the address
; pagesel(addr) is used in the same way, but for ROM
;
;=======================================================
banksel(100h) ; select the bank of 100h
pagesel($) ; this selects the current page
 
 
;=======================================================
;
; PSECT: Program Section  
;
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
psect code, class=CODE, reloc=2, global

 
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
psect eeprom, class=EEDATA, noexec, space=3
 
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
;=======================================================
psect code
 
main:
    ; Initialize Ports
    BANKSEL TRISA              ; Select bank for TRISA
    CLRF TRISA                 ; Set all PORTA pins as output
    BANKSEL PORTA              ; Select bank for PORTA
    CLRF PORTA                 ; Clear all PORTA pins (turn off LEDs)

blink_loop:
    ; Toggle RA0
    BANKSEL PORTA              ; Ensure the correct bank is selected
    BTG PORTA, 0               ; BTG = Bit-Toggle bit'0' (RA0) of PORTA
    
    
;=======================================================
;
; MOVLW : move value [0x00-0xFF] -> WREG
; MOVWF : move value in WREG     -> address
; 
; * Wreg/address only work in 8-bit range [0x00-0xFF]
;
;=======================================================
    movlw 0x10                 ; w = 0x10
    movwf 0x01                 ; [0x01] = 0x10
    addwf 0x01, w              ; w= [0x01] + w 
    MOVLW EMPTY                ; Reset WREG <= EMPTY(0x00)
    MOVWF COUNTER              ; Store WREG => 0x20

    
;=======================================================
;
; JUMP
; use fcall and ljmp for long calls/jumps.
;
;=======================================================
    CALL delay                 ; Call delay routine

    ; Repeat
    GOTO blink_loop             ; Repeat the loop

delay:
    ; Simple Delay Routine
    MOVLW DELAY_COUNT          ; Load WREG <= delay count
    MOVWF COUNTER              ; Store WREG => COUNTER register
delay_loop:
    DECFSZ COUNTER, F          ; Decrement the COUNTER register, skip if zero
    GOTO delay_loop             ; Continue loop
    RETURN                     ; Return from delay routine

    END                        ; End of program



