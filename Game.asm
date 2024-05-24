.cpu _65c02
#import "zeroPage.asm"
#import "Int.asm"
#import "screen.asm"
#import "player.asm"
#import "gameVars.asm"

*=$0801
	BasicUpstart2(main)
main: {
	backupVeraAddrInfo()

    jsr spriteEngine.copyGFXtoVera
	jsr spriteEngine.buildSpriteAddressTable
	break()
	lda #$ff
	sta HL
	inc
	sta DE
	lda #$08
	sta HL+1
	sta DE+1
	ldx #02
	//lda (HL,x)
	lda HL
	inc
	sta HL
	adc HL+1
	sta HL+1
	break()

    lda VERA_DC_video
    ora #SPRITEENABLE
    sta VERA_DC_video
	lda #DCSCALEx2				// screen will be 640/2 * 480/2  320*240 . so Y hi not needed anywhere in this code!
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
	ora #$07		// enable vsync and line and sprite collision ints
	sta VERAINTENABLE
    cli    

	lda #1 
	sta gameMode
	sta player.playerActive
	lda #4
	sta invaders.setStartDrop.oldDeltaX
	lda #$24
	sta player.playerXpos
	stz player.playerXpos+1
	
	jsr player.addShields
	jsr player.addPlayer
	jsr player.addPlayerLives
	jsr invaders.initialiseInvaders
	
gameLoop:

	lda $ff			// wait for vsync semaphore
	beq gameLoop
	stz $ff
	jsr spriteEngine.updateVera

	lda gameMode
	cmp #1
	bne gametestmode2
	lda invaders.invadersLiving
	cmp #55
	beq arrayfull
	jsr invaders.add1Invader
	jmp gametestmode3
arrayfull:
	inc gameMode
	stz invaders.invaderArrayIndex
	stz invaders.livingCycle
	bra gametestmode3
gametestmode2:
	cmp #2
	bne gametestmode3
	lda invaders.deathTimer
	beq gmt2a
	dec invaders.deathTimer
	bne gametestmode3
	ldy invaders.dyingInvaderArrayRef
	ldx invaders.invaderArray,y
	lda #$00
	sta invaders.invaderArray,y
	lda #$80
	sta SpriteArray.status,x
	sta SpriteArray.updateReqd,x
	stz SpriteArray.ATTR1,x
	stz player.shotActive
    stz player.shotallowed
	bra gametestmode3
gmt2a:
	lda invaders.collisionType
	beq gmt2b
	jsr player.checkCollision
gmt2b:
	lda invaders.invadersLiving
	beq gametestmode4			//need to cahnge this to deal with none alive. next rack etc
	jsr invaders.findInvader
	bpl gmt2c
	stz invaders.invaderArrayIndex
	stz invaders.livingCycle
	jsr spriteEngine.testXLimit	// carry if we hit an edge
	bcc gmt2b	// go back and find an invader since we missed last pass
	jsr invaders.setStartDrop
	bra gmt2b	// now go find next invader to move 
gmt2c:
	jsr spriteEngine.process1Sprite
	inc invaders.livingCycle
	lda invaders.livingCycle
	cmp invaders.invadersLiving
	bne gametestmode3
	stz invaders.livingCycle
	lda invaders.setStopDrop.newXdelta
	beq gametestmode3
	jsr invaders.setStopDrop
gametestmode3:
	jsr player.getJoystick
	jsr player.processPlayer
	jsr player.processShot
	jmp gameLoop
	rts
gametestmode4:
	bra gametestmode4
}
gameMode: .byte 0
