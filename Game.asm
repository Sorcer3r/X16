.cpu _65c02
#importonce 

#import "Lib\constants.asm"
#import "Lib\petscii.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm"
#import "Int.asm"
#import "SpriteEngine.asm"
//#import "gameVars.asm"
#import "screen.asm"
#import "invaders.asm"
#import "player.asm"

* = $22 "zeropage" virtual
#import "gameVars.asm"

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
	//jsr setupSomeSprites  //this is garbage code but got some sprites active :)

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
	lda #$30			// first line int is line 48 for red colour1
	sta VERASCANLINE 
	lda VERAINTENABLE  
	and #$7f		// clear bit 8 line int
	ora #$03		// enable vsync and line ints
	sta VERAINTENABLE
    cli    

	lda #1 
	sta gameMode
	jsr player.addShields
	jsr player.addPlayer
	jsr player.addPlayerLives
	jsr invaders.initialiseInvaders
	
gameLoop:
	lda $ff			// wait for vsync semaphore
	beq gameLoop
	stz $ff

	lda gameMode
	cmp #1
	bne gametestmode2
	lda invaders.invadersLiving
	cmp #55
	beq arrayfull
	jsr invaders.add1Invader
	bra gametestmode3
arrayfull:
	inc gameMode
	stz invaders.invaderArrayIndex
	stz invaders.livingCycle
	bra gametestmode3
gametestmode2:
	cmp #2
	bne gametestmode3
	jsr invaders.findInvader
	bcc gametestmode3		// no living invaders
	jsr spriteEngine.process1Sprite
	inc invaders.invaderArrayIndex
	lda invaders.invaderArrayIndex
	cmp #55
	bne checkDoneAllInvaders
	stz invaders.invaderArrayIndex
checkDoneAllInvaders:
	inc invaders.livingCycle
	lda invaders.livingCycle
	cmp invaders.invadersLiving
	bne gametestmode3
	stz invaders.livingCycle
	lda invaders.setStopDrop.newXdelta
	beq checkX
	jsr invaders.setStopDrop
checkX:
	jsr spriteEngine.testXLimit	// carry if we hit an edge
	bcc gametestmode3
	jsr invaders.setStartDrop

gametestmode3:
	bra gameLoop
	rts
}
gameMode: .byte 0
