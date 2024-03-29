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


startHere:
    copyDataToVera(spriteData,SPRITEDATA,spriteDataEnd-spriteData)

    lda VERA_DC_video
    ora #SPRITEENABLE
    sta VERA_DC_video

    addressRegister(0,SPRITEREGBASE,1,0)
    // 0	Address (12:5)
    // 1	Mode (1)	-(3)	Address (16:13)
    // 2	X (7:0)
    // 3	-	X (9:8)
    // 4	Y (7:0)
    // 5	-	Y (9:8)
    // 6	Collision mask (4)	Z-depth (2)	V-flip (1)	H-flip (1)
    // 7	Sprite height (2)	 Sprite width (2)	 Palette offset (4)

dospritebits:
    lda #(SPRITEDATA + 512 >> 5) & $ff
    sta VERADATA0
    sta sprite
    lda #(SPRITEDATA + 512 >> 13) & $0f
    sta VERADATA0
    lda #$00
    sta xpos
    sta VERADATA0
    lda #0
    sta xposHi
    sta VERADATA0
    lda #0
    sta VERADATA0
    lda #0
    sta VERADATA0
    lda #$0c
    sta VERADATA0
    lda #$50
    sta VERADATA0


deadend:
    wai
    addressRegister(0,SPRITEREGBASE+2,1,0)
    inc xpos
    lda xpos: #00
    sta VERADATA0
    tax
    cmp #$80
    beq noInc
    cmp #$00
    bne skip
incHi:
    inc xposHi
noInc:
    lda xposHi: #$00
    and #$03
    cmp #$02
    bne storeMe
    txa
    cmp #$80
    bne storeMe
    lda #0
    sta xpos
    sta xposHi
storeMe:
    lda xposHi
    sta VERADATA0

skip:
    txa
    and #$0f        //change frame every 16
    bne deadend
    addressRegister(0,SPRITEREGBASE,1,0)
    lda sprite: #$00
    eor #$04
    sta sprite
    sta VERADATA0
    jmp deadend
    

done:
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

spriteData:
.import binary "E:\X16\mine\spacesprites16x164bpp.SPR"
spriteDataEnd:
