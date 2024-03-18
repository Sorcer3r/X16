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
    bmi nextSprite
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
    bne processSprite
    jmp intReturn: $deaf
}