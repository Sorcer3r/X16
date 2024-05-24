.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "gameVars.asm"
#import "SpriteEngine.asm"

invaders:{

initialiseInvaders:{
    //x = 28 + 24per
    //y =120 - 26 per row
    lda #$30  // 28
    sta setInvaderBasics.setXlo
    lda #$78 // 120 
    sta setInvaderBasics.setYlo
    lda #$04
    sta setInvaderBasics.setType
    lda #$00
    sta setInvaderBasics.setXhi
    sta invaderArrayIndex
    sta invaderArrayX
    sta invaderArrayY
    sta invadersLiving
    sta invadersFalling
    sta setStopDrop.newXdelta
    rts
}
// build 11*5 array 1st row is lowest
add1Invader:{
    jsr setInvaderBasics
    inc invadersLiving
    ldy invadersLiving
    jsr spriteEngine.insertIntoArray        // returns slot used in y
    ldx invaderArrayIndex
    lda invadersLiving
    sta invaderArray,x      //array value is sprite#
    inc invaderArrayIndex
    inc invaderArrayX
    lda invaderArrayX
    cmp #11
    beq nextRow
    lda setInvaderBasics.setXlo
    clc
    adc #20 //24 x offset
    sta setInvaderBasics.setXlo
    lda setInvaderBasics.setXhi
    adc #0
    sta setInvaderBasics.setXhi
    bra exit
nextRow:
    stz invaderArrayX
    stz setInvaderBasics.setXhi
    lda #$30  // 28
    sta setInvaderBasics.setXlo
    lda setInvaderBasics.setYlo
    sec
    sbc #12     // 12 y shiftr row
    sta setInvaderBasics.setYlo
    inc invaderArrayY
    ldy invaderArrayY
    lda invaderYSprite,y
    sta setInvaderBasics.setType
exit:    
    rts
}

setInvaderBasics:{
lda setType: #$00
sta game.arrayLoad.imagePtr
lda #2
sta game.arrayLoad.numFrames
lda setXlo: #$00
sta game.arrayLoad.xLo
lda setXhi: #$00
sta game.arrayLoad.xHi
lda setYlo: #$00
sta game.arrayLoad.yLo
lda #$bc  // collision mask 1011xxxx, xxxx1100 zdepth 3
sta game.arrayLoad.ATTR1
lda #$10
sta game.arrayLoad.ATTR2
lda #4                     //default x delta
sta game.arrayLoad.xDelta
lda #$00
sta game.arrayLoad.status
sta game.arrayLoad.yHi
sta game.arrayLoad.yDelta
sta game.arrayLoad.speedxTicks
sta game.arrayLoad.speedyTicks
sta game.arrayLoad.frameTicks
sta game.arrayLoad.speedxCtrl
sta game.arrayLoad.speedyCtrl
sta game.arrayLoad.frameCtrl
rts
}

setStopDrop:{
    ldy #$00
setStop:
    lda invaderArray,y
    beq next
    tax
    stz SpriteArray.yDelta,x    //zero Y delta
    lda newXdelta: #$00 
    sta SpriteArray.xDelta,x    // restore x delta (already inverted from set fall)
next:
    iny
    cpy #55
    bne setStop
    stz newXdelta
    rts
}

setStartDrop:{
    ldy #$00
    //break()
setStart:
    lda invaderArray,y
    beq next
    tax
    stz SpriteArray.xDelta,x    //zero x delta
    lda #8 
    sta SpriteArray.yDelta,x    // set Y delta
next:
    iny
    cpy #55
    bne setStart
    lda #0
    sec
    sbc oldDeltaX: #$04
    sta oldDeltaX
    sta setStopDrop.newXdelta
    rts
}

findInvader:{
	ldy invaderArrayIndex
findInv1:
	lda invaderArray,y
	bne alive
    iny	
//	cpy #56
	bne findInv1
alive:
    iny
	sty invaderArrayIndex
	tax	
	rts
}

invaderArray:       .fill 55,0
invaderArrayEnd:    .byte $ff
invadersLiving:     .byte 0
invaderArrayIndex:  .byte 0 
invaderArrayX:      .byte 0
invaderArrayY:      .byte 0
invadersFalling:    .byte 0
livingCycle:        .byte 0
currentInvader:     .byte 0
collisionType:      .byte 0
dyingInvaderSpriteRef: .byte 0
dyingInvaderArrayRef: .byte 0
deathTimer:         .byte 0
invaderYSprite:     .byte 4,4,2,2,0

}