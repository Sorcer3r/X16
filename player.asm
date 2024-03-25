.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm"
#import "gameVars.asm"
#import "SpriteEngine.asm"

player:{

addShields:{
    // left starts at 48 set in shieldarrayload
    // add 64 for each shield x
    // y  = b8,c0
    lda #$30    //48 left edge
    sta shieldX
    ldx #4
    stx shieldCount
add1:
    ldx shieldX: #$00       // x position
    jsr addShield
    lda shieldX         //add 64 to next shield
    clc
    adc #$40
    sta shieldX
    dec shieldCount
    bne add1
    rts
}

addShield:{         // y = b0 (top) shieldx = left
    stx shieldLeft
    jsr shieldArrayLoad
    ldx #2
addBottomLoop:   
    phx
    lda shieldLeft: #$00
    sta game.arrayLoad.xLo
    stz game.arrayLoad.xHi
    ldy #3
addTopLoop:
    phy
    jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    lda game.arrayLoad.xLo
    clc
    adc #$08
    sta game.arrayLoad.xLo
    lda game.arrayLoad.xHi
    adc #$00
    sta game.arrayLoad.xHi
    inc game.arrayLoad.imagePtr   //frame
    ply
    dey
    bne addTopLoop
    lda #$c0    //second row
    sta game.arrayLoad.yLo
    plx
    dex
    bne addBottomLoop
    rts
}

shieldArrayLoad:{
lda #$19 //topleft image
sta game.arrayLoad.imagePtr
lda #$30
sta game.arrayLoad.xLo
lda #$b8
sta game.arrayLoad.yLo
lda #$0c
sta game.arrayLoad.ATTR1
lda #$00
sta game.arrayLoad.ATTR2
lda #$00
sta game.arrayLoad.status
sta game.arrayLoad.xHi
sta game.arrayLoad.yHi
sta game.arrayLoad.xDelta
sta game.arrayLoad.yDelta
sta game.arrayLoad.speedxTicks
sta game.arrayLoad.speedyTicks
sta game.arrayLoad.frameTicks
sta game.arrayLoad.speedxCtrl
sta game.arrayLoad.speedyCtrl
sta game.arrayLoad.frameCtrl
sta game.arrayLoad.numFrames
rts
}

addPlayerLives:{
    jsr shieldArrayLoad //put some basic data in
    lda #$e4
    sta game.arrayLoad.yLo
    lda #$10
    sta game.arrayLoad.ATTR2
    lda #6
    sta game.arrayLoad.imagePtr
    lda #$28
    sta game.arrayLoad.xLo
    jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    lda #$40
    sta game.arrayLoad.xLo
    jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    lda #$58
    sta game.arrayLoad.xLo
    jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    rts
}

addPlayer:{
    jsr shieldArrayLoad //put some basic data in
    lda #$d0
    sta game.arrayLoad.yLo
    lda #$10
    sta game.arrayLoad.ATTR2
    lda #6
    sta game.arrayLoad.imagePtr
    lda #$24
    sta game.arrayLoad.xLo
    jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    rts
}

shieldCount: .byte $00
lives: .byte $03
player: .byte 0 // 0 = alive, 1/2 is explosions
}


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
	