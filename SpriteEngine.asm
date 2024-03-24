.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "gameVars.asm"


spriteEngine:{

processSprites:{
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
}

// check if at screen edges and reverse dir
checkLimits:{
    ldx #0
checkActive:    
    lda SpriteArray.status,x
    bmi checkNext
    lda SpriteArray.speedxTicks,x
    bne checkY
    lda SpriteArray.xDelta,x
    bmi checkLeft
    beq checkY
    //check right edge
    lda SpriteArray.xHi,x
    cmp #1      // was 2
    bne checkY
    lda SpriteArray.xLo,x
    cmp #$30 //48
    bcs reverseX
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
    lda SpriteArray.speedyTicks,x
    bne checkNext
    lda SpriteArray.yDelta,x
    bmi checkTop
    beq checkNext    //check Bottom edge
    //lda SpriteArray.yHi,x
    // cmp #1
    // bne checkNext     // never get to line 256 in x2 scale
    lda SpriteArray.yLo,x
    cmp #$d8 //224 - 8(sprite size)
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

copyGFXtoVera:{             // -$20 because files includes pallete data we dont need
    copyDataToVera(spriteFiles.spriteAliens,SPRITEALIENBASE,spriteFiles._spriteAliens - spriteFiles.spriteAliens - $20)
    copyDataToVera(spriteFiles.spriteShots,SPRITESHOTBASE,spriteFiles._spriteShots - spriteFiles.spriteShots - $20)
    copyDataToVera(spriteFiles.spriteShieldbase,SPRITESHIELDBASE,spriteFiles._spriteShieldbase - spriteFiles.spriteShieldbase - $20)
    copyDataToVera(spriteFiles.spriteSpaceship,SPRITESPACESHIPBASE,spriteFiles._spriteSpaceship - spriteFiles.spriteSpaceship - $20)
    copyDataToVera(spriteFiles.tileSet,VRAM_lowerchars,64*8)
    rts
}

buildSpriteAddressTable:{
	lda #<(SPRITEALIENBASE >> 5) & $ff			//lo
	sta loAdd
	lda #>(SPRITEALIENBASE >>5)			//hi
	ldy #$00 	// offset in array
	sta hiAdd
	// aliens
	lda #2			//16*8
	sta spriteStep
	ldx #$0a	// 10 of these
	jsr fillArray
	// shots
	// y and pointers continue
	lda #1			// 8*8
	sta spriteStep
	ldx #$0f	// 15 of these 
	jsr fillArray
	// shield
	// step stays same, y and pointers continue
	ldx #$18	// 24 of these 
	jsr fillArray
	lda #$04	// 32*8
	sta spriteStep
	ldx #$02	// 2 sprites
fillArray:	
	lda hiAdd: #$00
	sta SpriteArray.addressTableHi,y
	lda loAdd: #$00
	sta SpriteArray.addressTableLo,y
	clc
	adc spriteStep: #$00	// point to next sprite(vera addressing)
	sta loAdd
	iny
	dex
	bne fillArray
	rts
}

insertIntoArray:{
    .label arrayAddr = $fd 
    jsr findArraySlot
    cpx #SpriteArray.TOTALSPRITES
    beq exit    // no room at the inn, not added
    //txa
    //clc
    //adc #<SpriteArray.status
    lda #<SpriteArray.status
    sta arrayAddr
    lda #>SpriteArray.status
    sta arrayAddr+1
    txa
    tay     // y is now slot offset
    ldx #$00
insert1:
    lda game.arrayLoad,x
    sta (arrayAddr),y
    //sta arrayAddr: $deaf,x
    lda arrayAddr
    clc
    adc #$80
    sta arrayAddr
    lda arrayAddr+1
    adc #0
    sta arrayAddr+1
    inx
    cpx #$11        // 16 parameters to copy
    bne insert1
exit:
    rts
}

findArraySlot:{     // x = index into array, $80 if no slot
    ldx #0
checkNext:
    lda SpriteArray.status,x
    bpl foundSlot
    inx
    cpx #SpriteArray.TOTALSPRITES
    bne checkNext
foundSlot:
    rts
}

*=$6000 "Sprite Data files"
spriteFiles:{
// sprite data sets#import "SpriteArray.asm"

spriteAliens:
#import "sprites 10 16x8(64).asm"
_spriteAliens:

spriteShots:
#import "shots 15 8x8(32).asm"
_spriteShots:

spriteShieldbase:
#import "shieldbase 6x4 8x8(32).asm"
_spriteShieldbase:

spriteSpaceship:
#import "spaceship 2 32x8(128).asm"
_spriteSpaceship:

tileSet:
#import "tileset 8x8.asm"
_tileSet:
}
}