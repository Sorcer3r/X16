.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm"
#import "gameConstants.asm"
#import "gameVars.asm"
#import "SpriteEngine.asm"
#import "Lib\kernal_routines.asm"
#import "invaders.asm"


player:{

addShields:{
    // left starts at 48 set in shieldarrayload
    // add 64 for each shield x
    // y  = b8,c0
    ldy #$40    //shields in 64-87 $40-$57
    sty shieldPos //position in array
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
    lda #$d0        //collision mask 1101xxxx
    ora game.arrayLoad.ATTR1
    sta game.arrayLoad.ATTR1
    ldx #2
addBottomLoop:   
    phx
    lda shieldLeft: #$00
    sta game.arrayLoad.xLo
    stz game.arrayLoad.xHi
    ldy #3
addTopLoop:
    phy
    //jsr spriteEngine.findArraySlot  // in y
    ldy shieldPos
    jsr spriteEngine.insertIntoArray
    inc shieldPos
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
    lda lives
addLoop:
    dec
    beq exit
    pha
    lda #$59        //90 - 1
    clc 
    adc lives
    tay
    //jsr spriteEngine.findArraySlot  // in y
    jsr spriteEngine.insertIntoArray
    lda game.arrayLoad.xLo
    clc
    adc #$18
    sta game.arrayLoad.xLo
    pla
    bra addLoop
exit:
    rts
}

addPlayer:{
    lda playerActive
    beq exit
    jsr shieldArrayLoad //put some basic data in
    lda #$d0
    sta game.arrayLoad.yLo
    lda #$10
    sta game.arrayLoad.ATTR2
    lda #$30        // collision mask 0011xxxx
    ora game.arrayLoad.ATTR1
    sta game.arrayLoad.ATTR1
    lda #6
    sta game.arrayLoad.imagePtr
    lda playerXpos
    sta game.arrayLoad.xLo
    ldy #playerSpriteNum        //60 = player
    jsr spriteEngine.insertIntoArray
exit:
    rts
}

getJoystick:{
    //  SNES | B | Y |SEL    |STA   |UP     |DN    |LT    |RT    |
    //  KBD  | Z | A |L SHIFT|ENTER |CUR UP |CUR DN|CUR LT|CUR RT|
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
}

processPlayer:{
    lda playerActive
    beq exit
    lda leftPressed
    bne checkRight
    dec playerXpos
    lda playerXpos
    cmp #$ff
    bne checkRight
    dec playerXpos+1
checkRight:
    lda rightPressed
    bne move1
    inc playerXpos
    bne move1
    inc playerXpos+1
move1:
    lda playerXpos+1
    bne checkRightLimit
checklimits:
    lda playerXpos
    cmp #$10    //left limit
    bcs finishMove
    lda #$10
    bra finishMove
checkRightLimit:
    lda playerXpos
    cmp #$20
    bcc finishMove
    lda #$20       
finishMove:
    sta playerXpos
    ldx #playerSpriteNum
    sta SpriteArray.xLo,x
    lda playerXpos+1
    sta SpriteArray.xHi,x

    lda firePressed
    ora shotallowed
    ora shotActive
    bne exit
    bra addShot
exit:
    rts
}

addShot:{
    jsr shieldArrayLoad
    ldy #shotSpriteNum
    ldx #playerSpriteNum
    lda SpriteArray.xLo,x
    clc
    adc #$05
    sta game.arrayLoad.xLo
    lda SpriteArray.xHi,x
    adc #$00
    sta game.arrayLoad.xHi
    lda #$cc        //y start pos
    sta game.arrayLoad.yLo
    lda #$0a        //shot sprite image
    sta game.arrayLoad.imagePtr
    lda #$fc  // -4 in y dir
    sta game.arrayLoad.yDelta
    lda #$01
    sta game.arrayLoad.speedyCtrl
    lda #$01
    sta game.arrayLoad.numFrames
    lda #$f0            // collision mask 1111xxxx
    ora game.arrayLoad.ATTR1
    sta game.arrayLoad.ATTR1
    jsr spriteEngine.insertIntoArray
    lda #$01
    sta shotActive
    rts
}

processShot:{
    ldx #shotSpriteNum
    lda shotActive
    beq exit
    lda shotallowed
    bne shotCountdown
    jsr spriteEngine.process1Sprite
    lda SpriteArray.yLo,x
    cmp #$1c
    bcs exit
    //clc
    //adc #$04
    //sta SpriteArray.yLo,x
    lda #$0b        // shot explosion
    sta SpriteArray.imagePtr,x
    lda #$20
    sta shotallowed
    lda #$80
    sta shotActive
shotCountdown:
    dec shotallowed
    beq clearShot
    cmp #$02
    bne exit
    stz SpriteArray.ATTR1,x        //move to layer 0 and clears collision mask
    bra exit
clearShot:
    lda #$80
    sta SpriteArray.status,x
    stz shotActive
    stz shotallowed
exit:
    rts
}

checkCollision:{
    // masks
    //  bullet  %11110000
    //  bomb    %01110000
    //  invader %10110000
    //  shield  %11010000
    //  ufo     %01000000
    //  player  %00110000
    //
    //  bullet hits:
    //  bomb    %00000111   $07
    //  invader %00001011   $0c
    //  shield  %00001101   $0d
    //  ufo     %00000100   $04
    //
    //  bomb hits:
    //  shield  %00000101   $05
    //  player  %00000011   $03
    //
    //  alien hits:
    //  shield  %00001001   $09
    //  invader collision is Y = bottm row - end game

    lda invaders.collisionType
    cmp #$0b        //bullet alien
    beq bulletHitAlien
    cmp #$0d
    beq bulletHitBase
    cmp #$07
    beq bulletHitBomb
    //etc 
    stz invaders.collisionType
    rts
}
bulletHitAlien:{
    ldx #shotSpriteNum
    lda SpriteArray.xLo,x
    sta bulletXlo
    lda SpriteArray.xHi,x
    sta bulletXhi
    lda SpriteArray.yLo,x
    sta bulletY
    jsr findHitAlien
    //break()
    stz invaders.collisionType
    rts
}
bulletHitBase:{
    ldx #shotSpriteNum
    lda SpriteArray.xLo,x
    sta bulletXlo
    lda SpriteArray.xHi,x
    sta bulletXhi
    lda SpriteArray.yLo,x
    sta bulletY
    break()
    stz invaders.collisionType
    rts
}
bulletHitBomb:{
    stz invaders.collisionType
    rts
}

findHitAlien:{
    ldx #$00
findLivingAlien:
    lda invaders.invaderArray,x
    beq checkNext
    tay
    lda SpriteArray.yLo,y
    cmp bulletY
    bne checkNext
    //got y match
    //break()
   	sec				// set carry for borrow
	lda SpriteArray.xLo,y
	sbc bulletXlo
    sta hitXdiff
	// no need to store result since we dont care about bit 9, just need the carry status
	lda SpriteArray.xHi,y
	sbc bulletXhi
    bpl skip2Comp
    lda #$00
    clc
    sbc hitXdiff    //make positive
    sta hitXdiff
skip2Comp:
    lda hitXdiff
    cmp #$0a    //are we <10 from sprite x
    bcs checkNext
    //got hit
    lda #$01
    sta SpriteArray.numFrames,y
    lda #$00
    sta SpriteArray.status,y
    lda #$ff
    sta SpriteArray.frameCtrl,y
    lda #$09
    sta SpriteArray.imagePtr,y  // change icon to expl
    sta SpriteArray.updateReqd,y
    //stz invaders.invaderArray,x // kill alien in invader array
    //sty invaders.dyingInvaderSpriteRef
    stx invaders.dyingInvaderArrayRef
    lda #$10
    sta invaders.deathTimer
   // lda #$04
   // sta VERAINTSTATUS   //clear collision int
    ldx #shotSpriteNum
    lda #$80
    sta SpriteArray.status,x
    // lda #$09
	// sta SpriteArray.imagePtr,x
    lda #$02
    sta SpriteArray.xHi,x
    // sta SpriteArray.numFrames,x
    // sta SpriteArray.frameCtrl,x
    // sta SpriteArray.frameTicks,x
    sta SpriteArray.updateReqd,x
    //stz SpriteArray.ATTR1,x        //move to layer 0 and clears collision mask
    dec invaders.invadersLiving
    rts
checkNext:
    inx
    cpx #55
    bne findLivingAlien
    rts
}
kbdJoy1: .byte $00
kbdJoy2: .byte $00
kbdJoy3: .byte $00
firePressed: .byte 0
leftPressed: .byte 0
rightPressed: .byte 0
startPressed: .byte 0
shieldCount: .byte $00
shieldPos:  .byte 0
lives: .byte $03
player: .byte 0 // 0 = alive, 1/2 is explosions
playerXpos: .word 0
playerActive: .byte 0
shotActive: .byte 0         // non zero if active, -ve if exploding
shotallowed: .byte 0    // countdown until zero before can fire
bulletXlo:  .byte 0
bulletXhi:  .byte 0
bulletY:    .byte 0
hitXdiff:   .byte 0
}
