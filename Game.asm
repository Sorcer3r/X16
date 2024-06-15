.cpu _65c02
#importonce 

#import "Lib\constants.asm"
#import "Lib\petscii.asm"
#import "Lib\macro.asm"
#import "Lib\kernal_routines.asm"

*=$0801
	BasicUpstart2(main)
main: {
	jsr setDisplay
	jsr clearScreen
	jsr setupCharsInVera
	jsr drawPianoKeys
	//bra part2
	jsr Music.IRQ_SoundSetup
	jsr Music.IRQ_TitleMusicStart
PlayTitle:
	lda Music.finished
	beq PlayTitle
	jsr Music.IRQ_StopAllSound
part2:
	jsr Music.IRQ_GameSoundEnable
	jsr Music.IRQ_GameMusicStart
	

playGameMusic:
	jsr getJoystick
	lda getJoystick.firePressed
	bne playGameMusic
//	jsr Music.IRQ_GameMusicStop
	lda Music.voicePlayTime
	bne playGameMusic
	jsr Music.playBell



	bra playGameMusic		//forever	
	rts
}

getJoystick:{
    //  SNES | B | Y |SEL    |STA   |UP     |DN    |LT    |RT    |
    //  KBD  | Z | A |L SHIFT|ENTER |CUR UP |CUR DN|CUR LT|CUR RT|z
    // stores zero in location if key pressed, nz if not

    lda #$00    //keyboard joystick
    jsr kernal.joystick_get
    sta kbdJoy1
    stx kbdJoy2
    sty kbdJoy3
    tax
    and #$80
    sta firePressed // zer = key pressed
    txa
    and #$02
    sta leftPressed
    txa 
    and #$01
    sta rightPressed
    txa 
    and #$10
    sta startPressed
    rts
kbdJoy1: .byte 0
kbdJoy2: .byte 0
kbdJoy3: .byte 0
firePressed: .byte 0
leftPressed: .byte 0
rightPressed: .byte 0
startPressed: .byte 0

}
setDisplay:{
// set 40 chars etc
	setDCSel(0)
	lda #$40			//64 double H,V
	sta VERA_DC_hscale
	sta VERA_DC_vscale
	sta VERA_DC_border	//black
	rts

}

clearScreen:{
	ldx #30
	addressRegister(0,VRAM_layer1_map,1,0)
line:
	ldy #80		// 40 char+40colour
row:	
	stz VERADATA0
	stz VERADATA0
	dey
	bne row
	stz VERAAddrLow
	inc VERAAddrHigh
	dex
	bne line
	rts
}

drawPianoKeys:{
	addressRegister(0,VRAM_layer1_map +(17*256)+8,1,0)	// point to row 18,col 4(2perchar)
	ldx #0
	ldy #$01		//black back, white fore
topRow:
	lda pianoTopRow,x
	sta VERADATA0
	sty VERADATA0
	inx
	cpx #32
	bne topRow
	lda #$08			//reset x to col 4
	sta VERAAddrLow	
	inc VERAAddrHigh	//move down a row
	//lda #0				//char 0 
	ldx #32
bottomRow:
	stz VERADATA0
	sty VERADATA0
	dex
	bne bottomRow	
	rts

pianoTopRow:{
	.byte 1,3,3,2,1,3,2,1,3,3,2,1,3,2,1,3,2,1,3,3,2,1,3,2,1,3,3,2,1,3,2,0
}
}

setupCharsInVera:{
	copyDataToVera(Tile0,$00000,32) 
	stz VERA_L1_tilebase
	rts
}
#import "playTitleMusic.asm"
#import "tuneData.asm"
#import "pianokeysCharSet.asm"