.cpu _65c02

#import "lib/constants.asm"
#import "lib/petscii.asm"
#import "lib/macro.asm"

*=$0801
	BasicUpstart2(main)

main: {

    // make move bytes macro .
    // copy first to last first  then move 80 < (or 81<) - quicker for more than 1 chaar i think
    

// put some chars on screen for reference
    backupVeraAddrInfo()
	addressRegister(0,$1bf00,1,0)
    lda #$01
    sta colour
// put chars + colour on lines to scroll
    ldx #6
!loop1:
	ldy #0
!loop2:
    lda scrolltext,y
	sta VERADATA0
    lda colour
    sta VERADATA0
    iny
    cpy #$80
	bne !loop2-
    inc colour
    dex
    bne !loop1-

CharLooper:

waitforline126:
    lda VERASCANLINE
    cmp #126
    bne waitforline126
    inc hscroll
    lda hscroll
    sta VERA_L1_hscrollLow

// waitforline128:
//     lda VERASCANLINE
//     cmp #128
//     bne waitforline128


// waitforline129:
//     lda VERASCANLINE
//     cmp #129
//     bne waitforline129


// waitforline130:
//     lda VERASCANLINE
//     cmp #130
//     bne waitforline130


// waitforline131:
//     lda VERASCANLINE
//     cmp #131
//     bne waitforline131


// waitforline132:
//     lda VERASCANLINE
//     cmp #132
//     bne waitforline132


// waitforline133:
//     lda VERASCANLINE
//     cmp #133
//     bne waitforline133

waitforline134:
    lda VERASCANLINE
    cmp #134
    bne waitforline134

    // lda $9f34
    // ora #$01
    // sta $9f34

    lda hscroll
    asl
    sta VERA_L1_hscrollLow


waitforline142:
    lda VERASCANLINE
    cmp #142
    bne waitforline142
    lda #8
    sec
    sbc hscroll
    asl
    clc
    adc #16
    sta VERA_L1_hscrollLow


// waitforline143:
//     lda VERASCANLINE
//     cmp #143
//     bne waitforline143
// 	addressRegister(0,$1fa00,0,0)
//     inc VERADATA0
    
// waitforline145:
//     lda VERASCANLINE
//     cmp #145
//     bne waitforline145
//     inc VERADATA0

// waitforline131:
//     lda VERASCANLINE
//     cmp #131
//     bne waitforline131


// waitforline132:
//     lda VERASCANLINE
//     cmp #132
//     bne waitforline132


// waitforline133:
//     lda VERASCANLINE
//     cmp #133
//     bne waitforline133


waitforline150:
    lda VERASCANLINE
    cmp #150
    bne waitforline150
    lda #8
    sec
    sbc hscroll
    clc
    adc #16
    sta VERA_L1_hscrollLow

waitforline158:
    lda VERASCANLINE
    cmp #158
    bne waitforline158






//reset Hscroll
    stz VERA_L1_hscrollLow



waitforline143:
    lda VERASCANLINE
    cmp #160
    bne waitforline143
	addressRegister(0,$1fa00,0,0)
    //inc VERADATA0
    
waitforline145:
    lda VERASCANLINE
    cmp #162
    bne waitforline145
    //inc VERADATA0

    // lda $9f34
    // and #$fe
    // sta $9f34

//test if we scrolled 8 pixels (could do 32 using only hscroll low but line copy would need more work and i'm lazy))
    lda hscroll
    cmp #8
    beq docopy
    jmp skiplinescroll

//    jmp CharLooper
docopy:
// Copy That line elsewhere (Only the Character)
 	addressRegister(0,$1c000,1,0)
 	//addressRegister(1,$1c000,1,0)
    lda VERADATA0
    sta FirstChar
    lda VERADATA0
    sta FirstColour
    copyVERAData($1c002,$1c000,$fe)
    lda FirstChar
    sta VERADATA1
    lda FirstColour
    sta VERADATA1

 	addressRegister(0,$1c100,1,0)
 	lda VERADATA0
    sta FirstChar
    lda VERADATA0
    sta FirstColour
    lda VERADATA0
    sta SecondChar
    lda VERADATA0
    sta SecondColour
    copyVERAData($1c104,$1c100,$fa)
    lda FirstChar
    sta VERADATA1
    lda FirstColour
    sta VERADATA1
    lda SecondChar
    sta VERADATA1
    lda SecondColour
    sta VERADATA1

 	addressRegister(0,$1c2fc,1,0)
 	lda VERADATA0
    sta FirstChar
    lda VERADATA0
    sta FirstColour
    lda VERADATA0
    sta SecondChar
    lda VERADATA0
    sta SecondColour
    copyVERAData($1c200,$1c204,$fc)
    addressRegister(1,$1c200,1,0)
    lda FirstChar
    sta VERADATA1
    lda FirstColour
    sta VERADATA1
    lda SecondChar
    sta VERADATA1
    lda SecondColour
    sta VERADATA1

 	addressRegister(0,$1c3fe,1,0)
 	lda VERADATA0
    sta FirstChar
    lda VERADATA0
    sta FirstColour
    copyVERAData($1c300,$1c302,$fe)
    addressRegister(1,$1c300,1,0)
    lda FirstChar
    sta VERADATA1
    lda FirstColour
    sta VERADATA1
    



//reset hscroll
    stz hscroll

skiplinescroll:
    wai
    jmp CharLooper
//we never get here 
    restoreVeraAddrInfo()    
	rts
}

//data storage
colour:	.byte 0
hscroll: .byte 0
hscroll2: .byte 0
FirstChar: .byte 0
FirstColour: .byte 0
SecondChar: .byte 0
SecondColour: .byte 0

.align $100
.encoding "screencode_mixed"


scrolltext: .text "this is the scrolling text message that will fit on one complete"
            .text " screen line including all the characters hiding off screen..   "