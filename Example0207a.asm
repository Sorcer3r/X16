.cpu _65c02

#import "lib/constants.asm"
#import "lib/petscii.asm"
#import "lib/macro.asm"

*=$0801
//    .byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00
	BasicUpstart2(main)

* = $080d

FirstChar: .byte 0
FirstColour: .byte 0

main: {

// put some chars on screen for reference
    ldx #3
l0:
    lda #47
    sta FirstChar
    ldy #80
l1:
    inc FirstChar
    lda FirstChar
    jsr $FFD2
    dey
    bne l1
    dex
    bne l0
    backupVeraAddrInfo()

	addressRegister(0,$1c000,1,0)

// put chars + colour on line to scroll
	ldy #$80
!loop:
	sta VERADATA0
    lda colour
    inc colour
    sta VERADATA0
    dey
	bne !loop-

CharLooper:

waitforline126:
    lda VERASCANLINE
    cmp #126
    bne waitforline126

    inc hscroll
    lda hscroll
    sta VERA_L1_hscrollLow

waitforline134:
    lda VERASCANLINE
    cmp #134
    bne waitforline134

//reset Hscroll
    stz VERA_L1_hscrollLow

//test if we scrolled 8 pixels (could do 32 using only hscroll low but line copy would need more work and i'm lazy))
    lda hscroll
    cmp #8
    bne skiplinecopy
// Copy That line elsewhere (Only the Character)
 	addressRegister(0,$1c000,1,0)
 	addressRegister(1,$1c000,1,0)

     lda VERADATA0
     sta FirstChar
     lda VERADATA0
     sta FirstColour

 // Setting up line of H's
 	ldy #160
 !lineshift:
 	lda VERADATA0
 	sta VERADATA1
 	dey
 	bne !lineshift-
//put first char back on end of line
     lda FirstChar
     sta VERADATA1
     lda FirstColour
     sta VERADATA1
//reset hscroll if we shifted data
    stz hscroll
skiplinecopy:
    wai

    jmp CharLooper
//we never get here 
    restoreVeraAddrInfo()    
	rts
}

colour:	.byte 0

hscroll: .byte 0