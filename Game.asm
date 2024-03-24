.cpu _65c02
#importonce 

#import "Lib\constants.asm"
#import "Lib\petscii.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm"
#import "Int.asm"
#import "SpriteEngine.asm"
#import "gameVars.asm"
#import "screen.asm"
#import "invaders.asm"


*=$0801
	BasicUpstart2(main)
main: {
	backupVeraAddrInfo()

    jsr spriteEngine.copyGFXtoVera
	jsr spriteEngine.buildSpriteAddressTable

    lda VERA_DC_video
    ora #SPRITEENABLE
    sta VERA_DC_video
	lda #DCSCALEx2
	sta VERA_DC_hscale
	sta VERA_DC_vscale
	lda #VRAM_lowerchars >>9
	and #$fc
	sta VERA_L1_tilebase

	jsr screen.cls
	jsr screen.scoreText
	jsr setupSomeSprites  //this is garbage code but got some sprites active :)

//setup interrupt

    lda $314
    sta moveSpritesInt.intReturn
    lda $315
    sta moveSpritesInt.intReturn+1
    sei
    lda #moveSpritesInt & $ff
    sta $314
    lda #(moveSpritesInt >> 8) & $ff
    sta $315
	restoreVeraAddrInfo() 
	lda #$30			// first line int is line 48
	sta VERASCANLINE 
	lda VERAINTENABLE  
	and #$7f		// clear bit 8 line int
	ora #$03		// enable vsync and line ints
	sta VERAINTENABLE
    cli    

	jsr invaders.addInvader
	
gameLoop:
	lda $ff			// wait for vsync semaphore
	beq gameLoop
	stz $ff

	jsr spriteEngine.checkLimits
	jsr spriteEngine.processSprites
	//jsr screen.timer


	bra gameLoop
	rts
}


setupSomeSprites:{



	ldx #0			//sprite 0
	lda #20
	sta SpriteArray.xLo,x
	sta SpriteArray.yLo,x
	lda #0
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #1
	sta SpriteArray.xDelta,x
	lda #-1
	sta SpriteArray.yDelta,x
	lda #2
	sta SpriteArray.speedxCtrl,x
	lda #2
	sta SpriteArray.speedyCtrl,x
	lda #20
	sta SpriteArray.frameCtrl,x
	lda #$10	//16*8
	sta SpriteArray.ATTR2,x

inx							//sprite 1
	lda #40
	sta SpriteArray.xLo,x
	lda #30
	sta SpriteArray.yLo,x
	lda #0
	sta SpriteArray.xHi,x
	lda #2
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #-1
	sta SpriteArray.xDelta,x
	lda #1
	sta SpriteArray.yDelta,x
	lda #20
	sta SpriteArray.speedxCtrl,x
	lda #20
	sta SpriteArray.speedyCtrl,x
	lda #60
	sta SpriteArray.frameCtrl,x
	lda #$10	//16*8
	sta SpriteArray.ATTR2,x
	
inx						//sprite 2
	lda #$f7
	sta SpriteArray.xLo,x
	lda #0
	sta SpriteArray.xHi,x
	lda #$c0
	sta SpriteArray.yLo,x
	lda #4
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #-1
	sta SpriteArray.xDelta,x
	lda #-2
	sta SpriteArray.yDelta,x
	lda #20
	sta SpriteArray.speedxCtrl,x
	lda #20
	sta SpriteArray.speedyCtrl,x
	lda #15
	sta SpriteArray.frameCtrl,x
	lda #$10	//16*8
	sta SpriteArray.ATTR2,x
	

inx								//sprite 3 spaceship
	lda #30
	sta SpriteArray.xLo,x
	lda #200
	sta SpriteArray.yLo,x
	lda #6 // player					// spaceship
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #0
	sta SpriteArray.xDelta,x
	lda #0
	sta SpriteArray.yDelta,x
	lda #0
	sta SpriteArray.speedxCtrl,x
	lda #0
	sta SpriteArray.speedyCtrl,x
	lda #15
	sta SpriteArray.frameCtrl,x
	lda #1
	sta SpriteArray.numFrames,x
	lda #$10	//32*8
	sta SpriteArray.ATTR2,x
	

inx								//sprite 4
	lda #20
	sta SpriteArray.xLo,x
	lda #$e4
	sta SpriteArray.yLo,x
	lda #0
	sta SpriteArray.yHi,x
	lda #6
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #0
	sta SpriteArray.xDelta,x
	lda #0
	sta SpriteArray.yDelta,x
	lda #0
	sta SpriteArray.speedxCtrl,x
	lda #0
	sta SpriteArray.speedyCtrl,x
	lda #0
	sta SpriteArray.frameCtrl,x
	lda #1
	sta SpriteArray.numFrames,x
	lda #$10	//16*8
	sta SpriteArray.ATTR2,x
	
rts
}
