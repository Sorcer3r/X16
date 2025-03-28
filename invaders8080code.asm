.cpu _65c02
#importonce 

#import "zeroPage.asm" 
#import "invaders8080vars.asm"
#import "Lib\macro.asm"
#import "screen.asm"
#import "SpriteArray.asm"

inv8080:{
reset:                //Reset: 
                //; Execution begins here on power-up and reset.
                //0000: 00              NOP                          ; This provides a slot ...
                //0001: 00              NOP                          ; ... to put in a JP for ...
                //0002: 00              NOP                          ; ... development
jmp init        //0003: C3 D4 18        JP      init                 ; Continue startup at 18D4
                //0006: 00 00      ; Padding before fixed ISR address
                //
                //ScanLine96:
ScanLine96:     //called by my int handler that deals with colours. backup zp regs?                 
                 // half way there (line 224) = 112pixels    
                //;Interrupt brings us here when the beam is *near* the middle of the screen. The real middle
                //;would be 224/2 = 112. The code pretends this interrupt happens at line 128.
                //0008: F5              PUSH    AF                   ; Save ...
saveRegs()                //0009: C5              PUSH    BC                   ; ...
                //000A: D5              PUSH    DE                   ; ...
                //000B: E5              PUSH    HL                   ; ... everything
                //000C: C3 8C 00        JP      $008C                ; Continue ISR at 8C (this was for space before #10)
                //
                //; Continues here at scanline 96
                //;
                //008C: AF              XOR     A                    ; Flag that tells ...
stz gamevars8080.vblankStatus                //008D: 32 72 20        LD      (vblankStatus),A    ; ... objects on the upper half of screen to draw/move"
lda gamevars8080.suspendPlay                //0090: 3A E9 20        LD      A,(suspendPlay)     ; Are we moving ..."
                //0093: A7              AND     A                    ; ... game objects?
beq isrExit                //0094: CA 82 00        JP      Z,$0082             ; No ... restore and return"
lda gamevars8080.gameMode                //0097: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //009A: A7              AND     A                    ; ... game mode?
bne processObjects                //009B: C2 A5 00        JP      NZ,$00A5            ; Yes .... process game objects and out"
lda gamevars8080.isrSplashTask                //009E: 3A C1 20        LD      A,(isrSplashTask)   ; Splash-animation tasks"
ror                //00A1: 0F              RRCA                         ; If we are in demo-mode then we'll process the tasks anyway
bcc isrExit                //00A2: D2 82 00        JP      NC,$0082            ; Not in demo mode ... done"
                //;
processObjects:                
loadHL(gamevars8080.obj1TimerMSB)       //00A5: 21 20 20        LD      HL,$2020            ; Game object table (skip player-object at 2010)"
jsr RunGameObjs1                //00A8: CD 4B 02        CALL    $024B                ; Process all game objects (except player object)
jsr CursorNextAlien                //00AB: CD 41 01        CALL    CursorNextAlien     ; Advance cursor to next alien (move the alien if it is last one)
bra isrExit                //00AE: C3 82 00        JP      $0082                ; Restore and return
                //000F: 00         ; Padding before fixed ISR address
                //
                //ScanLine224:
ScanLine224:    //called by my int handler for colours. backup zp regs? 
                // vblank 
               //; Interrupt brings us here when the beam is at the end of the screen (line 224) when the VBLANK begins.
                //0010: F5              PUSH    AF                   ; Save ...
saveRegs()                //0011: C5              PUSH    BC                   ; ...
                //0012: D5              PUSH    DE                   ; ...
                //0013: E5              PUSH    HL                   ; ... everything
lda #$80                //0014: 3E 80           LD      A,$80                ; Flag that tells objects ..."
sta gamevars8080.vblankStatus                //0016: 32 72 20        LD      (vblankStatus),A    ; ... on the lower half of the screen to draw/move"
dec gamevars8080.isrDelay                    //0019: 21 C0 20        LD      HL,isrDelay         ; Decrement ..."
                                            //dec (hl)
                //001D: CD CD 17        CALL    CheckHandleTilt     ; Check and handle TILT
                //0020: DB 01           IN      A,(INP1)            ; Read coin switch"
                //0022: 0F              RRCA                         ; Has a coin been deposited (bit 0)?
                //0023: DA 67 00        JP      C,$0067             ; Yes ... note that switch is closed and continue at 3F with A=1"
                //0026: 3A EA 20        LD      A,(coinSwitch)      ; Switch is now open. Was it ..."
                //0029: A7              AND     A                    ; ... closed last time?
 bra noCoinDeposit               //002A: CA 42 00        JP      Z,$0042             ; No ... skip registering the credit"
                //;
                //; Handle bumping credit count
lda gamevars8080.numCoins                //002D: 3A EB 20        LD      A,(numCoins)        ; Number of credits in BCD"
cmp #$99                //0030: FE 99           CP      $99                  ; 99 credits already?
beq maxCoins                //0032: CA 3E 00        JP      Z,$003E             ; Yes ... ignore this (better than rolling over to 00)"
sed                //0035: C6 01           ADD     A,$01                ; Bump number of credits"
inc
cld
                //0037: 27              DAA                          ; Make it binary coded decimal
sta gamevars8080.numCoins                //0038: 32 EB 20        LD      (numCoins),A        ; New number of credits"
jsr DrawNumCredits                //003B: CD 47 19        CALL    DrawNumCredits      ; Draw credits on screen
maxCoins:
                //003E: AF              XOR     A                    ; Credit switch ...
stz gamevars8080.coinSwitch                //003F: 32 EA 20        LD      (coinSwitch),A      ; ... has opened"

noCoinDeposit:                //;
lda gamevars8080.suspendPlay                //0042: 3A E9 20        LD      A,(suspendPlay)     ; Are we moving ..."
                //0045: A7              AND     A                    ; ... game objects?
beq isrExit                //0046: CA 82 00        JP      Z,$0082             ; No ... restore registers and out"
lda gamevars8080.gameMode                //0049: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //004C: A7              AND     A                    ; ... game mode?
bne gameLoop                //004D: C2 6F 00        JP      NZ,$006F            ; Yes ... go process game-play things and out"
lda gamevars8080.numCoins                //0050: 3A EB 20        LD      A,(numCoins)        ; Number of credits"
                //0053: A7              AND     A                    ; Are there any credits (player standing there)?
bne gotCredits                //0054: C2 5D 00        JP      NZ,$005D            ; Yes ... skip any ISR animations for the splash screens"
jsr ISRSplTasks                //0057: CD BF 0A        CALL    ISRSplTasks         ; Process ISR tasks for splash screens
bra isrExit                //005A: C3 82 00        JP      $0082                ; Restore registers and out
                //;
gotCredits:                //; At this point no game is going and there are credits
break()
lda gamevars8080.waitStartLoop                //005D: 3A 93 20        LD      A,(waitStartLoop)   ; Are we in the ..."
                //0060: A7              AND     A                    ; ... ""press start" loop?"
bne isrExit                //0061: C2 82 00        JP      NZ,$0082            ; Yes ... restore registers and out"
jmp waitForStart                //0064: C3 65 07        JP      WaitForStart        ; Start the ""press start" loop"
                //;
                //; Mark credit as needing registering
                //0067: 3E 01           LD      A,$01                ; Remember switch ..."
                //0069: 32 EA 20        LD      (coinSwitch),A      ; ... state for debounce"
                //006C: C3 3F 00        JP      $003F                ; Continue
                //;
gameLoop:                //; Main game-play timing loop
jsr TimeFleetSound                //006F: CD 40 17        CALL    TimeFleetSound      ; Time down fleet sound and sets flag if needs new delay value
gameLoopNoSound:
lda gamevars8080.obj2TimerExtra               //0072: 3A 32 20        LD      A,(obj2TimerExtra)  ; Use rolling shot's timer to sync ..."
sta gamevars8080.shotSync                //0075: 32 80 20        LD      (shotSync),A        ; ... other two shots"
jsr DrawAlien                //0078: CD 00 01        CALL    DrawAlien           ; Draw the current alien (or exploding alien)
jsr RunGameObjs                //007B: CD 48 02        CALL    RunGameObjs         ; Process game objects (including player object)
jsr TimeToSaucer                //007E: CD 13 09        CALL    TimeToSaucer        ; Count down time to saucer
                //0081: 00              NOP                          ; ** Why are we waiting?
isrExit:                //;
restoreRegs()          //0082: E1              POP     HL                   ; Restore ...
                //0083: D1              POP     DE                   ; ...
                //0084: C1              POP     BC                   ; ...
                //0085: F1              POP     AF                   ; ... everything
                //0086: FB              EI                           ; Enable interrupts
rts                //0087: C9              RET                          ; Return from interrupt
                //
                //0088: 00 00 00 00 ; ** Why waste the space?
                //The Aliens
                //InitRack:
                //; Initialize the player's rack of aliens. Copy the reference-location and deltas from the
                //; player's data bank.
                //;
                //00B1: CD 86 08        CALL    GetAlRefPtr         ; 2xFC Get current player's ref-alien position pointer
                //00B4: E5              PUSH    HL                   ; Hold pointer
                //00B5: 7E              LD      A,(HL)              ; Get player's ..."
                //00B6: 23              INC     HL                   ; ... ref-alien ...
                //00B7: 66              LD      H,(HL)              ; ..."
                //00B8: 6F              LD      L,A                  ; ... coordinates"
                //00B9: 22 09 20        LD      (refAlienYr),HL     ; Set game's reference alien's X,Y"
                //00BC: 22 0B 20        LD      (alienPosLSB),HL    ; Set game's alien cursor bit position"
                //00BF: E1              POP     HL                   ; Restore pointer
                //00C0: 2B              DEC     HL                   ; 21FB or 22FB ref alien's delta (left or right)
                //00C1: 7E              LD      A,(HL)              ; Get ref alien's delta X"
                //00C2: FE 03           CP      $03                  ; If there is one alien it will move right at 3
                //00C4: C2 C8 00        JP      NZ,$00C8            ; Not 3 ... keep it"
                //00C7: 3D              DEC     A                    ; If it is 3, back it down to 2 until it switches again"
                //00C8: 32 08 20        LD      (refAlienDXr),A     ; Store alien deltaY"
                //00CB: FE FE           CP      $FE                  ; Moving left?
                //00CD: 3E 00           LD      A,$00                ; Value of 0 for rack-moving-right (not XOR so flags are unaffected)"
                //00CF: C2 D3 00        JP      NZ,$00D3            ; Not FE ... keep the value 0 for right"
                //00D2: 3C              INC     A                    ; It IS FE ... use 1 for left
                //00D3: 32 0D 20        LD      (rackDirection),A   ; Store rack direction"
                //00D6: C9              RET                          ; Done
                //
                //00D7: 3E 02           LD      A,$02                ; Set ..."
                //00D9: 32 FB 21        LD      (p1RefAlienDX),A    ; ... player 1 and 2 ..."
                //00DC: 32 FB 22        LD      (p2RefAlienDX),A    ; ... alien delta to 2 (right 2 pixels)"
                //00DF: C3 E4 08        JP      $08E4                ; 
                //
                //00E2: 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //00F0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;
                //; This is heavily patched from a previous version of the code. There was a test here to jump to a
                //; self-test routine on startup (based on a dip switch). Even the original code padded with zeros
                //; to make the next function begin at 0100. Room for expansion?
                //
DrawAlien:                //DrawAlien:
//break()                //; 2006 holds the index into the alien flag data grid. 2067 holds the MSB of the pointer (21xx or 22xx).
                //; If there is an alien exploding time it down. Otherwise draw the alien if it alive (or skip if
                //; it isn't). If an alien is drawn (or blank) then the 2000 alien-drawing flag is cleared.
                //;
lda gamevars8080.alienIsExploding                 //0100: 21 02 20        LD      HL,$2002            ; Is there an ..."
                //0103: 7E              LD      A,(HL)              ; ... alien ..."
                //0104: A7              AND     A                    ; ... exploding?
beq !+
jmp AExplodeTime                //0105: C2 38 15        JP      NZ,AExplodeTime     ; Yes ... go time it down and out"
!:
stz gamevars8080.alienPosLSB                //zero lsb msb for edge check array
stz gamevars8080.alienPosMSB
                //0108: E5              PUSH    HL                   ; 2002 on the stack
lda gamevars8080.alienCurIndex                //0109: 3A 06 20        LD      A,(alienCurIndex)   ; Get alien index ..."
sta HL                //010C: 6F              LD      L,A                  ; ... for the 21xx or 22xx pointer"
lda gamevars8080.playerDataMSB                //010D: 3A 67 20        LD      A,(playerDataMSB)   ; Get MSB ..."
sta HL+1                //0110: 67              LD      H,A                  ; ... of data area (21xx or 22xx)"
lda (HL)                //0111: 7E              LD      A,(HL)              ; Get alien status flag"
                //0112: A7              AND     A                    ; Is the alien alive?
                //0113: E1              POP     HL                   ; HL=2002
beq DrawAlienExit                //0114: CA 36 01        JP      Z,$0136             ; No alien ... skip drawing alien sprite (but flag done)"
                //0117: 23              INC     HL                   ; HL=2003 Bump descriptor
                //0118: 23              INC     HL                   ; HL=2004 Point to alien's row
lda gamevars8080.alienRow                //0119: 7E              LD      A,(HL)              ; Get alien type"
                //011A: 23              INC     HL                   ; HL=2005 Bump descriptor
                //011B: 46              LD      B,(HL)              ; Get animation number"
and #$fe                //011C: E6 FE           AND     $FE                  ; Translate row to type offset as follows: ...
                //011E: 07              RLCA                         ; ... 0,1 -> 32 (type 1) ..." 000 001 000   00000000 0
                //011F: 07              RLCA                         ; ... 2,3 -> 16 (type 2) ..." 010 011 010   00010000 16
// row 0,1 =0                //0120: 07              RLCA                         ; ...   4 -> 32 (type 3) on top row 100 100 00100000 32
// row 2,3 =2               //0121: 5F              LD      E,A                  ; Sprite offset LSB"
//row 4 = 4                //0122: 16 00           LD      D,$00                ; MSB is 0"
// use as X for sprite image                 //0124: 21 00 1C        LD      HL,$1C00            ; Position 0 alien sprites"
// and add 1 if frame 1                //0127: 19              ADD     HL,DE                ; Offset to sprite type"
clc               //0128: EB              EX      DE,HL                ; Sprite offset to DE"
adc gamevars8080.alienFrame                //0129: 78              LD      A,B                  ; Animation frame number"
tax                //012A: A7              AND     A                    ; Is it position 0?
//x is frame image for alien                //012B: C4 3B 01        CALL    NZ,$013B            ; No ... add 30 and use position 1 alien sprites"

//deleted this. dont think i need poslsb/msb?
//lda gamevars8080.alienPosLSB     //X           //012E: 2A 0B 20        LD      HL,(alienPosLSB)    ; Pixel position"
//sta HL
//lda gamevars8080.alienPosMSB    //Y
//sta HL+1

//loadBC($1000)                //0131: 06 10           LD      B,$10                ; 16 rows in alien sprites"
jsr DrawSprite                //0133: CD D3 15        CALL    DrawSprite          ; Draw shifted sprite
lda HL+1
sta gamevars8080.alienPosLSB
lda HL
sta gamevars8080.alienPosMSB

DrawAlienExit:
               //;
ldx gamevars8080.alienCurIndex
lda gamevars8080.alienPosLSB    //X
sta gamevars8080.EdgeCheckX,x
lda gamevars8080.alienPosMSB    //Y
sta gamevars8080.EdgeCheckY,x
//save x and y in array for checks later
                //0136: AF              XOR     A                    ; Let the ISR routine ...
stz gamevars8080.waitOnDraw               //0137: 32 00 20        LD      (waitOnDraw),A      ; ... advance the cursor to the next alien"
rts                //013A: C9              RET                          ; Out
                //;
                //013B: 21 30 00        LD      HL,$0030            ; Offset sprite pointer ..."
                //013E: 19              ADD     HL,DE                ; ... to animation frame 1 sprites"
                //013F: EB              EX      DE,HL                ; Back to DE"
                //0140: C9              RET                          ; Out
                //
CursorNextAlien:                //CursorNextAlien:
                //; This is called from the mid-screen ISR to set the cursor for the next alien to draw.
                //; When the cursor moves over all aliens then it is reset to the beginning and the reference
                //; alien is moved to its next position.
                //;
                //; The flag at 2000 keeps this in sync with the alien-draw routine called from the end-screen ISR.
                //; When the cursor is moved here then the flag at 2000 is set to 1. This routine will not change
                //; the cursor until the alien-draw routine at 100 clears the flag. Thus no alien is skipped.
                //;
lda gamevars8080.playerOK                //0141: 3A 68 20        LD      A,(playerOK)        ; Is the player ..."
                //0144: A7              AND     A                    ; ... blowing up?
beq cursorNextExit                //0145: C8              RET     Z                    ; Yes ... ignore the aliens
lda gamevars8080.waitOnDraw                //0146: 3A 00 20        LD      A,(waitOnDraw)      ; Still waiting on ..."
                //0149: A7              AND     A                    ; ... this alien to be drawn?
bne cursorNextExit                //014A: C0              RET     NZ                   ; Yes ... leave cursor in place
lda gamevars8080.playerDataMSB                //014B: 3A 67 20        LD      A,(playerDataMSB)   ; Load alien-data ..."
sta HL+1                //014E: 67              LD      H,A                  ; ... MSB (either 21xx or 22xx)"
lda #$02
sta DE+1
ldx gamevars8080.alienCurIndex                //014F: 3A 06 20        LD      A,(alienCurIndex)   ; Load the xx part of the alien flag pointer"
                    //0152: 16 02           LD      D,$02                ; When all are gone this triggers 1A1 to return from this stack frame"
nextAlien:
inx                 //0154: 3C              INC     A                    ; Have we drawn all aliens ...
cpx #$37            //0155: FE 37           CP      $37                  ; ... at last position?
bne !+               //0157: CC A1 01        CALL    Z,MoveRefAlien       ; Yes ... move the bottom/right alien and reset index to 0
jsr MoveRefAlien
!:
stx HL                //015A: 6F              LD      L,A                  ; HL now points to alien flag"
lda (HL)                //015B: 46              LD      B,(HL)              ; Is alien ..."
dec                //015C: 05              DEC     B                    ; ... alive?
bne nextAlien                //015D: C2 54 01        JP      NZ,$0154            ; No ... skip to next alien"
stx gamevars8080.alienCurIndex                //0160: 32 06 20        LD      (alienCurIndex),A   ; New alien index"
jsr GetAlienCoords                //0163: CD 7A 01        CALL    GetAlienCoords      ; Calculate bit position and type for index
sty HL+1                //0166: 61              LD      H,C                  ; The calculation returns the MSB in C (y)
lda HL+1                //0167: 22 0B 20        LD      (alienPosLSB),HL    ; Store new bit position"
sta gamevars8080.alienPosMSB
lda HL
sta gamevars8080.alienPosLSB
//break()
                //016A: 7D              LD      A,L                  ; Has this alien ..."
cmp #$d8                //016B: FE 28           CP      $28                  ; ... reached the end of screen? checkbottom
bcc !+                //016D: DA 71 19        JP      C,$1971             ; Yes ... kill the player"
jmp AlienAtBottom
!:
lda DE+1               //0170: 7A              LD      A,D                  ; This alien's ..."
sta gamevars8080.alienRow                //0171: 32 04 20        LD      (alienRow),A        ; ... row index"
lda #$01                //0174: 3E 01           LD      A,$01                ; Set the wait-flag for the ..."
sta gamevars8080.waitOnDraw                //0176: 32 00 20        LD      (waitOnDraw),A      ; ... draw-alien routine to clear"
cursorNextExit:
rts                //0179: C9              RET                          ; Done
                //
GetAlienCoords:                //GetAlienCoords:
                //; Convert alien index in L to screen bit position in C,L."
                //; Return alien row index (converts to type) in D.
                //;
stz DE+1                //017A: 16 00           LD      D,$00                ; Row 0"
lda HL                //017C: 7D              LD      A,L                  ; Hold onto alien index"
sta PTR1
loadHL(gamevars8080.refAlienYr)                //017D: 21 09 20        LD      HL,$2009            ; Get alien X ..."

lda (HL)                //0180: 46              LD      B,(HL)              ; ... to B"
tax
inc HL                //0181: 23              INC     HL                   ; Get alien y ...
lda (HL)                //0182: 4E              LD      C,(HL)              ; ... to C"
tay
lda PTR1
getCoordsNextRow:
cmp #$0b                //0183: FE 0B           CP      $0B                  ; Can we take a full row off of index?
bmi getCoordsGotRow               //0185: FA 94 01        JP      M,$0194             ; No ... we have the row"
sec                //0188: DE 0B           SBC     A,$0B                ; Subtract off 11 (one whole row)"
sbc #$0b
sta DE                //018A: 5F              LD      E,A                  ; Hold the new index"
tax                //018B: 78              LD      A,B                  ; Add ..."
clc                //018C: C6 10           ADD     A,$10                ; ... 16 to bit ..."
adc #$10
txa                //018E: 47              LD      B,A                  ; ... position Y (1 row in rack)"
lda DE                //018F: 7B              LD      A,E                  ; Restore tallied index"
inc DE+1                //0190: 14              INC     D                    ; Next row
bra getCoordsNextRow                //0191: C3 83 01        JP      $0183                ; Keep skipping whole rows
getCoordsGotRow:                //;
stx HL                //0194: 68              LD      L,B                  ; We have the LSB (the row)"

getCoordsGetX:                //0195: A7              AND     A                    ; Are we in the right column?
bne !+                //0196: C8              RET     Z                    ; Yes ... X and Y are right
rts
!:
sta DE                //0197: 5F              LD      E,A                  ; Hold index"
tya                //0198: 79              LD      A,C                  ; Add ..."
clc                //0199: C6 10           ADD     A,$10                ; ... 16 to bit ..."
adc #$10
tay                //019B: 4F              LD      C,A                  ; ... position X (1 column in rack)"
lda DE                //019C: 7B              LD      A,E                  ; Restore index"
dec                //019D: 3D              DEC     A                    ; We adjusted for 1 column
bra getCoordsGetX                //019E: C3 95 01        JP      $0195                ; Keep moving over column
                //
MoveRefAlien:                //MoveRefAlien:
                //; The ""reference alien" is the bottom left. All other aliens are drawn relative to this"
                //; reference. This routine moves the reference alien (the delta is set elsewhere) and toggles
                //; the animation frame number between 0 and 1.
                //;
lda DE+1               //01A1: 15              DEC     D                    ; This decrements with each call to move
dec
sta DE+1
beq ReturnTwo                //01A2: CA CD 01        JP      Z,ReturnTwo         ; Return out of TWO call frames (only used if no aliens left)"
loadHL(gamevars8080.alienCurIndex)                //01A5: 21 06 20        LD      HL,$2006            ; Set current alien ..."
stz gamevars8080.alienCurIndex                //01A8: 36 00           LD      (HL),$00            ; ... index to 0"
inc HL                //01AA: 23              INC     HL                   ; Point to DeltaX
lda gamevars8080.refAlienDYr                //01AB: 4E              LD      C,(HL)              ; Load DX into C"
stz gamevars8080.refAlienDYr                //01AC: 36 00           LD      (HL),$00            ; Set DX to 0"
jsr AddDelta               //01AE: CD D9 01        CALL    AddDelta            ; Move alien
                //01B1: 21 05 20        LD      HL,$2005            ; Alien animation frame number"
lda gamevars8080.alienFrame                //01B4: 7E              LD      A,(HL)              ; Toggle ..."
eor #$01                //01B5: 3C              INC     A                    ; ... animation ...
                //01B6: E6 01           AND     $01                  ; ... number between ...
sta gamevars8080.alienFrame                //01B8: 77              LD      (HL),A              ; ... 0 and 1"
lda #$00                //01B9: AF              XOR     A                    ; Alien index in A is now 0
ldx gamevars8080.playerDataMSB                //01BA: 21 67 20        LD      HL,$2067            ; Restore H ..."
stx HL+1                //01BD: 66              LD      H,(HL)              ; ... to player data MSB (21 or 22)"
rts                //01BE: C9              RET                          ; Done
                //
                //01BF: 00 ; ** Why?
                //
InitAliens:                //InitAliens:
                //; Initialize the 55 aliens from last to 1st. 1 means alive.
                //;
lda #$01                //01C0: 21 00 21        LD      HL,$2100            ; Start of alien structures (this is the last alien)"
//sta gamevars8080.numAliens      // todo remove this and fix alien count
ldx #$36                //01C3: 06 37           LD      B,$37                ; Count to 55 (that's five rows of 11 aliens)"
InitAliens1:
sta gamevars8080.P1Data,x                //01C5: 36 01           LD      (HL),$01            ; Bring alien to live"
                        //01C7: 23              INC     HL                   ; Next alien
dex                     //01C8: 05              DEC     B                    ; All done?
bpl InitAliens1         //01C9: C2 C5 01        JP      NZ,$01C5            ; No ... keep looping"
rts                     //01CC: C9              RET                          ; Done
                //
ReturnTwo:                //ReturnTwo:
                //; If there are no aliens left on the screen then MoveDrawAlien comes here which returns from the
                //; caller's stack frame.
                //;
pla                //01CD: E1              POP     HL                   ; Drop return to caller
pla
rts                //01CE: C9              RET                          ; Return to caller's caller
                //Misc
DrawBottomLine:                //DrawBottomLine:
                //; Draw a 1px line across the player's stash at the bottom of the screen.
                //;
addressRegister(0,$1cc0c,1,0)
lda #$3e                //01CF: 3E 01           LD      A,$01                ; Bit 1 set ... going to draw a 1-pixel stripe down left side"
ldy #$01
ldx #$1c               //01D1: 06 E0           LD      B,$E0                ; All the way down the screen 224
drawBottom1:
sta VERADATA0                //01D3: 21 02 24        LD      HL,$2402            ; Screen coordinates (3rd byte from upper left)"
sty VERADATA0                //01D6: C3 CC 14        JP      $14CC                ; Draw line down left side
dex
bne drawBottom1
rts
                //
AddDelta:                //AddDelta:
                //; HL points to descriptor: DX DY XX YY except DX is already loaded in C
                //; ** Why the ""already loaded" part? Why not just load it here?"
                //;

sta PTR1    // DX
inc HL                //01D9: 23              INC     HL                   ; We loaded delta-x already ... skip over it
lda (HL)                //01DA: 46              LD      B,(HL)              ; Get delta-y"
sta PTR2    //dy
inc HL                //01DB: 23              INC     HL                   ; Skip over it
lda PTR1                //01DC: 79              LD      A,C                  ; Add delta-x ..."
clc                //01DD: 86              ADD     A,(HL)              ; ... to x"
adc (HL)
sta (HL)                //01DE: 77              LD      (HL),A              ; Store new x"
inc HL                //01DF: 23              INC     HL                   ; Skip to y
lda PTR2                    //01E0: 78              LD      A,B                  ; Add delta-y ..."
clc                //01E1: 86              ADD     A,(HL)              ; ... to y"
adc (HL)
sta (HL)                //01E2: 77              LD      (HL),A              ; Store new y"
rts                //01E3: C9              RET                          ; Done
                //
                //CopyRAMMirror:
                //; Block copy ROM mirror 1B00-1BBF to initialize RAM at 2000-20BF.
CopyRAMMirror:                //;
lda #$c0               //01E4: 06 C0           LD      B,$C0                ; Number of bytes"
sta BC+1
CopyRAMMirrorB:
lda #<InitializationDATA                 //01E6: 11 00 1B        LD      DE,$1B00            ; RAM mirror in ROM"
sta DE
lda #>InitializationDATA
sta DE+1
lda #<gamevars8080.waitOnDraw                //01E9: 21 00 20        LD      HL,$2000            ; Start of RAM"
sta HL
lda #>gamevars8080.waitOnDraw
sta HL+1
jmp BlockCopy                //01EC: C3 32 1A        JP      BlockCopy           ; Copy [DE]->[HL] and return
                //Copy/Restore Shields
DrawShieldPl1:                //DrawShieldPl1:
                //; Draw the shields for player 1 (draws it in the buffer in the player's data area).
                //;
                //01EF: 21 42 21        LD      HL,$2142            ; Player 1 shield buffer (remember between games in multi-player)"
                //01F2: C3 F8 01        JP      $01F8                ; Common draw point
                //;
                //DrawShieldPl2:
                //; Draw the shields for player 1 (draws it in the buffer in the player's data area).
                //;
                //01F5: 21 42 22        LD      HL,$2242            ; Player 2 shield buffer (remember between games in multi-player)"
                //;
                //01F8: 0E 04           LD      C,$04                ; Going to draw 4 shields"
                //01FA: 11 20 1D        LD      DE,$1D20            ; Shield pixel pattern"
                //01FD: D5              PUSH    DE                   ; Hold the start for the next shield
                //01FE: 06 2C           LD      B,$2C                ; 44 bytes to copy"
                //0200: CD 32 1A        CALL    BlockCopy           ; Block copy DE to HL (B bytes)
                //0203: D1              POP     DE                   ; Restore start of shield pattern
                //0204: 0D              DEC     C                    ; Drawn all shields?
                //0205: C2 FD 01        JP      NZ,$01FD            ; No ... go draw them all"
rts                //0208: C9              RET                          ; Done
                //
RememberShields1:                //RememberShields1:
                //; Copy shields on the screen to player 1's data area.
                //;
                //0209: 3E 01           LD      A,$01                ; Not zero means remember"
                //020B: C3 1B 02        JP      $021B                ; Shuffle-shields player 1
                //
RememberShields2:                //RememberShields2:
                //; Copy shields on the screen to player 2's data area.
                //;
                //020E: 3E 01           LD      A,$01                ; Not zero means remember"
                //0210: C3 14 02        JP      $0214                ; Shuffle-shields player 2
                //
RestoreShields2:                //RestoreShields2:
                //; Copy shields from player 2's data area to screen.
                //;
                //0213: AF              XOR     A                    ; Zero means restore
                //0214: 11 42 22        LD      DE,$2242            ; Player 2 shield buffer (remember between games in multi-player)"
                //0217: C3 1E 02        JP      CopyShields         ; Shuffle-shields player 2
                //
RestoreShields1:                //RestoreShields1:
                //; Copy shields from player 1's data area to screen.
                //;
                //021A: AF              XOR     A                    ; Zero means restore
                //021B: 11 42 21        LD      DE,$2142            ; Player 1 shield buffer (remember between games in multi-player)"
                //
CopyShields:                //CopyShields:
                //; A is 1 for screen-to-buffer, 0 for to buffer-to-screen"
                //; HL is screen coordinates of first shield. There are 23 rows between shields.
                //; DE is sprite buffer in memory.
                //;
                //021E: 32 81 20        LD      (tmp2081),A         ; Remember copy/restore flag"
                //0221: 01 02 16        LD      BC,$1602            ; 22 rows, 2 bytes/row (for 1 shield pattern)"
                //0224: 21 06 28        LD      HL,$2806            ; Screen coordinates"
                //0227: 3E 04           LD      A,$04                ; Four shields to move"
                //0229: F5              PUSH    AF                   ; Hold shield count
                //022A: C5              PUSH    BC                   ; Hold sprite-size
                //022B: 3A 81 20        LD      A,(tmp2081)         ; Get back copy/restore flag"
                //022E: A7              AND     A                    ; Not zero ...
                //022F: C2 42 02        JP      NZ,$0242            ; ... means remember shidles"
                //0232: CD 69 1A        CALL    RestoreShields      ; Restore player's shields
                //0235: C1              POP     BC                   ; Get back sprite-size
                //0236: F1              POP     AF                   ; Get back shield count
                //0237: 3D              DEC     A                    ; Have we moved all shields?
                //0238: C8              RET     Z                    ; Yes ... out
                //0239: D5              PUSH    DE                   ; Hold sprite buffer
                //023A: 11 E0 02        LD      DE,$02E0            ; Add 2E0 (23 rows) to get to ..."
                //023D: 19              ADD     HL,DE                ; ... next shield on screen"
                //023E: D1              POP     DE                   ; restore sprite buffer
                //023F: C3 29 02        JP      $0229                ; Go back and do all
                //;
                //0242: CD 7C 14        CALL    RememberShields     ; Remember player's shields
rts                //0245: C3 35 02        JP      $0235                ; Continue with next shield
                //Game Objects
RunGameObjs:                //RunGameObjs:
//break()                //; Process game objects. Each game object has a 16 byte structure. The handler routine for the object
                //; is at xx03 and xx04 of the structure. The pointer to xx04 is pushed onto the stack before calling
                //; the handler.
                //;
                //; All game objects (except task 0 ... the player) are called at the mid-screen and end-screen renderings.
                //; Each object decides when to run based on its Y (not rotated) coordinate. If an object is on the lower
                //; half of the screen then it does its work when the beam is at the top of the screen. If an object is
                //; on the top of the screen then it does its work when the beam is at the bottom. This keeps the
                //; object from updating while it is being drawn which would result in an ugly flicker.
                //;
                //;
                //; The player is only processed at the mid-screen interrupt. I am not sure why.
                //;
                //; The first three bytes of the structure are used for status and timers.
                //;
                //; If the first byte is FF then the end of the game-task list has been reached.
                //; If the first byte is FE then the object is skipped.
                //;
                //; If the first-two bytes are non-zero then they are treated like a two-byte counter
                //; and decremented as such. The 2nd byte is the LSB (moves the fastest).
                //;
                //; If the first-two bytes are zero then the third byte is treated as an additional counter. It
                //; is decremented as such.
                //;
                //; When all three bytes reach zero the task is executed.
                //;
                //; The third-byte-counter was used as a speed-governor for the player's object, but evidently even the slowest"
                //; setting was too slow. It got changed to 0 (fastest possible).
                //;
loadHL(gamevars8080.obj0TimerMSB)                //0248: 21 10 20        LD      HL,$2010            ; First game object (active player)"
RunGameObjs1:
lda (HL)               //024B: 7E              LD      A,(HL)              ; Have we reached the ..."
cmp #$ff                //024C: FE FF           CP      $FF                  ; ... end of the object list?
bne !+               //024E: C8              RET     Z                    ; Yes ... done
rts
!:
cmp #$fe                //024F: FE FE           CP      $FE                  ; Is object active?
beq RunGameObjNext                //0251: CA 81 02        JP      Z,$0281             ; No ... skip it"
tay                     // save a in y (C)
inc HL                //0254: 23              INC     HL                   ; xx01
lda (HL)                //0255: 46              LD      B,(HL)              ; First byte to B"
sta BC+1
tax                     // store in x (B)
tya                     // get a back (C)
sta BC                //0256: 4F              LD      C,A                  ; Hold 1st byte"
ora BC+1                //0257: B0              OR      B                    ; OR 1st and 2nd byte
                //0258: 79              LD      A,C                  ; Restore 1st byte"
bne RunGameObjDec                //0259: C2 77 02        JP      NZ,$0277            ; If word at xx00,xx02 is non zero then decrement it"
                //;
inc HL                //025C: 23              INC     HL                   ; xx02
lda (HL)                //025D: 7E              LD      A,(HL)              ; Get byte counter"
                //025E: A7              AND     A                    ; Is it 0?
bne runGameObjDecExtra                //025F: C2 88 02        JP      NZ,$0288            ; No ... decrement byte counter at xx02"
inc HL                //0262: 23              INC     HL                   ; xx03
lda (HL)              //0263: 5E              LD      E,(HL)              ; Get handler address LSB"
sta objHandlerAddress                    //save LSB of handler
inc HL                //0264: 23              INC     HL                   ; xx04
lda (HL)                //0265: 56              LD      D,(HL)              ; Get handler address MSB"
sta objHandlerAddress+1                     // save MSB of handler
lda HL+1                //0266: E5              PUSH    HL                   ; Remember pointer to MSB
tax
lda HL
tay
phx
phy
                //0267: EB              EX      DE,HL                ; Handler address to HL"
                //0268: E5              PUSH    HL                   ; Now to stack (making room for indirect call)
lda #>gameObjReturnHere-1                //0269: 21 6F 02        LD      HL,$026F            ; Return address to 026F"
pha
lda #<gameObjReturnHere-1                // because stupid 6502 doesnt return to the address on the stack but the address+1!
pha
                //026C: E3              EX      (SP),HL             ; Return address (026F) now on stack. Handler in HL."
phx                //026D: D5              PUSH    DE                   ; Push pointer to data struct (xx04) for handler to use
phy
jmp objHandlerAddress: $deaf                //026E: E9              JP      (HL)                 ; Run object's code (will return to next line)
gameObjReturnHere:
pla                //026F: E1              POP     HL                   ; Restore pointer to xx04
sta HL
pla
sta HL+1
lda #$0c                //0270: 11 0C 00        LD      DE,$000C            ; Offset to next ..."
clc
adc HL                //0273: 19              ADD     HL,DE                ; ... game task (C+4=10)"
sta HL
bra RunGameObjs1                //0274: C3 4B 02        JP      $024B                ; Do next game task
                //;
                //; Word at xx00 and xx01 is non-zero. Decrement it and move to next task.
RunGameObjDec:
dex                //0277: 05              DEC     B                    ; Decrement ...
inx                //0278: 04              INC     B                    ; ... two ...
bne decLow                //0279: C2 7D 02        JP      NZ,$027D            ; ... byte ..."
dey                //027C: 3D              DEC     A                    ; ... value ...
decLow:
dex                //027D: 05              DEC     B                    ; ... at ...
txa
sta (HL)                //027E: 70              LD      (HL),B              ; ... xx00 ..."
tya                //027F: 2B              DEC     HL                   ; ... and ...
dec HL
sta (HL)                //0280: 77              LD      (HL),A              ; ... xx01"
                //;
RunGameObjNext:
lda  HL              //0281: 11 10 00        LD      DE,$0010            ; Next ..."
clc                //0284: 19              ADD     HL,DE                ; ... object descriptor"
adc #$10
sta HL
bra RunGameObjs1                //0285: C3 4B 02        JP      $024B                ; Keep processing game objects
                //;
                //; Word at xx00 and xx01 is zero and byte at xx02 is non-zero. Decrement xx02 and
                //; move to next task.
runGameObjDecExtra:
dec                 //0288: 35              DEC     (HL)                 ; Decrement the xx02 counter
sta (HL)
dec HL                //0289: 2B              DEC     HL                   ; Back up to ...
dec HL                //028A: 2B              DEC     HL                   ; ... start of game task
bra RunGameObjNext                //028B: C3 81 02        JP      $0281                ; Next game task
                //
                //
                //
GameObj0:                //GameObj0:
                //; Game object 0: Move/draw the player
                //;
                //; This task is only called at the mid-screen ISR. It ALWAYS does its work here, even though"
                //; the player can be on the top or bottom of the screen (not rotated).
                //;
pla                //028E: E1              POP     HL                   ; Get player object structure 2014
sta HL
pla
sta HL+1
inc HL                //028F: 23              INC     HL                   ; Point to blow-up status
lda (HL)                //0290: 7E              LD      A,(HL)              ; Get player blow-up status"
cmp #$ff                //0291: FE FF           CP      $FF                  ; Player is blowing up?
beq GameObj0Normal                //0293: CA 3B 03        JP      Z,$033B             ; No ... go do normal movement"
                //;
                //; Handle blowing up player
inc HL                //0296: 23              INC     HL                   ; Point to blow-up delay count
lda (HL)                //0297: 35              DEC     (HL)                 ; Decrement the blow-up delay
dec
sta (HL)
beq !+                //0298: C0              RET     NZ                   ; Not time for a new blow-up sprite ... out
rts
!:
tax                //0299: 47              LD      B,A                  ; Hold sprite image number"
                //029A: AF              XOR     A                    ; 0
stz gamevars8080.playerOK                //029B: 32 68 20        LD      (playerOK),A        ; Player is NOT OK ... player is blowing up"
stz gamevars8080.enableAlienFire                //029E: 32 69 20        LD      (enableAlienFire),A ; Alien fire is disabled"
lda #$30                //02A1: 3E 30           LD      A,$30                ; Reset count ..."
sta gamevars8080.alienFireDelay                //02A3: 32 6A 20        LD      (alienFireDelay),A  ; ... till alien shots are enabled"
            // do later for flags                //02A6: 78              LD      A,B                  ; Restore sprite image number (used if we go to 39B)"
lda #$05                //02A7: 36 05           LD      (HL),$05            ; Reload time between blow-up changes"
sta (HL)
inc HL                //02A9: 23              INC     HL                   ; Point to number of blow-up changes
lda (HL)                //02AA: 35              DEC     (HL)                 ; Count down blow-up changes
dec
sta (HL)
txa
beq !+
jmp DrawPlayerDie                //02AB: C2 9B 03        JP      NZ,DrawPlayerDie    ; Still blowing up ... go draw next sprite"
                //;
!:                //; Blow up finished
break()                //02AE: 2A 1A 20        LD      HL,(playerYr)       ; Player's coordinates"
lda #$10                //02B1: 06 10           LD      B,$10                ; 16 Bytes"
                //02B3: CD 24 14        CALL    EraseSimpleSprite   ; Erase simple sprite (the player)
                //02B6: 21 10 20        LD      HL,$2010            ; Restore player ..."
                //02B9: 11 10 1B        LD      DE,$1B10            ; ... structure ..."
                //02BC: 06 10           LD      B,$10                ; ... from ..."
                //02BE: CD 32 1A        CALL    BlockCopy           ; ... ROM mirror
                //02C1: 06 00           LD      B,$00                ; Turn off ..."
                //02C3: CD DC 19        CALL    SoundBits3Off       ; ... all sounds
                //02C6: 3A 6D 20        LD      A,(invaded)         ; Has rack reached ..."
                //02C9: A7              AND     A                    ; ... the bottom of the screen?
                //02CA: C0              RET     NZ                   ; Yes ... done here
                //02CB: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //02CE: A7              AND     A                    ; ... game mode?
                //02CF: C8              RET     Z                    ; No ... return to splash screens
                //02D0: 31 00 24        LD      SP,$2400            ; We aren't going to return"
                //02D3: FB              EI                           ; Enable interrupts (we just dropped the ISR context)
                //02D4: CD D7 19        CALL    DsableGameTasks     ; Disable game tasks
                //02D7: CD 2E 09        CALL    $092E                ; Get number of ships for active player
                //02DA: A7              AND     A                    ; Any left?
                //02DB: CA 6D 16        JP      Z,$166D             ; No ... handle game over for player"
                //02DE: CD E7 18        CALL    $18E7                ; Get player-alive status pointer
                //02E1: 7E              LD      A,(HL)              ; Is player ..."
                //02E2: A7              AND     A                    ; ... alive?
                //02E3: CA 2C 03        JP      Z,$032C             ; Yes ... remove a ship from player's stash and reenter game loop"
                //02E6: 3A CE 20        LD      A,(twoPlayers)      ; Multi-player game"
                //02E9: A7              AND     A                    ; Only one player?
                //02EA: CA 2C 03        JP      Z,$032C             ; Yes ... remove a ship from player's stash and reenter game loop"
switchPlayers:
break()                //02ED: 3A 67 20        LD      A,(playerDataMSB)   ; Player data MSB"
                //02F0: F5              PUSH    AF                   ; Hold the MSB
                //02F1: 0F              RRCA                         ; Player 1 is active player?
                //02F2: DA 32 03        JP      C,$0332             ; Yes ... go store player 1 shields and come back to 02F8"
                //02F5: CD 0E 02        CALL    RememberShields2    ; No ... go store player 2 shields
                //02F8: CD 78 08        CALL    $0878                ; Get ref-alien info and pointer to storage
                //02FB: 73              LD      (HL),E              ; Hold the ..."
                //02FC: 23              INC     HL                   ; ... ref-alien ...
                //02FD: 72              LD      (HL),D              ; ... screen coordinates"
                //02FE: 2B              DEC     HL                   ; Back up ...
                //02FF: 2B              DEC     HL                   ; .. to delta storage
                //0300: 70              LD      (HL),B              ; Store ref-alien's delta (direction)"
                //0301: 00              NOP                          ; ** Why?
                //0302: CD E4 01        CALL    CopyRAMMirror       ; Copy RAM mirror (getting ready to switch players)
                //0305: F1              POP     AF                   ; Restore active player MSB
                //0306: 0F              RRCA                         ; Player 1?
                //0307: 3E 21           LD      A,$21                ; Player 1 data pointer"
                //0309: 06 00           LD      B,$00                ; Cocktail bit=0 (player 1)"
                //030B: D2 12 03        JP      NC,$0312            ; It was player one ... keep data for player 2"
                //030E: 06 20           LD      B,$20                ; Cocktail bit=1 (player 2)"
                //0310: 3E 22           LD      A,$22                ; Player 2 data pointer"
                //0312: 32 67 20        LD      (playerDataMSB),A   ; Change players"
                //0315: CD B6 0A        CALL    TwoSecDelay         ; Two second delay
                //0318: AF              XOR     A                    ; Clear the player-object ...
                //0319: 32 11 20        LD      (obj0TimerLSB),A    ; ... timer (player can move instantly after switching players)"
                //031C: 78              LD      A,B                  ; Cocktail bit to A"
                //031D: D3 05           OUT     (SOUND2),A          ; Set the cocktail mode"
                //031F: 3C              INC     A                    ; Fleet sound 1 (first tone)
                //0320: 32 98 20        LD      (soundPort5),A      ; Set the port 5 hold"
                //0323: CD D6 09        CALL    ClearPlayField      ; Clear center window
                //0326: CD 7F 1A        CALL    RemoveShip          ; Remove a ship and update indicators
                //0329: C3 F9 07        JP      $07F9                ; Tell the players that the switch has been made
                //;
                //032C: CD 7F 1A        CALL    RemoveShip          ; Remove a ship and update indicators
                //032F: C3 17 08        JP      $0817                ; Continue into game loop
                //;
                //0332: CD 09 02        CALL    RememberShields1    ; Remember the shields for player 1
                //0335: C3 F8 02        JP      $02F8                ; Back to switching-players above
                //
                //0338: 00 00 00 ; ** Why
                //           
GameObj0Normal:
                //; Player not blowing up ... handle inputs
loadHL(gamevars8080.playerOK)                //033B: 21 68 20        LD      HL,$2068            ; Player OK flag"
lda #$01
sta (HL)                //033E: 36 01           LD      (HL),$01            ; Flag 1 ... player is OK"
inc HL                //0340: 23              INC     HL                   ; 2069
lda (HL)                //0341: 7E              LD      A,(HL)              ; Alien shots enabled?"
                //0342: A7              AND     A                    ; Set flags
                //0343: C3 B0 03        JP      $03B0                ; Continue  moved 3b0 here .. made sense
bne movePlayerShip                //03B0: C2 4A 03        JP      NZ,$034A            ; Alien shots enabled ... move player's ship, draw it, and out"
inc HL                //03B3: 23              INC     HL                   ; To 206A
lda (HL)
dec
sta (HL)                //03B4: 35              DEC     (HL)                 ; Time until aliens can fire
bne movePlayerShip                //03B5: C2 4A 03        JP      NZ,$034A            ; Not time to enable ... move player's ship, draw it, and out"
                //03B8: C3 46 03        JP      $0346                ; Enable alien fire ... move player's ship, draw it, and out"



                //
enableAlienFire:
                //0346: 00              NOP                          ; ** Why?
dec HL                //0347: 2B              DEC     HL                   ; 2069
lda #$01
sta (HL)                //0348: 36 01           LD      (HL),$01            ; Enable alien fire"
                //
movePlayerShip:
lda gamevars8080.playerXr                //034A: 3A 1B 20        LD      A,(playerXr)        ; Current player coordinates"
sta BC+1                //034D: 47              LD      B,A                  ; Hold it"
lda gamevars8080.gameMode                //034E: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //0351: A7              AND     A                    ; ... game mode?
bne usePlayerInputs                //0352: C2 63 03        JP      NZ,$0363            ; Yes ... use switches as player controls"
                //;
lda gamevars8080.nextDemoCmd                //0355: 3A 1D 20        LD      A,(nextDemoCmd)     ; Get demo command"
ror                //0358: 0F              RRCA                         ; Is it right?
bcs MovePlayerRight                //0359: DA 81 03        JP      C,MovePlayerRight   ; Yes ... do right"
ror                //035C: 0F              RRCA                         ; Is it left?
bcs MovePlayerLeft                //035D: DA 8E 03        JP      C,MovePlayerLeft    ; Yes ... do left"
bra drawPlayerSprite                //0360: C3 6F 03        JP      $036F                ; Skip over movement (draw player and out)
                //; Player is in control
usePlayerInputs:
jsr ReadInputs                //0363: CD C0 17        CALL    ReadInputs          ; Read active player controls
rol                //0366: 07              RLCA                         ; Test for ...
rol                //0367: 07              RLCA                         ; ... right button
bcs MovePlayerRight                //0368: DA 81 03        JP      C,MovePlayerRight   ; Yes ... handle move right"
rol                //036B: 07              RLCA                         ; Test for left button
bcs MovePlayerLeft                //036C: DA 8E 03        JP      C,MovePlayerLeft    ; Yes ... handle move left"
                //; Draw player sprite
drawPlayerSprite:
addressRegister(0,$1fc00 + (59*8),1,0)   // sprite number 59 1fdd8 = player
lda SpriteArray.addressTableLo + 6  // player image = sprite 6                //036F: 21 18 20        LD      HL,$2018            ; Active player descriptor"
sta VERADATA0                   //0372: CD 3B 1A        CALL    ReadDesc            ; Load 5 byte sprite descriptor in order: EDLHB
lda SpriteArray.addressTableHi +6                //0375: CD 47 1A        CALL    ConvToScr           ; Convert HL to screen coordinates
sta VERADATA0
lda gamevars8080.playerXr                 //0378: CD 39 14        CALL    DrawSimpSprite      ; Draw player
clc
adc #$30
sta VERADATA0
lda #$00
adc #$00
sta VERADATA0
lda gamevars8080.playerYr
sta VERADATA0
stz VERADATA0
lda #%00001100
sta VERADATA0
lda #%00010000
sta VERADATA0
                //037B: 3E 00           LD      A,$00                ; Clear the task timer. Nobody changes this but it could have ..."
stz gamevars8080.obj0TimerExtra                //037D: 32 12 20        LD      (obj0TimerExtra),A  ; ... been speed set for the player with a value other than 0 (not XORA)"
rts                //0380: C9              RET                          ; Out
                //
MovePlayerRight:                //MovePlayerRight:
                //; Handle player moving right
lda BC+1               //0381: 78              LD      A,B                  ; Player coordinate"
cmp #$bf                //0382: FE D9           CP      $D9                  ; At right edge? PLAYER RIGHT LIMIT
beq drawPlayerSprite                //0384: CA 6F 03        JP      Z,$036F             ; Yes ... ignore this"
inc                //0387: 3C              INC     A                    ; Bump X coordinate
sta gamevars8080.playerXr                //0388: 32 1B 20        LD      (playerXr),A        ; New X coordinate"
bra drawPlayerSprite                //038B: C3 6F 03        JP      $036F                ; Draw player and out
                //
MovePlayerLeft:                //MovePlayerLeft: 
                //; Handle player moving left
lda BC+1                //038E: 78              LD      A,B                  ; Player coordinate"
cmp #$10                //038F: FE 30           CP      $30                  ; At left edge   player left limit
beq drawPlayerSprite                //0391: CA 6F 03        JP      Z,$036F             ; Yes ... ignore this"
dec                //0394: 3D              DEC     A                    ; Bump X coordinate
sta gamevars8080.playerXr                //0395: 32 1B 20        LD      (playerXr),A        ; New X coordinate"
bra drawPlayerSprite                //0398: C3 6F 03        JP      $036F                ; Draw player and out
                //
DrawPlayerDie:                //DrawPlayerDie:
break()                //; Toggle the player's blowing-up sprite between two pictures and draw it
                //039B: 3C              INC     A                    ; Toggle blowing-up ...
                //039C: E6 01           AND     $01                  ; ... player sprite (0,1,0,1)"
                //039E: 32 15 20        LD      (playerAlive),A     ; Hold current state"
                //03A1: 07              RLCA                         ; *2
                //03A2: 07              RLCA                         ; *4
                //03A3: 07              RLCA                         ; *8
                //03A4: 07              RLCA                         ; *16
                //03A5: 21 70 1C        LD      HL,$1C70            ; Base blow-up sprite location"
                //03A8: 85              ADD     A,L                  ; Offset sprite ..."
                //03A9: 6F              LD      L,A                  ; ... pointer"
                //03AA: 22 18 20        LD      (plyrSprPicL),HL    ; New blow-up sprite picture"
                //03AD: C3 6F 03        JP      $036F                ; Draw new blow-up sprite and out
                //
                //03B0: C2 4A 03        JP      NZ,$034A            ; Alien shots enabled ... move player's ship, draw it, and out"
                //03B3: 23              INC     HL                   ; To 206A
                //03B4: 35              DEC     (HL)                 ; Time until aliens can fire
                //03B5: C2 4A 03        JP      NZ,$034A            ; Not time to enable ... move player's ship, draw it, and out"
                //03B8: C3 46 03        JP      $0346                ; Enable alien fire ... move player's ship, draw it, and out"
                //
                //
GameObj1:                //GameObj1:
                //; Game object 1: Move/draw the player shot
                //;
                //; This task executes at either mid-screen ISR (if it is on the top half of the non-rotated screen) or
                //; at the end-screen ISR (if it is on the bottom half of the screen).
pla                 //03C1: E1              POP     HL                   ; Pointer to task data
sta PTR1            // and save it in ptr1/2 for now
pla 
sta PTR2 

                //;
loadDE(gamevars8080.obj1CoorYr)               //03BB: 11 2A 20        LD      DE,$202A            ; Object's Yn coordiante"
jsr CompYToBeam                //03BE: CD 06 1A        CALL    CompYToBeam         ; Compare to screen-update location
php                    // save Flags 
lda PTR1                // get HL back
sta HL
lda PTR2
sta HL+1
plp                 //restore flags
bcs !+              
rts                //03C2: D0              RET     NC                   ; Make sure we are in the right ISR
!:                //
inc HL                //03C3: 23              INC     HL                   ; Point to 2025 ... the shot status
lda (HL)                //03C4: 7E              LD      A,(HL)              ; Get shot status"
bne !+                //03C5: A7              AND     A                    ; Return if ...
rts                //03C6: C8              RET     Z                    ; ... no shot is active
!:                //;
cmp #$01                //03C7: FE 01           CP      $01                  ; Shot just starting (requested elsewhere)?
beq InitPlyShot                //03C9: CA FA 03        JP      Z,InitPlyShot       ; Yes ... go initiate shot"
                //;
cmp #$02                //03CC: FE 02           CP      $02                  ; Progressing normally?
beq MovePlyShot                //03CE: CA 0A 04        JP      Z,MovePlyShot       ; Yes ... go move it"
                //;
inc HL                //03D1: 23              INC     HL                   ; 2026
cmp #$03                //03D2: FE 03           CP      $03                  ; Shot blowing up (not because of alien)?
bne testOtherOptions                //03D4: C2 2A 04        JP      NZ,$042A            ; No ... try other options"
                //;
                //; Shot blowing up because it left the playfield, hit a shield, or hit another bullet"
lda (HL)
dec
sta (HL)               //03D7: 35              DEC     (HL)                 ; Decrement the timer
beq EndOfBlowup                //03D8: CA 36 04        JP      Z,EndOfBlowup       ; If done then"
                //03DB: 7E              LD      A,(HL)              ; Get timer value"
cmp #$0f                //03DC: FE 0F           CP      $0F                  ; Starts at 10 ... first decrement brings us here
beq !+
rts                //03DE: C0              RET     NZ                   ; Not the first time ... explosion has been drawn
!:
                //; Draw explosion first pass through timer loop
addressRegister(0,$1fc00+(60*8),1,0)    //point to sprite 60
lda SpriteArray.addressTableLo+15
sta VERADATA0
lda SpriteArray.addressTableHi+15
sta VERADATA0

rts             // just change sprite image!
                //03DF: E5              PUSH    HL                   ; Hold pointer to data
                //03E0: CD 30 04        CALL    ReadPlyShot         ; Read shot descriptor
                //03E3: CD 52 14        CALL    EraseShifted        ; Erase the sprite
                //03E6: E1              POP     HL                   ; 2026 (timer flag)
                //03E7: 23              INC     HL                   ; 2027 point to sprite LSB
                //03E8: 34              INC     (HL)                 ; Change 1C90 to 1C91
                //03E9: 23              INC     HL                   ; 2028
                //03EA: 23              INC     HL                   ; 2029
                //03EB: 35              DEC     (HL)                 ; Drop X coordinate ...
                //03EC: 35              DEC     (HL)                 ; ... by 2
                //03ED: 23              INC     HL                   ; 202A
                //03EE: 35              DEC     (HL)                 ; Drop Y ...
                //03EF: 35              DEC     (HL)                 ; ... coordinate ...
                //03F0: 35              DEC     (HL)                 ; ... by .../
                //03F1: 23              INC     HL                   ; ... 3
                //03F2: 36 08           LD      (HL),$08            ; 202B 8 bytes in size of sprite"
                //03F4: CD 30 04        CALL    ReadPlyShot         ; Read player shot structure
                //03F7: C3 00 14        JP      DrawShiftedSprite   ; Draw sprite and out
                //;
InitPlyShot: 
               //InitPlyShot:
inc                //03FA: 3C              INC     A                    ; Type is now ...
sta (HL)                //03FB: 77              LD      (HL),A              ; ... 2 (in progress)"
lda gamevars8080.playerXr                //03FC: 3A 1B 20        LD      A,(playerXr)        ; Players Y coordinate"
clc
adc #$06               //03FF: C6 08           ADD     A,$08                ; To center of player"
sta gamevars8080.obj1CoorYr                //0401: 32 2A 20        LD      (obj1CoorXr),A      ; Shot's Y coordinate"
jsr ReadPlyShot                //0404: CD 30 04        CALL    ReadPlyShot         ; Read 5 byte structure
jmp DrawPlayerShot                //0407: C3 00 14        JP      DrawShiftedSprite   ; Draw sprite and out
                //;
MovePlyShot:                //MovePlyShot:
jsr ReadPlyShot                //040A: CD 30 04        CALL    ReadPlyShot         ; Read the shot structure
                //040D: D5              PUSH    DE                   ; Hold pointer to sprite image
                //040E: E5              PUSH    HL                   ; Hold sprite coordinates
                //040F: C5              PUSH    BC                   ; Hold sprite size (in B)
// no need to erase                //0410: CD 52 14        CALL    EraseShifted        ; Erase the sprite from the screen
                //0413: C1              POP     BC                   ; Restore size
                //0414: E1              POP     HL                   ; Restore coords
                //0415: D1              POP     DE                   ; Restore pointer to sprite image
lda gamevars8080.shotDeltaX                //0416: 3A 2C 20        LD      A,(shotDeltaX)      ; DeltaX for shot"
clc
adc HL+1                //0419: 85              ADD     A,L                  ; Move the shot ..."
sta HL+1                //041A: 6F              LD      L,A                  ; ... up the screen"
sta gamevars8080.obj1CoorXr                //041B: 32 29 20        LD      (obj1CoorYr),A      ; Store shot's new X coordinate"
jsr DrawPlayerShotCollison                //041E: CD 91 14        CALL    DrawSprCollision    ; Draw sprite with collision detection
lda gamevars8080.collision                //0421: 3A 61 20        LD      A,(collision)       ; Test for ..."
                //0424: A7              AND     A                    ; ... collision
bne !+                //0425: C8              RET     Z                    ; No collision ... out
rts                //;
!:                //; Collision with alien detected
sta gamevars8080.alienIsExploding                //0426: 32 02 20        LD      (alienIsExploding),A; Set to not-0 indicating ..."
rts                //0429: C9              RET                          ; ... an alien is blowing up
                //;
testOtherOptions:                //; Other shot-status options
cmp #$05               //042A: FE 05           CP      $05                  ; Alien explosion in progress?
bne !+
rts                //042C: C8              RET     Z                    ; Yes ... nothing to do
!:
bra EndOfBlowup                //042D: C3 36 04        JP      EndOfBlowup         ; Anything else erases the shot and removes it from duty
                //
ReadPlyShot:
loadHL(gamevars8080.obj1ImageLSB)                //0430: 21 27 20        LD      HL,$2027            ; Read 5 byte sprite structure for ..."
jmp ReadDesc                //0433: C3 3B 1A        JP      ReadDesc            ; ... player shot
                //
EndOfBlowup:                //EndOfBlowup:
                //0436: CD 30 04        CALL    ReadPlyShot         ; Read the shot structure
addressRegister(0,$1fc00+(60*8)+6,1,0)    //point to sprite 60
stz VERADATA0       // turn off sprite 60 
                //0439: CD 52 14        CALL    EraseShifted        ; Erase the player's shot
loadHL(gamevars8080.plyrShotStatus)                //043C: 21 25 20        LD      HL,$2025            ; Reinit ..."
loadDE(gameobj1Ptr+5)                //043F: 11 25 1B        LD      DE,$1B25            ; ... shot structure ..."
loadBC($0700)                //0442: 06 07           LD      B,$07                ; ... from ..."
jsr BlockCopy                //0444: CD 32 1A        CALL    BlockCopy           ; ... ROM mirror
lda gamevars8080.sauScoreLSB                //0447: 2A 8D 20        LD      HL,(sauScoreLSB)    ; Get pointer to saucer-score table"
inc             //044A: 2C              INC     L                    ; Every shot explosion advances it one
                //044B: 7D              LD      A,L                  ; Have we passed ..."
cmp #<SaucerScrTab+15                //044C: FE 63           CP      $63                  ; ... the end at 1D63 (bug! this should be $64 to cover all 16 values)
bcs !+                //044E: DA 53 04        JP      C,$0453             ; No .... keep it"
lda #<SaucerScrTab                //0451: 2E 54           LD      L,$54                ; Wrap back around to 1D54"
sta gamevars8080.sauScoreLSB                //0453: 22 8D 20        LD      (sauScoreLSB),HL    ; New score pointer"
inc gamevars8080.shotCountLSB                //0456: 2A 8F 20        LD      HL,(shotCountLSB)   ; Increments with every shot ..."
                //0459: 2C              INC     L                    ; ... but only LSB ** ...
                //045A: 22 8F 20        LD      (shotCountLSB),HL   ; ... used for saucer direction"
                //;
lda gamevars8080.saucerActive                //045D: 3A 84 20        LD      A,(saucerActive)    ; Is saucer ..."
                //0460: A7              AND     A                    ; ... on screen?
beq !+
rts                //0461: C0              RET     NZ                   ; Yes ... don't reset it
!:                //;
                //; Setup saucer direction for next trip
lda   gamevars8080.shotCountLSB              //0462: 7E              LD      A,(HL)              ; Shot counter"
loadBC($0229)                //0463: E6 01           AND     $01                  ; Lowest bit set?
and #$01                //0465: 01 29 02        LD      BC,$0229            ; Xr delta of 2 starting at Xr=29"
bne !+                //0468: C2 6E 04        JP      NZ,$046E            ; Yes ... use 2/29"
loadBC($FEE0)                //046B: 01 E0 FE        LD      BC,$FEE0            ; No ... Xr delta of -2 starting at Xr=E0"
!:
loadHL(gamevars8080.saucerPriPicMSB)                //046E: 21 8A 20        LD      HL,$208A            ; Saucer descriptor"
lda BC
sta (HL)                //0471: 71              LD      (HL),C              ; Store Xr coordinate"
inc HL                //0472: 23              INC     HL                   ; Point to ...
inc HL                //0473: 23              INC     HL                   ; ... delta Xr
lda BC+1
sta (HL)                //0474: 70              LD      (HL),B              ; Store delta Xr"
rts                //0475: C9              RET                          ; Done
                //
                //
GameObj2:                //GameObj2:
//break()                //; Game object 2: Alien rolling-shot (targets player specifically)
//lda #$02                //;
// pla
// pla
//rts                //; The 2-byte value at 2038 is where the firing-column-table-pointer would be (see other
                //; shots ... next game objects). This shot doesn't use that table. It targets the player
                //; specifically. Instead the value is used as a flag to have the shot skip its first
                //; attempt at firing every time it is reinitialized (when it blows up).
                //;
                //; The task-timer at 2032 is copied to 2080 in the game loop. The flag is used as a
                //; synchronization flag to keep all the shots processed on separate interrupt ticks. This
                //; has the main effect of slowing the shots down.
                //;
                //; When the timer is 2 the squiggly-shot/saucer (object 4 ) runs.
                //; When the timer is 1 the plunger-shot (object 3) runs.
                //; When the timer is 0 this object, the rolling-shot, runs."
                //;
pla                //0476: E1              POP     HL                   ; Game object data
pla
lda InitializationDATA+$32                //0477: 3A 32 1B        LD      A,($1B32)           ; Restore delay from ..."
sta gamevars8080.obj2TimerExtra                //047A: 32 32 20        LD      (obj2TimerExtra),A  ; ... ROM mirror (value 2)"
lda gamevars8080.rolShotCFirLSB                //047D: 2A 38 20        LD      HL,(rolShotCFirLSB) ; Get pointer to ..."
sta HL
lda gamevars8080.rolShotCFirMSB
sta HL+1
ora HL                //0480: 7D              LD      A,L                  ; ... column-firing table."
                //0481: B4              OR      H                    ; All zeros?
bne GameObj2Fire                //0482: C2 8A 04        JP      NZ,$048A            ; No ... must be a valid column. Go fire."
dec HL                //0485: 2B              DEC     HL                   ; Decrement the counter
lda HL                //0486: 22 38 20        LD      (rolShotCFirLSB),HL ; Store new counter value (run the shot next time)"
sta gamevars8080.rolShotCFirLSB
lda HL+1
sta gamevars8080.rolShotCFirMSB
rts                //0489: C9              RET                          ; And out
                //
GameObj2Fire:
lda #<gamevars8080.rolShotStatus                //048A: 11 35 20        LD      DE,$2035            ; Rolling-shot data structure"
sta DE
lda #>gamevars8080.rolShotStatus
sta DE+1

lda #$f9                //048D: 3E F9           LD      A,$F9                ; Last picture of ""rolling" alien shot"
jsr ToShotStruct                //048F: CD 50 05        CALL    ToShotStruct        ; Set code to handle rolling-shot
lda gamevars8080.pluShotStepCnt                //0492: 3A 46 20        LD      A,(pluShotStepCnt)  ; Get the plunger-shot step count"
sta gamevars8080.otherShot1                //0495: 32 70 20        LD      (otherShot1),A      ; Hold it"
lda gamevars8080.squShotStepCnt                //0498: 3A 56 20        LD      A,(squShotStepCnt)  ; Get the squiggly-shot step count"
sta gamevars8080.otherShot2                //049B: 32 71 20        LD      (otherShot2),A      ; Hold it"
jsr HandleAlienShot                //049E: CD 63 05        CALL    HandleAlienShot     ; Handle active shot structure
                //04A1: 3A 78 20        LD      A,(aShotBlowCnt)    ; Blow up counter"
                //04A4: A7              AND     A                    ; Test if shot has cycled through blowing up
loadHL(gamevars8080.rolShotStatus)                //04A5: 21 35 20        LD      HL,$2035            ; Rolling-shot data structure"
lda gamevars8080.aShotBlowCnt
beq ResetShot                //04A8: C2 5B 05        JP      NZ,FromShotStruct   ; If shot is still running, copy the updated data and out"
jmp FromShotStruct          //
ResetShot:                //ResetShot:
                //; The rolling-shot has blown up. Reset the data structure.
loadDE(gameobj2Ptr)                //04AB: 11 30 1B        LD      DE,$1B30            ; Reload ..."
loadHL(gamevars8080.obj2TimerMSB)                //04AE: 21 30 20        LD      HL,$2030            ; ... object ..."
loadBC($1000)                //04B1: 06 10           LD      B,$10                ; ... structure ..."
jmp BlockCopy                //04B3: C3 32 1A        JP      BlockCopy           ; ... from ROM mirror and out
                //
                //
GameObj3:                //GameObj3:
//break()                //; Game object 3: Alien plunger-shot
lda #$03                //; This is skipped if there is only one alien left on the screen.
pla
pla
rts                //;
                //04B6: E1              POP     HL                   ; Game object data
                //04B7: 3A 6E 20        LD      A,(skipPlunger)     ; One alien left? Skip plunger shot?"
                //04BA: A7              AND     A                    ; Check
                //04BB: C0              RET     NZ                   ; Yes. Only one alien. Skip this shot.
                //04BC: 3A 80 20        LD      A,(shotSync)        ; Sync flag (copied from GO-2's timer value)"
                //04BF: FE 01           CP      $01                  ; GO-2 and GO-4 are idle?
                //04C1: C0              RET     NZ                   ; No ... only one shot at a time
                //
                //04C2: 11 45 20        LD      DE,$2045            ; Plunger alien shot data structure"
                //04C5: 3E ED           LD      A,$ED                ; Last picture of ""plunger" alien shot"
                //04C7: CD 50 05        CALL    ToShotStruct        ; Copy the plunger alien to the active structure
                //04CA: 3A 36 20        LD      A,(rolShotStepCnt)  ; Step count from rolling-shot"
                //04CD: 32 70 20        LD      (otherShot1),A      ; Hold it"
                //04D0: 3A 56 20        LD      A,(squShotStepCnt)  ; Step count from squiggly shot"
                //04D3: 32 71 20        LD      (otherShot2),A      ; Hold it"
                //04D6: CD 63 05        CALL    HandleAlienShot     ; Handle active shot structure
                //04D9: 3A 76 20        LD      A,(aShotCFirLSB)    ; LSB of column-firing table"
                //04DC: FE 10           CP      $10                  ; Been through all entries in the table?
                //04DE: DA E7 04        JP      C,$04E7             ; Not yet ... table is OK"
                //04E1: 3A 48 1B        LD      A,($1B48)           ; Been through all .."
                //04E4: 32 76 20        LD      (aShotCFirLSB),A    ; ... so reset pointer into firing-column table"
                //04E7: 3A 78 20        LD      A,(aShotBlowCnt)    ; Get the blow up timer"
                //04EA: A7              AND     A                    ; Zero means shot is done
                //04EB: 21 45 20        LD      HL,$2045            ; Plunger shot data"
                //04EE: C2 5B 05        JP      NZ,FromShotStruct   ; If shot is still running, go copy the updated data and out"
                //;
                //04F1: 11 40 1B        LD      DE,$1B40            ; Reload ..."
                //04F4: 21 40 20        LD      HL,$2040            ; ... object ..."
                //04F7: 06 10           LD      B,$10                ; ... structure ..."
                //04F9: CD 32 1A        CALL    BlockCopy           ; ... from mirror
                //;
                //04FC: 3A 82 20        LD      A,(numAliens)       ; Number of aliens on screen"
                //04FF: 3D              DEC     A                    ; Is there only one left?
                //0500: C2 08 05        JP      NZ,$0508            ; No ... move on"
                //0503: 3E 01           LD      A,$01                ; Disable plunger shot ..."
                //0505: 32 6E 20        LD      (skipPlunger),A     ; ... when only one alien remains"
                //0508: 2A 76 20        LD      HL,(aShotCFirLSB)   ; Set the plunger shot's ..."
jmp updateAlienShotPtr                //050B: C3 7E 06        JP      $067E                ; ... column-firing pointer data
                //
                //; Game task 4 when splash screen alien is shooting extra ""C" with a squiggly shot"
gameTask4Alienshoot:
pla                //050E: E1              POP     HL                   ; Ignore the task data pointer passed on stack
pla                //;
squigglyShot:                //; GameObject 4 comes here if processing a squiggly shot
loadDE(gamevars8080.squShotStatus)                //050F: 11 55 20        LD      DE,$2055            ; Squiggly shot data structure"
lda #$DB        // sprite squiggly?        //0512: 3E DB           LD      A,$DB                ; LSB of last byte of picture"
jsr ToShotStruct                //0514: CD 50 05        CALL    ToShotStruct        ; Copy squiggly shot to
lda gamevars8080.pluShotStepCnt                //0517: 3A 46 20        LD      A,(pluShotStepCnt)  ; Get plunger ..."
sta gamevars8080.otherShot1                //051A: 32 70 20        LD      (otherShot1),A      ; ... step count"
lda gamevars8080.rolShotStepCnt                //051D: 3A 36 20        LD      A,(rolShotStepCnt)  ; Get rolling ..."
sta gamevars8080.otherShot2                //0520: 32 71 20        LD      (otherShot2),A      ; ... step count"
jsr HandleAlienShot                //0523: CD 63 05        CALL    HandleAlienShot     ; Handle active shot structure
lda gamevars8080.aShotCFirLSB                //0526: 3A 76 20        LD      A,(aShotCFirLSB)    ; LSB of column-firing table pointer"
cmp #$15                //0529: FE 15           CP      $15                  ; Have we processed all entries?
bcs !noReset+             //052B: DA 34 05        JP      C,$0534             ; No ... don't reset it"
lda gameobj4Ptr+8                //052E: 3A 58 1B        LD      A,($1B58)           ; Reset the pointer ..."
sta gamevars8080.aShotCFirLSB                //0531: 32 76 20        LD      (aShotCFirLSB),A    ; ... back to the start of the table"
!noReset:
                //0534: 3A 78 20        LD      A,(aShotBlowCnt)    ; Check to see if squiggly shot is done"
                //0537: A7              AND     A                    ; 0 means blow-up timer expired
loadHL(gamevars8080.squShotStatus)                //0538: 21 55 20        LD      HL,$2055            ; Squiggly shot data structure"
lda gamevars8080.aShotBlowCnt
bne FromShotStruct                //053B: C2 5B 05        JP      NZ,FromShotStruct   ; If shot is still running, go copy the updated data and out"
                //
                //; Shot explosion is over. Remove the shot.
loadDE(gameobj4Ptr)                //053E: 11 50 1B        LD      DE,$1B50            ; Reload"
loadHL(gamevars8080.obj4TimerMSB)                //0541: 21 50 20        LD      HL,$2050            ; ... object ..."
loadBC($1000)                //0544: 06 10           LD      B,$10                ; ... structure ..."
jsr BlockCopy                //0546: CD 32 1A        CALL    BlockCopy           ; ... from mirror
lda gamevars8080.aShotCFirLSB                //0549: 2A 76 20        LD      HL,(aShotCFirLSB)   ; Copy pointer to column-firing table ..."
sta gamevars8080.squShotCFirLSB
lda gamevars8080.aShotCFirMSB
sta gamevars8080.squShotCFirMSB                //054C: 22 58 20        LD      (squShotCFirLSB),HL ; ... back to data structure (for next shot)"
rts                //054F: C9              RET                          ; Done
                //
ToShotStruct:                //ToShotStruct:
sta gamevars8080.shotPicEnd                //0550: 32 7F 20        LD      (shotPicEnd),A      ; LSB of last byte of last picture in sprite"
loadHL(gamevars8080.aShotStatus)                //0553: 21 73 20        LD      HL,$2073            ; Destination is the shot-structure"
loadBC($0b00)                //0556: 06 0B           LD      B,$0B                ; 11 bytes"
jmp BlockCopy                //0558: C3 32 1A        JP      BlockCopy           ; Block copy and out
                //
FromShotStruct:                //FromShotStruct:
loadDE(gamevars8080.aShotStatus)                //055B: 11 73 20        LD      DE,$2073            ; Source is the shot-structure"
loadBC($0b00)                //055E: 06 0B           LD      B,$0B                ; 11 bytes"
jmp BlockCopy                //0560: C3 32 1A        JP      BlockCopy           ; Block copy and out
                //
HandleAlienShot:                //HandleAlienShot:
                //; Each of the 3 shots copy their data to the 2073 structure (0B bytes) and call this.
                //; Then they copy back if the shot is still active. Otherwise they copy from the mirror.
                //;
                //; The alien ""fire rate" is based on the number of steps the other two shots on the screen"
                //; have made. The smallest number-of-steps is compared to the reload-rate. If it is too
                //; soon then no shot is made. The reload-rate is based on the player's score. The MSB
                //; is looked up in a table to get the reload-rate. The smaller the rate the faster the
                //; aliens fire. Setting rate this way keeps shots from walking on each other.
                //;
loadHL(gamevars8080.aShotStatus)                //0563: 21 73 20        LD      HL,$2073            ; Start of active shot structure"
lda HL                //0566: 7E              LD      A,(HL)              ; Get the shot status"
//and #$80                //0567: E6 80           AND     $80                  ; Is the shot active?
bpl !+
jmp MoveAlienShot                //0569: C2 C1 05        JP      NZ,$05C1            ; Yes ... go move it"
!:                //
lda gamevars8080.isrSplashTask                //056C: 3A C1 20        LD      A,(isrSplashTask)   ; ISR splash task"
cmp #$04                //056F: FE 04           CP      $04                  ; Shooting the ""C" ?"
php
lda gamevars8080.enableAlienFire                //0571: 3A 69 20        LD      A,(enableAlienFire) ; Alien fire enabled flag"
plp
beq MarkShotActive                //0574: CA B7 05        JP      Z,$05B7             ; We are shooting the extra ""C" ... just flag it active and out"
and #$00                //0577: A7              AND     A                    ; Is alien fire enabled?
bne !+                //0578: C8              RET     Z                    ; No ... don't start a new shot
rts
!:
                //
inc HL                //0579: 23              INC     HL                   ; 2074 step count of current shot
stz HL                //057A: 36 00           LD      (HL),$00            ; clear the step count"
                //
                //; Make sure it isn't too soon to fire another shot
lda gamevars8080.otherShot1               //057C: 3A 70 20        LD      A,(otherShot1)      ; Get the step count of the 1st ""other shot"""
                //057F: A7              AND     A                    ; Any steps made?
beq ignoreThisCount                //0580: CA 89 05        JP      Z,$0589             ; No ... ignore this count"
sta BC+1                //0583: 47              LD      B,A                  ; Shuffle off step count"
lda gamevars8080.aShotReloadRate                //0584: 3A CF 20        LD      A,(aShotReloadRate) ; Get the reload rate (based on MSB of score)"
cmp BC+1                //0587: B8              CP      B                    ; Too soon to fire again?
bcs ignoreThisCount
rts                //0588: D0              RET     NC                   ; Yes ... don't fire
ignoreThisCount:
lda gamevars8080.otherShot2                //0589: 3A 71 20        LD      A,(otherShot2)      ; Get the step count of the 2nd ""other shot"""
                //058C: A7              AND     A                    ; Any steps made?
beq clearToFire                //058D: CA 96 05        JP      Z,$0596             ; No steps on any shot ... we are clear to fire"
sta BC+1                //0590: 47              LD      B,A                  ; Shuffle off step count"
lda gamevars8080.aShotReloadRate                //0591: 3A CF 20        LD      A,(aShotReloadRate) ; Get the reload rate (based on MSB of score)"
cmp BC+1                //0594: B8              CP      B                    ; Too soon to fire again?
bcs clearToFire
rts                //0595: D0              RET     NC                   ; Yes ... don't fire
clearToFire:
inc HL                //0596: 23              INC     HL                   ; 2075
lda HL                //0597: 7E              LD      A,(HL)              ; Get tracking flag"
                //0598: A7              AND     A                    ; Does this shot track the player?
bne !+
jmp makeTrackingShot                //0599: CA 1B 06        JP      Z,$061B             ; Yes ... go make a tracking shot;"
!:
loadHL(gamevars8080.aShotCFirLSB)                //059C: 2A 76 20        LD      HL,(aShotCFirLSB)   ; Column-firing table"
lda HL                //059F: 4E              LD      C,(HL)              ; Get next column to fire from"
sta BC
inc HL                //05A0: 23              INC     HL                   ; Bump the ...
                //05A1: 00              NOP                          ; % WHY?
lda HL
sta gamevars8080.aShotCFirLSB                //05A2: 22 76 20        LD      (aShotCFirLSB),HL   ; ... pointer into column table"
lda HL+1
sta gamevars8080.aShotCFirMSB
jsr FindInColumn                //05A5: CD 2F 06        CALL    FindInColumn        ; Find alien in target column
bcs !+
rts                //05A8: D0              RET     NC                   ; No alien is alive in target column ... out
!:                //;
jsr GetAlienCoords                //05A9: CD 7A 01        CALL    GetAlienCoords      ; Get coordinates of alien (lowest alien in firing column)
lda BC                //05AC: 79              LD      A,C                  ; Offset ..."
clc
adc #$07                //05AD: C6 07           ADD     A,$07                ; ... Y by 7"
sta HL+1                //05AF: 67              LD      H,A                  ; To H"
lda HL                //05B0: 7D              LD      A,L                  ; Offset ..."
sec
sbc #$0a                //05B1: D6 0A           SUB     $0A                  ; ... X down 10
sta HL                //05B3: 6F              LD      L,A                  ; To L"
sta gamevars8080.alienShotYr                //05B4: 22 7B 20        LD      (alienShotYr),HL    ; Set shot coordinates below alien"
lda HL+1
sta gamevars8080.alienShotXr
                //;
MarkShotActive:
loadHL(gamevars8080.aShotStatus)                //05B7: 21 73 20        LD      HL,$2073            ; Alien shot status"
lda HL                //05BA: 7E              LD      A,(HL)              ; Get the status"
ora #$80                //05BB: F6 80           OR      $80                  ; Mark this shot ...
sta HL                //05BD: 77              LD      (HL),A              ; ... as actively running"
inc HL                //05BE: 23              INC     HL                   ; 2074 step count
lda HL
inc                 //05BF: 34              INC     (HL)                 ; Give this shot 1 step (it just started)
sta HL
rts                //05C0: C9              RET                          ; Out
                //;
MoveAlienShot:                //; Move the alien shot
loadDE(gamevars8080.alienShotXr)                //05C1: 11 7C 20        LD      DE,$207C            ; Alien-shot Y coordinate"
jsr CompYToBeam                //05C4: CD 06 1A        CALL    CompYToBeam         ; Compare to beam position
bcs !+
rts                //05C7: D0              RET     NC                   ; Not the right ISR for this shot
!:                //;
inc HL                //05C8: 23              INC     HL                   ; 2073 status
lda HL                //05C9: 7E              LD      A,(HL)              ; Get shot status"
and #$01                //05CA: E6 01           AND     $01                  ; Bit 0 is 1 if blowing up
bne ShotBlowingUp                //05CC: C2 44 06        JP      NZ,ShotBlowingUp    ; Go do shot-is-blowing-up sequence"
inc HL                //05CF: 23              INC     HL                   ; 2074 step count
lda HL
inc
sta HL                //05D0: 34              INC     (HL)                 ; Count the steps (used for fire rate)
jsr eraseShot                //05D1: CD 75 06        CALL    $0675                ; Erase shot
lda gamevars8080.aShotImageLSB                //05D4: 3A 79 20        LD      A,(aShotImageLSB)   ; Get LSB of the image pointer"
clc
adc #$03                //05D7: C6 03           ADD     A,$03                ; Next set of images"
loadHL(gamevars8080.shotPicEnd)               //05D9: 21 7F 20        LD      HL,$207F            ; End of image"
cmp HL                //05DC: BE              CP      (HL)                 ; Have we reached the end of the set?
bcs !skip+                //05DD: DA E2 05        JP      C,$05E2             ; No ... keep it"
sec
sbc #$0c                //05E0: D6 0C           SUB     $0C                  ; Back up to the 1st image in the set
!skip:
sta gamevars8080.aShotImageLSB                //05E2: 32 79 20        LD      (aShotImageLSB),A   ; New LSB image pointer"
lda gamevars8080.alienShotYr                //05E5: 3A 7B 20        LD      A,(alienShotYr)     ; Get shot's Y coordinate"
sta BC+1                //05E8: 47              LD      B,A                  ; Hold it"
lda gamevars8080.alienShotDelta                //05E9: 3A 7E 20        LD      A,(alienShotDelta)  ; Get alien shot delta"
clc
adc BC+1                //05EC: 80              ADD     A,B                  ; Add to shots coordinate"
sta gamevars8080.alienShotYr                //05ED: 32 7B 20        LD      (alienShotYr),A     ; New shot Y coordinate"
jsr drawAlienShot                //05F0: CD 6C 06        CALL    $066C                ; Draw the alien shot
                //05F3: 3A 7B 20        LD      A,(alienShotYr)     ; Shot's Y coordinate"
                //05F6: FE 15           CP      $15                  ; Still in the active playfield?
                //05F8: DA 12 06        JP      C,$0612             ; No ... end it"
                //05FB: 3A 61 20        LD      A,(collision)       ; Did shot collide ..."
                //05FE: A7              AND     A                    ; ... with something?
                //05FF: C8              RET     Z                    ; No ... we are done here
                //0600: 3A 7B 20        LD      A,(alienShotYr)     ; Shot's Y coordinate"
                //0603: FE 1E           CP      $1E                  ; Is it below player's area?
                //0605: DA 12 06        JP      C,$0612             ; Yes ... end it"
                //0608: FE 27           CP      $27                  ; Is it above player's area?
                //060A: 00              NOP                          ; ** WHY?
                //060B: D2 12 06        JP      NC,$0612            ; Yes ... end it"
                //060E: 97              SUB     A                    ; Flag that player ...
                //060F: 32 15 20        LD      (playerAlive),A     ; ... has been struck"
                //;
                //0612: 3A 73 20        LD      A,(aShotStatus)     ; Flag to ..."
                //0615: F6 01           OR      $01                  ; ... start shot ...
                //0617: 32 73 20        LD      (aShotStatus),A     ; ... blowing up"
break()                //061A: C9              RET                          ; Out
                //;
                //; Start a shot right over the player
makeTrackingShot:
                //061B: 3A 1B 20        LD      A,(playerXr)        ; Player's X coordinate"
                //061E: C6 08           ADD     A,$08                ; Center of player"
                //0620: 67              LD      H,A                  ; To H for routine"
                //0621: CD 6F 15        CALL    FindColumn          ; Find the column
                //0624: 79              LD      A,C                  ; Get the column right over player"
                //0625: FE 0C           CP      $0C                  ; Is it a valid column?
                //0627: DA A5 05        JP      C,$05A5             ; Yes ... use what we found"
                //062A: 0E 0B           LD      C,$0B                ; Else use ..."
                //062C: C3 A5 05        JP      $05A5                ; ... as far over as we can
                //
FindInColumn:                //FindInColumn:
                //; C contains the target column. Look for a live alien in the column starting with
                //; the lowest position. Return C=1 if found ... HL points to found slot.
dec BC                //062F: 0D              DEC     C                    ; Column that is firing
lda gamevars8080.playerDataMSB                //0630: 3A 67 20        LD      A,(playerDataMSB)   ; Player's MSB (21xx or 22xx)"
sta HL+1                //0633: 67              LD      H,A                  ; To MSB of HL"
lda BC
sta HL                //0634: 69              LD      L,C                  ; Column to L"
loadDE($0500)                //0635: 16 05           LD      D,$05                ; 5 rows of aliens"
keepLooking:
lda HL                //0637: 7E              LD      A,(HL)              ; Get alien's status"
                    //0638: A7              AND     A                    ; 0 means dead
sec                //0639: 37              SCF                          ; In case not 0
beq !+
rts                //063A: C0              RET     NZ                   ; Alien is alive? Yes ... return
!:
lda HL                //063B: 7D              LD      A,L                  ; Get the flag pointer LSB"
clc
adc #$0b                //063C: C6 0B           ADD     A,$0B                ; Jump to same column on next row of rack (+11 aliens per row)"
sta HL                //063E: 6F              LD      L,A                  ; New alien index"
dec DE+1                //063F: 15              DEC     D                    ; Tested all rows?
bne keepLooking                //0640: C2 37 06        JP      NZ,$0637            ; No ... keep looking for a live alien up the rack"
clc
rts                //0643: C9              RET                          ; Didn't find a live alien. Return with C=0.
                //
ShotBlowingUp:                //ShotBlowingUp:
                //; Alien shot is blowing up
                //0644: 21 78 20        LD      HL,$2078            ; Blow up timer"
                //0647: 35              DEC     (HL)                 ; Decrement the value
                //0648: 7E              LD      A,(HL)              ; Get the value"
                //0649: FE 03           CP      $03                  ; First tick, 4, we draw the explosion"
                //064B: C2 67 06        JP      NZ,$0667            ; After that just wait"
                //064E: CD 75 06        CALL    $0675                ; Erase the shot
                //0651: 21 DC 1C        LD      HL,$1CDC            ; Alien shot ..."
                //0654: 22 79 20        LD      (aShotImageLSB),HL  ; ... explosion sprite"
                //0657: 21 7C 20        LD      HL,$207C            ; Alien shot Y"
                //065A: 35              DEC     (HL)                 ; Left two for ...
                //065B: 35              DEC     (HL)                 ; ... explosion
                //065C: 2B              DEC     HL                   ; Point slien shot X
                //065D: 35              DEC     (HL)                 ; Up two for ...
                //065E: 35              DEC     (HL)                 ; ... explosion
                //065F: 3E 06           LD      A,$06                ; Alien shot descriptor ..."
                //0661: 32 7D 20        LD      (alienShotSize),A   ; ... size 6"
                //0664: C3 6C 06        JP      $066C                ; Draw alien shot explosion
                //
                //0667: A7              AND     A                    ; Have we reached 0?
                //0668: C0              RET     NZ                   ; No ... keep waiting
break()                //0669: C3 75 06        JP      $0675                ; Erase the explosion and out
                //;
drawAlienShot:
loadHL(gamevars8080.aShotImageLSB)                //066C: 21 79 20        LD      HL,$2079            ; Alien shot descriptor"
jsr ReadDesc                //066F: CD 3B 1A        CALL    ReadDesc            ; Read 5 byte structure
jmp DrawPlayerShot  // alien shot fix???                //0672: C3 91 14        JP      DrawSprCollision    ; Draw shot and out
                //;
eraseShot:
loadHL(gamevars8080.aShotImageLSB)                //0675: 21 79 20        LD      HL,$2079            ; Alien shot descriptor"
jsr ReadDesc                //0678: CD 3B 1A        CALL    ReadDesc            ; Read 5 byte structure
jmp EraseShifted                //067B: C3 52 14        JP      EraseShifted        ; Erase the shot and out
                //
updateAlienShotPtr:
lda HL
sta gamevars8080.pluShotCFirLSB                //067E: 22 48 20        LD      (pluShotCFirLSB),HL ; From 50B, update ..."
lda HL+1
sta gamevars8080.pluShotCFirMSB
rts                //0681: C9              RET                          ; ... column-firing table pointer and out
                //
 //endmoveshot                //       
                //
GameObj4:                //GameObj4:
//break()                //; Game object 4: Flying Saucer OR squiggly shot
lda #$04                //;
pla
pla
rts                //; This task is shared by the squiggly-shot and the flying saucer. The saucer waits until the
                //; squiggly-shot is over before it begins.
                //;
                //0682: E1              POP     HL                   ; Pull data pointer from the stack (not going to use it)
                //0683: 3A 80 20        LD      A,(shotSync)        ; Sync flag (copied from GO-2's timer value)"
                //0686: FE 02           CP      $02                  ; Are GO-2 and GO-3 idle?
                //0688: C0              RET     NZ                   ; No ... only one at a time
                //0689: 21 83 20        LD      HL,$2083            ; Time-till-saucer flag"
                //068C: 7E              LD      A,(HL)              ; Is it time ..."
                //068D: A7              AND     A                    ; ... for a saucer?
bne !+          //068E: CA 0F 05        JP      Z,$050F             ; No ... go process squiggly shot"
jmp squigglyShot            
!:
break()                //0691: 3A 56 20        LD      A,(squShotStepCnt)  ; Is there a ..."
lda #4                //0694: A7              AND     A                    ; ... squiggly shot going?
                //0695: C2 0F 05        JP      NZ,$050F            ; Yes ... go handle squiggly shot"
                //
                //0698: 23              INC     HL                   ; Saucer on screen flag
                //0699: 7E              LD      A,(HL)              ; (2084) Is the saucer ..."
                //069A: A7              AND     A                    ; ... already on the screen?
                //069B: C2 AB 06        JP      NZ,$06AB            ; Yes ... go handle it"
                //069E: 3A 82 20        LD      A,(numAliens)       ; Number of aliens remaining"
                //06A1: FE 08           CP      $08                  ; Less than ...
                //06A3: DA 0F 05        JP      C,$050F             ; ... 8 ... no saucer"
                //06A6: 36 01           LD      (HL),$01            ; (2084) The saucer is on the screen"
                //06A8: CD 3C 07        CALL    $073C                ; Draw the flying saucer
                //
                //06AB: 11 8A 20        LD      DE,$208A            ; Saucer's Y coordinate"
                //06AE: CD 06 1A        CALL    CompYToBeam         ; Compare to beam position
                //06B1: D0              RET     NC                   ; Not the right ISR for moving saucer
                //
                //06B2: 21 85 20        LD      HL,$2085            ; Saucer hit flag"
                //06B5: 7E              LD      A,(HL)              ; Has saucer ..."
                //06B6: A7              AND     A                    ; ... been hit?
                //06B7: C2 D6 06        JP      NZ,$06D6            ; Yes ... don't move it"
                //
                //06BA: 21 8A 20        LD      HL,$208A            ; Saucer's structure"
                //06BD: 7E              LD      A,(HL)              ; Get saucer's Y coordinate"
                //06BE: 23              INC     HL                   ; Bump to ...
                //06BF: 23              INC     HL                   ; ... delta Y
                //06C0: 86              ADD     A,(HL)              ; Move saucer"
                //06C1: 32 8A 20        LD      (saucerPriPicMSB),A ; New coordinate"
                //06C4: CD 3C 07        CALL    $073C                ; Draw the flying saucer
                //06C7: 21 8A 20        LD      HL,$208A            ; Saucer's structure"
                //06CA: 7E              LD      A,(HL)              ; Y coordinate"
                //06CB: FE 28           CP      $28                  ; Too low? End of screen?
                //06CD: DA F9 06        JP      C,$06F9             ; Yes ... remove from play"
                //06D0: FE E1           CP      $E1                  ; Too high? End of screen?
                //06D2: D2 F9 06        JP      NC,$06F9            ; Yes ... remove from play"
                //06D5: C9              RET                          ; Done
                //
                //06D6: 06 FE           LD      B,$FE                ; Turn off ..."
                //06D8: CD DC 19        CALL    SoundBits3Off       ; ... flying saucer sound
                //06DB: 23              INC     HL                   ; (2086) show-hit timer
                //06DC: 35              DEC     (HL)                 ; Count down show-hit timer
                //06DD: 7E              LD      A,(HL)              ; Get current value"
                //06DE: FE 1F           CP      $1F                  ; Starts at 20 ... is this the first tick of show-hit timer?
                //06E0: CA 4B 07        JP      Z,$074B             ; Yes ... go show the explosion"
                //06E3: FE 18           CP      $18                  ; A little later ...
                //06E5: CA 0C 07        JP      Z,$070C             ; ... show the score besides the saucer and add it"
                //06E8: A7              AND     A                    ; Has timer expired?
                //06E9: C0              RET     NZ                   ; No ... let it run
                //06EA: 06 EF           LD      B,$EF                ; 1110_1111 (mask off saucer hit sound)"
                //06EC: 21 98 20        LD      HL,$2098            ; Get current ..."
                //06EF: 7E              LD      A,(HL)              ; ... value of port 5 sound"
                //06F0: A0              AND     B                    ; Mask off the saucer-hit sound
                //06F1: 77              LD      (HL),A              ; Set the new value"
                //06F2: E6 20           AND     $20                  ; All sound off but ...
                //06F4: D3 05           OUT     (SOUND2),A          ; ... cocktail cabinet bit"
                //06F6: 00              NOP                          ; ** Why
                //06F7: 00              NOP                          ; **
                //06F8: 00              NOP                          ; **
                //;
                //06F9: CD 42 07        CALL    $0742                ; Covert pixel pos from descriptor to HL screen and shift
                //06FC: CD CB 14        CALL    ClearSmallSprite    ; Clear a one byte sprite at HL
                //06FF: 21 83 20        LD      HL,$2083            ; Saucer structure"
                //0702: 06 0A           LD      B,$0A                ; 10 bytes in saucer structure"
                //0704: CD 5F 07        CALL    $075F                ; Re-initialize saucer structure
                //
                //0707: 06 FE           LD      B,$FE                ; Turn off UFO ..."
                //0709: C3 DC 19        JP      SoundBits3Off       ; ... sound and out
                //
                //070C: 3E 01           LD      A,$01                ; Flag the score ..."
                //070E: 32 F1 20        LD      (adjustScore),A     ; ... needs updating"
                //0711: 2A 8D 20        LD      HL,(sauScoreLSB)    ; Saucer score table"
                //0714: 46              LD      B,(HL)              ; Get score for this saucer"
                //0715: 0E 04           LD      C,$04                ; There are only 4 possibilities"
                //0717: 21 50 1D        LD      HL,$1D50            ; Possible scores table"
                //071A: 11 4C 1D        LD      DE,$1D4C            ; Print strings for each score"
                //071D: 1A              LD      A,(DE)              ; Find ..."
                //071E: B8              CP      B                    ; ... the ...
                //071F: CA 28 07        JP      Z,$0728             ; ... print ..."
                //0722: 23              INC     HL                   ; ... string ...
                //0723: 13              INC     DE                   ; ... for ...
                //0724: 0D              DEC     C                    ; ... the ...
                //0725: C2 1D 07        JP      NZ,$071D            ; ... score"
                //0728: 7E              LD      A,(HL)              ; Get LSB of message (MSB is 2088 which is 1D)"
                //0729: 32 87 20        LD      (saucerPriLocLSB),A ; Message's LSB (_50=1D94 100=1D97 150=1D9A 300=1D9D)"
                //072C: 26 00           LD      H,$00                ; MSB = 0 ..."
                //072E: 68              LD      L,B                  ; HL = B"
                //072F: 29              ADD     HL,HL                ; *2"
                //0730: 29              ADD     HL,HL                ; *4"
                //0731: 29              ADD     HL,HL                ; *8"
                //0732: 29              ADD     HL,HL                ; *16"
                //0733: 22 F2 20        LD      (scoreDeltaLSB),HL  ; Add score for hitting saucer (015 becomes 150 in BCD)."
                //0736: CD 42 07        CALL    $0742                ; Get the flying saucer score descriptor
                //0739: C3 F1 08        JP      $08F1                ; Print the three-byte score and out
                //
                //073C: CD 42 07        CALL    $0742                ; Draw the ...
                //073F: C3 39 14        JP      DrawSimpSprite      ; ... flying saucer
                //
                //0742: 21 87 20        LD      HL,$2087            ; Read flying saucer ..."
                //0745: CD 3B 1A        CALL    ReadDesc            ; ... structure
                //0748: C3 47 1A        JP      ConvToScr           ; Convert pixel number to screen and shift and out
                //;
                //074B: 06 10           LD      B,$10                ; Saucer hit sound bit"
                //074D: 21 98 20        LD      HL,$2098            ; Current state of sounds"
                //0750: 7E              LD      A,(HL)              ; OR ..."
                //0751: B0              OR      B                    ; ... in ...
                //0752: 77              LD      (HL),A              ; ... saucer-hit sound"
                //0753: CD 70 17        CALL    $1770                ; Turn off fleet sound and start saucer-hit
                //0756: 21 7C 1D        LD      HL,$1D7C            ; Sprite for saucer blowing up"
                //0759: 22 87 20        LD      (saucerPriLocLSB),HL; Store it in structure"
                //075C: C3 3C 07        JP      $073C                ; Draw the flying saucer
                //;
                //075F: 11 83 1B        LD      DE,$1B83            ; Data for saucer (702 sets count to 0A)"
                //0762: C3 32 1A        JP      BlockCopy           ; Reset saucer object data
                //
                //
waitForStart:                //WaitForStart:
break()                //; Wait for player 1 start button press
lda #$fe                //0765: 3E 01           LD      A,$01                ; Tell ISR that we ..."
                //0767: 32 93 20        LD      (waitStartLoop),A   ; ... have started to wait"
                //076A: 31 00 24        LD      SP,$2400            ; Reset stack"
                //076D: FB              EI                           ; Enable interrupts
                //076E: CD 79 19        CALL    $1979                ; Suspend game tasks
                //0771: CD D6 09        CALL    ClearPlayField      ; Clear center window
                //0774: 21 13 30        LD      HL,$3013            ; Screen coordinates"
                //0777: 11 F3 1F        LD      DE,$1FF3            ; ""PRESS"""
                //077A: 0E 04           LD      C,$04                ; Message length"
                //077C: CD F3 08        CALL    PrintMessage        ; Print it
                //077F: 3A EB 20        LD      A,(numCoins)        ; Number of credits"
                //0782: 3D              DEC     A                    ; Set flags
                //0783: 21 10 28        LD      HL,$2810            ; Screen coordinates"
                //0786: 0E 14           LD      C,$14                ; Message length"
                //0788: C2 57 08        JP      NZ,$0857            ; Take 1 or 2 player start"
                //078B: 11 CF 1A        LD      DE,$1ACF            ; ""ONLY 1PLAYER BUTTON """
                //078E: CD F3 08        CALL    PrintMessage        ; Print message
                //0791: DB 01           IN      A,(INP1)            ; Read player controls"
                //0793: E6 04           AND     $04                  ; 1Player start button?
                //0795: CA 7F 07        JP      Z,$077F             ; No ... wait for button or credit"
                //Start New Game
                //NewGame:
                //; 1 Player start
                //0798: 06 99           LD      B,$99                ; Essentially a -1 for DAA"
                //079A: AF              XOR     A                    ; Clear two player flag
                //;
                //; 2 player start sequence enters here with a=1 and B=98 (-2)
                //079B: 32 CE 20        LD      (twoPlayers),A      ; Set flag for 1 or 2 players"
                //079E: 3A EB 20        LD      A,(numCoins)        ; Number of credits"
                //07A1: 80              ADD     A,B                  ; Take away credits"
                //07A2: 27              DAA                          ; Convert back to DAA
                //07A3: 32 EB 20        LD      (numCoins),A        ; New credit count"
                //07A6: CD 47 19        CALL    DrawNumCredits      ; Display number of credits
                //07A9: 21 00 00        LD      HL,$0000            ; Score of 0000"
                //07AC: 22 F8 20        LD      (P1ScorL),HL        ; Clear player-1 score"
                //07AF: 22 FC 20        LD      (P2ScorL),HL        ; Clear player-2 score"
                //07B2: CD 25 19        CALL    $1925                ; Print player-1 score
                //07B5: CD 2B 19        CALL    $192B                ; Print player-2 score
                //07B8: CD D7 19        CALL    DsableGameTasks     ; Disable game tasks
                //07BB: 21 01 01        LD      HL,$0101            ; Two bytes 1, 1"
                //07BE: 7C              LD      A,H                  ; 1 to A"
                //07BF: 32 EF 20        LD      (gameMode),A        ; 20EF=1 ... game mode"
                //07C2: 22 E7 20        LD      (player1Alive),HL   ; 20E7 and 20E8 both one ... players 1 and 2 are alive"
                //07C5: 22 E5 20        LD      (player1Ex),HL      ; Extra-ship is available for player-1 and player-2"
                //07C8: CD 56 19        CALL    DrawStatus          ; Print scores and credits
                //07CB: CD EF 01        CALL    DrawShieldPl1       ; Draw shields for player-1
                //07CE: CD F5 01        CALL    DrawShieldPl2       ; Draw shields for player-2
                //07D1: CD D1 08        CALL    GetShipsPerCred     ; Get number of ships from DIP settings
                //07D4: 32 FF 21        LD      (p1ShipsRem),A      ; Player-1 ships"
                //07D7: 32 FF 22        LD      (p2ShipsRem),A      ; Player-2 ships"
                //07DA: CD D7 00        CALL    $00D7                ; Set player-1 and player-2 alien racks going right
                //07DD: AF              XOR     A                    ; Make a 0
                //07DE: 32 FE 21        LD      (p1RackCnt),A       ; Player 1 is on first rack of aliens"
                //07E1: 32 FE 22        LD      (p2RackCnt),A       ; Player 2 is on first rack of aliens"
                //07E4: CD C0 01        CALL    InitAliens          ; Initialize 55 aliens for player 1
                //07E7: CD 04 19        CALL    InitAliensP2        ; Initialize 55 aliens for player 2
                //07EA: 21 78 38        LD      HL,$3878            ; Screen coordinates for lower-left alien"
                //07ED: 22 FC 21        LD      (p1RefAlienY),HL    ; Initialize reference alien for player 1"
                //07F0: 22 FC 22        LD      (p2RefAlienYr),HL   ; Initialize reference alien for player 2"
                //07F3: CD E4 01        CALL    CopyRAMMirror       ; Copy ROM mirror to RAM (2000 - 20C0)
                //07F6: CD 7F 1A        CALL    RemoveShip          ; Initialize ship hold indicator
                //;
                //07F9: CD 8D 08        CALL    PromptPlayer        ; Prompt with ""PLAY PLAYER """
                //07FC: CD D6 09        CALL    ClearPlayField      ; Clear the playfield
                //07FF: 00              NOP                          ; % Why?
                //0800: AF              XOR     A                    ; Make a 0
                //0801: 32 C1 20        LD      (isrSplashTask),A   ; Disable isr splash-task animation"
                //0804: CD CF 01        CALL    DrawBottomLine      ; Draw line across screen under player
                //0807: 3A 67 20        LD      A,(playerDataMSB)   ; Current player"
                //080A: 0F              RRCA                         ; Right bit tells all
                //080B: DA 72 08        JP      C,$0872             ; Go do player 1"
                //;
                //080E: CD 13 02        CALL    RestoreShields2     ; Restore shields for player 2
                //0811: CD CF 01        CALL    DrawBottomLine      ; Draw line across screen under player
                //0814: CD B1 00        CALL    InitRack            ; Initialize alien rack for current player
                //0817: CD D1 19        CALL    EnableGameTasks     ; Enable game tasks in ISR
                //081A: 06 20           LD      B,$20                ; Enable ..."
                //081C: CD FA 18        CALL    SoundBits3On        ; ... sound amplifier
                //;
                //; GAME LOOP
                //;
                //081F: CD 18 16        CALL    PlrFireOrDemo       ; Initiate player shot if button pressed
                //0822: CD 0A 19        CALL    PlyrShotAndBump     ; Collision detect player's shot and rack-bump
                //0825: CD F3 15        CALL    CountAliens         ; Count aliens (count to 2082)
                //0828: CD 88 09        CALL    AdjustScore         ; Adjust score (and print) if there is an adjustment
                //082B: 3A 82 20        LD      A,(numAliens)       ; Number of live aliens"
                //082E: A7              AND     A                    ; All aliens gone?
                //082F: CA EF 09        JP      Z,$09EF             ; Yes ... end of turn"
                //0832: CD 0E 17        CALL    AShotReloadRate     ; Update alien-shot-rate based on player's score
                //0835: CD 35 09        CALL    $0935                ; Check (and handle) extra ship award
                //0838: CD D8 08        CALL    SpeedShots          ; Adjust alien shot speed
                //083B: CD 2C 17        CALL    ShotSound           ; Shot sound on or off with 2025
                //083E: CD 59 0A        CALL    $0A59                ; Check if player is hit
                //0841: CA 49 08        JP      Z,$0849             ; No hit ... jump handler"
                //0844: 06 04           LD      B,$04                ; Player hit sound"
                //0846: CD FA 18        CALL    SoundBits3On        ; Make explosion sound
                //0849: CD 75 17        CALL    FleetDelayExShip    ; Extra-ship sound timer, set fleet-delay, play fleet movement sound"
                //084C: D3 06           OUT     (WATCHDOG),A        ; Feed the watchdog"
                //084E: CD 04 18        CALL    CtrlSaucerSound     ; Control saucer sound
                //0851: C3 1F 08        JP      $081F                ; Continue game loop
                //
                //0854: 00 00 00                                      ; ** Why?
                //
                //; Test for 1 or 2 player start button press
                //0857: 11 BA 1A        LD      DE,$1ABA            ; ""1 OR 2PLAYERS BUTTON"""
                //085A: CD F3 08        CALL    PrintMessage        ; Print message
                //085D: 06 98           LD      B,$98                ; -2 (take away 2 credits)"
                //085F: DB 01           IN      A,(INP1)            ; Read player controls"
                //0861: 0F              RRCA                         ; Test ...
                //0862: 0F              RRCA                         ; ... bit 2
                //0863: DA 6D 08        JP      C,$086D             ; 2 player button pressed ... do it"
                //0866: 0F              RRCA                         ; Test bit 3
                //0867: DA 98 07        JP      C,NewGame           ; One player start ... do it"
                //086A: C3 7F 07        JP      $077F                ; Keep waiting on credit or button
                //; 2 PLAYER START
                //086D: 3E 01           LD      A,$01                ; Flag 2 player game"
                //086F: C3 9B 07        JP      $079B                ; Continue normal startup
                //
                //0872: CD 1A 02        CALL    RestoreShields1     ; Restore shields for player 1
                //0875: C3 14 08        JP      $0814                ; Continue in game loop
                //
                //0878: 3A 08 20        LD      A,(refAlienDXr)     ; Alien deltaY"
                //087B: 47              LD      B,A                  ; Hold it"
                //087C: 2A 09 20        LD      HL,(refAlienYr)     ; Alien coordinates"
                //087F: EB              EX      DE,HL                ; Coordinates to DE"
                //0880: C3 86 08        JP      GetAlRefPtr         ; HL is 21FC or 22FC and out
                //            
                //0883: 00 00 00                                      ; ** Why?
                //
                //GetAlRefPtr:
                //; Get pointer to player's alien ref coordiantes
                //0886: 3A 67 20        LD      A,(playerDataMSB)   ; Player data MSB (21 or 22)"
                //0889: 67              LD      H,A                  ; To H"
                //088A: 2E FC           LD      L,$FC                ; 21FC or 22FC ... alien coordinates"
                //088C: C9              RET                          ; Done
                //
                //PromptPlayer:
                //; Print ""PLAY PLAYER <n>" and blink score for 2 seconds."
                //;
                //088D: 21 11 2B        LD      HL,$2B11            ; Screen coordinates"
                //0890: 11 70 1B        LD      DE,$1B70            ; Message ""PLAY PLAYER<1>"""
                //0893: 0E 0E           LD      C,$0E                ; 14 bytes in message"
                //0895: CD F3 08        CALL    PrintMessage        ; Print the message
                //0898: 3A 67 20        LD      A,(playerDataMSB)   ; Get the player number"
                //089B: 0F              RRCA                         ; C will be set for player 1
                //089C: 3E 1C           LD      A,$1C                ; The ""2" character"
                //089E: 21 11 37        LD      HL,$3711            ; Replace the ""<1>" with ""<2"">"
                //08A1: D4 FF 08        CALL    NC,DrawChar         ; If player 2 ... change the message"
                //08A4: 3E B0           LD      A,$B0                ; Delay of 176 (roughly 2 seconds)"
                //08A6: 32 C0 20        LD      (isrDelay),A        ; Set the ISR delay value"
                //;
                //08A9: 3A C0 20        LD      A,(isrDelay)        ; Get the ISR delay value"
                //08AC: A7              AND     A                    ; Has the 2 second delay expired?
                //08AD: C8              RET     Z                    ; Yes ... done
                //08AE: E6 04           AND     $04                  ; Every 4 ISRs ...
                //08B0: C2 BC 08        JP      NZ,$08BC            ; ... flash the player's score"
                //08B3: CD CA 09        CALL    $09CA                ; Get the score descriptor for the active player
                //08B6: CD 31 19        CALL    DrawScore           ; Draw the score
                //08B9: C3 A9 08        JP      $08A9                ; Back to the top of the wait loop
                //;
                //08BC: 06 20           LD      B,$20                ; 32 rows (4 characters * 8 bytes each)"
                //08BE: 21 1C 27        LD      HL,$271C            ; Player-1 score on the screen"
                //08C1: 3A 67 20        LD      A,(playerDataMSB)   ; Get the player number"
                //08C4: 0F              RRCA                         ; C will be set for player 1
                //08C5: DA CB 08        JP      C,$08CB             ; We have the right score coordinates"
                //08C8: 21 1C 39        LD      HL,$391C            ; Use coordinates for player-2's score"
                //08CB: CD CB 14        CALL    ClearSmallSprite    ; Clear a one byte sprite at HL
                //08CE: C3 A9 08        JP      $08A9                ; Back to the top of the wait loop
                //
                //
GetShipsPerCred:                //GetShipsPerCred:
                //; Get number of ships from DIP settings
                //08D1: DB 02           IN      A,(INP2)            ; DIP settings"
                //08D3: E6 03           AND     $03                  ; Get number of ships
lda shipsPerCred                //08D5: C6 03           ADD     A,$03                ; From 3-6"
rts                //08D7: C9              RET                          ; Out
                //
                //SpeedShots:
                //; With less than 9 aliens on the screen the alien shots get a tad bit faster. Probably
                //; because the advancing rack can catch them.
                //;
                //08D8: 3A 82 20        LD      A,(numAliens)       ; Number of aliens on screen"
                //08DB: FE 09           CP      $09                  ; More than 8?
                //08DD: D0              RET     NC                   ; Yes ... leave shot speed alone
                //08DE: 3E FB           LD      A,$FB                ; Normally FF (-4) ... now FB (-5)"
                //08E0: 32 7E 20        LD      (alienShotDelta),A  ; Speed up alien shots"
                //08E3: C9              RET                          ; Done
                //
                //08E4: 3A CE 20        LD      A,(twoPlayers)      ; Number of players"
                //08E7: A7              AND     A                    ; Skip if ...
                //08E8: C0              RET     NZ                   ; ... two player
                //08E9: 21 1C 39        LD      HL,$391C            ; Player 2's score"
                //08EC: 06 20           LD      B,$20                ; 32 rows is 4 digits * 8 rows each"
                //08EE: C3 CB 14        JP      ClearSmallSprite    ; Clear a one byte sprite (32 rows long) at HL
                //
                //08F1: 0E 03           LD      C,$03                ; Length of saucer-score message ... fall into print"
                //
PrintMessage:                //PrintMessage:
                //; Print a message on the screen
                //; HL = coordinates
                //; DE = message buffer
                //; C = length
	addressRegisterByHL(0,1,1,0)
	//addressRegisterByHL(1,1,2,0)
	ldy #$00
PrintMessage1:
	lda (DE),y
	sta VERADATA0
	lda BC+1
	sta VERADATA0
	iny
    cpy BC
	bne PrintMessage1
    rts
                    //08F3: 1A              LD      A,(DE)              ; Get character"
                //08F4: D5              PUSH    DE                   ; Preserve
                //08F5: CD FF 08        CALL    DrawChar            ; Print character
                //08F8: D1              POP     DE                   ; Restore
                //08F9: 13              INC     DE                   ; Next character
                //08FA: 0D              DEC     C                    ; All done?
                //08FB: C2 F3 08        JP      NZ,PrintMessage     ; Print all of message"
                //08FE: C9              RET                          ; Out
                //
                //;=============================================================
                //DrawChar:
                //; Get pointer to 8 byte sprite number in A and
                //; draw sprite on screen at HL
DrawChar:
    tay
	addressRegisterByHL(0,1,1,0)
	tya
    sta VERADATA0
	lda #$01
	sta VERADATA0
    inc HL
    inc HL
    rts                
                //08FF: 11 00 1E        LD      DE,$1E00            ; Character set"
                //0902: E5              PUSH    HL                   ; Preserve
                //0903: 26 00           LD      H,$00                ; MSB=0"
                //0905: 6F              LD      L,A                  ; Character number to L"
                //0906: 29              ADD     HL,HL                ; HL = HL *2"
                //0907: 29              ADD     HL,HL                ; *4"
                //0908: 29              ADD     HL,HL                ; *8 (8 bytes each)"
                //0909: 19              ADD     HL,DE                ; Get pointer to sprite"
                //090A: EB              EX      DE,HL                ; Now into DE"
                //090B: E1              POP     HL                   ; Restore HL
                //090C: 06 08           LD      B,$08                ; 8 bytes each"
                //090E: D3 06           OUT     (WATCHDOG),A        ; Feed watchdog"
                //0910: C3 39 14        JP      DrawSimpSprite      ; To screen
                //
TimeToSaucer:                //TimeToSaucer:
lda gamevars8080.refAlienYr                //0913: 3A 09 20        LD      A,(refAlienYr)      ; Reference alien's X coordinate"
cmp #$78                //0916: FE 78           CP      $78                  ; Don't process saucer timer ... ($78 is 1st rack Yr)
bcc TimeTosaucerExit                //0918: D0              RET     NC                   ; ... unless aliens are closer to bottom
loadHL(gamevars8080.tillSaucerLSB)
lda (HL)               //0919: 2A 91 20        LD      HL,(tillSaucerLSB)  ; Time to saucer"
                //091C: 7D              LD      A,L                  ; Is it time ..."
ora (HL+1)               //091D: B4              OR      H                    ; ... for a saucer
bne DecTimeToSaucer               //091E: C2 29 09        JP      NZ,$0929            ; No ... skip flagging"
loadHL($0600)               //0921: 21 00 06        LD      HL,$0600            ; Reset timer to 600 game loops"
lda #$01                //0924: 3E 01           LD      A,$01                ; Flag a ..."
sta gamevars8080.saucerStart                //0926: 32 83 20        LD      (saucerStart),A     ; ... saucer sequence"
DecTimeToSaucer:
dec HL                //0929: 2B              DEC     HL                   ; Decrement the ...
bcc !+
dec HL+1
!:
lda HL                //092A: 22 91 20        LD      (tillSaucerLSB),HL  ; ... time-to-saucer"
sta gamevars8080.tillSaucerLSB
lda HL+1
sta gamevars8080.tillSaucerMSB
TimeTosaucerExit:
rts                //092D: C9              RET                          ; Done
                //
                //;=============================================================
getNumActiveShips:                //; Get number of ships for acive player
jsr GetPlayerDataPtr                //092E: CD 11 16        CALL    GetPlayerDataPtr    ; HL points to player data
dec HL                //0931: 2E FF           LD      L,$FF                ; Last byte = numbe of ships"
lda (HL)                //0933: 7E              LD      A,(HL)              ; Get number of ships"
rts                //0934: C9              RET                          ; Done
                //
                //;=============================================================
                //; Award extra ship if score has reached ceiling
                //0935: CD 10 19        CALL    CurPlyAlive         ; Get descriptor of sorts
                //0938: 2B              DEC     HL                   ; Back up ...
                //0939: 2B              DEC     HL                   ; ... two bytes
                //093A: 7E              LD      A,(HL)              ; Has extra ship ..."
                //093B: A7              AND     A                    ; already been awarded?
                //093C: C8              RET     Z                    ; Yes ... ignore
                //093D: 06 15           LD      B,$15                ; Default 1500"
                //093F: DB 02           IN      A,(INP2)            ; Read DIP settings"
                //0941: E6 08           AND     $08                  ; Extra ship at 1000 or 1500
                //0943: CA 48 09        JP      Z,$0948             ; 0=1500"
                //0946: 06 10           LD      B,$10                ; Awarded at 1000"
                //0948: CD CA 09        CALL    $09CA                ; Get score descriptor for active player
                //094B: 23              INC     HL                   ; MSB of score ...
                //094C: 7E              LD      A,(HL)              ; ... to accumulator"
                //094D: B8              CP      B                    ; Time for an extra ship?
                //094E: D8              RET     C                    ; No ... out
                //094F: CD 2E 09        CALL    $092E                ; Get pointer to number of ships
                //0952: 34              INC     (HL)                 ; Bump number of ships
                //0953: 7E              LD      A,(HL)              ; Get the new total"
                //0954: F5              PUSH    AF                   ; Hang onto it for a bit
                //0955: 21 01 25        LD      HL,$2501            ; Screen coords for ship hold"
                //0958: 24              INC     H                    ; Bump to ...
                //0959: 24              INC     H                    ; ... next
                //095A: 3D              DEC     A                    ; ... spot
                //095B: C2 58 09        JP      NZ,$0958            ; Find spot for new ship"
                //095E: 06 10           LD      B,$10                ; 16 byte sprite"
                //0960: 11 60 1C        LD      DE,$1C60            ; Player sprite"
                //0963: CD 39 14        CALL    DrawSimpSprite      ; Draw the sprite
                //0966: F1              POP     AF                   ; Restore the count
                //0967: 3C              INC     A                    ; +1
                //0968: CD 8B 1A        CALL    $1A8B                ; Print the number of ships
                //096B: CD 10 19        CALL    CurPlyAlive         ; Get descriptor for active player of some sort
                //096E: 2B              DEC     HL                   ; Back up ...
                //096F: 2B              DEC     HL                   ; ... two bytes
                //0970: 36 00           LD      (HL),$00            ; Flag extra ship has been awarded"
                //0972: 3E FF           LD      A,$FF                ; Set timer ..."
                //0974: 32 99 20        LD      (extraHold),A       ; ... for extra-ship sound"
                //0977: 06 10           LD      B,$10                ; Make sound ..."
                //0979: C3 FA 18        JP      SoundBits3On        ; ... for extra man
                //
                //AlienScoreValue:
                //097C: 21 A0 1D        LD      HL,$1DA0            ; Table for scores for hitting alien"
                //097F: FE 02           CP      $02                  ; 0 or 1 (lower two rows) ...
                //0981: D8              RET     C                    ; ... return HL points to value 10
                //0982: 23              INC     HL                   ; next value
                //0983: FE 04           CP      $04                  ; 2 or 3 (middle two rows) ...
                //0985: D8              RET     C                    ; ... return HL points to value 20
                //0986: 23              INC     HL                   ; Top row ...
                //0987: C9              RET                          ; ... return HL points to value 30
                //
                //AdjustScore:
                //; Adjust the score for the active player. 20F1 is 1 if there is a new value to add.
                //; The adjustment is in 20F2,20F3. Then print the score."
                //0988: CD CA 09        CALL    $09CA                ; Get score structure for active player
                //098B: 3A F1 20        LD      A,(adjustScore)     ; Does the score ..."
                //098E: A7              AND     A                    ; ... need increasing?
                //098F: C8              RET     Z                    ; No ... done
                //0990: AF              XOR     A                    ; Mark score ...
                //0991: 32 F1 20        LD      (adjustScore),A     ; ... as adjusted"
                //0994: E5              PUSH    HL                   ; Hold the pointer to the structure
                //0995: 2A F2 20        LD      HL,(scoreDeltaLSB)  ; Get requested adjustment"
                //0998: EB              EX      DE,HL                ; Adjustment to DE"
                //0999: E1              POP     HL                   ; Get back pointer to structure
                //099A: 7E              LD      A,(HL)              ; Add adjustment ..."
                //099B: 83              ADD     A,E                  ; ... first byte"
                //099C: 27              DAA                          ; Adjust it for BCD
                //099D: 77              LD      (HL),A              ; Store new LSB"
                //099E: 5F              LD      E,A                  ; Add adjustment ..."
                //099F: 23              INC     HL                   ; ... to ...
                //09A0: 7E              LD      A,(HL)              ; ... second ..."
                //09A1: 8A              ADC     A,D                  ; ... byte"
                //09A2: 27              DAA                          ; Adjust for BCD (cary gets dropped)
                //09A3: 77              LD      (HL),A              ; Store second byte"
                //09A4: 57              LD      D,A                  ; Second byte to D (first byte still in E)"
                //09A5: 23              INC     HL                   ; Load ...
                //09A6: 7E              LD      A,(HL)              ; ... the ..."
                //09A7: 23              INC     HL                   ; ... screen ...
                //09A8: 66              LD      H,(HL)              ; ... coordinates ..."
                //09A9: 6F              LD      L,A                  ; ... to HL"
                //09AA: C3 AD 09        JP      Print4Digits        ; ** Usually a good idea, but wasted here"
                //
Print4Digits:                //Print4Digits:
                    //; Print 4 digits in DE
lda DE+1                //09AD: 7A              LD      A,D                  ; Get first 2 digits of BCD or hex"
jsr DrawHexByte                //09AE: CD B2 09        CALL    DrawHexByte         ; Print them
lda DE                //09B1: 7B              LD      A,E                  ; Get second 2 digits of BCD or hex (fall into print)"
                //
DrawHexByte:                //DrawHexByte:
                //; Display 2 digits in A to screen at HL
                //09B2: D5              PUSH    DE                   ; Preserve
pha                //09B3: F5              PUSH    AF                   ; Save for later
ror                //09B4: 0F              RRCA                         ; Get ...
ror                //09B5: 0F              RRCA                         ; ...
ror                //09B6: 0F              RRCA                         ; ...
ror                //09B7: 0F              RRCA                         ; ... left digit
and #$0f                //09B8: E6 0F           AND     $0F                  ; Mask out lower digit's bits
jsr printCharAtHL                //09BA: CD C5 09        CALL    $09C5                ; To screen at HL
pla                //09BD: F1              POP     AF                   ; Restore digit
and #$0f                //09BE: E6 0F           AND     $0F                  ; Mask out upper digit
//jsr printCharAtHL                //09C0: CD C5 09        CALL    $09C5                ; To screen
                //09C3: D1              POP     DE                   ; Restore
//rts                //09C4: C9              RET                          ; Done
printCharAtHL:                //;
clc                //09C5: C6 1A           ADD     A,$1A                ; Bump to number characters"
adc #$1a
jmp DrawChar                //09C7: C3 FF 08        JP      DrawChar            ; Continue ...
                //
getScoreDescActivePlyr:                //; Get score descriptor for active player
loadHL(gamevars8080.P1ScorL)                //09CA: 3A 67 20        LD      A,(playerDataMSB)   ; Get active player"
lda gamevars8080.playerDataMSB                //09CD: 0F              RRCA                         ; Test for player
ror                //09CE: 21 F8 20        LD      HL,$20F8            ; Player 1 score descriptor"
bcs !+                //09D1: D8              RET     C                    ; Keep it if player 1 is active
loadHL(gamevars8080.P2ScorL)                //09D2: 21 FC 20        LD      HL,$20FC            ; Else get player 2 descriptor"
!:
rts                //09D5: C9              RET                          ; Out
                //
ClearPlayField:                //ClearPlayField:
                //; Clear center window of screen
loadHL($040c)                //09D6: 21 02 24        LD      HL,$2402            ; Thrid from left, top of screen"
cpf1:
addressRegisterByHL(0,1,1,0)
ldx #$38
lda #$26
cpf2:
sta VERADATA0
stz VERADATA0
dex
bne cpf2
inc HL+1
lda HL+1
cmp #$1c
bne cpf1
inc HL+1
addressRegister(0,$1fc00+6,4,0)
ldx #128
cpfSprites:
stz VERADATA0
dex
bne cpfSprites
rts
                //09D9: 36 00           LD      (HL),$00            ; Clear screen byte"
                //09DB: 23              INC     HL                   ; Next in row
                //09DC: 7D              LD      A,L                  ; Get X ..."
                //09DD: E6 1F           AND     $1F                  ; ... coordinate
                //09DF: FE 1C           CP      $1C                  ; Edge minus a buffer?
                //09E1: DA E8 09        JP      C,$09E8             ; No ... keep going"
                //09E4: 11 06 00        LD      DE,$0006            ; Else ... bump to"
                //09E7: 19              ADD     HL,DE                ; ... next edge + buffer"
                //09E8: 7C              LD      A,H                  ; Get Y coordinate"
                //09E9: FE 40           CP      $40                  ; Reached bottom?
                //09EB: DA D9 09        JP      C,$09D9             ; No ... keep going"
                //09EE: C9              RET                          ; Done
                //
                //09EF: CD 3C 0A        CALL    $0A3C                ; 
                //09F2: AF              XOR     A                    ; Suspend ...
                //09F3: 32 E9 20        LD      (suspendPlay),A     ; ... ISR game tasks"
                //09F6: CD D6 09        CALL    ClearPlayField      ; Clear playfield
                //09F9: 3A 67 20        LD      A,(playerDataMSB)   ; Hold current player number ..."
                //09FC: F5              PUSH    AF                   ; ... on stack
                //09FD: CD E4 01        CALL    CopyRAMMirror       ; Block copy RAM mirror from ROM
                //0A00: F1              POP     AF                   ; Restore ...
                //0A01: 32 67 20        LD      (playerDataMSB),A   ; ... current player number"
                //0A04: 3A 67 20        LD      A,(playerDataMSB)   ; ** Why load this again? Nobody ever jumps to 0A04?"
                //0A07: 67              LD      H,A                  ; To H"
                //0A08: E5              PUSH    HL                   ; Hold player-data pointer
                //0A09: 2E FE           LD      L,$FE                ; 2xFE ... rack count"
                //0A0B: 7E              LD      A,(HL)              ; Get the number of racks the player has beaten"
                //0A0C: E6 07           AND     $07                  ; 0-7
                //0A0E: 3C              INC     A                    ; Now 1-8
                //0A0F: 77              LD      (HL),A              ; Update count since player just beat a rack"
                //0A10: 21 A2 1D        LD      HL,$1DA2            ; Starting coordinate of alien table"
                //0A13: 23              INC     HL                   ; Find the ...
                //0A14: 3D              DEC     A                    ; ... right entry ...
                //0A15: C2 13 0A        JP      NZ,$0A13            ; ... in the table"
                //0A18: 7E              LD      A,(HL)              ; Get the starting Y coordiante"
                //0A19: E1              POP     HL                   ; Restore player's pointer
                //0A1A: 2E FC           LD      L,$FC                ; 2xFC ..."
                //0A1C: 77              LD      (HL),A              ; Set rack's starting Y coordinate"
                //0A1D: 23              INC     HL                   ; Point to X
                //0A1E: 36 38           LD      (HL),$38            ; Set rack's starting X coordinate to 38"
                //0A20: 7C              LD      A,H                  ; Player ..."
                //0A21: 0F              RRCA                         ; ... number to carry
                //0A22: DA 33 0A        JP      C,$0A33             ; 2nd player stuff"
                //0A25: 3E 21           LD      A,$21                ; Start fleet with ..."
                //0A27: 32 98 20        LD      (soundPort5),A      ; ... first sound"
                //0A2A: CD F5 01        CALL    DrawShieldPl2       ; Draw shields for player 2
                //0A2D: CD 04 19        CALL    InitAliensP2        ; Initalize aliens for player 2
                //0A30: C3 04 08        JP      $0804                ; Continue at top of game loop
                //;
                //0A33: CD EF 01        CALL    DrawShieldPl1       ; Draw shields for player 1
                //0A36: CD C0 01        CALL    InitAliens          ; Initialize aliens for player 1
                //0A39: C3 04 08        JP      $0804                ; Continue at top of game loop
                //;
                //0A3C: CD 59 0A        CALL    $0A59                ; Check player collision
                //0A3F: C2 52 0A        JP      NZ,$0A52            ; Player is not alive ... skip delay"
                //0A42: 3E 30           LD      A,$30                ; Half second delay"
                //0A44: 32 C0 20        LD      (isrDelay),A        ; Set ISR timer"
                //0A47: 3A C0 20        LD      A,(isrDelay)        ; Has timer expired?"
                //0A4A: A7              AND     A                    ; Check exipre
                //0A4B: C8              RET     Z                    ; Out if done
                //0A4C: CD 59 0A        CALL    $0A59                ; Check player collision
                //0A4F: CA 47 0A        JP      Z,$0A47             ; No collision ... wait on timer"
                //0A52: CD 59 0A        CALL    $0A59                ; Wait for ...
                //0A55: C2 52 0A        JP      NZ,$0A52            ; ... collision to end"
                //0A58: C9              RET                          ; Done
                //
isPlayerAlive:                //; Check to see if player is hit
lda gamevars8080.playerAlive                //0A59: 3A 15 20        LD      A,(playerAlive)     ; Active player hit flag"
cmp #$ff                //0A5C: FE FF           CP      $FF                  ; All FFs means player is OK
rts                //0A5E: C9              RET                          ; Out
                //
                //ScoreForAlien:
                //; Start the hit-alien sound and flag the adjustment for the score.
                //; B contains the row, which determines the score value."
                //0A5F: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //0A62: A7              AND     A                    ; ... game mode?
                //0A63: CA 7C 0A        JP      Z,$0A7C             ; No ... skip scoring in demo"
                //0A66: 48              LD      C,B                  ; Hold row number"
                //0A67: 06 08           LD      B,$08                ; Alien hit sound"
                //0A69: CD FA 18        CALL    SoundBits3On        ; Enable sound
                //0A6C: 41              LD      B,C                  ; Restore row number"
                //0A6D: 78              LD      A,B                  ; Into A"
                //0A6E: CD 7C 09        CALL    AlienScoreValue     ; Look up the score for the alien
                //0A71: 7E              LD      A,(HL)              ; Get the score value"
                //0A72: 21 F3 20        LD      HL,$20F3            ; Pointer to score delta"
                //0A75: 36 00           LD      (HL),$00            ; Upper byte of score delta is ""00"""
                //0A77: 2B              DEC     HL                   ; Point to score delta LSB
                //0A78: 77              LD      (HL),A              ; Set score for hitting alien"
                //0A79: 2B              DEC     HL                   ; Point to adjust-score-flag
                //0A7A: 36 01           LD      (HL),$01            ; The score will get changed elsewhere"
                //0A7C: 21 62 20        LD      HL,$2062            ; Return exploding-alien descriptor"
                //0A7F: C9              RET                          ; Out
                //
Animate:                //Animate:
                //; Start the ISR moving the sprite. Return when done.
lda #$02                //0A80: 3E 02           LD      A,$02                ; Start simple linear ..."
sta gamevars8080.isrSplashTask                //0A82: 32 C1 20        LD      (isrSplashTask),A   ; ... sprite animation (splash)"
!wait:                //0A85: D3 06           OUT     (WATCHDOG),A        ; Feed watchdog"
lda gamevars8080.splashReached                //0A87: 3A CB 20        LD      A,(splashReached)   ; Has the ..."
                //0A8A: A7              AND     A                    ; ... sprite reached target?
beq !wait-                //0A8B: CA 85 0A        JP      Z,$0A85             ; No ... wait"
                //0A8E: AF              XOR     A                    ; Stop ...
stz gamevars8080.isrSplashTask                //0A8F: 32 C1 20        LD      (isrSplashTask),A   ; ... ISR animation"
rts                //0A92: C9              RET                          ; Done
                //
PrintMessageDel:                //PrintMessageDel:
                //; Print message from DE to screen at HL (length in C) with a
                //; delay between letters.
               //0A93: D5              PUSH    DE                   ; Preserve
lda (DE)                //0A94: 1A              LD      A,(DE)              ; Get character"
jsr DrawChar                //0A95: CD FF 08        CALL    DrawChar            ; Draw character on screen
                //0A98: D1              POP     DE                   ; Preserve
lda #$07               //0A99: 3E 07           LD      A,$07                ; Delay between letters"
sta gamevars8080.isrDelay                //0A9B: 32 C0 20        LD      (isrDelay),A        ; Set counter"
!delay:
lda gamevars8080.isrDelay                //0A9E: 3A C0 20        LD      A,(isrDelay)        ; Get counter"
dec                //0AA1: 3D              DEC     A                    ; Is it 1?
bne !delay-                //0AA2: C2 9E 0A        JP      NZ,$0A9E            ; No ... wait on it"
inc DE                //0AA5: 13              INC     DE                   ; Next in message
bne !+
inc DE+1
!:
dec BC                //0AA6: 0D              DEC     C                    ; All done?
bne PrintMessageDel                //0AA7: C2 93 0A        JP      NZ,PrintMessageDel  ; No ... do all"
rts                //0AAA: C9              RET                          ; Out
                //
SplashSquiggly:                //SplashSquiggly:
//lda #<gamevars8080.obj4TimerMSB                //0AAB: 21 50 20        LD      HL,$2050            ; Pointer to game-object 4 timer"
//sta HL
//lda #>gamevars8080.obj4TimerMSB
//sta HL+1
loadHL(gamevars8080.obj4TimerMSB)
jmp RunGameObjs1                //0AAE: C3 4B 02        JP      $024B                ; Process squiggly-shot in demo mode
                //
                //OneSecDelay:
                //; Delay 64 interrupts
OneSecDelay:
lda #$40                //0AB1: 3E 40           LD      A,$40                ; Delay of 64 (tad over 1 sec)"
jmp WaitOnDelay                //0AB3: C3 D7 0A        JP      WaitOnDelay         ; Do delay
                //
                //TwoSecDelay:
TwoSecDelay:
                //; Delay 128 interrupts
lda #$80                //0AB6: 3E 80           LD      A,$80                ; Delay of 80 (tad over 2 sec)"
jmp WaitOnDelay                //0AB8: C3 D7 0A        JP      WaitOnDelay         ; Do delay
                //
                //SplashDemo:
SplashDemo:                
pla                //0ABB: E1              POP     HL                   ; Drop the call to ABF and ...
pla     // remove return add from stack             
jmp gameLoopNoSound                //0ABC: C3 72 00        JP      $0072                ; ... do a demo game loop without sound
                //
ISRSplTasks:                //ISRSplTasks:
                //; Different types of splash tasks managed by ISR in splash screens. The ISR
                //; calls this if in splash-mode. These may have been bit flags to allow all 3
                //; at the same time. Maybe it is just easier to do a switch with a rotate-to-carry.
                //;
lda gamevars8080.isrSplashTask                //0ABF: 3A C1 20        LD      A,(isrSplashTask)   ; Get the ISR task number"
ror                //0AC2: 0F              RRCA                         ; In demo play mode?
bcs SplashDemo                //0AC3: DA BB 0A        JP      C,SplashDemo        ; 1: Yes ... go do game play (without sound)"
ror                //0AC6: 0F              RRCA                         ; Moving little alien from point A to B?
bcc !+
jmp SplashSprite                //0AC7: DA 68 18        JP      C,SplashSprite      ; 2: Yes ... go move little alien from point A to B"
!:
ror                //0ACA: 0F              RRCA                         ; Shooting extra ""C" with squiggly shot?"
bcs SplashSquiggly                //0ACB: DA AB 0A        JP      C,SplashSquiggly    ; 4: Yes ... go shoot extra ""C" in splash"
rts                //0ACE: C9              RET                          ; No task to do
                //
                //; Message to center of screen.
messageInvCentre:                //; Only used in one place for ""SPACE  INVADERS"""
loadHL($0b1a)                //0ACF: 21 14 2B        LD      HL,$2B14            ; Near center of screen"
loadBC($000f)                //0AD2: 0E 0F           LD      C,$0F                ; 15 bytes in message"
jmp PrintMessageDel                //0AD4: C3 93 0A        JP      PrintMessageDel     ; Print and out
                //
                //WaitOnDelay:
                //; Wait on ISR counter to reach 0
WaitOnDelay: 
sta gamevars8080.isrDelay                //0AD7: 32 C0 20        LD      (isrDelay),A        ; Delay counter"
!: lda gamevars8080.isrDelay               //0ADA: 3A C0 20        LD      A,(isrDelay)        ; Get current delay"
                //0ADD: A7              AND     A                    ; Zero yet?
bne !-                //0ADE: C2 DA 0A        JP      NZ,$0ADA            ; No ... wait on it"
rts                //0AE1: C9              RET                          ; Out
                //
IniSplashAni:                //IniSplashAni:
                //; Init the splash-animation block
loadHL(gamevars8080.splashAnForm)               //0AE2: 21 C2 20        LD      HL,$20C2            ; The splash-animation descriptor"
loadBC($0c00)                //0AE5: 06 0C           LD      B,$0C                ; C bytes"
jmp BlockCopy                //0AE7: C3 32 1A        JP      BlockCopy           ; Block copy DE to descriptor
                //
                //;=============================================================
afterIniSplash:                //; After initialization ... splash screens
    lda #$00                //0AEA: AF              XOR     A                    ; Make a 0
                //0AEB: D3 03           OUT     (SOUND1),A          ; Turn off sound"
                //0AED: D3 05           OUT     (SOUND2),A          ; Turn off sound"
    jsr setISRSplashTask                //0AEF: CD 82 19        CALL    $1982                ; Turn off ISR splash-task
    cli                //0AF2: FB              EI                           ; Enable interrupts (using them for delays)
    jsr OneSecDelay                //0AF3: CD B1 0A        CALL    OneSecDelay         ; One second delay
                //0AF9: A7              AND     A                    ; Set flags based on type
    loadHL($0824)                //0AFA: 21 17 30        LD      HL,$3017            ; Screen coordinates (middle near top)"
    loadBC($0104)                //0AFD: 0E 04           LD      C,$04                ; 4 characters in ""PLAY"""
    lda gamevars8080.splashAnimate               //0AF6: 3A EC 20        LD      A,(splashAnimate)   ; Splash screen type"
    beq PlayU                //0AFF: C2 E8 0B        JP      NZ,$0BE8            ; Not 0 ... do ""normal" PLAY"
    loadDE(MessagePlayY)                //0BE8: 11 AB 1D        LD      DE,$1DAB            ; ""PLAY" with normal 'Y'"
    jsr PrintMessageDel                //0BEB: CD 93 0A        CALL    PrintMessageDel     ; Print it
    bra continueSplash                //0BEE: C3 0B 0B        JP      $0B0B                ; Continue with splash (DE will be pointing to next message)
PlayU:
    loadDE(MessagePlayUY)                //0B02: 11 FA 1C        LD      DE,$1CFA            ; The ""PLAy" with an upside down 'Y'"
    jsr PrintMessageDel                //0B05: CD 93 0A        CALL    PrintMessageDel     ; Print the ""PLAy"""
    loadDE(MessageInvaders)                //0B08: 11 AF 1D        LD      DE,$1DAF            ; ""SPACE  INVADERS" message"
continueSplash:
    jsr messageInvCentre                //0B0B: CD CF 0A        CALL    $0ACF                ; Print to middle-ish of screen
    jsr OneSecDelay                //0B0E: CD B1 0A        CALL    OneSecDelay         ; One second delay
    jsr DrawAdvTable                //0B11: CD 15 18        CALL    DrawAdvTable        ; Draw ""SCORE ADVANCE TABLE" with print delay"
    jsr TwoSecDelay            //0B14: CD B6 0A        CALL    TwoSecDelay         ; Two second delay
    lda gamevars8080.splashAnimate           //0B17: 3A EC 20        LD      A,(splashAnimate)   ; Do splash ..."
                //0B1A: A7              AND     A                    ; ... animations?
    beq ContSplash2
    jmp playDemo            //0B1B: C2 4A 0B        JP      NZ,$0B4A            ; Not 0 ... no animations"
                //;
                //; Animate small alien replacing upside-down Y with correct Y
    ContSplash2:
    loadDE(SplashAni1Struct)            //0B1E: 11 95 1A        LD      DE,$1A95            ; Animate sprite from Y=FE to Y=9E step -1"
    jsr IniSplashAni            //0B21: CD E2 0A        CALL    IniSplashAni        ; Copy to splash-animate structure
    jsr Animate            //0B24: CD 80 0A        CALL    Animate             ; Wait for ISR to move sprite (small alien)
    loadHL($082a)
    lda #$26        // space
    jsr DrawChar
    loadDE(SplashAni2Struct)            //0B27: 11 B0 1B        LD      DE,$1BB0            ; Animate sprite from Y=98 to Y=FF step 1"
    jsr IniSplashAni            //0B2A: CD E2 0A        CALL    IniSplashAni        ; Copy to splash-animate structure
    jsr Animate            //0B2D: CD 80 0A        CALL    Animate             ; Wait for ISR to move sprite (alien pulling upside down Y)
    addressRegister(0,$1fc06,1,0)
    stz VERADATA0
    jsr OneSecDelay            //0B30: CD B1 0A        CALL    OneSecDelay         ; One second delay
    loadDE(SplashAni3Struct)            //0B33: 11 C9 1F        LD      DE,$1FC9            ; Animate sprite from Y=FF to Y=97 step 1"
    jsr IniSplashAni            //0B36: CD E2 0A        CALL    IniSplashAni        ; Copy to splash-animate structure
    jsr Animate            //0B39: CD 80 0A        CALL    Animate             ; Wait for ISR to move sprite (alien pushing Y)
    jsr OneSecDelay            //0B3C: CD B1 0A        CALL    OneSecDelay         ; One second delay
    loadHL($082a)
    lda #$18 //Y
    jsr DrawChar
    addressRegister(0,$1fc06,1,0)
    stz VERADATA0               //turn sprite off
                //0B3F: 21 B7 33        LD      HL,$33B7            ; Where the splash alien ends up"
                //0B42: 06 0A           LD      B,$0A                ; 10 rows"
                //0B44: CD CB 14        CALL    ClearSmallSprite    ; Clear a one byte sprite at HL
    jsr TwoSecDelay            //0B47: CD B6 0A        CALL    TwoSecDelay         ; Two second delay
    //break()            //;
playDemo:                //; Play demo
jsr ClearPlayField              //0B4A: CD D6 09        CALL    ClearPlayField      ; Clear playfield
lda gamevars8080.p1ShipsRem                //0B4D: 3A FF 21        LD      A,(p1ShipsRem)      ; Number of ships for player-1"
                //0B50: A7              AND     A                    ; If non zero ...
bne playDemo1                //0B51: C2 5D 0B        JP      NZ,$0B5D            ; ... keep it (counts down between demos)"
jsr GetShipsPerCred                //0B54: CD D1 08        CALL    GetShipsPerCred     ; Get number of ships from DIP settings
sta gamevars8080.p1ShipsRem                //0B57: 32 FF 21        LD      (p1ShipsRem),A      ; Reset number of ships for player-1"
jsr RemoveShip                //0B5A: CD 7F 1A        CALL    RemoveShip          ; Remove a ship from stash and update indicators
                //;
playDemo1:
jsr TwoSecDelay
jsr CopyRAMMirror                //0B5D: CD E4 01        CALL    CopyRAMMirror       ; Block copy ROM mirror to initialize RAM
jsr InitAliens                //0B60: CD C0 01        CALL    InitAliens          ; Initialize all player 1 aliens
jsr DrawShieldPl1                //0B63: CD EF 01        CALL    DrawShieldPl1       ; Draw shields for player 1 (to buffer)
jsr RestoreShields1                //0B66: CD 1A 02        CALL    RestoreShields1     ; Restore shields for player 1 (to screen)
lda #$01                //0B69: 3E 01           LD      A,$01                ; ISR splash-task ..."
sta gamevars8080.isrSplashTask                //0B6B: 32 C1 20        LD      (isrSplashTask),A   ; ... playing demo"
jsr DrawBottomLine                //0B6E: CD CF 01        CALL    DrawBottomLine      ; Draw playfield line
contDemo1:                //;
jsr PlrFireOrDemo                //0B71: CD 18 16        CALL    PlrFireOrDemo       ; In demo ... process demo movement and always fire
jsr plyrShotBumpHidden                //0B74: CD F1 0B        CALL    $0BF1                ; Check player shot and aliens bumping edges of screen and hidden message
                //0B77: D3 06           OUT     (WATCHDOG),A        ; Feed watchdog"
jsr isPlayerAlive                //0B79: CD 59 0A        CALL    $0A59                ; Has demo player been hit?
beq contDemo1                //0B7C: CA 71 0B        JP      Z,$0B71             ; No ... continue game"
                //0B7F: AF              XOR     A                    ; Remove player shot ...
stz gamevars8080.plyrShotStatus                //0B80: 32 25 20        LD      (plyrShotStatus),A  ; ... from activity"
waitDemoBoom:
jsr isPlayerAlive                //0B83: CD 59 0A        CALL    $0A59                ; Wait for demo player ...
bne waitDemoBoom                //0B86: C2 83 0B        JP      NZ,$0B83            ; ... to stop exploding"
                //;
                //; Credit information
creditInfo:
                //0B89: AF              XOR     A                    ; Turn off ...
stz gamevars8080.isrSplashTask                //0B8A: 32 C1 20        LD      (isrSplashTask),A   ; ... splash animation"
jsr OneSecDelay                //0B8D: CD B1 0A        CALL    OneSecDelay         ; One second delay
jsr ClearPlayField               //0B90: CD 88 19        CALL    $1988                ; ** Something else at one time? Jump straight to clear-play-field
loadBC($010c)                //0B93: 0E 0C           LD      C,$0C                ; Message size"
loadHL($2c11)                //0B95: 21 11 2C        LD      HL,$2C11            ; Screen coordinates"
loadDE(MessageCoin)                //0B98: 11 90 1F        LD      DE,$1F90            ; ""INSERT  COIN"""
jsr PrintMessage               //0B9B: CD F3 08        CALL    PrintMessage        ; Print message
lda gamevars8080.splashAnimate                //0B9E: 3A EC 20        LD      A,(splashAnimate)   ; Do splash ..."
                //0BA1: FE 00           CP      $00                  ; ... animations?
bne notExtraC                //0BA3: C2 AE 0B        JP      NZ,$0BAE            ; Not 0 ... not on this screen"
loadHL($3311)                //0BA6: 21 11 33        LD      HL,$3311            ; Screen coordinates"
lda #$02                //0BA9: 3E 02           LD      A,$02                ; Character ""C"""
jsr DrawChar                //0BAB: CD FF 08        CALL    DrawChar            ; Put an extra ""C" for ""CCOIN" on the screen"
notExtraC:
loadBC(CreditTable)                //0BAE: 01 9C 1F        LD      BC,$1F9C            ; ""<1 OR 2 PLAYERS>  """
jsr ReadPriStruct                //0BB1: CD 56 18        CALL    ReadPriStruct       ; Load the screen,pointer"
jsr PrintAdvanceText                //0BB4: CD 4C 18        CALL    $184C                ; Print the message
                //0BB7: DB 02           IN      A,(INP2)            ; Display coin info (bit 7) ..."
                //0BB9: 07              RLCA                         ; ... on demo screen?
                //0BBA: DA C3 0B        JP      C,$0BC3             ; 1 means no ... skip it"
loadBC(CreditTable+4)               //0BBD: 01 A0 1F        LD      BC,$1FA0            ; ""*1 PLAYER  1 COIN """
jsr drawTable1                //0BC0: CD 3A 18        CALL    $183A                ; Load the descriptor
jsr TwoSecDelay                //0BC3: CD B6 0A        CALL    TwoSecDelay         ; Print TWO descriptors worth
lda gamevars8080.splashAnimate                //0BC6: 3A EC 20        LD      A,(splashAnimate)   ; Doing splash ..."
                //0BC9: FE 00           CP      $00                  ; ... animation?
bne !+                //0BCB: C2 DA 0B        JP      NZ,$0BDA            ; Not 0 ... not on this screen"
loadDE(SplashAni4Struct)                //0BCE: 11 D5 1F        LD      DE,$1FD5            ; Animation for small alien to line up with extra ""C"""
jsr IniSplashAni                //0BD1: CD E2 0A        CALL    IniSplashAni        ; Copy the animation block
jsr Animate                //0BD4: CD 80 0A        CALL    Animate             ; Wait for the animation to complete
jsr animateAlienC                //0BD7: CD 9E 18        CALL    $189E                ; Animate alien shot to extra ""C"""
!:
loadHL(gamevars8080.splashAnimate)               //0BDA: 21 EC 20        LD      HL,$20EC            ; Toggle ..."
lda (HL)                //0BDD: 7E              LD      A,(HL)              ; ... the ..."
eor #$01                //0BDE: 3C              INC     A                    ; ... splash screen ...
                //0BDF: E6 01           AND     $01                  ; ... animation for ...
sta (HL)                //0BE1: 77              LD      (HL),A              ; ... next time"
jsr ClearPlayField                //0BE2: CD D6 09        CALL    ClearPlayField      ; Clear play field
jmp keepSplashing                //0BE5: C3 DF 18        JP      $18DF                ; Keep splashing

plyrShotBumpHidden:                //
jsr PlyrShotAndBump           //0BF1: CD 0A 19        CALL    PlyrShotAndBump     ; Check if player is shot and aliens bumping the edge of screen
jmp CheckHiddenMes                //0BF4: C3 9A 19        JP      CheckHiddenMes      ; Check for hidden-message display sequence
                //
MessageCorp:                //MessageCorp:
                //; ""TAITO COP"""
.byte $13, $00, $08, $13, $0E, $26, $02, $0E, $0F                //0BF7: 13 00 08 13 0E 26 02 0E 0F
                //Diagnostics Routine
                //The very center 2K of the code map is an expansion area. It originally contained a 1K diagnostics routine beginning at 1000. The original code would check bit 0 of port 0 (wired to DIP4) and jump to this routine if the switch was flipped. The routine was removed in this Midway version of the code. And it was removed in later versions of the TAITO code line.
                //The original routine is shown here for reference.
                //0C00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0C20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0C40: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0C60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0C80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0CA0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0CC0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0CE0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //
                //0D00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0D20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0D40: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0D60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0D80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0DA0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0DC0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0DE0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //
                //0E00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0E20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0E40: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0E60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0E80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0EA0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0EC0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0EE0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //
                //0F00: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0F20: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0F40: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0F60: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0F80: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0FA0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0FC0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //0FE0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //
                //; The original TAITO code had a self-check routine here. The opening jump was to E2, which was a"
                //; check on bit 0 of port 0 (the DIP4 switch for self test). If the bit was set the code came here.
                //; When Midway branched the code, they left the check out."
                //
                //1000: 00              NOP                          ; Three bytes for ...
                //1001: 00              NOP                          ; ... development code ...
                //1002: 00              NOP                          ; ... jump opcode
                //;
                //1003: AF              XOR     A                    ; Turn off ...
                //1004: D3 03           OUT     (SOUND1),A          ; ... sound effects (AMP ENABLE bit 5)"
                //1006: 0E 03           LD      C,$03                ;"
                //1008: 06 55           LD      B,$55                ;"
                //100A: 21 00 20        LD      HL,$2000            ;"
                //100D: 70              LD      (HL),B              ;"
                //100E: 23              INC     HL                   ;
                //100F: 7C              LD      A,H                  ;"
                //1010: FE 40           CP      $40                  ;
                //1012: C2 0D 10        JP      NZ,$100D            ; "
                //1015: 21 00 20        LD      HL,$2000            ;"
                //1018: 7E              LD      A,(HL)              ;"
                //1019: A8              XOR     B                    ;
                //101A: C2 90 11        JP      NZ,$1190            ; "
                //101D: 23              INC     HL                   ;
                //101E: 7C              LD      A,H                  ;"
                //101F: FE 40           CP      $40                  ;
                //1021: C2 18 10        JP      NZ,$1018            ; "
                //1024: 06 AA           LD      B,$AA                ;"
                //1026: 21 00 20        LD      HL,$2000            ;"
                //1029: 70              LD      (HL),B              ;"
                //102A: 23              INC     HL                   ;
                //102B: 7C              LD      A,H                  ;"
                //102C: FE 40           CP      $40                  ;
                //102E: C2 29 10        JP      NZ,$1029            ; "
                //1031: 21 00 20        LD      HL,$2000            ;"
                //1034: 7E              LD      A,(HL)              ;"
                //1035: A8              XOR     B                    ;
                //1036: C2 90 11        JP      NZ,$1190            ; "
                //1039: 23              INC     HL                   ;
                //103A: 7C              LD      A,H                  ;"
                //103B: FE 40           CP      $40                  ;
                //103D: C2 34 10        JP      NZ,$1034            ; "
                //1040: 0D              DEC     C                    ;
                //1041: C2 08 10        JP      NZ,$1008            ; "
                //1044: 21 00 20        LD      HL,$2000            ;"
                //1047: 06 00           LD      B,$00                ;"
                //1049: 78              LD      A,B                  ;"
                //104A: 77              LD      (HL),A              ;"
                //104B: 23              INC     HL                   ;
                //104C: 04              INC     B                    ;
                //104D: 78              LD      A,B                  ;"
                //104E: FE FF           CP      $FF                  ;
                //1050: C2 55 10        JP      NZ,$1055            ; "
                //1053: 06 00           LD      B,$00                ;"
                //1055: 7C              LD      A,H                  ;"
                //1056: FE 40           CP      $40                  ;
                //1058: C2 49 10        JP      NZ,$1049            ; "
                //105B: 21 00 20        LD      HL,$2000            ;"
                //105E: 06 00           LD      B,$00                ;"
                //1060: 7E              LD      A,(HL)              ;"
                //1061: A8              XOR     B                    ;
                //1062: C2 90 11        JP      NZ,$1190            ; "
                //1065: 04              INC     B                    ;
                //1066: 78              LD      A,B                  ;"
                //1067: FE FF           CP      $FF                  ;
                //1069: C2 6E 10        JP      NZ,$106E            ; "
                //106C: 06 00           LD      B,$00                ;"
                //106E: 23              INC     HL                   ;
                //106F: 7C              LD      A,H                  ;"
                //1070: FE 40           CP      $40                  ;
                //1072: C2 60 10        JP      NZ,$1060            ; "
                //1075: 31 00 24        LD      SP,$2400            ;"
                //1078: CD 83 11        CALL    $1183                ; 
                //107B: 11 48 13        LD      DE,$1348            ;"
                //107E: 21 01 25        LD      HL,$2501            ;"
                //1081: CD 55 11        CALL    $1155                ; 
                //1084: 21 01 27        LD      HL,$2701            ;"
                //1087: CD 55 11        CALL    $1155                ; 
                //108A: 21 01 33        LD      HL,$3301            ;"
                //108D: CD 55 11        CALL    $1155                ; 
                //1090: 21 07 2A        LD      HL,$2A07            ;"
                //1093: 0E 0F           LD      C,$0F                ;"
                //1095: 11 6F 13        LD      DE,$136F            ;"
                //1098: D5              PUSH    DE                   ;
                //1099: CD 57 11        CALL    $1157                ; 
                //109C: D1              POP     DE                   ;
                //109D: 21 07 2E        LD      HL,$2E07            ;"
                //10A0: 0E 0F           LD      C,$0F                ;"
                //10A2: CD 57 11        CALL    $1157                ; 
                //10A5: 3E 1D           LD      A,$1D                ;"
                //10A7: 21 0B 2E        LD      HL,$2E0B            ;"
                //10AA: CD 66 11        CALL    $1166                ; 
                //10AD: 06 0B           LD      B,$0B                ;"
                //10AF: 21 0E 34        LD      HL,$340E            ;"
                //10B2: 11 7E 13        LD      DE,$137E            ;"
                //10B5: 0E 06           LD      C,$06                ;"
                //10B7: C5              PUSH    BC                   ;
                //10B8: CD 57 11        CALL    $1157                ; 
                //10BB: 01 FA 00        LD      BC,$00FA            ;"
                //10BE: 09              ADD     HL,BC                ;"
                //10BF: C1              POP     BC                   ;
                //10C0: 05              DEC     B                    ;
                //10C1: C2 B5 10        JP      NZ,$10B5            ; "
                //10C4: 06 02           LD      B,$02                ;"
                //10C6: C5              PUSH    BC                   ;
                //10C7: 21 0D 34        LD      HL,$340D            ;"
                //10CA: 22 00 20        LD      (waitOnDraw),HL     ; "
                //10CD: 3E 01           LD      A,$01                ;"
                //10CF: F5              PUSH    AF                   ;
                //10D0: F6 20           OR      $20                  ;
                //10D2: D3 03           OUT     (SOUND1),A          ; "
                //10D4: CD 05 11        CALL    $1105                ; 
                //10D7: 3E 20           LD      A,$20                ;"
                //10D9: D3 03           OUT     (SOUND1),A          ; "
                //10DB: CD 10 11        CALL    $1110                ; 
                //10DE: F1              POP     AF                   ;
                //10DF: 07              RLCA                         ;
                //10E0: FE 20           CP      $20                  ;
                //10E2: C2 CF 10        JP      NZ,$10CF            ; "
                //10E5: 3E 01           LD      A,$01                ;"
                //10E7: F5              PUSH    AF                   ;
                //10E8: D3 05           OUT     (SOUND2),A          ; "
                //10EA: CD 05 11        CALL    $1105                ; 
                //10ED: AF              XOR     A                    ;
                //10EE: D3 05           OUT     (SOUND2),A          ; "
                //10F0: CD 10 11        CALL    $1110                ; 
                //10F3: F1              POP     AF                   ;
                //10F4: 07              RLCA                         ;
                //10F5: FE 40           CP      $40                  ;
                //10F7: C2 E7 10        JP      NZ,$10E7            ; "
                //10FA: C1              POP     BC                   ;
                //10FB: 05              DEC     B                    ;
                //10FC: C2 C6 10        JP      NZ,$10C6            ; "
                //10FF: CD 29 11        CALL    $1129                ; 
                //1102: C3 FF 10        JP      $10FF                ; 
                //1105: 2A 00 20        LD      HL,(waitOnDraw)     ; "
                //1108: 3E 0F           LD      A,$0F                ;"
                //110A: CD 66 11        CALL    $1166                ; 
                //110D: C3 1F 11        JP      $111F                ; 
                //1110: CD 1F 11        CALL    $111F                ; 
                //1113: 2A 00 20        LD      HL,(waitOnDraw)     ; "
                //1116: 3E 28           LD      A,$28                ;"
                //1118: CD 66 11        CALL    $1166                ; 
                //111B: 22 00 20        LD      (waitOnDraw),HL     ; "
                //111E: C9              RET                          ;
                //111F: 3E 60           LD      A,$60                ;"
                //1121: CD CE 11        CALL    $11CE                ; 
                //1124: 3D              DEC     A                    ;
                //1125: C2 21 11        JP      NZ,$1121            ; "
                //1128: C9              RET                          ;
                //1129: F5              PUSH    AF                   ;
                //112A: 21 0E 2B        LD      HL,$2B0E            ;"
                //112D: DB 01           IN      A,(INP1)            ; "
                //112F: CD 3C 11        CALL    $113C                ; 
                //1132: 21 0E 2F        LD      HL,$2F0E            ;"
                //1135: DB 02           IN      A,(INP2)            ; "
                //1137: CD 3C 11        CALL    $113C                ; 
                //113A: F1              POP     AF                   ;
                //113B: C9              RET                          ;
                //113C: 06 08           LD      B,$08                ;"
                //113E: C5              PUSH    BC                   ;
                //113F: E5              PUSH    HL                   ;
                //1140: 0F              RRCA                         ;
                //1141: F5              PUSH    AF                   ;
                //1142: 3E 28           LD      A,$28                ;"
                //1144: DA 49 11        JP      C,$1149             ; "
                //1147: 3E 25           LD      A,$25                ;"
                //1149: CD 66 11        CALL    $1166                ; 
                //114C: F1              POP     AF                   ;
                //114D: E1              POP     HL                   ;
                //114E: 23              INC     HL                   ;
                //114F: C1              POP     BC                   ;
                //1150: 05              DEC     B                    ;
                //1151: C2 3E 11        JP      NZ,$113E            ; "
                //1154: C9              RET                          ;
                //1155: 0E 0D           LD      C,$0D                ;"
                //1157: 1A              LD      A,(DE)              ;"
                //1158: D5              PUSH    DE                   ;
                //1159: E5              PUSH    HL                   ;
                //115A: CD 66 11        CALL    $1166                ; 
                //115D: E1              POP     HL                   ;
                //115E: 23              INC     HL                   ;
                //115F: D1              POP     DE                   ;
                //1160: 13              INC     DE                   ;
                //1161: 0D              DEC     C                    ;
                //1162: C2 57 11        JP      NZ,$1157            ; "
                //1165: C9              RET                          ;
                //1166: 11 00 12        LD      DE,$1200            ;"
                //1169: E5              PUSH    HL                   ;
                //116A: 6F              LD      L,A                  ;"
                //116B: 26 00           LD      H,$00                ;"
                //116D: 29              ADD     HL,HL                ;"
                //116E: 29              ADD     HL,HL                ;"
                //116F: 29              ADD     HL,HL                ;"
                //1170: 19              ADD     HL,DE                ;"
                //1171: EB              EX      DE,HL                ;"
                //1172: E1              POP     HL                   ;
                //1173: 06 08           LD      B,$08                ;"
                //1175: C5              PUSH    BC                   ;
                //1176: 1A              LD      A,(DE)              ;"
                //1177: 77              LD      (HL),A              ;"
                //1178: 13              INC     DE                   ;
                //1179: 01 20 00        LD      BC,$0020            ;"
                //117C: 09              ADD     HL,BC                ;"
                //117D: C1              POP     BC                   ;
                //117E: 05              DEC     B                    ;
                //117F: C2 75 11        JP      NZ,$1175            ; "
                //1182: C9              RET                          ;
                //1183: 21 00 24        LD      HL,$2400            ;"
                //1186: 36 00           LD      (HL),$00            ;"
                //1188: 23              INC     HL                   ;
                //1189: 7C              LD      A,H                  ;"
                //118A: FE 40           CP      $40                  ;
                //118C: C2 86 11        JP      NZ,$1186            ; "
                //118F: C9              RET                          ;
                //1190: 06 01           LD      B,$01                ;"
                //1192: 0F              RRCA                         ;
                //1193: DA 9A 11        JP      C,$119A             ; "
                //1196: 04              INC     B                    ;
                //1197: C3 92 11        JP      $1192                ; 
                //119A: 7D              LD      A,L                  ;"
                //119B: 21 D8 12        LD      HL,$12D8            ;"
                //119E: 0F              RRCA                         ;
                //119F: D2 A5 11        JP      NC,$11A5            ; "
                //11A2: 21 B8 13        LD      HL,$13B8            ;"
                //11A5: 78              LD      A,B                  ;"
                //11A6: 07              RLCA                         ;
                //11A7: 07              RLCA                         ;
                //11A8: 07              RLCA                         ;
                //11A9: 47              LD      B,A                  ;"
                //11AA: 58              LD      E,B                  ;"
                //11AB: 16 00           LD      D,$00                ;"
                //11AD: 19              ADD     HL,DE                ;"
                //11AE: EB              EX      DE,HL                ;"
                //11AF: 06 08           LD      B,$08                ;"
                //11B1: 21 11 30        LD      HL,$3011            ;"
                //11B4: 1A              LD      A,(DE)              ;"
                //11B5: 77              LD      (HL),A              ;"
                //11B6: 78              LD      A,B                  ;"
                //11B7: 01 20 00        LD      BC,$0020            ;"
                //11BA: 09              ADD     HL,BC                ;"
                //11BB: 47              LD      B,A                  ;"
                //11BC: 13              INC     DE                   ;
                //11BD: 05              DEC     B                    ;
                //11BE: C2 B4 11        JP      NZ,$11B4            ; "
                //11C1: 06 08           LD      B,$08                ;"
                //11C3: 21 12 30        LD      HL,$3012            ;"
                //11C6: 11 40 13        LD      DE,$1340            ;"
                //11C9: D3 06           OUT     (WATCHDOG),A        ; "
                //11CB: C3 B4 11        JP      $11B4                ; 
                //11CE: CD 29 11        CALL    $1129                ; 
                //11D1: D3 06           OUT     (WATCHDOG),A        ; "
                //11D3: C9              RET                          ;
                //11D4: FF              RST     0X38                 ;
                //11D5: FF              RST     0X38                 ;
                //11D6: FF              RST     0X38                 ;
                //11D7: FF              RST     0X38                 ;
                //11D8: FF              RST     0X38                 ;
                //11D9: FF              RST     0X38                 ;
                //11DA: FF              RST     0X38                 ;
                //11DB: FF              RST     0X38                 ;
                //11DC: FF              RST     0X38                 ;
                //11DD: FF              RST     0X38                 ;
                //11DE: FF              RST     0X38                 ;
                //11DF: FF              RST     0X38                 ;
                //11E0: FF              RST     0X38                 ;
                //11E1: FF              RST     0X38                 ;
                //11E2: FF              RST     0X38                 ;
                //11E3: FF              RST     0X38                 ;
                //11E4: FF              RST     0X38                 ;
                //11E5: FF              RST     0X38                 ;
                //11E6: FF              RST     0X38                 ;
                //11E7: FF              RST     0X38                 ;
                //11E8: FF              RST     0X38                 ;
                //11E9: FF              RST     0X38                 ;
                //11EA: FF              RST     0X38                 ;
                //11EB: FF              RST     0X38                 ;
                //11EC: FF              RST     0X38                 ;
                //11ED: FF              RST     0X38                 ;
                //11EE: FF              RST     0X38                 ;
                //11EF: FF              RST     0X38                 ;
                //11F0: FF              RST     0X38                 ;
                //11F1: FF              RST     0X38                 ;
                //11F2: FF              RST     0X38                 ;
                //11F3: FF              RST     0X38                 ;
                //11F4: FF              RST     0X38                 ;
                //11F5: FF              RST     0X38                 ;
                //11F6: FF              RST     0X38                 ;
                //11F7: FF              RST     0X38                 ;
                //11F8: FF              RST     0X38                 ;
                //11F9: FF              RST     0X38                 ;
                //11FA: FF              RST     0X38                 ;
                //11FB: FF              RST     0X38                 ;
                //11FC: FF              RST     0X38                 ;
                //11FD: FF              RST     0X38                 ;
                //11FE: FF              RST     0X38                 ;
                //11FF: FF              RST     0X38                 ;
                //1200: 00              NOP                          ;
                //1201: 70              LD      (HL),B              ;"
                //1202: 88              ADC     A,B                  ;"
                //1203: A8              XOR     B                    ;
                //1204: E8              RET     PE                   ;
                //1205: 68              LD      L,B                  ;"
                //1206: 08              EX      AF,AF'              ;"
                //1207: F0              RET     P                    ;
                //1208: 00              NOP                          ;
                //1209: 20 50           JR      NZ,$125B            ; "
                //120B: 88              ADC     A,B                  ;"
                //120C: 88              ADC     A,B                  ;"
                //120D: F8              RET     M                    ;
                //120E: 88              ADC     A,B                  ;"
                //120F: 88              ADC     A,B                  ;"
                //1210: 00              NOP                          ;
                //1211: 78              LD      A,B                  ;"
                //1212: 88              ADC     A,B                  ;"
                //1213: 88              ADC     A,B                  ;"
                //1214: 78              LD      A,B                  ;"
                //1215: 88              ADC     A,B                  ;"
                //1216: 88              ADC     A,B                  ;"
                //1217: 78              LD      A,B                  ;"
                //1218: 00              NOP                          ;
                //1219: 70              LD      (HL),B              ;"
                //121A: 88              ADC     A,B                  ;"
                //121B: 08              EX      AF,AF'              ;"
                //121C: 08              EX      AF,AF'              ;"
                //121D: 08              EX      AF,AF'              ;"
                //121E: 88              ADC     A,B                  ;"
                //121F: 70              LD      (HL),B              ;"
                //1220: 00              NOP                          ;
                //1221: 78              LD      A,B                  ;"
                //1222: 88              ADC     A,B                  ;"
                //1223: 88              ADC     A,B                  ;"
                //1224: 88              ADC     A,B                  ;"
                //1225: 88              ADC     A,B                  ;"
                //1226: 88              ADC     A,B                  ;"
                //1227: 78              LD      A,B                  ;"
                //1228: 00              NOP                          ;
                //1229: F8              RET     M                    ;
                //122A: 08              EX      AF,AF'              ;"
                //122B: 08              EX      AF,AF'              ;"
                //122C: 78              LD      A,B                  ;"
                //122D: 08              EX      AF,AF'              ;"
                //122E: 08              EX      AF,AF'              ;"
                //122F: F8              RET     M                    ;
                //1230: 00              NOP                          ;
                //1231: F8              RET     M                    ;
                //1232: 08              EX      AF,AF'              ;"
                //1233: 08              EX      AF,AF'              ;"
                //1234: 78              LD      A,B                  ;"
                //1235: 08              EX      AF,AF'              ;"
                //1236: 08              EX      AF,AF'              ;"
                //1237: 08              EX      AF,AF'              ;"
                //1238: 00              NOP                          ;
                //1239: F0              RET     P                    ;
                //123A: 08              EX      AF,AF'              ;"
                //123B: 08              EX      AF,AF'              ;"
                //123C: 08              EX      AF,AF'              ;"
                //123D: C8              RET     Z                    ;
                //123E: 88              ADC     A,B                  ;"
                //123F: F0              RET     P                    ;
                //1240: 00              NOP                          ;
                //1241: 88              ADC     A,B                  ;"
                //1242: 88              ADC     A,B                  ;"
                //1243: 88              ADC     A,B                  ;"
                //1244: F8              RET     M                    ;
                //1245: 88              ADC     A,B                  ;"
                //1246: 88              ADC     A,B                  ;"
                //1247: 88              ADC     A,B                  ;"
                //1248: 00              NOP                          ;
                //1249: 70              LD      (HL),B              ;"
                //124A: 20 20           JR      NZ,$126C            ; "
                //124C: 20 20           JR      NZ,$126E            ; "
                //124E: 20 70           JR      NZ,$12C0            ; "
                //1250: 00              NOP                          ;
                //1251: 80              ADD     A,B                  ;"
                //1252: 80              ADD     A,B                  ;"
                //1253: 80              ADD     A,B                  ;"
                //1254: 80              ADD     A,B                  ;"
                //1255: 80              ADD     A,B                  ;"
                //1256: 88              ADC     A,B                  ;"
                //1257: 70              LD      (HL),B              ;"
                //1258: 00              NOP                          ;
                //1259: 88              ADC     A,B                  ;"
                //125A: 48              LD      C,B                  ;"
                //125B: 28 18           JR      Z,$1275             ; "
                //125D: 28 48           JR      Z,$12A7             ; "
                //125F: 88              ADC     A,B                  ;"
                //1260: 00              NOP                          ;
                //1261: 08              EX      AF,AF'              ;"
                //1262: 08              EX      AF,AF'              ;"
                //1263: 08              EX      AF,AF'              ;"
                //1264: 08              EX      AF,AF'              ;"
                //1265: 08              EX      AF,AF'              ;"
                //1266: 08              EX      AF,AF'              ;"
                //1267: F8              RET     M                    ;
                //1268: 00              NOP                          ;
                //1269: 88              ADC     A,B                  ;"
                //126A: D8              RET     C                    ;
                //126B: A8              XOR     B                    ;
                //126C: A8              XOR     B                    ;
                //126D: 88              ADC     A,B                  ;"
                //126E: 88              ADC     A,B                  ;"
                //126F: 88              ADC     A,B                  ;"
                //1270: 00              NOP                          ;
                //1271: 88              ADC     A,B                  ;"
                //1272: 88              ADC     A,B                  ;"
                //1273: 98              SBC     B                    ;
                //1274: A8              XOR     B                    ;
                //1275: C8              RET     Z                    ;
                //1276: 88              ADC     A,B                  ;"
                //1277: 88              ADC     A,B                  ;"
                //1278: 00              NOP                          ;
                //1279: 70              LD      (HL),B              ;"
                //127A: 88              ADC     A,B                  ;"
                //127B: 88              ADC     A,B                  ;"
                //127C: 88              ADC     A,B                  ;"
                //127D: 88              ADC     A,B                  ;"
                //127E: 88              ADC     A,B                  ;"
                //127F: 70              LD      (HL),B              ;"
                //1280: 00              NOP                          ;
                //1281: 78              LD      A,B                  ;"
                //1282: 88              ADC     A,B                  ;"
                //1283: 88              ADC     A,B                  ;"
                //1284: 78              LD      A,B                  ;"
                //1285: 08              EX      AF,AF'              ;"
                //1286: 08              EX      AF,AF'              ;"
                //1287: 08              EX      AF,AF'              ;"
                //1288: 00              NOP                          ;
                //1289: 70              LD      (HL),B              ;"
                //128A: 88              ADC     A,B                  ;"
                //128B: 88              ADC     A,B                  ;"
                //128C: 88              ADC     A,B                  ;"
                //128D: A8              XOR     B                    ;
                //128E: 48              LD      C,B                  ;"
                //128F: B0              OR      B                    ;
                //1290: 00              NOP                          ;
                //1291: 78              LD      A,B                  ;"
                //1292: 88              ADC     A,B                  ;"
                //1293: 88              ADC     A,B                  ;"
                //1294: 78              LD      A,B                  ;"
                //1295: 28 48           JR      Z,$12DF             ; "
                //1297: 88              ADC     A,B                  ;"
                //1298: 00              NOP                          ;
                //1299: 70              LD      (HL),B              ;"
                //129A: 88              ADC     A,B                  ;"
                //129B: 08              EX      AF,AF'              ;"
                //129C: 70              LD      (HL),B              ;"
                //129D: 80              ADD     A,B                  ;"
                //129E: 88              ADC     A,B                  ;"
                //129F: 70              LD      (HL),B              ;"
                //12A0: 00              NOP                          ;
                //12A1: F8              RET     M                    ;
                //12A2: 20 20           JR      NZ,$12C4            ; "
                //12A4: 20 20           JR      NZ,$12C6            ; "
                //12A6: 20 20           JR      NZ,$12C8            ; "
                //12A8: 00              NOP                          ;
                //12A9: 88              ADC     A,B                  ;"
                //12AA: 88              ADC     A,B                  ;"
                //12AB: 88              ADC     A,B                  ;"
                //12AC: 88              ADC     A,B                  ;"
                //12AD: 88              ADC     A,B                  ;"
                //12AE: 88              ADC     A,B                  ;"
                //12AF: 70              LD      (HL),B              ;"
                //12B0: 00              NOP                          ;
                //12B1: 88              ADC     A,B                  ;"
                //12B2: 88              ADC     A,B                  ;"
                //12B3: 88              ADC     A,B                  ;"
                //12B4: 88              ADC     A,B                  ;"
                //12B5: 88              ADC     A,B                  ;"
                //12B6: 50              LD      D,B                  ;"
                //12B7: 20 00           JR      NZ,$12B9            ; "
                //12B9: 88              ADC     A,B                  ;"
                //12BA: 88              ADC     A,B                  ;"
                //12BB: 88              ADC     A,B                  ;"
                //12BC: A8              XOR     B                    ;
                //12BD: A8              XOR     B                    ;
                //12BE: D8              RET     C                    ;
                //12BF: 88              ADC     A,B                  ;"
                //12C0: 00              NOP                          ;
                //12C1: 88              ADC     A,B                  ;"
                //12C2: 88              ADC     A,B                  ;"
                //12C3: 50              LD      D,B                  ;"
                //12C4: 20 50           JR      NZ,$1316            ; "
                //12C6: 88              ADC     A,B                  ;"
                //12C7: 88              ADC     A,B                  ;"
                //12C8: 00              NOP                          ;
                //12C9: 88              ADC     A,B                  ;"
                //12CA: 88              ADC     A,B                  ;"
                //12CB: 50              LD      D,B                  ;"
                //12CC: 20 20           JR      NZ,$12EE            ; "
                //12CE: 20 20           JR      NZ,$12F0            ; "
                //12D0: 00              NOP                          ;
                //12D1: F8              RET     M                    ;
                //12D2: 80              ADD     A,B                  ;"
                //12D3: 40              LD      B,B                  ;"
                //12D4: 20 10           JR      NZ,$12E6            ; "
                //12D6: 08              EX      AF,AF'              ;"
                //12D7: F8              RET     M                    ;
                //12D8: 00              NOP                          ;
                //12D9: 70              LD      (HL),B              ;"
                //12DA: 88              ADC     A,B                  ;"
                //12DB: C8              RET     Z                    ;
                //12DC: A8              XOR     B                    ;
                //12DD: 98              SBC     B                    ;
                //12DE: 88              ADC     A,B                  ;"
                //12DF: 70              LD      (HL),B              ;"
                //12E0: 00              NOP                          ;
                //12E1: 20 30           JR      NZ,$1313            ; "
                //12E3: 20 20           JR      NZ,$1305            ; "
                //12E5: 20 20           JR      NZ,$1307            ; "
                //12E7: 70              LD      (HL),B              ;"
                //12E8: 00              NOP                          ;
                //12E9: 70              LD      (HL),B              ;"
                //12EA: 88              ADC     A,B                  ;"
                //12EB: 80              ADD     A,B                  ;"
                //12EC: 60              LD      H,B                  ;"
                //12ED: 10 08           DJNZ    $12F7                ; 
                //12EF: F8              RET     M                    ;
                //12F0: 00              NOP                          ;
                //12F1: F8              RET     M                    ;
                //12F2: 80              ADD     A,B                  ;"
                //12F3: 40              LD      B,B                  ;"
                //12F4: 60              LD      H,B                  ;"
                //12F5: 80              ADD     A,B                  ;"
                //12F6: 88              ADC     A,B                  ;"
                //12F7: 70              LD      (HL),B              ;"
                //12F8: 00              NOP                          ;
                //12F9: 40              LD      B,B                  ;"
                //12FA: 60              LD      H,B                  ;"
                //12FB: 50              LD      D,B                  ;"
                //12FC: 48              LD      C,B                  ;"
                //12FD: F8              RET     M                    ;
                //12FE: 40              LD      B,B                  ;"
                //12FF: 40              LD      B,B                  ;"
                //1300: 00              NOP                          ;
                //1301: F8              RET     M                    ;
                //1302: 08              EX      AF,AF'              ;"
                //1303: 78              LD      A,B                  ;"
                //1304: 80              ADD     A,B                  ;"
                //1305: 80              ADD     A,B                  ;"
                //1306: 88              ADC     A,B                  ;"
                //1307: 70              LD      (HL),B              ;"
                //1308: 00              NOP                          ;
                //1309: E0              RET     PO                   ;
                //130A: 10 08           DJNZ    $1314                ; 
                //130C: 78              LD      A,B                  ;"
                //130D: 88              ADC     A,B                  ;"
                //130E: 88              ADC     A,B                  ;"
                //130F: 70              LD      (HL),B              ;"
                //1310: 00              NOP                          ;
                //1311: F8              RET     M                    ;
                //1312: 80              ADD     A,B                  ;"
                //1313: 40              LD      B,B                  ;"
                //1314: 20 10           JR      NZ,$1326            ; "
                //1316: 10 10           DJNZ    $1328                ; 
                //1318: 00              NOP                          ;
                //1319: 70              LD      (HL),B              ;"
                //131A: 88              ADC     A,B                  ;"
                //131B: 88              ADC     A,B                  ;"
                //131C: 70              LD      (HL),B              ;"
                //131D: 88              ADC     A,B                  ;"
                //131E: 88              ADC     A,B                  ;"
                //131F: 70              LD      (HL),B              ;"
                //1320: 00              NOP                          ;
                //1321: 70              LD      (HL),B              ;"
                //1322: 88              ADC     A,B                  ;"
                //1323: 88              ADC     A,B                  ;"
                //1324: F0              RET     P                    ;
                //1325: 80              ADD     A,B                  ;"
                //1326: 40              LD      B,B                  ;"
                //1327: 38 00           JR      C,$1329             ; "
                //1329: 20 A8           JR      NZ,$12D3            ; "
                //132B: 70              LD      (HL),B              ;"
                //132C: 20 70           JR      NZ,$139E            ; "
                //132E: A8              XOR     B                    ;
                //132F: 20 00           JR      NZ,$1331            ; "
                //1331: 10 20           DJNZ    $1353                ; 
                //1333: 40              LD      B,B                  ;"
                //1334: 80              ADD     A,B                  ;"
                //1335: 40              LD      B,B                  ;"
                //1336: 20 10           JR      NZ,$1348            ; "
                //1338: 00              NOP                          ;
                //1339: 00              NOP                          ;
                //133A: 00              NOP                          ;
                //133B: 00              NOP                          ;
                //133C: 00              NOP                          ;
                //133D: 00              NOP                          ;
                //133E: 00              NOP                          ;
                //133F: 20 00           JR      NZ,$1341            ; "
                //1341: 00              NOP                          ;
                //1342: 00              NOP                          ;
                //1343: 00              NOP                          ;
                //1344: 00              NOP                          ;
                //1345: 00              NOP                          ;
                //1346: 00              NOP                          ;
                //1347: 00              NOP                          ;
                //1348: 26 0F           LD      H,$0F                ;"
                //134A: 0B              DEC     BC                   ;
                //134B: 28 01           JR      Z,$134E             ; "
                //134D: 0C              INC     C                    ;
                //134E: 0C              INC     C                    ;
                //134F: 28 12           JR      Z,$1363             ; "
                //1351: 01 0D 13        LD      BC,$130D            ;"
                //1354: 28 26           JR      Z,$137C             ; "
                //1356: 03              INC     BC                   ;
                //1357: 08              EX      AF,AF'              ;"
                //1358: 05              DEC     B                    ;
                //1359: 03              INC     BC                   ;
                //135A: 0B              DEC     BC                   ;
                //135B: 28 09           JR      Z,$1366             ; "
                //135D: 0E 10           LD      C,$10                ;"
                //135F: 0F              RRCA                         ;
                //1360: 12              LD      (DE),A              ;"
                //1361: 14              INC     D                    ;
                //1362: 26 03           LD      H,$03                ;"
                //1364: 08              EX      AF,AF'              ;"
                //1365: 05              DEC     B                    ;
                //1366: 03              INC     BC                   ;
                //1367: 0B              DEC     BC                   ;
                //1368: 28 13           JR      Z,$137D             ; "
                //136A: 0F              RRCA                         ;
                //136B: 15              DEC     D                    ;
                //136C: 0E 04           LD      C,$04                ;"
                //136E: 28 10           JR      Z,$1380             ; "
                //1370: 0F              RRCA                         ;
                //1371: 12              LD      (DE),A              ;"
                //1372: 14              INC     D                    ;
                //1373: 1C              INC     E                    ;
                //1374: 28 28           JR      Z,$139E             ; "
                //1376: 1B              DEC     DE                   ;
                //1377: 1C              INC     E                    ;
                //1378: 1D              DEC     E                    ;
                //1379: 1E 1F           LD      E,$1F                ;"
                //137B: 20 21           JR      NZ,$139E            ; "
                //137D: 22 25 15        LD      ($1525),HL          ; "
                //1380: 06 0F           LD      B,$0F                ;"
                //1382: 27              DAA                          ;
                //1383: 06 25           LD      B,$25                ;"
                //1385: 0D              DEC     C                    ;
                //1386: 09              ADD     HL,BC                ;"
                //1387: 13              INC     DE                   ;
                //1388: 13              INC     DE                   ;
                //1389: 0C              INC     C                    ;
                //138A: 25              DEC     H                    ;
                //138B: 0C              INC     C                    ;
                //138C: 01 15 27        LD      BC,$2715            ;"
                //138F: 08              EX      AF,AF'              ;"
                //1390: 25              DEC     H                    ;
                //1391: 09              ADD     HL,BC                ;"
                //1392: 0E 16           LD      C,$16                ;"
                //1394: 27              DAA                          ;
                //1395: 08              EX      AF,AF'              ;"
                //1396: 25              DEC     H                    ;
                //1397: 05              DEC     B                    ;
                //1398: 18 14           JR      $13AE                ; 
                //139A: 12              LD      (DE),A              ;"
                //139B: 01 25 09        LD      BC,$0925            ;"
                //139E: 0E 16           LD      C,$16                ;"
                //13A0: 27              DAA                          ;
                //13A1: 1C              INC     E                    ;
                //13A2: 25              DEC     H                    ;
                //13A3: 09              ADD     HL,BC                ;"
                //13A4: 0E 16           LD      C,$16                ;"
                //13A6: 27              DAA                          ;
                //13A7: 1D              DEC     E                    ;
                //13A8: 25              DEC     H                    ;
                //13A9: 09              ADD     HL,BC                ;"
                //13AA: 0E 16           LD      C,$16                ;"
                //13AC: 27              DAA                          ;
                //13AD: 1E 25           LD      E,$25                ;"
                //13AF: 09              ADD     HL,BC                ;"
                //13B0: 0E 16           LD      C,$16                ;"
                //13B2: 27              DAA                          ;
                //13B3: 1F              RRA                          ;
                //13B4: 25              DEC     H                    ;
                //13B5: 15              DEC     D                    ;
                //13B6: 06 0F           LD      B,$0F                ;"
                //13B8: 27              DAA                          ;
                //13B9: 08              EX      AF,AF'              ;"
                //13BA: 25              DEC     H                    ;
                //13BB: 16 09           LD      D,$09                ;"
                //13BD: 04              INC     B                    ;
                //13BE: 27              DAA                          ;
                //13BF: 12              LD      (DE),A              ;"
                //13C0: 20 50           JR      NZ,$1412            ; "
                //13C2: 88              ADC     A,B                  ;"
                //13C3: 88              ADC     A,B                  ;"
                //13C4: F8              RET     M                    ;
                //13C5: 88              ADC     A,B                  ;"
                //13C6: 88              ADC     A,B                  ;"
                //13C7: 00              NOP                          ;
                //13C8: 78              LD      A,B                  ;"
                //13C9: 88              ADC     A,B                  ;"
                //13CA: 88              ADC     A,B                  ;"
                //13CB: 78              LD      A,B                  ;"
                //13CC: 88              ADC     A,B                  ;"
                //13CD: 88              ADC     A,B                  ;"
                //13CE: 78              LD      A,B                  ;"
                //13CF: 00              NOP                          ;
                //13D0: 70              LD      (HL),B              ;"
                //13D1: 88              ADC     A,B                  ;"
                //13D2: 08              EX      AF,AF'              ;"
                //13D3: 08              EX      AF,AF'              ;"
                //13D4: 08              EX      AF,AF'              ;"
                //13D5: 88              ADC     A,B                  ;"
                //13D6: 70              LD      (HL),B              ;"
                //13D7: 00              NOP                          ;
                //13D8: 70              LD      (HL),B              ;"
                //13D9: 90              SUB     B                    ;
                //13DA: 90              SUB     B                    ;
                //13DB: 90              SUB     B                    ;
                //13DC: 90              SUB     B                    ;
                //13DD: 90              SUB     B                    ;
                //13DE: 70              LD      (HL),B              ;"
                //13DF: 00              NOP                          ;
                //13E0: E0              RET     PO                   ;
                //13E1: 20 20           JR      NZ,$1403            ; "
                //13E3: E0              RET     PO                   ;
                //13E4: 20 20           JR      NZ,$1406            ; "
                //13E6: E0              RET     PO                   ;
                //13E7: 00              NOP                          ;
                //13E8: 3E 02           LD      A,$02                ;"
                //13EA: 02              LD      (BC),A              ;"
                //13EB: 1E 02           LD      E,$02                ;"
                //13ED: 02              LD      (BC),A              ;"
                //13EE: 02              LD      (BC),A              ;"
                //13EF: 00              NOP                          ;
                //13F0: 3C              INC     A                    ;
                //13F1: 02              LD      (BC),A              ;"
                //13F2: 02              LD      (BC),A              ;"
                //13F3: 02              LD      (BC),A              ;"
                //13F4: 32 22 3C     ;LD    ($3C22),A          ;"
                //13F7: 00              NOP                          ;
                //13F8: 22 22 22        LD      (+22),HL            ; "
                //13FB: 3E 22           LD      A,$22                ;"
                //13FD: 22 22 00     ;LD    ($0022),HL         ;"
                //
                //
                //;1000: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1020: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1040: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1060: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1080: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;10A0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;10C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;10E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1100: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1120: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1140: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1160: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1180: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;11A0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;11C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;11E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1200: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1220: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1240: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1260: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1280: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;12A0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;12C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;12E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1300: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1320: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1340: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1360: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;1380: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;13A0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;13C0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //;13E0: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                //

DrawPlayerShotCollison:
lda #%00101100      //playershot collsion mask 0010?
sta drawShotMask
bra DrawPlayerShot1

DrawPlayerShot:                //DrawShiftedSprite:
                //; The only differences between this and EraseSimpleSprite is two CPL instructions in the latter and
                //; the use of AND instead of OR. NOP takes the same amount of time/space as CPL. So the two NOPs
                //; here make these two parallel routines the same size and speed.
                //;
                //HL is position ( x/y??
                //BC = $1000 . 16 lines. dont need!
                //; Draw sprite at [DE] to screen at pixel position in HL
                //; The hardware shift register is used in converting pixel positions
                //; to screen coordinates.
lda #%00001100      //playershot collsion mask 0000? disabled
sta drawShotMask


DrawPlayerShot1:
addressRegister(0,$1fc00+(60*8),1,0)  //point to sprite number based on currentalien
lda SpriteArray.addressTableLo+14
sta VERADATA0
lda SpriteArray.addressTableHi+14
sta VERADATA0
lda HL //gamevars8080.splashXr
clc
adc #$30
sta VERADATA0
lda #$00
adc #$00
sta VERADATA0
lda HL+1   //gamevars8080.splashYr
sta VERADATA0
stz VERADATA0
lda drawShotMask: #$00   //#%00001100
sta VERADATA0
lda #%00000000  //8*8
sta VERADATA0
stz gamevars8080.collision
rts                //15F2: C9              RET                          ; Done


                //1400: 00              NOP                          ; Time/size pad to match CPL in EraseShiftedSprite
                //1401: CD 74 14        CALL    CnvtPixNumber       ; Convert pixel number to coord and shift
                //1404: 00              NOP                          ; Time/size pad to match CPL in EraseShiftedSprite
                //1405: C5              PUSH    BC                   ; Hold count
                //1406: E5              PUSH    HL                   ; Hold start coordinate
                //1407: 1A              LD      A,(DE)              ; Get the picture bits"
                //1408: D3 04           OUT     (SHFT_DATA),A       ; Store in shift register"
                //140A: DB 03           IN      A,(SHFT_IN)         ; Read the shifted pixels"
                //140C: B6              OR      (HL)                 ; OR them onto the screen
                //140D: 77              LD      (HL),A              ; Store them back to screen"
                //140E: 23              INC     HL                   ; Next colummn on screen
                //140F: 13              INC     DE                   ; Next in picture
                //1410: AF              XOR     A                    ; Shift over ...
                //1411: D3 04           OUT     (SHFT_DATA),A       ; ... to next byte in register (shift in 0)"
                //1413: DB 03           IN      A,(SHFT_IN)         ; Read the shifted pixels"
                //1415: B6              OR      (HL)                 ; OR them onto the screen
                //1416: 77              LD      (HL),A              ; Store them back to screen"
                //1417: E1              POP     HL                   ; Restore starting coordinate
                //1418: 01 20 00        LD      BC,$0020            ; Add 32 ..."
                //141B: 09              ADD     HL,BC                ; ... to coordinate (move to next row)"
                //141C: C1              POP     BC                   ; Restore count
                //141D: 05              DEC     B                    ; All done?
                //141E: C2 05 14        JP      NZ,$1405            ; No ... go do all rows"
                //1421: C9              RET                          ; Done
                //
                //1422: 00 00 ; ** Why?
                //
                //EraseSimpleSprite:
                //; Clear a sprite from the screen (standard pixel number descriptor).
                //; ** We clear 2 bytes even though the draw-simple only draws one.
                //1424: CD 74 14        CALL    CnvtPixNumber       ; Convert pixel number in HL
                //1427: C5              PUSH    BC                   ; Hold
                //1428: E5              PUSH    HL                   ; Hold
                //1429: AF              XOR     A                    ; 0
                //142A: 77              LD      (HL),A              ; Clear screen byte"
                //142B: 23              INC     HL                   ; Next byte
                //142C: 77              LD      (HL),A              ; Clear byte"
                //142D: 23              INC     HL                   ; ** Is this to mimic timing? We increment then pop
                //142E: E1              POP     HL                   ; Restore screen coordinate
                //142F: 01 20 00        LD      BC,$0020            ; Add 1 row ..."
                //1432: 09              ADD     HL,BC                ; ... to screen coordinate"
                //1433: C1              POP     BC                   ; Restore counter
                //1434: 05              DEC     B                    ; All rows done?
                //1435: C2 27 14        JP      NZ,$1427            ; Do all rows"
                //1438: C9              RET                          ; out
                //
                //DrawSimpSprite:
                //; Display character to screen
                //; HL = screen coordinates
                //; DE = character data
                //; B = number of rows
                //1439: C5              PUSH    BC                   ; Preserve counter
                //143A: 1A              LD      A,(DE)              ; From character set ..."
                //143B: 77              LD      (HL),A              ; ... to screen"
                //143C: 13              INC     DE                   ; Next in character set
                //143D: 01 20 00        LD      BC,$0020            ; Next row ..."
                //1440: 09              ADD     HL,BC                ; ... on screen"
                //1441: C1              POP     BC                   ; Restore counter
                //1442: 05              DEC     B                    ; Decrement counter
                //1443: C2 39 14        JP      NZ,DrawSimpSprite   ; Do all"
                //1446: C9              RET                          ; Out
                //
                //1447: 00 00 00 00 00 00 00 00 00 00 00 ; ** Why?
                //                         
EraseShifted:                //EraseShifted:
break()                //; Erases a shifted sprite from screen (like for player's explosion)
                //1452: CD 74 14        CALL    CnvtPixNumber       ; Convert pixel number in HL to coorinates with shift
                //1455: C5              PUSH    BC                   ; Hold BC
                //1456: E5              PUSH    HL                   ; Hold coordinate
                //1457: 1A              LD      A,(DE)              ; Get picture value"
                //1458: D3 04           OUT     (SHFT_DATA),A       ; Value into shift register"
                //145A: DB 03           IN      A,(SHFT_IN)         ; Read shifted sprite picture"
                //145C: 2F              CPL                          ; Reverse it (erasing bits)
                //145D: A6              AND     (HL)                 ; Erase the bits from the screen
                //145E: 77              LD      (HL),A              ; Store the erased pattern back"
                //145F: 23              INC     HL                   ; Next column on screen
                //1460: 13              INC     DE                   ; Next in image
                //1461: AF              XOR     A                    ; Shift register over ...
                //1462: D3 04           OUT     (SHFT_DATA),A       ; ... 8 bits (shift in 0)"
                //1464: DB 03           IN      A,(SHFT_IN)         ; Read 2nd byte of image"
                //1466: 2F              CPL                          ; Reverse it (erasing bits)
                //1467: A6              AND     (HL)                 ; Erase the bits from the screen
                //1468: 77              LD      (HL),A              ; Store the erased pattern back"
                //1469: E1              POP     HL                   ; Restore starting coordinate
                //146A: 01 20 00        LD      BC,$0020            ; Add 32 ..."
                //146D: 09              ADD     HL,BC                ; ... to next row"
                //146E: C1              POP     BC                   ; Restore BC (count)
                //146F: 05              DEC     B                    ; All rows done?
                //1470: C2 55 14        JP      NZ,$1455            ; No ... erase all"
rts                //1473: C9              RET                          ; Done
                //
                //CnvtPixNumber:
                //; Convert pixel number in HL to screen coordinate and shift amount.
                //; HL gets screen coordinate.
                //; Hardware shift-register gets amount.
                //1474: 7D              LD      A,L                  ; Get X coordinate"
                //1475: E6 07           AND     $07                  ; Shift by pixel position
                //1477: D3 02           OUT     (SHFTAMNT),A        ; Write shift amount to hardware"
                //1479: C3 47 1A        JP      ConvToScr           ; HL = HL/8 + 2000 (screen coordinate)
                //
                //RememberShields:
                //; In a multi-player game the player's shields are block-copied to and from RAM between turns.
                //; HL = screen pointer
                //; DE = memory buffer
                //; B = number of rows
                //; C = number of columns
                //147C: C5              PUSH    BC                   ; Hold counter
                //147D: E5              PUSH    HL                   ; Hold start
                //147E: 7E              LD      A,(HL)              ; From sprite ... (should be DE)"
                //147F: 12              LD      (DE),A              ; ... to screen ... (should be HL)"
                //1480: 13              INC     DE                   ; Next in sprite
                //1481: 23              INC     HL                   ; Next on screen
                //1482: 0D              DEC     C                    ; All columns done?
                //1483: C2 7E 14        JP      NZ,$147E            ; No ... do multi columns"
                //1486: E1              POP     HL                   ; Restore screen start
                //1487: 01 20 00        LD      BC,$0020            ; Add 32 ..."
                //148A: 09              ADD     HL,BC                ; ... to get to next row"
                //148B: C1              POP     BC                   ; Pop the counters
                //148C: 05              DEC     B                    ; All rows done?
                //148D: C2 7C 14        JP      NZ,RememberShields  ; No ... do multi rows"
                //1490: C9              RET                          ; Done
                //
DrawSprCollision:                //DrawSprCollision:
break()                //1491: CD 74 14        CALL    CnvtPixNumber       ; Convert pixel number to coord and shift
                //1494: AF              XOR     A                    ; Clear the ...
                //1495: 32 61 20        LD      (collision),A       ; ... collision-detection flag"
                //1498: C5              PUSH    BC                   ; Hold count
                //1499: E5              PUSH    HL                   ; Hold screen
                //149A: 1A              LD      A,(DE)              ; Get byte"
                //149B: D3 04           OUT     (SHFT_DATA),A       ; Write first byte to shift register"
                //149D: DB 03           IN      A,(SHFT_IN)         ; Read shifted pattern"
                //149F: F5              PUSH    AF                   ; Hold the pattern
                //14A0: A6              AND     (HL)                 ; Any bits from pixel collide with bits on screen?
                //14A1: CA A9 14        JP      Z,$14A9             ; No ... leave flag alone"
                //14A4: 3E 01           LD      A,$01                ; Yes ... set ..."
                //14A6: 32 61 20        LD      (collision),A       ; ... collision flag"
                //14A9: F1              POP     AF                   ; Restore the pixel pattern
                //14AA: B6              OR      (HL)                 ; OR it onto the screen
                //14AB: 77              LD      (HL),A              ; Store new screen value"
                //14AC: 23              INC     HL                   ; Next byte on screen
                //14AD: 13              INC     DE                   ; Next in pixel pattern
                //14AE: AF              XOR     A                    ; Write zero ...
                //14AF: D3 04           OUT     (SHFT_DATA),A       ; ... to shift register"
                //14B1: DB 03           IN      A,(SHFT_IN)         ; Read 2nd half of shifted sprite"
                //14B3: F5              PUSH    AF                   ; Hold pattern
                //14B4: A6              AND     (HL)                 ; Any bits from pixel collide with bits on screen?
                //14B5: CA BD 14        JP      Z,$14BD             ; No ... leave flag alone"
                //14B8: 3E 01           LD      A,$01                ; Yes ... set ..."
                //14BA: 32 61 20        LD      (collision),A       ; ... collision flag"
                //14BD: F1              POP     AF                   ; Restore the pixel pattern
                //14BE: B6              OR      (HL)                 ; OR it onto the screen
                //14BF: 77              LD      (HL),A              ; Store new screen pattern"
                //14C0: E1              POP     HL                   ; Starting screen coordinate
                //14C1: 01 20 00        LD      BC,$0020            ; Add 32 ..."
                //14C4: 09              ADD     HL,BC                ; ... to get to next row"
                //14C5: C1              POP     BC                   ; Restore count
                //14C6: 05              DEC     B                    ; All done?
                //14C7: C2 98 14        JP      NZ,$1498            ; No ... do all rows"
                //14CA: C9              RET                          ; Done
                //
                //ClearSmallSprite:
                //; Clear a one byte sprite at HL. B=number of rows.
                //14CB: AF              XOR     A                    ; 0
                //14CC: C5              PUSH    BC                   ; Preserve BC
                //14CD: 77              LD      (HL),A              ; Clear screen byte"
                //14CE: 01 20 00        LD      BC,$0020            ; Bump HL ..."
                //14D1: 09              ADD     HL,BC                ; ... one screen row"
                //14D2: C1              POP     BC                   ; Restore
                //14D3: 05              DEC     B                    ; All done?
                //14D4: C2 CC 14        JP      NZ,$14CC            ; No ... clear all"
                //14D7: C9              RET                          
                //
PlayerShotHit:                //PlayerShotHit:
                //; The player's shot hit something (or is being removed from play)
                //;
lda gamevars8080.plyrShotStatus                //14D8: 3A 25 20        LD      A,(plyrShotStatus)  ; Player shot flag"
cmp #$05                //14DB: FE 05           CP      $05                  ; Alien explosion in progress?
beq PlayerShotHitExit                //14DD: C8              RET     Z                    ; Yes ... ignore this function
cmp #$02                //14DE: FE 02           CP      $02                  ; Normal movement?
beq PlayerSHotHit1                //14E0: C0              RET     NZ                   ; No ... out
PlayerShotHitExit:
rts                //;
PlayerSHotHit1:
lda gamevars8080.obj1CoorXr                //14E1: 3A 29 20        LD      A,(obj1CoorYr)      ; Get Yr coordinate of player shot"
tax
cmp #$19               //14E4: FE D8           CP      $D8                  ; Compare to 216 (40 from Top-rotated)
                //14E6: 47              LD      B,A                  ; Hold value for later"
bcc plyrShotHitOther                //14E7: D2 30 15        JP      NC,$1530            ; Yr is within 40 from top initiate miss-explosion (shot flag 3)"
lda gamevars8080.alienIsExploding                //14EA: 3A 02 20        LD      A,(alienIsExploding); Is an alien ..."
bne !+                //14ED: A7              AND     A                    ; ... blowing up?
rts                //14EE: C8              RET     Z                    ; No ... out
!:                //;
txa                //14EF: 78              LD      A,B                  ; Get original Yr coordinate back to A"
cmp #$30                //14F0: FE CE           CP      $CE                  ; Compare to 206 (50 from rotated top)
bcc hitSaucer                //14F2: D2 79 15        JP      NC,$1579            ; Yr is within 50 from top? Yes ... saucer must be hit"
                //14F5: C6 06           ADD     A,$06                ; Offset to coordinate for wider ""explosion" picture"
break()                //14F7: 47              LD      B,A                  ; Hold that"
rts //test for alien collison here                //14F8: 3A 09 20        LD      A,(refAlienYr)      ; Ref alien Y coordianate"
                //
                //; If the lower 4 rows are all empty then the reference alien's Y coordinate will wrap around from 0 to F8.
                //; At this point the top row of aliens is in the shields and we will assume that everything is within
                //; the rack.
                //
                //14FB: FE 90           CP      $90                  ; This is true if ...
                //14FD: D2 04 15        JP      NC,CodeBug1         ; ... aliens are down in the shields"
                //1500: B8              CP      B                    ; Compare to shot's coordinate
                //1501: D2 30 15        JP      NC,$1530            ; Outside the rack-square ... do miss explosion"
                //
                //CodeBug1:
                //;
                //; We get here if the player's shot hit something within the rack area (a shot or an alien).
                //; Find the alien that is (or would be) where the shot hit. If there is no alien alive at the row/column
                //; thn the player hit an alien missile. If there is an alien then explode the alien.
                //;
                //; There is a code bug here, but it is extremely subtle. The algorithm for finding the row/column in the"
                //; rack works by adding 16 to the reference coordinates (X for column, Y for row) until it passes or equals"
                //; the target coordinates. This works great as long as the target point is within the alien's rack area.
                //; If the reference point is far to the right, the column number will be greater than 11, which messes"
                //; up the column/row-to-pointer math.
                //;
                //; The entire rack of aliens is based on the lower left alien. Imagine all aliens are dead except the
                //; upper left. It wiggles down the screen and enters the players shields on the lower left where it begins
                //; to eat them. Imagine the player is under his own shields on the right side of the screen and fires a
                //; shot into his own shield.
                //;
                //; The alien is in the rack on row 4 (rows are numbered from bottom up starting with 0). The shot hits
                //; the shields below the alien's Y coordinate and gets correctly assigned to row 3. The alien is in the rack
                //; at column 0 (columns are numbered from left to right starting with 0). The shot hits the shields far to
                //; the right of the alien's X coordinate. The algorithm says it is in column 11. But 0-10 are the only
                //; correct values.
                //;
                //; The column/row-to-pointer math works by multiplying the row by 11 and adding the column. For the alien
                //; that is 11*4 + 0 = 44. For the shot that is 11*3 +11 = 44. The game thinks the shot hit the alien.
                //;
                //1504: 68              LD      L,B                  ; L now holds the shot coordinate (adjusted)"
                //1505: CD 62 15        CALL    FindRow             ; Look up row number to B
                //1508: 3A 2A 20        LD      A,(obj1CoorXr)      ; Player's shot's Xr coordinate ..."
                //150B: 67              LD      H,A                  ; ... to H"
                //150C: CD 6F 15        CALL    FindColumn          ; Get alien's coordinate
                //150F: 22 64 20        LD      (expAlienYr),HL     ; Put it in the exploding-alien descriptor"
                //1512: 3E 05           LD      A,$05                ; Flag alien explosion ..."
                //1514: 32 25 20        LD      (plyrShotStatus),A  ; ... in progress"
                //1517: CD 81 15        CALL    GetAlienStatPtr     ; Get descriptor for alien
                //151A: 7E              LD      A,(HL)              ; Is alien ..."
                //151B: A7              AND     A                    ; ... alive
                //151C: CA 30 15        JP      Z,$1530             ; No ... must have been an alien shot"
                //;
                //151F: 36 00           LD      (HL),$00            ; Make alien invader dead"
                //1521: CD 5F 0A        CALL    ScoreForAlien       ; Makes alien explosion sound and adjust score
                //1524: CD 3B 1A        CALL    ReadDesc            ; Load 5 byte sprite descriptor
                //1527: CD D3 15        CALL    DrawSprite          ; Draw explosion sprite on screen
                //152A: 3E 10           LD      A,$10                ; Initiate alien-explosion"
                //152C: 32 03 20        LD      (expAlienTimer),A   ; ... timer to 16"
                //152F: C9              RET                          ; Out
                //;
plyrShotHitOther:                //; Player shot leaving playfield, hitting shield, or hitting an alien shot"
lda #$03                //1530: 3E 03           LD      A,$03                ; Mark ..."
sta gamevars8080.plyrShotStatus                //1532: 32 25 20        LD      (plyrShotStatus),A  ; ... player shot hit something other than alien"
bra plyShotFinished                //1535: C3 4A 15        JP      $154A                ; Finish up
                //;
                //AExplodeTime:
                //; Time down the alien explosion. Remove when done.
AExplodeTime:
break()                //1538: 21 03 20        LD      HL,$2003            ; Decrement alien explosion ..."
                //153B: 35              DEC     (HL)                 ; ... timer
                //153C: C0              RET     NZ                   ; Not done  ... out
                //153D: 2A 64 20        LD      HL,(expAlienYr)     ; Pixel pointer for exploding alien"
                //1540: 06 10           LD      B,$10                ; 16 row pixel"
                //1542: CD 24 14        CALL    EraseSimpleSprite   ; Clear the explosion sprite from the screen
removePlayerShot:
lda #$04                //1545: 3E 04           LD      A,$04                ; 4 means that ..."
sta gamevars8080.plyrShotStatus                //1547: 32 25 20        LD      (plyrShotStatus),A  ; ... alien has exploded (remove from active duty)"
                //;
plyShotFinished:
stz gamevars8080.alienIsExploding                //154A: AF              XOR     A                    ; Turn off ...
                //154B: 32 02 20        LD      (alienIsExploding),A; ... alien-is-blowing-up flag"
                //154E: 06 F7           LD      B,$F7                ; Turn off ..."
rts                //1550: C3 DC 19        JP      SoundBits3Off       ; ... alien exploding sound
                //
                //64.7083333333333
                //    
                //Cnt16s:
                //; Count number of 16s needed to bring reference (in A) up to target (in H).
                //; If the reference starts out beyond the target then we add 16s as long as
                //; the reference has a signed bit. But these aren't signed quantities. This
                //; doesn't make any sense. This counting algorithm produces questionable
                //; results if the reference is beyond the target.
                //;
                //1554: 0E 00           LD      C,$00                ; Count of 16s"
                //1556: BC              CP      H                    ; Compare reference coordinate to target
                //1557: D4 90 15        CALL    NC,WrapRef          ; If reference is greater or equal then do something questionable ... see below"
                //155A: BC              CP      H                    ; Compare reference coordinate to target
                //155B: D0              RET     NC                   ; If reference is greater or equal then done
                //155C: C6 10           ADD     A,$10                ; Add 16 to reference"
                //155E: 0C              INC     C                    ; Bump 16s count
                //155F: C3 5A 15        JP      $155A                ; Keep testing
                //
                //FindRow:
                //; L contains a Yr coordinate. Find the row number within the rack that corresponds
                //; to the Yr coordinate. Return the row coordinate in L and the row number in C.
                //;
                //1562: 3A 09 20        LD      A,(refAlienYr)      ; Reference alien Yr coordinate"
                //1565: 65              LD      H,L                  ; Target Yr coordinate to H"
                //1566: CD 54 15        CALL    Cnt16s              ; Count 16s needed to bring ref alien to target
                //1569: 41              LD      B,C                  ; Count to B"
                //156A: 05              DEC     B                    ; Base 0
                //156B: DE 10           SBC     A,$10                ; The counting also adds 16 no matter what"
                //156D: 6F              LD      L,A                  ; To coordinate"
                //156E: C9              RET                          ; Done
                //
                //FindColumn:
                //; H contains a Xr coordinate. Find the column number within the rack that corresponds
                //; to the Xr coordinate. Return the column coordinate in H and the column number in C.
                //;
                //156F: 3A 0A 20        LD      A,(refAlienXr)      ; Reference alien Yn coordinate"
                //1572: CD 54 15        CALL    Cnt16s              ; Count 16s to bring Y to target Y
                //1575: DE 10           SBC     A,$10                ; Subtract off extra 16"
                //1577: 67              LD      H,A                  ; To H"
                //1578: C9              RET                          ; Done
                //
hitSaucer:
lda #$01                //1579: 3E 01           LD      A,$01                ; Mark flying ..."
sta gamevars8080.saucerHit                //157B: 32 85 20        LD      (saucerHit),A       ; ... saucer has been hit"
bra removePlayerShot                //157E: C3 45 15        JP      $1545                ; Remove player shot
                //
                //GetAlienStatPtr:
                //; B is row number. C is column number (starts at 1).
                //; Return pointer to alien-status flag for current player.
                //1581: 78              LD      A,B                  ; Hold original"
                //1582: 07              RLCA                         ; *2
                //1583: 07              RLCA                         ; *4
                //1584: 07              RLCA                         ; *8
                //1585: 80              ADD     A,B                  ; *9"
                //1586: 80              ADD     A,B                  ; *10"
                //1587: 80              ADD     A,B                  ; *11"
                //1588: 81              ADD     A,C                  ; Add row offset to column offset"
                //1589: 3D              DEC     A                    ; -1
                //158A: 6F              LD      L,A                  ; Set LSB of HL"
                //158B: 3A 67 20        LD      A,(playerDataMSB)   ; Set ..."
                //158E: 67              LD      H,A                  ; ... MSB of HL with active player indicator"
                //158F: C9              RET                          
                //
                //WrapRef:
                //; This is called if the reference point is greater than the target point. I believe the goal is to
                //; wrap the reference back around until it is lower than the target point. But the algorithm simply adds
                //; until the sign bit of the the reference is 0. If the target is 2 and the reference is 238 then this
                //; algorithm moves the reference 238+16=244 then 244+16=4. Then the algorithm stops. But the reference is
                //; STILL greater than the target.
                //;
                //; Also imagine that the target is 20 and the reference is 40. The algorithm adds 40+16=56, which is not"
                //; negative, so it stops there."
                //;
                //; I think the intended code is ""JP NC" instead of ""JP M"", but even that doesn't make sense."
                //;
                //1590: 0C              INC     C                    ; Increase 16s count
                //1591: C6 10           ADD     A,$10                ; Add 16 to ref"
                //1593: FA 90 15        JP      M,WrapRef           ; Keep going till result is positive"
                //1596: C9              RET                          ; Out
                //
RackBump:                //RackBump:
               //; When rack bumps the edge of the screen then the direction flips and the rack
                //; drops 8 pixels. The deltaX and deltaY values are changed here. Interestingly
                //; if there is only one alien left then the right value is 3 instead of the
                //; usual 2. The left direction is always -2.
    lda gamevars8080.rackDirection                //1597: 3A 0D 20        LD      A,(rackDirection)   ; Get rack direction"
                //159A: A7              AND     A                    ; Moving right?
    bne RackMovingLeft                //159B: C2 B7 15        JP      NZ,$15B7            ; No ... handle moving left"
    ldx #$00        //                //159E: 21 A4 3E        LD      HL,$3EA4            ; Line down the right edge of playfield"
NextMovingRight:                //;
    lda gamevars8080.EdgeCheckX,x                //15A1: CD C5 15        CALL    $15C5                ; Check line down the edge
    beq NextMovingRight2        // zero means no alien               //15A4: D0              RET     NC                   ; Nothing is there ... return
    txa                 
    jsr convtoRow       // conv alien num (0-54) in a to row number in y for Xpos limit 
    tya
    and #$fe        // now 0/2/4 in a for alien type
    clc
    adc #$c8        // add 200 , this is now X limit
    sta RBxLimit
    lda gamevars8080.EdgeCheckX,x              
    cmp RBxLimit: #$00
    bcs changeDir
NextMovingRight2:
    inx
    cpx #$37
    bne NextMovingRight
    rts            
    
    changeDir:
    ldy #$fe            //15A5: 06 FE           LD      B,$FE                ; Delta X of -2"
           //15A7: 3E 01           LD      A,$01                ; Rack now moving right"
    lda #$01            //;
    changeDir2:
    sta gamevars8080.rackDirection            //15A9: 32 0D 20        LD      (rackDirection),A   ; Set new rack direction"
                //15AC: 78              LD      A,B                  ; B has delta X"
    sty gamevars8080.refAlienDXr            //15AD: 32 08 20        LD      (refAlienDXr),A     ; Set new delta X"
    lda gamevars8080.rackDownDelta            //15B0: 3A 0E 20        LD      A,(rackDownDelta)   ; Set delta Y ..."
    sta gamevars8080.refAlienDYr            //15B3: 32 07 20        LD      (refAlienDYr),A     ; ... to drop rack by 8"
rts                //15B6: C9              RET                          ; Done
                //;

RackMovingLeft:
    ldx #$00                        //15B7: 21 24 25        LD      HL,$2524            ; Line down the left edge of playfield"
NextMovingLeft:                //;
    lda gamevars8080.EdgeCheckX,x                //15A1: CD C5 15        CALL    $15C5                ; Check line down the edge
    beq NextMovingLeft2        // zero means no alien               //15A4: D0              RET     NC                   ; Nothing is there ... return
    txa                 
    jsr convtoRow       // conv alien num (0-54) in a to row number in y for Xpos limit 
    tya
    lsr         // divide 2 = 0,0,1,1,2
    eor #$ff    //  now -1,-1,-2,-2,-3
    clc
    adc #$9        // add 8 gives 8,8,7,7,6 as X limit
    sta RBxLimitLeft
    lda gamevars8080.EdgeCheckX,x              
    cmp RBxLimitLeft: #$00
    bcc changeDirL
NextMovingLeft2:
    inx
    cpx #$37
    bne NextMovingLeft
    rts            
    
    changeDirL:
    ldy #$02            //18F1: 06 02           LD      B,$02                ; Rack moving right delta X"
    lda gamevars8080.numAliens            //18F3: 3A 82 20        LD      A,(numAliens)       ; Number of aliens on screen"
    dec            //18F6: 3D              DEC     A                    ; Just one left?
    bne ChangeDirL1            //18F7: C0              RET     NZ                   ; No ... use right delta X of 2
    iny            //18F8: 04              INC     B                    ; Just one alien ... move right at 3 instead of 2
    ChangeDirL1:
    lda #$00            //15C1: AF              XOR     A                    ; Rack now moving left
    bra changeDir2            //15C2: C3 A9 15        JP      $15A9                ; Set rack direction

                //    
convtoRow:      //a = alien num, return y = row
ldy #$ff
convToRow1:
iny
sec
sbc #$0B //11
bcs convToRow1
rts

DrawSprite:                //DrawSprite:
                // gamevars8080.alienCurIndex is sprite number
//break()                // x is offset to image
                //HL is position (bits?) x/y??
                //BC = $1000 . 16 lines. dont need!
                //; Draw sprite at [DE] to screen at pixel position in HL
                //; The hardware shift register is used in converting pixel positions
                //; to screen coordinates.
//lda HL
//sta DE
//lda HL+1
//sta DE+1

lda #$fc-$b0
sta HL+1
lda gamevars8080.alienCurIndex
asl
asl
asl         // *8 to sprite address $1fc00 +a
bcc !+
inc HL+1    // carry if we went past 255 in L
!:
sta HL
addressRegisterByHL(0,1,1,0)  //point to sprite number based on currentalien
lda gamevars8080.alienCurIndex
jsr ConvToScrPixel  //puts sprite x/y in HL from alienrefx/y

lda SpriteArray.addressTableLo,x
sta VERADATA0
lda SpriteArray.addressTableHi,x
sta VERADATA0
lda HL+1 //gamevars8080.splashXr
clc
adc #$30
sta VERADATA0
lda #$00
adc #$00
sta VERADATA0
lda HL   //gamevars8080.splashYr
sta VERADATA0
stz VERADATA0
lda #%00001100
sta VERADATA0
lda #%00010000
sta VERADATA0
                //15D3: CD 74 14        CALL    CnvtPixNumber       ; Convert pixel number to screen/shift
                //15D6: E5              PUSH    HL                   ; Preserve screen coordinate
                //15D7: C5              PUSH    BC                   ; Hold for a second
                //15D8: E5              PUSH    HL                   ; Hold for a second
                //15D9: 1A              LD      A,(DE)              ; From sprite data"
                //15DA: D3 04           OUT     (SHFT_DATA),A       ; Write data to shift register"
                //15DC: DB 03           IN      A,(SHFT_IN)         ; Read back shifted amount"
                //15DE: 77              LD      (HL),A              ; Shifted sprite to screen"
                //15DF: 23              INC     HL                   ; Adjacent cell
                //15E0: 13              INC     DE                   ; Next in sprite data
                //15E1: AF              XOR     A                    ; 0
                //15E2: D3 04           OUT     (SHFT_DATA),A       ; Write 0 to shift register"
                //15E4: DB 03           IN      A,(SHFT_IN)         ; Read back remainder of previous"
                //15E6: 77              LD      (HL),A              ; Write remainder to adjacent"
                //15E7: E1              POP     HL                   ; Old screen coordinate
                //15E8: 01 20 00        LD      BC,$0020            ; Offset screen ..."
                //15EB: 09              ADD     HL,BC                ; ... to next row"
                //15EC: C1              POP     BC                   ; Restore count
                //15ED: 05              DEC     B                    ; All done?
                //15EE: C2 D7 15        JP      NZ,$15D7            ; No ... do all"
                //15F1: E1              POP     HL                   ; Restore HL
rts                //15F2: C9              RET                          ; Done
                //
CountAliens:                //CountAliens:
                //; Count number of aliens remaining in active game and return count 2082 holds the current count.
                //; If only 1, 206B gets a flag of 1 ** but ever nobody checks this"
jsr GetPlayerDataPtr                //15F3: CD 11 16        CALL    GetPlayerDataPtr    ; Get active player descriptor
ldy #0              //y = alien living counter              //15F6: 01 00 37        LD      BC,$3700            ; B=55 aliens to check?"
ldx #$37            // x = alien counter
CountLoop:
lda (HL)                //15F9: 7E              LD      A,(HL)              ; Get byte"
                //15FA: A7              AND     A                    ; Is it a zero?
beq CountAliens1                //15FB: CA FF 15        JP      Z,$15FF             ; Yes ... don't count it"
iny                //15FE: 0C              INC     C                    ; Count the live aliens
CountAliens1:
inc HL                //15FF: 23              INC     HL                   ; Next alien
dex                //1600: 05              DEC     B                    ; Count ...
bne CountLoop                //1601: C2 F9 15        JP      NZ,$15F9            ; ... all alien indicators"
                //1604: 79              LD      A,C                  ; Get the count"
sty gamevars8080.numAliens                //1605: 32 82 20        LD      (numAliens),A       ; Hold it"
                //1608: FE 01           CP      $01                  ; Just one?
                //160A: C0              RET     NZ                   ; No keep going
                //160B: 21 6B 20        LD      HL,$206B            ; Set flag if ..."  << this is never checked so pass
                //160E: 36 01           LD      (HL),$01            ; ... only one alien left"
rts                //1610: C9              RET                          ; Out
                //
GetPlayerDataPtr:                //GetPlayerDataPtr:
                //; Set HL with 2100 if player 1 is active or 2200 if player 2 is active
                //;
stz HL                //1611: 2E 00           LD      L,$00                ; Byte boundary"
lda gamevars8080.playerDataMSB                //1613: 3A 67 20        LD      A,(playerDataMSB)   ; Active player number"
sta HL+1                //1616: 67              LD      H,A                  ; Set HL to data"
rts                //1617: C9              RET                          ; Done
                //
PlrFireOrDemo:                //PlrFireOrDemo:
                //; Initiate player fire if button is pressed.
                //; Demo commands are parsed here if in demo mode
lda gamevars8080.playerAlive                //1618: 3A 15 20        LD      A,(playerAlive)     ; Is there an active player?"
cmp #$ff                //161B: FE FF           CP      $FF                  ; FF = alive
bne PlrFireOrDemoExit                //161D: C0              RET     NZ                   ; Player has been shot - no firing
                //161E: 21 10 20        LD      HL,$2010            ; Get player ..."
lda gamevars8080.obj0TimerMSB                //1621: 7E              LD      A,(HL)              ; ... task ..."
                //1622: 23              INC     HL                   ; ... timer ...
ora gamevars8080.obj0TimerLSB                //1623: 46              LD      B,(HL)              ; ... value"
                //1624: B0              OR      B                    ; Is the timer 0 (object active)?
bne PlrFireOrDemoExit                //1625: C0              RET     NZ                   ; No ... no firing till player object starts
lda gamevars8080.plyrShotStatus                //1626: 3A 25 20        LD      A,(plyrShotStatus)  ; Does the player have ..."
                //1629: A7              AND     A                    ; ... a shot on the screen?
bne PlrFireOrDemoExit                //162A: C0              RET     NZ                   ; Yes ... ignore
lda gamevars8080.gameMode                //162B: 3A EF 20        LD      A,(gameMode)        ; Are we in ..."
                //162E: A7              AND     A                    ; ... game mode?
beq demoConstantFire                //162F: CA 52 16        JP      Z,$1652             ; No ... in demo mode ... constant firing in demo"
lda gamevars8080.fireBounce                //1632: 3A 2D 20        LD      A,(fireBounce)      ; Is fire button ..."
                //1635: A7              AND     A                    ; ... being held down?
bne plrFireDebounce                //1636: C2 48 16        JP      NZ,$1648            ; Yes ... wait for bounce"
jsr ReadInputs                //1639: CD C0 17        CALL    ReadInputs          ; Read active player controls
and #$10                //163C: E6 10           AND     $10                  ; Fire-button pressed?
beq PlrFireOrDemoExit                //163E: C8              RET     Z                    ; No ... out
lda #$01                //163F: 3E 01           LD      A,$01                ; Flag"
sta gamevars8080.plyrShotStatus                //1641: 32 25 20        LD      (plyrShotStatus),A  ; Flag shot active"
sta gamevars8080.fireBounce                //1644: 32 2D 20        LD      (fireBounce),A      ; Flag that fire button is down"
PlrFireOrDemoExit:
rts                //1647: C9              RET                          ; Out
plrFireDebounce:
jsr ReadInputs                //1648: CD C0 17        CALL    ReadInputs          ; Read active player controls
and #$10                //164B: E6 10           AND     $10                  ; Fire-button pressed?
bne PlrFireOrDemoExit                //164D: C0              RET     NZ                   ; Yes ... ignore
sta gamevars8080.fireBounce                //164E: 32 2D 20        LD      (fireBounce),A      ; Else ... clear flag"
rts                //1651: C9              RET                          ; Out
                //; Handle demo (constant fire, parse demo commands)"
demoConstantFire:
lda gamevars8080.demoCmdPtrMSB                //1652: 21 25 20        LD      HL,$2025            ; Demo fires ..."
sta HL+1
lda #$01                //1655: 36 01           LD      (HL),$01            ; ... constantly"
sta gamevars8080.plyrShotStatus
lda gamevars8080.demoCmdPtrLSB                //1657: 2A ED 20        LD      HL,(demoCmdPtrLSB)  ; Demo command bufer"
inc                 //165A: 23              INC     HL                   ; Next position
                    //165B: 7D              LD      A,L                  ; Command buffer ..."
cmp #<_DemoCommands                //165C: FE 7E           CP      $7E                  ; ... wraps around
bcc DemoFire1                //165E: DA 63 16        JP      C,$1663             ; ... Buffer from 1F74 to 1F7E"
lda #<DemoCommands                //1661: 2E 74           LD      L,$74                ; ... overflow"
DemoFire1:
sta gamevars8080.demoCmdPtrLSB                //1663: 22 ED 20        LD      (demoCmdPtrLSB),HL  ; Next demo command"
sta HL
lda (HL)                //1666: 7E              LD      A,(HL)              ; Get next command"
sta gamevars8080.nextDemoCmd                //1667: 32 1D 20        LD      (nextDemoCmd),A     ; Set command for movement"
rts                //166A: C9              RET                          ; Done
                //
                //166B: 37              SCF                          ; Set carry flag
                //166C: C9              RET                          ; Done
GameOverCurPlayer:                //
lda #$00                //166D: AF              XOR     A                    ; 0
jsr updateShipCount                //166E: CD 8B 1A        CALL    $1A8B                ; Print ZERO ships remain

UpdateHighScore:
jsr CurPlyAlive                //1671: CD 10 19        CALL    CurPlyAlive         ; Get active-flag ptr for current player
lda #$00
sta (HL)                //1674: 36 00           LD      (HL),$00            ; Flag player is dead"
jsr getScoreDescActivePlyr                //1676: CD CA 09        CALL    $09CA                ; Get score descriptor for current player
inc HL                //1679: 23              INC     HL                   ; Point to high two digits
loadDE(gamevars8080.HiScorM)                //167A: 11 F5 20        LD      DE,$20F5            ; Current high score upper two digits"
lda (DE)                //167D: 1A              LD      A,(DE)              ; Is player score greater ..."
cmp (HL)                //167E: BE              CP      (HL)                 ; ... than high score?
php
dec DE                //167F: 1B              DEC     DE                   ; Point to LSB
dec HL                //1680: 2B              DEC     HL                   ; Point to LSB
lda (DE)                //1681: 1A              LD      A,(DE)              ; Go ahead and fetch high score lower two digits"
plp
beq checkLower2                //1682: CA 8B 16        JP      Z,$168B             ; Upper two are the same ... have to check lower two"
bcc noHighScore                //1685: D2 98 16        JP      NC,$1698            ; Player score is lower than high ... nothing to do"
bra copyScore                //1688: C3 8F 16        JP      $168F                ; Player socre is higher ... go copy the new high score
                //;
checkLower2:
cmp (HL)                //168B: BE              CP      (HL)                 ; Is lower digit higher? (upper was the same)
bcc noHighScore                //168C: D2 98 16        JP      NC,$1698            ; No ... high score is still greater than player's score"
copyScore:
lda (HL)                //168F: 7E              LD      A,(HL)              ; Copy the new ..."
sta (DE)                //1690: 12              LD      (DE),A              ; ... high score lower two digits"
inc DE                //1691: 13              INC     DE                   ; Point to MSB
inc HL                //1692: 23              INC     HL                   ; Point to MSB
lda (HL)                //1693: 7E              LD      A,(HL)              ; Copy the new ..."
sta (DE)                //1694: 12              LD      (DE),A              ; ... high score upper two digits"
jsr PrintHiScore                //1695: CD 50 19        CALL    PrintHiScore        ; Draw the new high score
noHighScore:
lda gamevars8080.twoPlayers                //1698: 3A CE 20        LD      A,(twoPlayers)      ; Number of players"
                //169B: A7              AND     A                    ; Is this a single player game?
beq endGame               //169C: CA C9 16        JP      Z,$16C9             ; Yes ... short message"
loadHL($1006)                //169F: 21 03 28        LD      HL,$2803            ; Screen coordinates"
loadDE(MessageGOver)                //16A2: 11 A6 1A        LD      DE,$1AA6            ; ""GAME OVER PLAYER< >"""
loadBC($0114)                //16A5: 0E 14           LD      C,$14                ; 20 characters"
jsr PrintMessageDel                //16A7: CD 93 0A        CALL    PrintMessageDel     ; Print message
dec HL+1                //16AA: 25              DEC     H                    ; Back up ...
dec HL+1                //16AB: 25              DEC     H                    ; ... to player indicator
loadBC($1b00)                //16AC: 06 1B           LD      B,$1B                ; ""1"""
lda gamevars8080.playerDataMSB                //16AE: 3A 67 20        LD      A,(playerDataMSB)   ; Player number"
ror                //16B1: 0F              RRCA                         ; Is this player 1?
bcs !+                //16B2: DA B7 16        JP      C,$16B7             ; Yes ... keep the digit"
inc BC+1                //16B5: 06 1C           LD      B,$1C                ; Else ... set digit 2"
!:
lda BC+1                //16B7: 78              LD      A,B                  ; To A"
jsr DrawChar                //16B8: CD FF 08        CALL    DrawChar            ; Print player number
jsr OneSecDelay                //16BB: CD B1 0A        CALL    OneSecDelay         ; Short delay
jsr currentPlayerAliveFlag                //16BE: CD E7 18        CALL    $18E7                ; Get current player ""alive" flag"
lda (HL)                //16C1: 7E              LD      A,(HL)              ; Is player ..."
                //16C2: A7              AND     A                    ; ... alive?
beq endGame                //16C3: CA C9 16        JP      Z,$16C9             ; No ... skip to ""GAME OVER" sequence"
jmp switchPlayers                //16C6: C3 ED 02        JP      $02ED                ; Switch players and game loop
                //;
endGame:
loadHL($2d18)                //16C9: 21 18 2D        LD      HL,$2D18            ; Screen coordinates"
loadDE(MessageGOver)                //16CC: 11 A6 1A        LD      DE,$1AA6            ; ""GAME OVER PLAYER< >"""
loadBC($010A)                //16CF: 0E 0A           LD      C,$0A                ; Just the ""GAME OVER" part"
jsr PrintMessageDel                //16D1: CD 93 0A        CALL    PrintMessageDel     ; Print message
jsr TwoSecDelay                //16D4: CD B6 0A        CALL    TwoSecDelay         ; Long delay
jsr ClearPlayField                //16D7: CD D6 09        CALL    ClearPlayField      ; Clear center window
                //16DA: AF              XOR     A                    ; Now in ...
stz gamevars8080.gameMode                //16DB: 32 EF 20        LD      (gameMode),A        ; ... demo mode"
                //16DE: D3 05           OUT     (SOUND2),A          ; All sound off"
jsr EnableGameTasks                //16E0: CD D1 19        CALL    EnableGameTasks     ; Enable ISR game tasks
jmp creditInfo                //16E3: C3 89 0B        JP      $0B89                ; Print credit information and do splash
                //
endOfRound:
ldx $100                //16E6: 31 00 24        LD      SP,$2400            ; Reset stack"
txs
cli                //16E9: FB              EI                           ; Enable interrupts
stz gamevars8080.playerAlive                //16EA: AF              XOR     A                    ; Flag ...
                //16EB: 32 15 20        LD      (playerAlive),A     ; ... player is shot"
jsr PlayerShotHit                //16EE: CD D8 14        CALL    PlayerShotHit       ; Player's shot collision detection
                //16F1: 06 04           LD      B,$04                ; Player has been hit ..."
                //16F3: CD FA 18        CALL    SoundBits3On        ; ... sound
                //16F6: CD 59 0A        CALL    $0A59                ; Has flag been set?
                //16F9: C2 EE 16        JP      NZ,$16EE            ; No ... wait for the flag"
stz gamevars8080.suspendPlay                //16FC: CD D7 19        CALL    DsableGameTasks     ; Disable ISR game tasks
loadHL($1d12)                //16FF: 21 01 27        LD      HL,$2701            ; Player's stash of ships"
jsr clearShipLives                //1702: CD FA 19        CALL    $19FA                ; Erase the stash of shps
lda #$00                //1705: AF              XOR     A                    ; Print ...
jsr updateShipCount                //1706: CD 8B 1A        CALL    $1A8B                ; ... a zero (number of ships)
                //
loadBC($fb00)                //1709: 06 FB           LD      B,$FB                ; Turn off ..."
jmp plyrShotSndOff                //170B: C3 6B 19        JP      $196B                ; ... player shot sound
                //
                //AShotReloadRate:
                //; Use the player's MSB to determine how fast the aliens reload their
                //; shots for another fire.
                //170E: CD CA 09        CALL    $09CA                ; Get score descriptor for active player
                //1711: 23              INC     HL                   ; MSB value
                //1712: 7E              LD      A,(HL)              ; Get the MSB value"
                //1713: 11 B8 1C        LD      DE,$1CB8            ; Score MSB table"
                //1716: 21 A1 1A        LD      HL,$1AA1            ; Corresponding fire reload rate table"
                //1719: 0E 04           LD      C,$04                ; Only 4 entries (a 5th value of 7 is used after that)"
                //171B: 47              LD      B,A                  ; Hold the score value"
                //171C: 1A              LD      A,(DE)              ; Get lookup from table"
                //171D: B8              CP      B                    ; Compare them
                //171E: D2 27 17        JP      NC,$1727            ; Equal or below ... use this table entry"
                //1721: 23              INC     HL                   ; Next ...
                //1722: 13              INC     DE                   ; ... entry in table
                //1723: 0D              DEC     C                    ; Do all ...
                //1724: C2 1C 17        JP      NZ,$171C            ; ... 4 entries in the tables"
                //1727: 7E              LD      A,(HL)              ; Load the shot reload value"
                //1728: 32 CF 20        LD      (aShotReloadRate),A ; Save the value for use in shot routine"
                //172B: C9              RET                          ; Done
                //
                //; Shot sound on or off depending on 2025
                //ShotSound:
                //172C: 3A 25 20        LD      A,(plyrShotStatus)  ; Player shot flag"
                //172F: FE 00           CP      $00                  ; Active shot?
                //1731: C2 39 17        JP      NZ,$1739            ; Yes ... go"
                //1734: 06 FD           LD      B,$FD                ; Sound mask"
                //1736: C3 DC 19        JP      SoundBits3Off       ; Mask off sound
                //;
                //1739: 06 02           LD      B,$02                ; Sound bit"
                //173B: C3 FA 18        JP      SoundBits3On        ; OR on sound
                //
                //173E: 00 00 ; ** Why?
                //
TimeFleetSound:                //TimeFleetSound:
                //; This called from the ISR times down the fleet and sets the flag at 2095 if
                //; the fleet needs a change in sound handling (new delay, new sound)"
dec gamevars8080.fleetSndHold                //1740: 21 9B 20        LD      HL,$209B            ; Pointer to hold time for fleet"
bne !+//1743: 35              DEC     (HL)                 ; Decrement hold time
jsr fleetMoveSoundOff               //1744: CC 6D 17        CALL    Z,$176D             ; If 0 turn fleet movement sound off"
!:
lda gamevars8080.playerOK                //1747: 3A 68 20        LD      A,(playerOK)        ; Is player OK?"
                //174A: A7              AND     A                    ; 1  means OK
beq fleetMoveSoundOff                //174B: CA 6D 17        JP      Z,$176D             ; Player not OK ... fleet movement sound off and out"
dec gamevars8080.fleetSndCnt                //174E: 21 96 20        LD      HL,$2096            ; Current time on fleet sound"
                //1751: 35              DEC     (HL)                 ; Count down
bne !exit+                //1752: C0              RET     NZ                   ; Not time to change sound ... out
lda gamevars8080.soundPort3                //1753: 21 98 20        LD      HL,$2098            ; Current sound port 3 value"
                //1756: 7E              LD      A,(HL)              ; Get value"
                //1757: D3 05           OUT     (SOUND2),A          ; Set sounds"
lda gamevars8080.numAliens                //1759: 3A 82 20        LD      A,(numAliens)       ; Number of aliens on active screen"
                //175C: A7              AND     A                    ; Is it zero?
beq fleetMoveSoundOff                //175D: CA 6D 17        JP      Z,$176D             ; Yes ... turn off fleet movement sound and out"
                //1760: 2B              DEC     HL                   ; (2097) Point to fleet timer reload
lda gamevars8080.fleetSndReload                //1761: 7E              LD      A,(HL)              ; Get fleet delay value"
                //1762: 2B              DEC     HL                   ; (2096) Point to fleet timer
sta gamevars8080.fleetSndCnt                //1763: 77              LD      (HL),A              ; Reload the timer"
                //1764: 2B              DEC     HL                   ; Point to change-sound
lda #$01                //1765: 36 01           LD      (HL),$01            ; (2095) time to change sound"
sta gamevars8080.changeFleetSnd
lda #$04                //1767: 3E 04           LD      A,$04                ; Set hold ..."
sta gamevars8080.fleetSndHold                //1769: 32 9B 20        LD      (fleetSndHold),A    ; ... time for fleet sound"
!exit:
rts                //176C: C9              RET                          ; Done
                //
fleetMoveSoundOff:
lda gamevars8080.soundPort5                //176D: 3A 98 20        LD      A,(soundPort5)      ; Current sound port 3 value"
and #$30                //1770: E6 30           AND     $30                  ; Mask off fleet movement sounds
                //1772: D3 05           OUT     (SOUND2),A          ; Set sounds"
rts                //1774: C9              RET                          ; Out
                //
                //FleetDelayExShip:
                //; This game-loop routine handles two sound functions. The routine does:
                //; 1) Time out the extra-ship awarded sound and turn it off when done
                //; 2) Load the fleet sound delay based on number of remaining aliens
                //; 3) Make the changing fleet sound
                //;
                //; The 2095 flag is set by the ISR and cleared here. The ISR does the timing and sets 2095 when it
                //; is time to make a new fleet sound.
                //;
                //1775: 3A 95 20        LD      A,(changeFleetSnd)  ; Time for new ..."
                //1778: A7              AND     A                    ; ... fleet movement sound?
                //1779: CA AA 17        JP      Z,$17AA             ; No ... skip to extra-man timing"
                //177C: 21 11 1A        LD      HL,$1A11            ; Number of aliens list coupled ..."
                //177F: 11 21 1A        LD      DE,$1A21            ; ... with delay list"
                //1782: 3A 82 20        LD      A,(numAliens)       ; Get the number of aliens on the screen"
                //1785: BE              CP      (HL)                 ; Compare it to the first list value
                //1786: D2 8E 17        JP      NC,$178E            ; Number of live aliens is higher than value ... use the delay"
                //1789: 23              INC     HL                   ; Move to ...
                //178A: 13              INC     DE                   ; ... next list value
                //178B: C3 85 17        JP      $1785                ; Find the right delay
                //178E: 1A              LD      A,(DE)              ; Get the delay from the second list"
                //178F: 32 97 20        LD      (fleetSndReload),A  ; Store the new alien sound delay"
                //1792: 21 98 20        LD      HL,$2098            ; Get current state ..."
                //1795: 7E              LD      A,(HL)              ; ... of sound port"
                //1796: E6 30           AND     $30                  ; Mask off all fleet movement sounds
                //1798: 47              LD      B,A                  ; Hold the value"
                //1799: 7E              LD      A,(HL)              ; Get current state"
                //179A: E6 0F           AND     $0F                  ; This time ONLY the fleet movement sounds
                //179C: 07              RLCA                         ; Shift next to next sound
                //179D: FE 10           CP      $10                  ; Overflow?
                //179F: C2 A4 17        JP      NZ,$17A4            ; No ... keep it"
                //17A2: 3E 01           LD      A,$01                ; Reset back to first sound"
                //17A4: B0              OR      B                    ; Add fleet sounds to current sound value
                //17A5: 77              LD      (HL),A              ; Store new sound value"
                //17A6: AF              XOR     A                    ; Restart ...
                //17A7: 32 95 20        LD      (changeFleetSnd),A  ; ... waiting on fleet time"
                //;
                //17AA: 21 99 20        LD      HL,$2099            ; Sound timer for award extra ship"
                //17AD: 35              DEC     (HL)                 ; Time expired?
                //17AE: C0              RET     NZ                   ; No ... leave sound playing
                //17AF: 06 EF           LD      B,$EF                ; Turn off bit set with #$10 (award extra ship)"
                //17B1: C3 DC 19        JP      SoundBits3Off       ; Stop sound and out
                //
                //SndOffExtPly:
                //17B4: 06 EF           LD      B,$EF                ; Mask off sound bit 4 (Extended play)"
                //17B6: 21 98 20        LD      HL,$2098            ; Current sound content"
                //17B9: 7E              LD      A,(HL)              ; Get current sound bits"
                //17BA: A0              AND     B                    ; Turn off extended play
                //17BB: 77              LD      (HL),A              ; Remember settings"
                //17BC: D3 05           OUT     (SOUND2),A          ; Turn off extended play"
                //17BE: C9              RET                          ; Out
                //
                //17BF: 00 ; ** Why?
                //
ReadInputs:                //ReadInputs:
                //; Read control inputs for active player
                //17C0: 3A 67 20        LD      A,(playerDataMSB)   ; Get active player"
                //17C3: 0F              RRCA                         ; Test player
                //17C4: D2 CA 17        JP      NC,$17CA            ; Player 2 ... read port 2"
                //17C7: DB 01           IN      A,(INP1)            ; Player 1 ... read port 1"
                //17C9: C9              RET                          ; Out
                //17CA: DB 02           IN      A,(INP2)            ; Get controls for player 2"
rts                //17CC: C9              RET                          ; Out
                //
                //; Check and handle TILT
                //CheckHandleTilt:
                //17CD: DB 02           IN      A,(INP2)            ; Read input port"
                //17CF: E6 04           AND     $04                  ; Tilt?
                //17D1: C8              RET     Z                    ; No tilt ... return
                //17D2: 3A 9A 20        LD      A,(tilt)            ; Already in TILT handle?"
                //17D5: A7              AND     A                    ; 1 = yes
                //17D6: C0              RET     NZ                   ; Yes ... ignore it now
                //17D7: 31 00 24        LD      SP,$2400            ; Reset stack"
                //17DA: 06 04           LD      B,$04                ; Do this 4 times"
                //17DC: CD D6 09        CALL    ClearPlayField      ; Clear center window
                //17DF: 05              DEC     B                    ; All done?
                //17E0: C2 DC 17        JP      NZ,$17DC            ; No ... do again"
                //17E3: 3E 01           LD      A,$01                ; Flag ..."
                //17E5: 32 9A 20        LD      (tilt),A            ; ... handling TILT"
                //17E8: CD D7 19        CALL    DsableGameTasks     ; Disable game tasks
                //17EB: FB              EI                           ; Re-enable interrupts
                //17EC: 11 BC 1C        LD      DE,$1CBC            ; Message ""TILT"""
                //17EF: 21 16 30        LD      HL,$3016            ; Center of screen"
                //17F2: 0E 04           LD      C,$04                ; Four letters"
                //17F4: CD 93 0A        CALL    PrintMessageDel     ; Print ""TILT"""
                //17F7: CD B1 0A        CALL    OneSecDelay         ; Short delay
                //17FA: AF              XOR     A                    ; Zero
                //17FB: 32 9A 20        LD      (tilt),A            ; TILT handle over"
                //17FE: 32 93 20        LD      (waitStartLoop),A   ; Back into splash screens"
                //1801: C3 C9 16        JP      $16C9                ; Handle game over for player
                //
                //CtrlSaucerSound:
                //1804: 21 84 20        LD      HL,$2084            ; Saucer on screen flag"
                //1807: 7E              LD      A,(HL)              ; Is the saucer ..."
                //1808: A7              AND     A                    ; ... on the screen?
                //1809: CA 07 07        JP      Z,$0707             ; No ... UFO sound off"
                //180C: 23              INC     HL                   ; Saucer hit flag
                //180D: 7E              LD      A,(HL)              ; (2085) Get saucer hit flag"
                //180E: A7              AND     A                    ; Is saucer in ""hit" sequence?"
                //180F: C0              RET     NZ                   ; Yes ... out
                //1810: 06 01           LD      B,$01                ; Retrigger saucer ..."
                //1812: C3 FA 18        JP      SoundBits3On        ; ... sound (retrigger makes it warble?)
                //  
DrawAdvTable:                //DrawAdvTable:
                //; Draw ""SCORE ADVANCE TABLE"""
loadHL($0f14)                //1815: 21 10 28        LD      HL,$2810            ; 0x410 is 1040 rotCol=32, rotRow=16"
loadDE(MessageAdv)                //1818: 11 A3 1C        LD      DE,$1CA3            ; ""*SCORE ADVANCE TABLE*"""
loadBC($0115)                //181B: 0E 15           LD      C,$15                ; 21 bytes in message"
jsr PrintMessage                //181D: CD F3 08        CALL    PrintMessage        ; Print message
lda #$0a                //1820: 3E 0A           LD      A,$0A                ; 10 bytes in every ""=xx POINTS" string"
sta gamevars8080.temp206C                //1822: 32 6C 20        LD      (temp206C),A        ; Hold the count"
loadBC(scoreImages)                //1825: 01 BE 1D        LD      BC,$1DBE            ; Coordinate/sprite for drawing table"
!next:
jsr ReadPriStruct                //1828: CD 56 18        CALL    ReadPriStruct       ; Get HL=coordinate, DE=image"
bcs advanceText                //182B: DA 37 18        JP      C,$1837             ; Move on if done"
lda DE                //182E: CD 44 18        CALL    $1844                ; Draw 16-byte sprite
jsr DrawChar
lda DE+1
jsr DrawChar
bra !next-                //1831: C3 28 18        JP      $1828                ; Do all in table
advanceText:                //;
jsr OneSecDelay               //1834: CD B1 0A        CALL    OneSecDelay         ; One second delay
loadBC(scoreTexts)                //1837: 01 CF 1D        LD      BC,$1DCF            ; Coordinate/message for drawing table"
!loop:
drawTable1:
jsr ReadPriStruct                //183A: CD 56 18        CALL    ReadPriStruct       ; Get HL=coordinate, DE=message"
bcs !exit+                //183D: D8              RET     C                    ; Out if done
jsr PrintAdvanceText                //183E: CD 4C 18        CALL    $184C                ; Print message
bra !loop-                //1841: C3 3A 18        JP      $183A                ; Do all in table
!exit:
rts
                //;
                //1844: C5              PUSH    BC                   ; Hold BC
                //1845: 06 10           LD      B,$10                ; 16 bytes"
                //1847: CD 39 14        CALL    DrawSimpSprite      ; Draw simple
                //184A: C1              POP     BC                   ; Restore BC
                //184B: C9              RET                          ; Out
                //;
PrintAdvanceText:
lda BC                //184C: C5              PUSH    BC                   ; Hold BC
sta PTR1
lda BC+1
sta PTR1+1
lda gamevars8080.temp206C                //184D: 3A 6C 20        LD      A,(temp206C)        ; Count of 10 ..."
sta BC                //1850: 4F              LD      C,A                  ; ... to C"
lda #$01
sta BC+1
jsr PrintMessageDel                //1851: CD 93 0A        CALL    PrintMessageDel     ; Print the message with delay between letters
lda PTR1+1                //1854: C1              POP     BC                   ; Restore BC
sta BC+1
lda PTR1
sta BC
rts                //1855: C9              RET                          ; Out
                //
ReadPriStruct:                //ReadPriStruct:
                //; Read a 4-byte print-structure pointed to by BC
                //; HL=Screen coordiante, DE=pointer to message"
                //; If the first byte is FF then return with Carry Set, Carry Cleared otherwise."
ldy #$00
!loop:
lda (BC),y                //1856: 0A              LD      A,(BC)              ; Get the screen LSB"
cmp #$ff                //1857: FE FF           CP      $FF                  ; Valid?
sec                //1859: 37              SCF                          ; If not Carry will be Set
beq !exit+                //185A: C8              RET     Z                    ; Return if 255
sta HL,y                //185B: 6F              LD      L,A                  ; Screen LSB to L"
iny                //185C: 03              INC     BC                   ; Next
cpy #$04                //185E: 67              LD      H,A                  ; Screen MSB to H"
bne !loop-                //185F: 03              INC     BC                   ; Next
lda BC                //1860: 0A              LD      A,(BC)              ; Read message LSB"
clc                //1861: 5F              LD      E,A                  ; Message LSB to E"
adc #$04                //1862: 03              INC     BC                   ; Next
sta BC                //1863: 0A              LD      A,(BC)              ; Read message MSB"
clc                //1864: 57              LD      D,A                  ; Message MSB to D"
                //1865: 03              INC     BC                   ; Next (for next print)
                //1866: A7              AND     A                    ; Clear Carry
!exit:
rts                //1867: C9              RET                          ; Done
                //
MessagePlayY:                //MessagePlayY:
.byte $0f,$0b,$00,$18                //1DAB: 0F 0B 00 18   ; ""PLAY" with normal Y"
                //
MessageInvaders:                //MessageInvaders:
                //; ""SPACE  INVADERS"""
.byte $12, $0F, $00, $02, $04, $26, $26, $08, $0D, $15, $00, $03, $04, $11, $12                //1DAF: 12 0F 00 02 04 26 26 08 0D 15 00 03 04 11 12 
                //
.align $100
scoreImages:                //; Tables used to draw ""SCORE ADVANCE TABLE" information"
.byte $1c,$11,$34,$35       //1DBE: 0E 2C 68 1D           ; Flying Saucer 52/53
.byte $1c,$13,$2a,$2b       //1DC2: 0C 2C 20 1C           ; Alien C, sprite 0"  43/44
.byte $1c,$15,$2c,$2d       //1DC6: 0A 2C 40 1C           ; Alien B, sprite 1"  45/46
.byte $1c,$17,$2e,$2f       //1DCA: 08 2C 00 1C           ; Alien A, sprite 0"  47/48
.byte $ff                   //1DCE: FF                     ; End of list
                //;
scoreTexts:                //AlienScoreTable:
.byte $20, $11, <MessageMyst, >MessageMyst                //1DCF: 0E 2E E0 1D           ; ""=? MYSTERY"""
.byte $20, $13, <Message30Pts, >Message30Pts                 //1DD3: 0C 2E EA 1D           ; ""=30 POINTS"""
.byte $20, $15, <Message20Pts, >Message20Pts                //1DD7: 0A 2E F4 1D           ; ""=20 POINTS"""
.byte $20, $17, <Message10Pts, >Message10Pts                //1DDB: 08 2E 99 1C           ; ""=10 POINTS"""
.byte $ff                //1DDF: FF                     ; End of list
                //
MessageMyst:                //MessageMyst:
.byte $27, $38, $26, $0C, $18, $12, $13, $04, $11, $18                //1DE0: 27 38 26 0C 18 12 13 04 11 18   ; ""=? MYSTERY"""
                //
Message30Pts:                //Message30Pts:
.byte $27, $1D, $1A, $26, $0F, $0E, $08, $0D, $13, $12                //1DEA: 27 1D 1A 26 0F 0E 08 0D 13 12   ; ""=30 POINTS"""
                //
Message20Pts:                //Message20Pts:
.byte $27, $1C, $1A, $26, $0F, $0E, $08, $0D, $13, $12                //1DF4: 27 1C 1A 26 0F 0E 08 0D 13 12   ; ""=20 POINTS"""
                //
Message10Pts:                //Message10Pts:
.byte $27, $1B, $1A, $26, $0F, $0E, $08, $0D, $13, $12                //1C99: 27 1B 1A 26 0F 0E 08 0D 13 12    ; ""=10 POINTS"""                //


SplashSprite:                //SplashSprite:
                //; Moves a sprite up or down in splash mode. Interrupt moves the sprite. When it reaches
                //; Y value in 20CA the flag at 20CB is raised. The image flips between two pictures every
                //; 4 movements.
                //00 00 FF B8 FE 20 1C 10 9E 00 20 1C 
addressRegister(0,$1fc00,1,0)

loadHL(gamevars8080.splashAnForm)               //1868: 21 C2 20        LD      HL,$20C2            ; Descriptor"
inc gamevars8080.splashAnForm                   //186B: 34              INC     (HL)                 ; Change image
inc HL                      //186C: 23              INC     HL                   ; Point to delta-x
lda (HL)                //186D: 4E              LD      C,(HL)              ; Get delta-x"
jsr AddDelta                //186E: CD D9 01        CALL    AddDelta            ; Add delta-X and delta-Y to X and Y
                // add delta returns with yr in a                //1871: 47              LD      B,A                  ; Current y coordinate"
cmp gamevars8080.splashTargetY                //1872: 3A CA 20        LD      A,(splashTargetY)   ; Has sprite reached ..."
                //1875: B8              CP      B                    ; ... target coordinate?
beq atDest                //1876: CA 98 18        JP      Z,$1898             ; Yes ... flag and out"

ldx gamevars8080.splashImageLSB
lda gamevars8080.splashAnForm                //1879: 3A C2 20        LD      A,(splashAnForm)    ; Image number"
and #$04                //187C: E6 04           AND     $04                  ; Watching bit 3 for flip delay
bne splashImage1                //187E: 2A CC 20        LD      HL,(splashImRestLSB); Image"
ldx gamevars8080.splashImageMSB
splashImage1:
lda SpriteArray.addressTableLo,x
sta VERADATA0
lda SpriteArray.addressTableHi,x
sta VERADATA0
lda gamevars8080.splashXr
clc
adc #$30
sta VERADATA0
lda #$00
adc #$00
sta VERADATA0
lda gamevars8080.splashYr
sta VERADATA0
stz VERADATA0
lda #%00001100
sta VERADATA0
lda #%00010000
sta VERADATA0
                //1881: C2 88 18        JP      NZ,$1888            ; Did bit 3 go to 0? No ... keep current image"
                //1884: 11 30 00        LD      DE,$0030            ; 16*3 ..."
                //1887: 19              ADD     HL,DE                ; ...  use other image form"
                //1888: 22 C7 20        LD      (splashImageLSB),HL ; Image to descriptor structure"
                //188B: 21 C5 20        LD      HL,$20C5            ; X,Y,Image descriptor"
                //188E: CD 3B 1A        CALL    ReadDesc            ; Read sprite descriptor
                //1891: EB              EX      DE,HL                ; Image to DE, position to HL"
rts                //1892: C3 D3 15        JP      DrawSprite          ; Draw the sprite
                //
                //1895: 00 00 00                           
                //
atDest:
lda #$01                //1898: 3E 01           LD      A,$01                ; Flag that sprite ..."
sta gamevars8080.splashReached                //189A: 32 CB 20        LD      (splashReached),A   ; ... reached location"
rts                //189D: C9              RET                          ; Out
                //
                //;Animate alien shot to extra ""C" in splash"
animateAlienC:
loadHL(gamevars8080.obj4TimerMSB)                //189E: 21 50 20        LD      HL,$2050            ; Task descriptor for game object 4 (squiggly shot)"
loadDE(extraCAlienStruct)                //18A1: 11 C0 1B        LD      DE,$1BC0            ; Task info for animate-shot-to-extra-C"
loadBC($1000)                //18A4: 06 10           LD      B,$10                ; Block copy ..."
jsr BlockCopy                //18A6: CD 32 1A        CALL    BlockCopy           ; ... 16 bytes
lda #$02                //18A9: 3E 02           LD      A,$02                ; Set shot sync ..."
sta gamevars8080.shotSync                //18AB: 32 80 20        LD      (shotSync),A        ; ... to run the squiggly shot"
lda $01                //18AE: 3E FF           LD      A,$FF                ; Shot direction (-1)"
sta gamevars8080.alienShotDelta                //18B0: 32 7E 20        LD      (alienShotDelta),A  ; Alien shot delta"
lda #$04                //18B3: 3E 04           LD      A,$04                ; Animate ..."
sta gamevars8080.isrSplashTask                //18B5: 32 C1 20        LD      (isrSplashTask),A   ; ... shot"
!wait1:
lda gamevars8080.squShotStatus                //18B8: 3A 55 20        LD      A,(squShotStatus)   ; Has shot ..."
and #$01                //18BB: E6 01           AND     $01                  ; ... collided?
beq !wait1-                //18BD: CA B8 18        JP      Z,$18B8             ; No ... keep waiting"
!wait2:
lda gamevars8080.squShotStatus                //18C0: 3A 55 20        LD      A,(squShotStatus)   ; Wait ..."
and #$01                //18C3: E6 01           AND     $01                  ; ... for explosion ...
beq !wait2-                //18C5: C2 C0 18        JP      NZ,$18C0            ; ... to finish"
loadHL($3311)                //18C8: 21 11 33        LD      HL,$3311            ; Here is where the extra C is"
lda #$26                //18CB: 3E 26           LD      A,$26                ; Space character"
                //18CD: 00              NOP                          ; ** Why?
jsr DrawChar                //18CE: CD FF 08        CALL    DrawChar            ; Draw character
jmp TwoSecDelay                //18D1: C3 B6 0A        JP      TwoSecDelay         ; Two second delay and out
                //
                //; Initializiation comes here
                //;
                //init:
init:               //18D4: 31 00 24        LD      SP,$2400            ; Set stack pointer just below screen"
stz BC+1             //18D7: 06 00           LD      B,$00                ; Count 256 bytes"
jsr CopyRAMMirrorB               //18D9: CD E6 01        CALL    $01E6                ; Copy ROM to RAM
jsr DrawStatus                //18DC: CD 56 19        CALL    DrawStatus          ; Print scores and credits
                //;
keepSplashing:
lda #$08                //18DF: 3E 08           LD      A,$08                ; Set alien ..."
sta gamevars8080.aShotReloadRate               //18E1: 32 CF 20        LD      (aShotReloadRate),A ; ... shot reload rate"
//testing
// lda #2
// sta gamevars8080.isrSplashTask
// stz gamevars8080.splashAnimate

jmp afterIniSplash                //18E4: C3 EA 0A        JP      $0AEA                ; Top of splash screen loop
                //
currentPlayerAliveFlag:                //; Get player-alive flag for OTHER player
lda gamevars8080.playerDataMSB                //18E7: 3A 67 20        LD      A,(playerDataMSB)   ; Player data MSB"
loadHL(gamevars8080.player1Alive)                //18EA: 21 E7 20        LD      HL,$20E7            ; Alive flags (player 1 and 2)"
ror                //18ED: 0F              RRCA                         ; Bit 1=1 for player 1
bcc !+                //18EE: D0              RET     NC                   ; Player 2 ... we have it ... out
inc HL                //18EF: 23              INC     HL                   ; Player 1's flag
!:
rts                //18F0: C9              RET                          ; Done
                //
                //; If there is one alien left then the right motion is 3 instead of 2. That's
                //; why the timing is hard to hit after the change.
                //18F1: 06 02           LD      B,$02                ; Rack moving right delta X"
                //18F3: 3A 82 20        LD      A,(numAliens)       ; Number of aliens on screen"
                //18F6: 3D              DEC     A                    ; Just one left?
                //18F7: C0              RET     NZ                   ; No ... use right delta X of 2
                //18F8: 04              INC     B                    ; Just one alien ... move right at 3 instead of 2
                //18F9: C9              RET                          ; Done
                //
                //SoundBits3On:
                //; Add in bit for sound
                //18FA: 3A 94 20        LD      A,(soundPort3)      ; Current value of sound port"
                //18FD: B0              OR      B                    ; Add in new sounds
                //18FE: 32 94 20        LD      (soundPort3),A      ; New value of sound port"
                //1901: D3 03           OUT     (SOUND1),A          ; Write new value to sound hardware"
                //1903: C9              RET                          
                //
                //InitAliensP2:
                //1904: 21 00 22        LD      HL,$2200            ; Player 2 data area"
                //1907: C3 C3 01        JP      $01C3                ; Initialize player 2 aliens
                //
PlyrShotAndBump:                //PlyrShotAndBump:
jsr PlayerShotHit                //190A: CD D8 14        CALL    PlayerShotHit       ; Player's shot collision detection
jmp RackBump                //190D: C3 97 15        JP      RackBump            ; Change alien deltaX and deltaY when rack bumps edges
                //
CurPlyAlive:                //CurPlyAlive:
                //; Get the current player's alive status
loadHL(gamevars8080.player1Alive)                //1910: 21 E7 20        LD      HL,$20E7            ; Alive flags"
lda gamevars8080.playerDataMSB                //1913: 3A 67 20        LD      A,(playerDataMSB)   ; Player 1 or 2"
ror                //1916: 0F              RRCA                         ; Will be 1 if player 1
bcs CurPlyAliveExit                //1917: D8              RET     C                    ; Return if player 1
inc HL                //1918: 23              INC     HL                   ; Bump to player 2
CurPlyAliveExit:
rts                //1919: C9              RET                          ; Return
                //
DrawScoreHead:                //DrawScoreHead:
                //; Print score header " SCORE<1> HI-SCORE SCORE<2> """
lda #$1c                //191A: 0E 1C           LD      C,$1C                ; 28 bytes in message"
sta BC
lda #$01
sta BC+1        //colour
lda #$0c      // offset 6*2 chars since screen is 40 and real is 28          //191C: 21 1E 24        LD      HL,$241E            ; Screen coordinates"line 2(256pix*28 chars)
sta HL
lda #$00    //top row
sta HL+1
lda #<MessageScore                 //191F: 11 E4 1A        LD      DE,$1AE4            ; Score header message"
sta DE
lda #>MessageScore
sta DE+1
jmp PrintMessage                //1922: C3 F3 08        JP      PrintMessage        ; Print score header
                //
PrintP1Score:
lda #<gamevars8080.P1ScorL                //1925: 21 F8 20        LD      HL,$20F8            ; Player 1 score descriptor"
sta HL
bra printScore2                //1928: C3 31 19        JP      DrawScore           ; Print score
                //
PrintP2Score:
lda #<gamevars8080.P2ScorL               //192B: 21 FC 20        LD      HL,$20FC            ; Player 2 score descriptor"
sta HL
printScore2:
lda #>gamevars8080.P1ScorL
sta HL+1
                //192E: C3 31 19        JP      DrawScore           ; Print score
                //
DrawScore:                //DrawScore:
                //; Print score.
               //; HL = descriptor
lda (HL)                //1931: 5E              LD      E,(HL)              ; Get score LSB"
sta DE
inc HL                //1932: 23              INC     HL                   ; Next
lda (HL)                //1933: 56              LD      D,(HL)              ; Get score MSB"
sta DE+1
inc HL                //1934: 23              INC     HL                   ; Next
lda (HL)                //1935: 7E              LD      A,(HL)              ; Get coordinate LSB"
inc HL                //1936: 23              INC     HL                   ; Next
tax
lda (HL)                //1937: 66              LD      H,(HL)              ; Get coordiante MSB"
sta HL+1
txa                //1938: 6F              LD      L,A                  ; Set LSB"
sta HL
jmp Print4Digits                //1939: C3 AD 09        JP      Print4Digits        ; Print 4 digits in DE
                //1988
testchars:
ldx #30
lda #00
sta HL
lda #$00
sta HL+1
lda #00
nextTest:
pha
phx
jsr DrawHexByte
inc HL+1
stz HL
plx
pla
sed
clc
adc #$01
cld
dex
bne nextTest
rts
testchar1:
.byte 29
testchar2:
.byte 57,58,57,58,57,58,57,58

printCreditMsg:                //; Print message ""CREDIT """
lda #$07                //193C: 0E 07           LD      C,$07                ; 7 bytes in message"
sta BC
lda #$2e               //193E: 21 01 35        LD      HL,$3501            ; Screen coordinates"
sta HL
lda #$1d
sta HL+1
lda #<MessageCredit                //1941: 11 A9 1F        LD      DE,$1FA9            ; Message = ""CREDIT """
sta DE
lda #>MessageCredit
sta DE+1
jmp PrintMessage                //1944: C3 F3 08        JP      PrintMessage        ; Print message
                //
DrawNumCredits:                //DrawNumCredits:
                //; Display number of credits on screen
lda #$3c                //194A: 21 01 3C        LD      HL,$3C01            ; Screen coordinates"
sta HL
lda #$1d
sta HL+1
lda gamevars8080.numCoins                //1947: 3A EB 20        LD      A,(numCoins)        ; Number of credits"
jmp DrawHexByte                //194D: C3 B2 09        JP      DrawHexByte         ; Character to screen
                                //
PrintHiScore:                //PrintHiScore:
lda #<gamevars8080.HiScorL                //1950: 21 F4 20        LD      HL,$20F4            ; Hi Score descriptor"
sta HL
lda #>gamevars8080.HiScorL
sta HL+1
jmp DrawScore                //1953: C3 31 19        JP      DrawScore           ; Print Hi-Score
                //
DrawStatus:                //DrawStatus:
                //; Print scores (with header) and credits (with label)
jsr screen.cls  //1956: CD 5C 1A        CALL    ClearScreen         ; Clear the screen
jsr DrawScoreHead                //1959: CD 1A 19        CALL    DrawScoreHead       ; Print score header
jsr PrintP1Score                //195C: CD 25 19        CALL    $1925                ; Print player 1 score
jsr PrintP2Score                //195F: CD 2B 19        CALL    $192B                ; Print player 2 score
jsr PrintHiScore                //1962: CD 50 19        CALL    PrintHiScore        ; Print hi score
jsr printCreditMsg                //1965: CD 3C 19        CALL    $193C                ; Print credit lable
jsr testchars
jmp DrawNumCredits                //1968: C3 47 19        JP      DrawNumCredits      ; Number of credits
                //
plyrShotSndOff:
                 //196B: CD DC 19        CALL    SoundBits3Off       ; From 170B with B=FB. Turn off player shot sound
jmp UpdateHighScore                //196E: C3 71 16        JP      $1671                ; Update high-score if player's score is greater
                //
AlienAtBottom:
lda #$01                //1971: 3E 01           LD      A,$01                ; Set flag that ..."
sta gamevars8080.invaded                //1973: 32 6D 20        LD      (invaded),A         ; ... aliens reached bottom of screen"
jmp endOfRound                //1976: C3 E6 16        JP      $16E6                ; End of round
               //
                //1979: CD D7 19        CALL    DsableGameTasks     ; Disable ISR game tasks
                //197C: CD 47 19        CALL    DrawNumCredits      ; Display number of credits on screen
jsr printCreditMsg                //197F: C3 3C 19        JP      $193C                ; Print message ""CREDIT"""
                //
setISRSplashTask:
 sta gamevars8080.isrSplashTask               //1982: 32 C1 20        LD      (isrSplashTask),A   ; Set ISR splash task"
 rts               //1985: C9              RET                          ; Done
                //
                //; The original code (from TAITO) printed this message on the screen. When Midway branched the code
                //; they changed the logic so it isn't printed.
                //
                //1986: 8B 19 ; Points to print TAITO CORPORATION message ... not sure why
                //                
                //1988: C3 D6 09        JP      ClearPlayField      ; Clear playfield and out
                //
                //; Print ""*TAITO CORPORATION*"""
                //198B: 21 03 28        LD      HL,$2803            ; Screen coordinates"
                //198E: 11 BE 19        LD      DE,$19BE            ; Message ""*TAITO CORPORATION*"""
                //1991: 0E 13           LD      C,$13                ; Messgae length"
                //1993: C3 F3 08        JP      PrintMessage        ; Print message
                //
                //; The original TAITO code:
                //;1985: C3 8B 19     JP    $198B              ;
                //;1988: CD D6 09     CALL  $09D6              ;
                //;198B: 21 03 28     LD    HL,$2803           ;"
                //;198E: 11 BE 19     LD    DE,$19BE           ;"
                //;1991: 0E 13        LD    C,$13              ;"
                //;1993: C3 F3 08     JP    $08F3              ;
                //
                //1996: 00 00 00 00 ; ** Why?
                //                          
CheckHiddenMes:                //CheckHiddenMes:
                //; There is a hidden message ""TAITO COP" (with no ""R"") in the game. It can only be"
                //; displayed in the demonstration game during the splash screens. You must enter
                //; 2 seqences of buttons. Timing is not critical. As long as you eventually get all
                //; the buttons up/down in the correct pattern then the game will register the
                //; sequence.
                //;
                //; 1st: 2start(down) 1start(up)   1fire(down) 1left(down) 1right(down)
                //; 2nd: 2start(up)   1start(down) 1fire(down) 1left(down) 1right(up)
                //;
                //; Unfortunately MAME does not deliver the simultaneous button presses correctly. You can see the message in
                //; MAME by changing 19A6 to 02 and 19B1 to 02. Then the 2start(down) is the only sequence.
                //;
lda gamevars8080.hidMessSeq                //199A: 3A 1E 20        LD      A,(hidMessSeq)      ; Has the 1st ""hidden-message" sequence ..."
                //199D: A7              AND     A                    ; ... been registered?
bne CheckHiddenMes1                //199E: C2 AC 19        JP      NZ,$19AC            ; Yes ... go look for the 2nd sequence"
//get inputs                //19A1: DB 01           IN      A,(INP1)            ; Get player inputs"
and #$76                //19A3: E6 76           AND     $76                  ; 0111_0110 Keep 2Pstart, 1Pstart, 1Pshot, 1Pleft, 1Pright"
clc                //19A5: D6 72           SUB     $72                  ; 0111_0010 1st sequence: 2Pstart, 1Pshot, 1Pleft, 1Pright"
sbc #$72
bne CheckHiddenMesExit                //19A7: C0              RET     NZ                   ; Not first sequence ... out
inc                //19A8: 3C              INC     A                    ; Flag that 1st sequence ...
sta gamevars8080.hidMessSeq                //19A9: 32 1E 20        LD      (hidMessSeq),A      ; ... has been entered"
CheckHiddenMes1:
//get inputs                //19AC: DB 01           IN      A,(INP1)            ; Check inputs for 2nd sequence"
and #$76                //19AE: E6 76           AND     $76                  ; 0111_0110 Keep 2Pstart, 1Pstart, 1Pshot, 1Pleft, 1Pright"
cmp #$34                //19B0: FE 34           CP      $34                  ; 0011_0100 2nd sequence: 1Pstart, 1Pshot, 1Pleft"
bne CheckHiddenMesExit                //19B2: C0              RET     NZ                   ; If not second sequence ignore
loadHL($1414)                //19B3: 21 1B 2E        LD      HL,$2E1B            ; Screen coordinates"
loadDE(MessageTaito)                //19B6: 11 F7 0B        LD      DE,$0BF7            ; Message = ""TAITO COP" (no R)"
loadBC($0109)                //19B9: 0E 09           LD      C,$09                ; Message length"
jmp PrintMessage                //19BB: C3 F3 08        JP      PrintMessage        ; Print message and out
CheckHiddenMesExit:                //
rts
MessageTaito:                //MessageTaito:
                //; ""*TAITO CORPORATION*"""
.byte $28, $13, $00, $08, $13, $0E, $26, $02, $0E, $11, $0F, $0E, $11                 //19BE: 28 13 00 08 13 0E 26 02 0E 11 0F 0E 11      
.byte $00, $13, $08, $0E, $0D, $28                //19CB: 00 13 08 0E 0D 28
                //
EnableGameTasks:                //EnableGameTasks:
                //; Enable ISR game tasks
lda #$01                //19D1: 3E 01           LD      A,$01                ; Set ISR ..."
sta gamevars8080.suspendPlay                //19D3: 32 E9 20        LD      (suspendPlay),A     ; ... game tasks enabled"
rts                //19D6: C9              RET                          ; Done
                //
DisableGameTasks:                //DsableGameTasks:
                //; Disable ISR game tasks
                //; Clear 20E9 flag
                //19D7: AF              XOR     A                    ; Clear ISR game tasks flag
stz gamevars8080.suspendPlay                //19D8: C3 D3 19        JP      $19D3                ; Save a byte (the RET)
rts                //19DB: 00                                            ; ** Here is the byte saved. I wonder if this was an optimizer pass.
                //
                //SoundBits3Off:
                //; Turn off bit in sound port
                //19DC: 3A 94 20        LD      A,(soundPort3)      ; Current sound effects value"
                //19DF: A0              AND     B                    ; Mask bits off
                //19E0: 32 94 20        LD      (soundPort3),A      ; Store new hold value"
                //19E3: D3 03           OUT     (SOUND1),A          ; Change sounds"
                //19E5: C9              RET                          ; Done
                //
DrawNumShips:                //DrawNumShips: r $1c c $14
sta PTR1                //; Show ships remaining in hold for the player
loadHL($1d12)                //19E6: 21 01 27        LD      HL,$2701            ; Screen coordinates"
lda PTR1                //19E9: CA FA 19        JP      Z,$19FA             ; None in reserve ... skip display"
beq clearShipLives
                //; Draw line of ships
loadDE(shipChars)                //19EC: 11 60 1C        LD      DE,$1C60            ; Player sprite"
drawLives:
loadBC($0502)                //19EF: 06 10           LD      B,$10                ; 16 rows"
                    //19F1: 4F              LD      C,A                  ; Hold count"
jsr PrintMessage                //19F2: CD 39 14        CALL    DrawSimpSprite      ; Display 1byte sprite to screen
inc HL
inc HL
inc HL
inc HL
dec PTR1                //19F5: 79              LD      A,C                  ; Restore remaining"
bne drawLives                //19F6: 3D              DEC     A                    ; All done?
                //19F7: C2 EC 19        JP      NZ,$19EC            ; No ... keep going"
                //; Clear remainder of line
clearShipLives:
lda #$26                //19FA: 06 10           LD      B,$10                ; 16 rows"
jsr DrawChar                //19FC: CD CB 14        CALL    ClearSmallSprite    ; Clear 1byte sprite at HL
lda #$26
jsr DrawChar                //19FF: 7C              LD      A,H                  ; Get Y coordinate"
lda HL                //1A00: FE 35           CP      $35                  ; At edge?
cmp #$2a                //1A02: C2 FA 19        JP      NZ,$19FA            ; No ... do all"
bcc clearShipLives
rts                //1A05: C9              RET                          ; Out
shipChars:
.byte $39,$3a

                //
CompYToBeam:                //CompYToBeam:
                //;
                //; The ISRs set the upper bit of 2072 based on where the beam is. This is compared to the
                //; upper bit of an object's Y coordinate to decide whic ISR should handle it. When the
                //; beam passes the halfway point (or near it ... at scanline 96), the upper bit is cleared."
                //; When the beam reaches the end of the screen the upper bit is set.
                //;
                //; The task then runs in the ISR if the Y coordiante bit matches the 2072 flag. Objects that
                //; are at the top of the screen (upper bit of Y clear) run in the mid-screen ISR when
                //; the beam has moved to the bottom of the screen. Objects that are at the bottom of the screen
                //; (upper bit of Y set) run in the end-screen ISR when the beam is moving back to the top.
                //;
                //; The pointer to the object's Y coordinate is passed in DE. CF is set if the upper bits are
                //; the same (the calling ISR should execute the task).
                //;
loadHL(gamevars8080.vblankStatus)                //1A06: 21 72 20        LD      HL,$2072            ; Get the ..."
//lda (HL)                //1A09: 46              LD      B,(HL)              ; ... beam position status"
lda (DE)                //1A0A: 1A              LD      A,(DE)              ; Get the task structure flag"
and #$80                //1A0B: E6 80           AND     $80                  ; Only upper bits count
eor (HL)                //1A0D: A8              XOR     B                    ; XOR them together
bne !+                //1A0E: C0              RET     NZ                   ; Not the same (CF cleared)
sec                //1A0F: 37              SCF                          ; Set the CF if the same
!:
rts                //1A10: C9              RET                          ; Done
                //
                //; Alien delay lists. First list is the number of aliens. The second list is the corresponding delay.
                //; This delay is only for the rate of change in the fleet's sound.
                //; The check takes the first num-aliens-value that is lower or the same as the actual num-aliens on screen.
                //;
                //; The game starts with 55 aliens. The aliens are move/drawn one per interrupt which means it
                //; takes 55 interrupts. The first delay value is 52 ... which is almost in sync with the number
                //; of aliens. It is a tad faster and you can observe the sound and steps getting out of sync.
                //;
                //1A11: 32 2B 24 1C 16 11 0D 0A 08 07 06 05 04 03 02 01
                //1A21: 34 2E 27 22 1C 18 15 13 10 0E 0D 0C 0B 09 07 05     
                //1A31: FF   ; ** Needless terminator. The list value ""1" catches everything."
                //
BlockCopy:                //BlockCopy:
                //; Copy from [DE] to [HL] (b bytes)
lda (DE)                //1A32: 1A              LD      A,(DE)              ; Copy from [DE] to ..."
sta (HL)                //1A33: 77              LD      (HL),A              ; ... [HL]"
inc HL                //1A34: 23              INC     HL                   ; Next destination
bne !+
inc HL+1
!:
inc DE                //1A35: 13              INC     DE                   ; Next source
bne !+
inc DE+1
!:
dec BC+1                //1A36: 05              DEC     B                    ; Count in B
bne BlockCopy                //1A37: C2 32 1A        JP      NZ,BlockCopy        ; Do all"
rts                //1A3A: C9              RET                          ; Done
                //
ReadDesc:                //ReadDesc:
                //; Load 5 bytes sprite descriptor from [HL]
lda (HL)                //1A3B: 5E              LD      E,(HL)              ; Descriptor ..."
sta DE                //1A3C: 23              INC     HL                   ; ... sprite ...
inc HL
lda (HL)                //1A3D: 56              LD      D,(HL)              ; ..."
sta DE+1
inc HL                //1A3E: 23              INC     HL                   ; ... picture
lda (HL)                //1A3F: 7E              LD      A,(HL)              ; Descriptor ..."
tax
inc HL                //1A40: 23              INC     HL                   ; ... screen ...
lda (HL)                //1A41: 4E              LD      C,(HL)              ; ..."
sta BC
inc HL                //1A42: 23              INC     HL                   ; ... location
lda (HL)                //1A43: 46              LD      B,(HL)              ; Number of bytes in sprite"
sta BC+1
lda BC
sta HL+1                //1A44: 61              LD      H,C                  ; From A,C to ..."
txa
sta HL                //1A45: 6F              LD      L,A                  ; ... H,L"
rts                //1A46: C9              RET                          ; Done
                //
                //ConvToScr:
                //; The screen is organized as one-bit-per-pixel.
                //; In: HL contains pixel number (bbbbbbbbbbbbbppp)
                //; Convert from pixel number to screen coordinates (without shift)
                //; Shift HL right 3 bits (clearing the top 2 bits)
                //; and set the third bit from the left.
                //1A47: C5              PUSH    BC                   ; Hold B (will mangle)
                //1A48: 06 03           LD      B,$03                ; 3 shifts (divide by 8)"
                //1A4A: 7C              LD      A,H                  ; H to A"
                //1A4B: 1F              RRA                          ; Shift right (into carry, from doesn't matter)"
                //1A4C: 67              LD      H,A                  ; Back to H"
                //1A4D: 7D              LD      A,L                  ; L to A"
                //1A4E: 1F              RRA                          ; Shift right (from/to carry)
                //1A4F: 6F              LD      L,A                  ; Back to L"
                //1A50: 05              DEC     B                    ; Do all ...
                //1A51: C2 4A 1A        JP      NZ,$1A4A            ; ... 3 shifts"
                //1A54: 7C              LD      A,H                  ; H to A"
                //1A55: E6 3F           AND     $3F                  ; Mask off all but screen (less than or equal 3F)
                //1A57: F6 20           OR      $20                  ; Offset into RAM
                //1A59: 67              LD      H,A                  ; Back to H"
                //1A5A: C1              POP     BC                   ; Restore B
                //1A5B: C9              RET                          ; Done
//
ConvToScrPixel:         //puts sprite x/y in HL from alienrefx/y for alien in a 
// calc row (11/row)
// x = x + (16*alien mod 11)
//y = y- 16 * rownumbe r(0 is bttom row)
ldy #$ff
convRowCount:
iny
sec
sbc #$0B //11
bcs convRowCount
adc #$0b
// a = x (0-10)
// y = y (0-4)
asl
asl
asl
asl //*16
//clc  should be clear anyway!
adc gamevars8080.refAlienXr
sta HL+1
tya
asl
asl
asl
asl
sta PTR1
lda gamevars8080.refAlienYr
sec
sbc PTR1
sta HL
rts


                //
                //ClearScreen:
                //; Clear the screen
                //; Thanks to Mark Tankard for pointing out what this really does
                //1A5C: 21 00 24        LD      HL,$2400            ; Screen coordinate"
                //1A5F: 36 00           LD      (HL),$00            ; Clear it"
                //1A61: 23              INC     HL                   ; Next byte
                //1A62: 7C              LD      A,H                  ; Have we done ..."
                //1A63: FE 40           CP      $40                  ; ... all the screen?
                //1A65: C2 5F 1A        JP      NZ,$1A5F            ; No ... keep going"
                //1A68: C9              RET                          ; Out
                //
                //RestoreShields:
                //; Logically OR the player's shields back onto the playfield
                //; DE = sprite
                //; HL = screen
                //; C = bytes per row
                //; B = number of rows
                //1A69: C5              PUSH    BC                   ; Preserve BC
                //1A6A: E5              PUSH    HL                   ; Hold for a bit
                //1A6B: 1A              LD      A,(DE)              ; From sprite"
                //1A6C: B6              OR      (HL)                 ; OR with screen
                //1A6D: 77              LD      (HL),A              ; Back to screen"
                //1A6E: 13              INC     DE                   ; Next sprite
                //1A6F: 23              INC     HL                   ; Next on screen
                //1A70: 0D              DEC     C                    ; Row done?
                //1A71: C2 6B 1A        JP      NZ,$1A6B            ; No ... do entire row"
                //1A74: E1              POP     HL                   ; Original start
                //1A75: 01 20 00        LD      BC,$0020            ; Bump HL by ..."
                //1A78: 09              ADD     HL,BC                ; ... one screen row"
                //1A79: C1              POP     BC                   ; Restore
                //1A7A: 05              DEC     B                    ; Row counter
                //1A7B: C2 69 1A        JP      NZ,RestoreShields   ; Do all rows"
                //1A7E: C9              RET                          
                //
RemoveShip:                //RemoveShip:
                //; Remove a ship from the players stash and update the
                //; hold indicators on the screen.
jsr getNumActiveShips                //1A7F: CD 2E 09        CALL    $092E                ; Get last byte from player data
beq !exit+                //1A82: A7              AND     A                    ; Is it 0?
                //1A83: C8              RET     Z                    ; Skip
sta PTR1                //1A84: F5              PUSH    AF                   ; Preserve number remaining
dec                //1A85: 3D              DEC     A                    ; Remove a ship from the stash
sta (HL)                //1A86: 77              LD      (HL),A              ; New number of ships"
jsr DrawNumShips                //1A87: CD E6 19        CALL    DrawNumShips        ; Draw the line of ships
lda PTR1
updateShipCount:
tax
loadHL($1d0e)                //1A8B: 21 01 25        LD      HL,$2501            ; Screen coordinates"
txa                //1A8A: F1              POP     AF                   ; Restore number
and #$0f                //1A8E: E6 0F           AND     $0F                  ; Make sure it is a digit
jmp printCharAtHL                //1A90: C3 C5 09        JP      $09C5                ; Print number remaining
!exit:
rts
                //Data From Here Down
                //1A93: 00 00       
                //
                //; Splash screen animation structure 1
                //; 00   Image form (increments each draw)
                //; 00   Delta X
                //; FF   Delta Y is -1
                //; B8   X coordinate
                //; FE   Y starting coordiante
                //; 1C20 Base image (small alien)
                //; 10   Size of image (16 bytes)
                //; 9E   Target Y coordiante
                //; 00   Reached Y flag
                //; 1C20 Base iamge (small alien)
SplashAni1Struct:
.byte $00, $00, $FF, $40, $FF, $04, $05, $10, $7A, $00, $20, $1C                  //1A95: 00 00 FF B8 FE 20 1C 10 9E 00 20 1C   
    //changed bytes 5/6 to sprite image numbers for alien
                //
ShotReloadRate:                //ShotReloadRate:
                //; The tables at 1CB8 and 1AA1 control how fast shots are created. The speed is based
                //; on the upper byte of the player's score. For a score of less than or equal 0200 then
                //; the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less
                //; than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything
                //; above 3000 is 07.
                //;
                //; 1CB8: 02 10 20 30
                //;
.byte $30, $10, $0b, $08                //1AA1: 30 10 0B 08                            
.byte $07                //1AA5: 07           ; Fastest shot firing speed
                //
MessageGOver:                //MessageGOver:
                //; GAME OVER PLAYER< >"""
.byte $06, $00, $0C, $04, $26, $0E, $15, $04, $11, $26, $26, $0F               //1AA6: 06 00 0C 04 26 0E 15 04 11 26 26 0F   
.byte $0B, $00, $18, $04, $11, $24, $26, $25               //1AB2: 0B 00 18 04 11 24 26 25                
                //
MessageB1or2:                //MessageB1or2:
                //; ""1 OR 2PLAYERS BUTTON"""
.byte $1B, $26, $0E, $11, $26, $1C, $0F, $0B, $00, $18, $04               //1ABA: 1B 26 0E 11 26 1C 0F 0B 00 18 04      
.byte $11, $12, $26, $01, $14, $13, $13, $0E, $0D, $26               //1AC5: 11 12 26 01 14 13 13 0E 0D 26
                //
Message1Only:                //Message1Only:
                //; ""ONLY 1PLAYER BUTTON """
                //; Note the space on the end ... both alternatives are same length
.byte $0E, $0D, $0B, $18, $26, $1B, $0F, $0B, $00, $18, $04, $11, $26, $26               //1ACF: 0E 0D 0B 18 26 1B 0F 0B 00 18 04 11 26 26 
.byte $01, $14, $13, $13, $0E, $0D, $26               //1ADD: 01 14 13 13 0E 0D 26                   
                //
MessageScore:                //MessageScore:
                //; " SCORE<1> HI-SCORE SCORE<2>"""
.byte  $26, $12, $02, $0E, $11, $04, $24, $1B, $25, $26, $07, $08                //1AE4: 26 12 02 0E 11 04 24 1B 25 26 07 08   
.byte  $3F, $12, $02, $0E, $11, $04, $26, $12, $02, $0E, $11, $04           //1AF0: 3F 12 02 0E 11 04 26 12 02 0E 11 04   
.byte  $24, $1C, $25, $26            //1AFC: 24 1C 25 26                      
                //
                //;-------------------------- RAM initialization -----------------------------
                //; Coppied to RAM (2000) C0 bytes as initialization.
                //; See the description of RAM at the top of this file for the details on this data.
.align $100
InitializationDATA:                //
.byte  $01, $00, $00, $10, $00, $00, $00, $00, $02, $78, $18, $78, $18, $00, $08, $00               //1B00: 01 00 00 10 00 00 00 00 02 78 38 78 38 00 F8 00
.byte  $00, $80, $00, <GameObj0, >GameObj0, $FF, $05, $0C, $60, $1C, $d8, $08, $12, $01, $00, $00    //gameobj0 data          //1B10: 00 80 00 8E 02 FF 05 0C 60 1C 20 30 10 01 00 00   
gameobj1Ptr:    //1b20
.byte  $00, $00, $00, <GameObj1, >GameObj1, $00, $10, >$fc00+(60*8), <$fc00+(60*8), $1c, $d4, $01, $fc, $00, $FF, $FF    //gameobj1 data          //1B20: 00 00 00 BB 03 00 10 90 1C 28 30 01 04 00 FF FF   
gameobj2Ptr:    //1b30
.byte  $00, $00, $02, <GameObj2, >GameObj2, $00, $00, $00, $00, $00, $04, $EE, $1C, $00, $00, $03    //gameobj2 data           //1B30: 00 00 02 76 04 00 00 00 00 00 04 EE 1C 00 00 03    
gameobj3Ptr:    //1b40
.byte  $00, $00, $00, <GameObj3, >GameObj3, $00, $00, $01, $00, $1D, $04, $E2, $1C, $00, $00, $03    //gameobj3 data          //1B40: 00 00 00 B6 04 00 00 01 00 1D 04 E2 1C 00 00 03 
gameobj4Ptr:    //1b50
.byte  $00, $00, $00, <GameObj4, >GameObj4, $00, $00, $01, $06, $1D, $04, $D0, $1C, $00, $00, $03    //gameobj4 data          //1B50: 00 00 00 82 06 00 00 01 06 1D 04 D0 1C 00 00 03
.byte  $FF, $00, $C0, $1C, $00, $00, $10, >gamevars8080.P1Data, $01, $00, $30, $00, $12, $00, $00, $00              //1B60: FF 00 C0 1C 00 00 10 21 01 00 30 00 12 00 00 00         
                //
                //; These don't need to be copied over to RAM (see 1BA0 below).
                //MesssageP1:
                //; ""PLAY PLAYER<1>"""
.byte  $0F, $0B, $00, $18, $26, $0F, $0B, $00, $18, $04, $11, $24, $1B, $25, $FC, $00              //1B70: 0F 0B 00 18 26 0F 0B 00 18 04 11 24 1B 25 FC 00
                //
.byte  $01, $FF, $FF, $00, $00, $00, $20, $64, $1D, $D0, $29, $18, $02, <SaucerScrTab, >SaucerScrTab, $00              //1B80: 01 FF FF 00 00 00 20 64 1D D0 29 18 02 54 1D 00                
.byte  $08, $00, $06, $00, $00, $01, $40, $00, $01, $00, $00, $10, $9E, $00, $20, $1C              //1B90: 08 00 06 00 00 01 40 00 01 00 00 10 9E 00 20 1C                                   
                // 
                //; These don't need to be copied over to RAM I believe this to be a mistake. The constant at 01E4 is C0,"
                //; which is the size of this mirror with the added sprite. It should be A0. I believe there was a macro
                //; to size this area and later the splash screens where put in. Some of the data spilled over into this
                //; and the macro automatically included it. No harm.
                //Alien Pulling Upside Down 'Y'
                //; Alien sprite type C pulling upside down Y
                //AlienSprCYA:
                //; ........
                //; **......
                //; ..*.....
                //; ...****.
                //; ..*.*...
                //; **..*...
                //; ...*....
                //; .*.**...
                //; *.****..
                //; ...*.**.
                //; ..******
                //; ..******
                //; ...*.**.
                //; *.****..
                //; .*.**...
                //; ........
.byte  $00, $03, $04, $78, $14, $13, $08, $1A, $3D, $68, $FC, $FC, $68, $3D, $1A, $00               //1BA0: 00 03 04 78 14 13 08 1A 3D 68 FC FC 68 3D 1A 00                                      
                //
SplashAni2Struct:
.byte  $00, $00, $01, $40, $78, $0a, $0b, $10, $FF, $00, $A0, $1B, $00, $00, $00, $00              //1BB0: 00 00 01 B8 98 A0 1B 10 FF 00 A0 1B 00 00 00 00                                      
                               //changed byte 5/6 to sprite image numbers     
                //;--------------------------- End of initialization copy -------------------------
                //
                //
extraCAlienStruct:                //; Shot descriptor for splash shooting the extra ""C"""
.byte $00, $10, $00, <gameTask4Alienshoot, >gameTask4Alienshoot, $00, $00, $00, $00, $00, $07, $D0, $1C, $C8, $9B, $03               //1BC0: 00 10 00 0E 05 00 00 00 00 00 07 D0 1C C8 9B 03

                //AlienSprCYB:
                //; Alien sprite C pulling upside down Y. Note the difference between this and the first picutre
                //; above. The Y is closer to the ship. This gives the effect of the Y kind of ""sticking" in the"
                //; animation.
                //; ........
                //; ........
                //; **......
                //; ..*.....
                //; ...****.
                //; ..*.*...
                //; **.*....
                //; *..**...
                //; .*.***..
                //; *.**.**.
                //; .*.*****
                //; .*.*****
                //; *.**.**.
                //; .*.***..
                //; *..**...
                //; ........
                //;
.byte  $00, $00, $03, $04, $78, $14, $0B, $19, $3A, $6D, $FA, $FA, $6D, $3A, $19, $00               //1BD0: 00 00 03 04 78 14 0B 19 3A 6D FA FA 6D 3A 19 00                                      
                //
                //; More RAM initialization copied by 18D9
.byte  $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $01, <DemoCommands, >DemoCommands, $00              //1BE0: 00 00 00 00 00 00 00 00 00 01 00 00 01 74 1F 00                                      
.byte  $80, $00, $00, $00, $00, $00, $22, $02, $00, $00, $12, $02, $00, $00, $36, $02               //1BF0: 80 00 00 00 00 00 1C 2F 00 00 1C 27 00 00 1C 39 
                //
                //AlienSprA:
                //Alien Images
                //; Alien sprite type A,B, and C at positions 0"
                //;  ........ ........ ........
                //;  ........ ........ ........
                //;  *..***.. ........ ........
                //;  *..****. ...****. ........
                //;  .*.****. *.***... *..**...
                //;  .***.**. .*****.* .*.***..
                //;  ..**.*** ..**.**. *.**.**.
                //;  .*.***** ..****.. .*.*****
                //;  .*.***** ..****.. .*.*****
                //;  ..**.*** ..****.. *.**.**.
                //;  .***.**. ..**.**. .*.***..
                //;  .*.****. .*****.* *..**...
                //;  *..****. *.***... ........
                //;  *..***.. ...****. ........
                //;  ........ ........ ........
                //;  ........ ........ ........
                //1C00: 00 00 39 79 7A 6E EC FA FA EC 6E 7A 79 39 00 00 
                //1C10: 00 00 00 78 1D BE 6C 3C 3C 3C 6C BE 1D 78 00 00 
                //1C20: 00 00 00 00 19 3A 6D FA FA 6D 3A 19 00 00 00 00 
                //
                //AlienSprB:
                //; Alien sprite type A,B, and C at positions 1"
                //;  ........ ........ ........
                //;  ........ ........ ........
                //;  ...***.. ........ ........
                //;  .*.****. .***.... ........
                //;  *******. ...**... .*.**...
                //;  *.**.**. .*****.* *.****..
                //;  ..**.*** *.**.**. ...*.**.
                //;  .*.***** *.****.. ..******
                //;  .*.***** ..****.. ..******
                //;  ..**.*** *.****.. ...*.**.
                //;  *.**.**. *.**.**. *.****..
                //;  *******. .*****.* .*.**...
                //;  .*.****. ...**... ........
                //;  ...***.. .***.... ........
                //;  ........ ........ ........
                //;  ........ ........ ........
                //1C30: 00 00 38 7A 7F 6D EC FA FA EC 6D 7F 7A 38 00 00 
                //1C40: 00 00 00 0E 18 BE 6D 3D 3C 3D 6D BE 18 0E 00 00 
                //1C50: 00 00 00 00 1A 3D 68 FC FC 68 3D 1A 00 00 00 00 
                //Player Sprite
                //PlayerSprite:
                //;  ........
                //;  ........
                //;  ****....
                //;  *****...
                //;  *****...
                //;  *****...
                //;  *****...
                //;  *******.
                //;  ********
                //;  *******.
                //;  *****...
                //;  *****...
                //;  *****...
                //;  *****...
                //;  ****....
                //;  ........
                //1C60: 00 00 0F 1F 1F 1F 1F 7F FF 7F 1F 1F 1F 1F 0F 00 
                //
                //
                //PlrBlowupSprites:
                //;  ........
                //;  ..*.....
                //;  *.......
                //;  **..*...
                //;  **......
                //;  ***.....
                //;  **..**.*
                //;  ****....
                //;  ****.*..
                //;  **......
                //;  ****.*..
                //;  *..*..*.
                //;  ..*.....
                //;  **......
                //;  ........
                //;  *.......
                //;
                //1C70: 00 04 01 13 03 07 B3 0F 2F 03 2F 49 04 03 00 01 
                //;
                //;  ......*.
                //;  ...*....
                //;  *.*.....
                //;  **...*.*
                //;  .*.*....
                //;  **......
                //;  **.**.*.
                //;  ****....
                //;  ***..*..
                //;  ***..*..
                //;  **.*....
                //;  **.*..*.
                //;  ......*.
                //;  ..*....*
                //;  *...*...
                //;  ...*..*.
                //1C80: 40 08 05 A3 0A 03 5B 0F 27 27 0B 4B 40 84 11 48 
                //Player Shot Sprite
                //PlayerShotSpr:
                //1C90: 0F    ; ++++....
                //Player Shot Exploding
                //ShotExploding:
                //; *..**..*
                //; ..****..
                //; .******.
                //; *.****..
                //; ..****.*
                //; .*****..
                //; ..*****.
                //; *..**..*
                //1C91: 99 3C 7E 3D BC 3E 7C 99     
                //      

                //
MessageAdv:                //MessageAdv:
                //; ""*SCORE ADVANCE TABLE*"""
.byte $28, $12, $02, $0E, $11, $04, $26, $00, $03, $15, $00, $0D, $02, $04, $26, $13, $00, $01, $0B, $04, $28                //1CA3: 28 12 02 0E 11 04 26 00                                   
                //1CAB: 03 15 00 0D 02 04 26 13                                   
                //1CB3: 00 01 0B 04 28                                      
                //
                //
AReloadScoreTab:                //AReloadScoreTab:
                //; The tables at 1CB8 and 1AA1 control how fast shots are created. The speed is based
                //; on the upper byte of the player's score. For a score of less than or equal 0200 then
                //; the fire speed is 30. For a score less than or equal 1000 the shot speed is 10. Less
                //; than or equal 2000 the speed is 0B. Less than or equal 3000 is 08. And anything
                //; above 3000 is 07.
                //;
                //; 1AA1: 30 10 0B 08
                //; 1AA5: 07           ; Fastest shot firing speed
                //;
.byte $02, $10, $20, $30                  //1CB8: 02 10 20 30                            
                //
                //MessageTilt:
                //1CBC: 13 08 0B 13   ; ""TILT"""
                //Alien Exploding Sprite
                //; Alien exploding sprite
                //AlienExplode:
                //;  ........
                //;  ...*....
                //;  *..*..*.
                //;  .*...*..
                //;  ..*.*...
                //;  *......*
                //;  .*....*.
                //;  ........
                //;  .*....*.
                //;  *......*
                //;  ..*.*...
                //;  .*...*..
                //;  *..*..*.
                //;  ...*....
                //;  ........
                //;  ........
                //1CC0: 00 08 49 22 14 81 42 00 42 81 14 22 49 08 00 00 
                //Squigly Shot Sprite
                //; Squigly shot picture in 4 animation frames
                //SquiglyShot:
                //1CD0: 44   ; ..*...*.
                //1CD1: AA   ; .*.*.*.*
                //1CD2: 10   ; ....*...
                //
                //1CD3: 88   ; ...*...*
                //1CD4: 54   ; ..*.*.*.
                //1CD5: 22   ; .*...*..
                //
                //1CD6: 10   ; ....*...
                //1CD7: AA   ; .*.*.*.*
                //1CD8: 44   ; ..*...*.
                //                                   
                //1CD9: 22   ; .*...*..
                //1CDA: 54   ; ..*.*.*.
                //1CDB: 88   ; ...*...*
                //Alien Shot Exploding
                //; Alien shot exploding
                //AShotExplo:      
                //; .*.*..*.
                //; *.*.*...
                //; .*****.*
                //; ******..
                //; .****.*.
                //; *.*..*..
                //1CDC: 4A 15 BE 3F 5E 25                                  
                //Plunger Shot Sprite
                //; Alien shot ... the plunger looking one
                //PlungerShot:
                //1CE2: 04  ; ..*.....
                //1CE3: FC  ; ..******
                //1CE4: 04  ; ..*.....
                //
                //1CE5: 10  ; ....*...
                //1CE6: FC  ; ..******
                //1CE7: 10  ; ....*...
                //
                //1CE8: 20  ; .....*..
                //1CE9: FC  ; ..******
                //1CEA: 20  ; .....*..
                //
                //1CEB: 80  ; .......*
                //1CEC: FC  ; ..******
                //1CED: 80  ; .......*
                //Rolling Shot Sprite
                //; Alien shot ... the rolling one
                //RollShot:
                //1CEE: 00  ; ........
                //1CEF: FE  ; .*******
                //1CF0: 00  ; ........
                //
                //1CF1: 24  ; ..*..*..
                //1CF2: FE  ; .*******
                //1CF3: 12  ; .*..*...
                //
                //1CF4: 00  ; ........
                //1CF5: FE  ; .*******
                //1CF6: 00  ; ........
                //
                //1CF7: 48  ; ...*..*.
                //1CF8: FE  ; .*******
                //1CF9: 90  ; ....*..*
                //                
MessagePlayUY:                //MessagePlayUY:
.byte $0f, $0b, $00, $29                //1CFA: 0F 0B 00 29    ; ""PLAy" with an upside down 'Y' for splash screen"
                //                       
                //1CFE: 00 00        
                //
.align $100                                             
ColFireTable:                //ColFireTable:
                //; This table decides which column a shot will fall from. The column number is read from the
                //; table (1-11) and the pointer increases for the shot type. For instance, the ""squiggly" shot"
                //; will fall from columns in this order: 0B, 01, 06, 03. If you play the game you'll see that"
                //; order.
                //;
                //; The ""plunger" shot uses index 00-0F (inclusive)"
                //; The ""squiggly" shot uses index 06-14 (inclusive)"
                //; The ""rolling" shot targets the player"
.byte $01, $07, $01, $01, $01, $04, $0B, $01, $06, $03, $01, $01, $0B, $09, $02, $08              //1D00: 01 07 01 01 01 04 0B 01 06 03 01 01 0B 09 02 08                                      
.byte $02, $0B, $04, $07, $0A              //1D10: 02 0B 04 07 0A    
                //;
                //; This appears to be part of the column-firing table, but it is never used."
                //; Perhaps this was originally intended for the ""rolling" shot but then the"
                //; ""rolling" was change to target the player specifically."
                //1D15: 05 02 05 04 06 07 08 0A 06 0A 03              
                //Shield Image
                //ShieldImage:
                //; Shield image pattern. 2 x 22 = 44 bytes.
                //;
                //;************....
                //;*************...
                //;**************..
                //;***************.
                //;****************
                //;..**************
                //;...*************
                //;....************
                //;....************
                //;....************
                //;....************
                //;....************
                //;....************
                //;....************
                //;...*************
                //;..**************
                //;****************
                //;****************
                //;***************.
                //;**************..
                //;*************...
                //;************....
                //;
                //1D20: FF 0F FF 1F FF 3F FF 7F FF FF FC FF F8 FF F0 FF F0 FF F0 FF F0 FF                                      
                //1D36: F0 FF F0 FF F0 FF F8 FF FC FF FF FF FF FF FF 7F FF 3F FF 1F FF 0F                                      
                //
                //
SaucerPossibleTable:
.byte 5,10,15,30                //1D4C: 05 10 15 30  ; Table of possible saucer scores
.byte SaucSoreStr,SaucSoreStr+3,SaucSoreStr+6,SaucSoreStr+9                //1D50: 94 97 9A 9D  ; Table of corresponding string prints for each possible score
                //
SaucerScrTab:                //SaucerScrTab:
                //; 208D points here to the score given when the saucer is shot. It advances
                //; every time the player-shot is removed. The code wraps after 15, but there"
                //; are 16 values in this table. This is a bug in the code at 044E (thanks to
                //; Colin Dooley for finding this).
                //;
                //; Thus the one and only 300 comes up every 15 shots (after an initial 8).
.byte 10, 05, 05, 10, 15, 10, 10, 05, 30, 10, 10, 10, 05, 15, 10, 05                 //1D54: 10 05 05 10 15 10 10 05 30 10 10 10 05 15 10 05                                   
                //Flying Saucer Sprite
                //SpriteSaucer:
                //; ........
                //; ........
                //; ........
                //; ........
                //; ..*.....
                //; ..**....
                //; .****...
                //; ***.**..
                //; .*****..
                //; ..*****.
                //; ..*.***.
                //; .******.
                //; .******.
                //; ..*.***.
                //; ..*****.
                //; .*****..
                //; ***.**..
                //; .****...
                //; ..**....
                //; ..*.....
                //; ........
                //; ........
                //; ........
                //; ........
                //1D64: 00 00 00 00 04 0C 1E 37 3E 7C 74 7E 7E 74 7C 3E 37 1E 0C 04 00 00 00 00
                //
                //SpriteSaucerExp:
                //;........
                //;.*...*..
                //;........
                //;*.*..*.*
                //;......*.
                //;...*....
                //;...**..*
                //;*.****..
                //;.**.**.*
                //;..****..
                //;.**.**..
                //;*.***...
                //;....*...
                //;...*..*.
                //;.*...**.
                //;.**.**.*
                //;*.***...
                //;...**..*
                //;...*....
                //;.*....*.
                //;....*..*
                //;...*....
                //;........
                //;........
                //1D7C: 00 22 00 A5 40 08 98 3D B6 3C 36 1D 10 48 62 B6 1D 98 08 42 90 08 00 00  
                //         
SaucSoreStr:                //SaucSoreStr:
.byte $26, $1F, $1A               //1D94: 26 1F 1A  ; _50
.byte $1B, $1A, $1A               //1D97: 1B 1A 1A  ; 100
.byte $1B, $1F, $1A               //1D9A: 1B 1F 1A  ; 150
.byte $1D, $1A, $1A               //1D9D: 1D 1A 1A  ; 300
                //
AlienScores:                //AlienScores:
                //; Score table for hitting alien type
.byte $0a                //1DA0: 10 ; Bottom 2 rows
.byte $14                //1DA1: 20 ; Middle row
.byte $1e                //1DA2: 30 ; Highest row
                //         
AlienStartTable:                //AlienStartTable:
                //; Starting Y coordinates for aliens at beginning of rounds. The first round is initialized to $78 at 07EA.
                //; After that this table is used for 2nd, 3rd, 4th, 5th, 6th, 7th, 8th, and 9th. The 10th starts over at"
                //; 1DA3 (60).
.byte 60                //1DA3: 60                                      
.byte 60                //1DA4: 50                                      
.byte 60                //1DA5: 48                                      
.byte 60                //1DA6: 48                                      
.byte 60                //1DA7: 48                                      
.byte 60                //1DA8: 40                                      
.byte 60                //1DA9: 40                                      
.byte 60                //1DAA: 40   
                //                                   
                //
                //1DFE: 00 00 ; Padding to put font table at 1E00
                //Text Character Sprites
                //; 8 byte sprites
                //; The screen is turned so rotate these pictures counter-clockwise.
                //; Some of the font characters at the end were never needed. The ROM overwrites these characters with
                //; data near the end. For instance, 1F90 would be a character but has the ""INSERT COIN" message. The ""?"""
                //; character is at 1FC0 and is used in messages as is 1FF8 ""-"". The ""light colored" tiles in the grid below"
                //; show the character slots that have been repurposed.
                //Characters:
                //1E00: 00 1F 24 44 24 1F 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1E08: 00 7F 49 49 49 36 00 00  ; *****... *******. .*****.. *******. *******. *******. .*****.. *******.
                //1E10: 00 3E 41 41 41 22 00 00  ; ..*..*.. *..*..*. *.....*. *.....*. *..*..*. ...*..*. *.....*. ...*....
                //1E18: 00 7F 41 41 41 3E 00 00  ; ..*...*. *..*..*. *.....*. *.....*. *..*..*. ...*..*. *.....*. ...*....
                //1E20: 00 7F 49 49 49 41 00 00  ; ..*..*.. *..*..*. *.....*. *.....*. *..*..*. ...*..*. *.*...*. ...*....
                //1E28: 00 7F 48 48 48 40 00 00  ; *****... .**.**.. .*...*.. .*****.. *.....*. ......*. ***...*. *******.
                //1E30: 00 3E 41 41 45 47 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1E38: 00 7F 08 08 08 7F 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //
                //1E40: 00 00 41 7F 41 00 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1E48: 00 02 01 01 01 7E 00 00  ; ........ .*...... *******. *******. *******. *******. .*****.. *******.
                //1E50: 00 7F 08 14 22 41 00 00  ; *.....*. *....... ...*.... *....... .....*.. ....*... *.....*. ...*..*.
                //1E58: 00 7F 01 01 01 01 00 00  ; *******. *....... ..*.*... *....... ...**... ...*.... *.....*. ...*..*.
                //1E60: 00 7F 20 18 20 7F 00 00  ; *.....*. *....... .*...*.. *....... .....*.. ..*..... *.....*. ...*..*.
                //1E68: 00 7F 10 08 04 7F 00 00  ; ........ .******. *.....*. *....... *******. *******. .*****.. ....**..
                //1E70: 00 3E 41 41 41 3E 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1E78: 00 7F 48 48 48 30 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //
                //1E80: 00 3E 41 45 42 3D 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1E88: 00 7F 48 4C 4A 31 00 00  ; .*****.. *******. .*..**.. ......*. .******. ..*****. *******. **...**.
                //1E90: 00 32 49 49 49 26 00 00  ; *.....*. ...*..*. *..*..*. ......*. *....... .*...... .*...... ..*.*...
                //1E98: 00 40 40 7F 40 40 00 00  ; *.*...*. ..**..*. *..*..*. *******. *....... *....... ..**.... ...*....
                //1EA0: 00 7E 01 01 01 7E 00 00  ; .*....*. .*.*..*. *..*..*. ......*. *....... .*...... .*...... ..*.*...
                //1EA8: 00 7C 02 01 02 7C 00 00  ; *.****.. *...**.. .**..*.. ......*. .******. ..*****. *******. **...**.
                //1EB0: 00 7F 02 0C 02 7F 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1EB8: 00 63 14 08 14 63 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //
                //1EC0: 00 60 10 0F 10 60 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1EC8: 00 43 45 49 51 61 00 00  ; .....**. **....*. .*****.. ........ **...*.. .*....*. ..**.... .*..***.
                //1ED0: 00 3E 45 49 51 3E 00 00  ; ....*... *.*...*. *.*...*. *....*.. *.*...*. *.....*. ..*.*... *...*.*.
                //1ED8: 00 00 21 7F 01 00 00 00  ; ****.... *..*..*. *..*..*. *******. *..*..*. *..*..*. ..*..*.. *...*.*.
                //1EE0: 00 23 45 49 49 31 00 00  ; ....*... *...*.*. *...*.*. *....... *..*..*. *..**.*. *******. *...*.*.
                //1EE8: 00 42 41 49 59 66 00 00  ; .....**. *....**. .*****.. ........ *...**.. .**..**. ..*..... .***..*.
                //1EF0: 00 0C 14 24 7F 04 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1EF8: 00 72 51 51 51 4E 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //
                //1F00: 00 1E 29 49 49 46 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1F08: 00 40 47 48 50 60 00 00  ; .****... ......*. .**.**.. *...**.. ...*.... ........ ........ ..*.*...
                //1F10: 00 36 49 49 49 36 00 00  ; *..*.*.. ***...*. *..*..*. *..*..*. ..*.*... *.....*. ........ ..*.*...
                //1F18: 00 31 49 49 4A 3C 00 00  ; *..*..*. ...*..*. *..*..*. *..*..*. .*...*.. .*...*.. ........ ..*.*...
                //1F20: 00 08 14 22 41 00 00 00  ; *..*..*. ....*.*. *..*..*. .*.*..*. *.....*. ..*.*... ........ ..*.*...
                //1F28: 00 00 41 22 14 08 00 00  ; .**...*. .....**. .**.**.. ..****.. ........ ...*.... ........ ..*.*...
                //1F30: 00 00 00 00 00 00 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //1F38: 00 14 14 14 14 14 00 00  ; ........ ........ ........ ........ ........ ........ ........ ........
                //
                //1F40: 00 22 14 7F 14 22 00 00  ; ........ ........
                //1F48: 00 03 04 78 04 03 00 00  ; .*...*.. **......
                //                                 ; ..*.*... ..*.....
                //                                 ; *******. ...****.
                //                                 ; ..*.*... ..*.....
                //                                 ; .*...*.. **......
                //                                 ; ........ ........
                //                                 ; ........ ........
                //
MessageP1or2:                //MessageP1or2:
.byte $24, $1B, $26, $0E, $11, $26, $1C, $26, $0F, $0B, $00, $18, $04, $11, $12, $25, $26, $26                //1F50: 24 1B 26 0E 11 26 1C 26  ; ""<1 OR 2 PLAYERS>  """
                //1F58: 0F 0B 00 18 04 11 12 25                
                //1F60: 26 26 
                //
Message1Coin:                //Message1Coin:
.byte $28, $1B, $26, $0F, $0B, $00, $18, $04, $11, $26, $26, $1B, $26, $02, $0E, $08, $0D, $26                 //1F62: 28 1B 26 0F 0B 00 18 04  ; ""*1 PLAYER  1 COIN """
                //1F6A: 11 26 26 1B 26 02 0E 08 
                //1F72: 0D 26                            
                //
DemoCommands:                //DemoCommands:
                //; (1=Right, 2=Left)"
.byte 1,1,0,0,1,0,2,1,0,2,1,0                //1F74: 01 01 00 00 01 00 02 01 00 02 01 00

_DemoCommands:                //Alien Sprite Carrying 'Y'
                //
                //; Small alien pushing Y back onto screen
                //AlienSprCA:
                //; .....**.
                //; ....*...
                //; ****....
                //; ....*...
                //; .....**.
                //; ....**..
                //; ...**...
                //; .*.**...
                //; *.****..
                //; ...*.**.
                //; ..******
                //; ..******
                //; ...*.**.
                //; *.****..
                //; .*.**...
                //; ........
                //                 
                //1F80: 60 10 0F 10 60 30 18 1A 3D 68 FC FC 68 3D 1A 00                
                //
MessageCoin:                //MessageCoin:
.byte $08, $0D, $12, $04, $11, $13, $26, $26, $02, $0E, $08, $0D                //1F90: 08 0D 12 04 11 13 26 26 02 0E 08 0D   ; ""INSERT  COIN"""
                //                           
CreditTable:                //CreditTable:
.byte $0d, $2a, <MessageP1or2, >MessageP1or2                 //1F9C: 0D 2A 50 1F                  ; ""<1 OR 2 PLAYERS>  " to screen at 2A0D"
.byte $0a, $2a, <Message1Coin, >Message1Coin               //1FA0: 0A 2A 62 1F                  ; ""*1 PLAYER  1 COIN " to screen at 2A0A"
.byte $07, $2a, <Message2Coins, >Message2Coins                //1FA4: 07 2A E1 1F                  ; ""*2 PLAYERS 2 COINS" to screen at 2A07"
.byte $ff                //1FA8: FF                           ; Terminates ""table print"""
                //
MessageCredit:                //MessageCredit:
.byte  $02, $11, $04, $03, $08, $13, $26               //1FA9: 02 11 04 03 08 13 26       ; ""CREDIT " (with space on the end)"
                //
                //AlienSprCB:
                //; ........
                //; .....**.
                //; ....*...
                //; ****....
                //; ....*...
                //; .....**.
                //; ...***..
                //; *..**...
                //; .*.***..
                //; *.**.**.
                //; .*.*****
                //; .*.*****
                //; *.**.**.
                //; .*.***..
                //; *..**...
                //; ........
                //1FB0: 00 60 10 0F 10 60 38 19 3A 6D FA FA 6D 3A 19 00                
                //
                //1FC0: 00 20 40 4D 50 20 00 00                ; ""?"""
                //
                //1FC8: 00 
                //
                //; Splash screen animation structure 3
                //; 00   Image form (increments each draw)
                //; 00   Delta X
                //; FF   Delta Y is -1
                //; B8   X coordinate
                //; FF   Y starting coordiante
                //; 1F80 Base image (small alien with Y)
                //; 10   Size of image (16 bytes)
                //; 97   Target Y coordiante
                //; 00   Reached Y flag
                //; 1F80 Base iamge (small alien with Y)
                //;
SplashAni3Struct:
.byte $00, $00, $FF, $40, $FF, $0c, $0d, $10, $78, $00, $80, $1F                //1FC9: 00 00 FF B8 FF 80 1F 10 97 00 80 1F 
                    // chnaged bytes 5/6 to image numbers for sprite+Y
                //
                //; Splash screen animation structure 4
                //; 00   Image form (increments each draw)
                //; 00   Delta X
                //; 01   Delta Y is 1
                //; D0   X coordinate
                //; 22   Y starting coordiante
                //; 1C20 Base image (small alien)
                //; 10   Size of image (16 bytes)
                //; 94   Target Y coordiante
                //; 00   Reached Y flag
                //; 1C20 Base iamge (small alien)
SplashAni4Struct:                //;
.byte $00, $00, $01, $D0, $22, $20, $1C, $10, $94, $00, $20, $1C                //1FD5: 00 00 01 D0 22 20 1C 10 94 00 20 1C 
                //
Message2Coins:                //Message2Coins:
.byte $28, $1C, $26, $0F, $0B, $00, $18, $04            //1FE1: 28 1C 26 0F 0B 00 18 04    ; ""*2 PLAYERS 2 COINS"""
.byte $11, $12, $26, $1C, $26, $02, $0E, $08            //1FE9: 11 12 26 1C 26 02 0E 08 
.byte $0D, $12             //1FF1: 0D 12                                
                //
MessagePush:                //MessagePush:
.byte $0F, $14, $12, $07, $26                //1FF3: 0F 14 12 07 26             ; ""PUSH " (with space on the end)"
                //
                //1FF8: 00 08 08 08 08 08 00 00                ; 3F:""-"""
shipsPerCred: 
.byte $03

}