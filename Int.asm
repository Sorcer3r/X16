.cpu _65c02
#importonce
// interrupt routine to update sprites
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm" 
#import "invaders.asm"
#import "invaders8080code.asm"

moveSpritesInt:{
    addressRegister(0,VRAMPalette+2,1,0)
    lda $9f27
    and #$04
    beq notSprite
    jsr spriteCollision
notSprite:    
    lda $9f27
    and #$02
    beq notline
    jsr lineInt
notline:
    lda $9f27
    and #$01
    beq exit
    lda #$ff        // reset col 1 to white (vblank here)
    sta VERADATA0
    sta VERADATA0
    jsr inv8080.ScanLine224
    lda VERAINTENABLE
    and #$7f  // clear bit 8 (line int)
    sta VERAINTENABLE
    lda #$01
    sta $ff     // vsync semaphore flag to rest of code.
exit:
    lda VERAINTSTATUS 
    ora #$07  // set bit 1,2 to clear int flag (handle vsync in main loop!)
    sta VERAINTSTATUS
    jmp intReturn: $deaf

lineInt:
    lda VERAINTENABLE
    and #$40
    bne lowerHalf               // are we below line 255 (480 lines each line is 2 pixels in double mode)
    lda VERASCANLINE
    cmp #$40    
    bne line1
    stz VERADATA0               // set colour to red for spaceship line if line $30 (24d)
    lda #$0f
    sta VERADATA0
    lda #$60                    // next int at line $50 (40d) to set back to white
    bra lineExit
line1:                          // gets here if in top half and not line 48d $30
    cmp #$60
    bne line2    
    lda #$ff                    // set colour back to white
    sta VERADATA0
    sta VERADATA0
    lda #$e0                    //line 224 (half way) (equiv 112 for 8080 code int!)
    bra lineExit
line2:
    cmp #$e0
    bne lineExit2    
    jsr inv8080.ScanLine96
    lda VERAINTENABLE
    ora #$80                    // set bit 8 for irq line (next is in bottom half)
    sta VERAINTENABLE
    lda #$70                    // set next int line to $70 in bottom half 
    //bra lineExit
lineExit:
    sta VERASCANLINE
lineExit2:
    //bra exit
    rts
lowerHalf:
    lda VERASCANLINE
    cmp #$70                    // line $170 (368d)
    bne lowerHalf2                // no then exit
    //lda VERASCANLINE            // set coluor to green
    lda #$f0
    sta VERADATA0
    stz VERADATA0
    lda #$c2            // set next line int to $38 (48d) for red (vblank will occor before to reset white for score)
    bra lineExit
lowerHalf2:
    cmp #$c2            // bottom line colour 0 is white
    bne lineExit2                // no then exit
    lda #$ff
    sta VERADATA0
    sta VERADATA0
    lda #$40
    bra lineExit

spriteCollision:{
    lda $9f27
    and #$f0        // mask collision bits
    lsr
    lsr
    lsr
    lsr
    sta invaders.collisionType
    rts
}
}