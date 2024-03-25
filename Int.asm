.cpu _65c02
#importonce
// interrupt routine to update sprites
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm" 

moveSpritesInt:{
    addressRegister(0,VRAMPalette+2,1,0)
    lda $9f27
    and #$2
    bne lineInt

    lda #$ff        // reset col 1 to white
    sta VERADATA0
    sta VERADATA0
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
    lda VERAINTENABLE
    and #$7f  // clear bit 8 (line int)
    sta VERAINTENABLE
    lda #$01
    sta $ff     // vsync semaphore flag to rest of code.
exit:
    lda VERAINTSTATUS 
    ora #$03  // set bit 0,1 to clear int flag
    sta VERAINTSTATUS
    jmp intReturn: $deaf

lineInt:
    lda VERAINTENABLE
    and #$40
    bne lowerHalf
    lda VERASCANLINE
    cmp #$30
    bne line1
    stz VERADATA0
    lda #$0f
    sta VERADATA0
    lda #$50
    bra lineExit
line1:    
    lda #$ff
    sta VERADATA0
    sta VERADATA0
    lda VERAINTENABLE
    ora #$80
    sta VERAINTENABLE
    lda #$70
    //bra lineExit
lineExit:
    sta VERASCANLINE
lineExit2:
    bra exit
lowerHalf:
   lda VERASCANLINE
   cmp #$70
   bne lineExit2
    lda VERASCANLINE 
    lda #$f0
    sta VERADATA0
    stz VERADATA0
    lda #$30
    bra lineExit
}