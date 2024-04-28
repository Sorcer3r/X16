.cpu _65c02
#importonce 
#import "tuneData.asm"
#import "Lib\macro.asm"
#import "Game.asm"
#import "notePositions.asm"

.const pianoKeyRow2 = VRAM_layer1_map +(18*256)

//$1:F9C0-$1:F9FF	VERA PSG Registers (16 x 4 bytes)
// voice0 1f9c0-1f9c3
// voice2 1f9c4-1f9c7

// each 4 bytes:
//0	Frequency word (7:0)
//1	Frequency word (15:8)
//2	Right(7) Left(6)	Volume(5-0) 
//3	Waveform(7-6)	    Pulse width(5-0)

//waveform
//0	Pulse       %00
//1	Sawtooth    %01
//2	Triangle    %10
//3	Noise       %11

// vol max is 63 %00111111
// pulse width max  63 %00111111  = 50% 

Music:{

voice1Ptr:  .byte 0
voice2Ptr:  .byte 0
voice1Time: .byte 0
voice2Time: .byte 0
finished:   .byte 0

INT_Save: .word $deaf

//call on frame int
IRQ_playTitleMusic:{
    lda voice1Ptr
    tay
    asl
    tax  
    lda titleTune.Voice01+1,x         
    bpl decvoice1Time               // freq_hi < $80 so must be valid data
    lda #$01                   //otherwise we hit end so set finished flag
    sta finished                   
    jmp IRQ_playTitleMusicX       


decvoice1Time:
    addressRegister(0,VERAPSG0,1,0)
    dec voice1Time
    lda voice1Time
    beq setVoice1       // count is 0 so get next note
    cmp #$01            // check if count is 1, if so, turn vol off/end note
    bne doVoice2        // otherwise count is not 1 so go deal with voice 2 
    stz VERADATA0       //
    stz VERADATA0
    stz VERADATA0
    bra doVoice2

setVoice1:
    lda titleTune.Voice01,x         //freq low 
    sta VERADATA0
    lda titleTune.Voice01+1,x       //freq hi
    sta VERADATA0
    ora titleTune.Voice01,x 
    beq v1setVol               //put 0 in vol if freqis 0
    lda #$ff                   //both channels, max vol
v1setVol:
    sta VERADATA0
    lda #$3f                // %10111111  triangle, 50% duty                
    sta VERADATA0
    lda titleTune.Voice01Time,y       
    sta voice1Time 
    inc voice1Ptr

// light up keyboard RED
    addressRegister(0,pianoKeyRow2,0,0)
    ldx #$01            //white
    lda notePositions.redKeys,y     //previous note
    beq thisRedNote                 // if zero then skip
    asl                 //double cos 2 bytes per char
    clc
    adc #$09            //offset from left + 1 for colour byte
    sta VERAAddrLow
    stx VERADATA0       // put colour in   
thisRedNote:
    lda notePositions.redKeys+1,y     //this note position
    beq doVoice2        //if nothing then skip
    ldx #02             //red
    asl                 //double cos 2 bytes per char
    clc
    adc #$09            //offset from left + 1 for colour byte
    sta VERAAddrLow
    stx VERADATA0       // put colour in   

doVoice2:
    addressRegister(0,VERAPSG1,1,0)
    dec voice2Time    
    lda voice2Time
    beq setVoice2           // timer = 0 , set next note
    cmp #$01
    bne IRQ_playTitleMusicX     // timer not 1 so do nothing
    stz VERADATA0
    stz VERADATA0
    stz VERADATA0           // set vol to 0 at count of 1 (end note)
    bra IRQ_playTitleMusicX

setVoice2:
    lda voice2Ptr
    tay
    asl
    tax
    lda titleTune.Voice02,x
    sta VERADATA0
    lda titleTune.Voice02+1,x         
    sta VERADATA0
    ora titleTune.Voice02,x 
    beq v2setVol                //put 0 in vol if freqis 0
    lda #$ff                   // both channels, vol $3f max
v2setVol:
    sta VERADATA0
    lda #$bf                // %10111111  triangle, 50% duty   
    sta VERADATA0
    lda titleTune.Voice02Time,y     
    sta voice2Time    
    inc voice2Ptr

// light up keyboard Blue
    addressRegister(0,pianoKeyRow2,0,0)
    ldx #$01            //white
    lda notePositions.blueKeys,y     //previous note
    beq thisBlueNote                 // if zero then skip
    asl                 //double cos 2 bytes per char
    clc
    adc #$09            //offset from left + 1 for colour byte
    sta VERAAddrLow
    stx VERADATA0       // put colour in   
thisBlueNote:
    lda notePositions.blueKeys+1,y     //this note position
    beq IRQ_playTitleMusicX        //if nothing then skip
    ldx #06             //Blue
    asl                 //double cos 2 bytes per char
    clc
    adc #$09            //offset from left + 1 for colour byte
    sta VERAAddrLow
    stx VERADATA0       // put colour in  

IRQ_playTitleMusicX:
    jmp (INT_Save)                  // System IRQ
}

IRQ_playGameMusic:{
    dec voice1Time
    bne IRQ_playGameMusicX  // countdown not zero so exit
    addressRegister(0,VERAPSG0,1,0)
    lda voice1Ptr
    asl             // *2
    tax
    lda gameTune+1,x    // check hi note for end of tune
    bpl setVoice1       // hi freq <$80 so valid note otherwise
    ldx #$00            // end of tune reached so reset 
    stx voice1Ptr
setVoice1:
    addressRegister(0,VERAPSG0,1,0)
    lda gameTune,x         //freq low 
    sta VERADATA0
    lda gameTune+1,x       //freq hi
    sta VERADATA0
//    ora gameTune,x 
//    beq v1setVol               //put 0 in vol if freqis 0
    lda #$ff                   //both channels, max vol
//v1setVol:
    sta VERADATA0
    lda #$3f                // %10111111  triangle, 50% duty                
    sta VERADATA0
    lda #$09
    sta voice1Time 
    inc voice1Ptr

IRQ_playGameMusicX:
    jmp (INT_Save)
}


IRQ_TitleMusicSetup:{
	// setup int for title music
    lda $314
    sta INT_Save
    lda $315
    sta INT_Save+1
    sei
    lda #<IRQ_playTitleMusic
    sta $314
    lda #>IRQ_playTitleMusic
    sta $315

	lda #0
	sta voice1Ptr
	sta voice2Ptr
	sta finished
	inc
	sta voice1Time
	sta voice2Time
	cli
	rts
}

IRQ_GameMusicSetup:{
	// setup int for title music
    lda $314
    sta INT_Save
    lda $315
    sta INT_Save+1
    sei
    lda #<IRQ_playGameMusic
    sta $314
    lda #>IRQ_playGameMusic
    sta $315
	lda #0
	sta voice1Ptr
	inc
	sta voice1Time
	cli
	rts
}

Restore_INT:{
	sei
	lda INT_Save
	sta $314
	lda INT_Save+1
	sta $315
	cli
	rts
}

}