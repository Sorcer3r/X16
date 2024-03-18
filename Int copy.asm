.cpu _65c02
#importonce
// interrupt routine to update sprites
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm" 

moveSpritesInt:{
    addressRegister(0,VERASPRITEBASE,1,0)

    ldx #0
processSprite:
    lda SpriteArray.status,x
    bpl doSprite
    ldy #8
skipVera:    
    lda VERADATA0
    dey
    bne skipVera
    jmp nextSprite
doSprite:   
    inc SpriteArray.speedxTicks,x
    inc SpriteArray.speedyTicks,x
    inc SpriteArray.frameTicks,x
    
//do x Move checks
    lda SpriteArray.speedxTicks,x
    cmp SpriteArray.speedxCtrl,x
    bne noxMove
    stz SpriteArray.speedxTicks,x
    lda SpriteArray.xDelta,x
    beq noxMove
// add xDelta to x
	lda SpriteArray.xLo,x
    clc
	adc SpriteArray.xDelta,x
	sta SpriteArray.xLo,x
	lda SpriteArray.xDelta,x
	ldy #0
	dec
	bpl addxDeltaHi
	dey
addxDeltaHi:
	sty signxExtend 
	lda SpriteArray.xHi,x
	adc signxExtend: #00
	sta SpriteArray.xHi,x

noxMove:    //do y Move checks
    lda SpriteArray.speedyTicks,x
    cmp SpriteArray.speedyCtrl,x
    bne noyMove
    stz SpriteArray.speedyTicks,x
    lda SpriteArray.yDelta,x
    beq noyMove
// add yDelta to y
	lda SpriteArray.yLo,x
    clc
	adc SpriteArray.yDelta,x
	sta SpriteArray.yLo,x
	lda SpriteArray.yDelta,x
	ldy #0
	dec
	bpl addyDeltaHi
	dey
addyDeltaHi:
	sty signyExtend 
	lda SpriteArray.yHi,x
	adc signyExtend: #00
	sta SpriteArray.yHi,x

noyMove:        // do frame change checks
    lda SpriteArray.frameTicks,x
    cmp SpriteArray.frameCtrl,x
    bne updateSprite
    stz SpriteArray.frameTicks,x
    lda SpriteArray.numFrames,x
    bpl notreversable
    // bit 7 is set so sprite cycles 0>max>0
    tay
    and #%01000000      // are we counting up(0) or down (1)
    beq spriteInc
    //  counting down
    dec SpriteArray.status,x
    beq reverseDir
    bra updateSprite
spriteInc: 
    //counting up
    inc SpriteArray.status,x
    tya
    //lda SpriteArray.numFrames,x
    and #%00111111              // mask off reverse and dir bits
    dec // because we count from 0 and frame count is total number of frames
    cmp SpriteArray.status,x
    bne updateSprite
reverseDir:  
    tya
    eor #%01000000
    sta SpriteArray.numFrames,x
    bra updateSprite
notreversable:    // inc to framemax then back to 0
    inc SpriteArray.status,x
    lda SpriteArray.status,x
    cmp SpriteArray.numFrames,x
    bne updateSprite
    stz SpriteArray.status,x
    
updateSprite:
    lda SpriteArray.status,x
    clc
    adc SpriteArray.imagePtr,x
    tay
    lda SpriteArray.addressTableLo,y
    sta VERADATA0
    lda SpriteArray.addressTableHi,y
    sta VERADATA0
    lda SpriteArray.xLo,x
    sta VERADATA0
    lda SpriteArray.xHi,x
    sta VERADATA0
    lda SpriteArray.yLo,x
    sta VERADATA0
    lda SpriteArray.yHi,x
    sta VERADATA0
    lda SpriteArray.ATTR1,x
    sta VERADATA0
    lda SpriteArray.ATTR2,x
    sta VERADATA0
nextSprite:
    inx
    cpx #SpriteArray.TOTALSPRITES
    beq exit
    jmp processSprite
exit:
    jmp intReturn: $deaf
}