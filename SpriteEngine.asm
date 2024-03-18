.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm  "

spriteEngine:{

processSprites:
    ldx #0
process:     
    lda SpriteArray.status,x
    bpl spriteActive
    jmp nextSprite
spriteActive:        
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
    bne nextSprite
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
    bra nextSprite
spriteInc: 
    //counting up
    inc SpriteArray.status,x
    tya
    //lda SpriteArray.numFrames,x
    and #%00111111              // mask off reverse and dir bits
    dec // because we count from 0 and frame count is total number of frames
    cmp SpriteArray.status,x
    bne nextSprite
reverseDir:  
    tya
    eor #%01000000
    sta SpriteArray.numFrames,x
    bra nextSprite
notreversable:    // inc to framemax then back to 0
    inc SpriteArray.status,x
    lda SpriteArray.status,x
    cmp SpriteArray.numFrames,x
    bne nextSprite
    stz SpriteArray.status,x

nextSprite:
    inx
    cpx #SpriteArray.TOTALSPRITES
    beq exit
    jmp process
exit:
    rts


// check if at screen edges and reverse dir
checkLimits:
    ldx #0
checkActive:    
    lda SpriteArray.status,x
    bmi checkNext
    lda SpriteArray.xDelta,x
    bmi checkLeft
    //check right edge
    lda SpriteArray.xHi,x
    cmp #2
    bne checkY
    lda SpriteArray.xLo,x
    bmi reverseX
    bra checkY
checkLeft:
    lda SpriteArray.xHi,x
    bpl checkY
reverseX:
    lda #0
    sec
    sbc SpriteArray.xDelta,x
    sta SpriteArray.xDelta,x


checkY:
    lda SpriteArray.yDelta,x
    bmi checkTop
    //check Bottom edge
    lda SpriteArray.yHi,x
    cmp #1
    bne checkNext
    lda SpriteArray.yLo,x
    cmp #$d0 /256+224
    bcs reverseY
    bra checkNext
checkTop: 
    lda SpriteArray.yHi,x
    bpl checkNext
reverseY:
    lda #0
    sec
    sbc SpriteArray.yDelta,x
    sta SpriteArray.yDelta,x   

checkNext:
    inx
    cmp #SpriteArray.TOTALSPRITES
    bne checkActive
    rts
}