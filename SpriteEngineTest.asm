.cpu _65c02

#import "Lib\constants.asm"
#import "Lib\petscii.asm"
#import "Int.asm"
#import "Lib\macro.asm"
#import "SpriteArray.asm"

*=$0801
	BasicUpstart2(main)
main: {
	backupVeraAddrInfo()
    copyDataToVera(spriteData,SPRITEDATA,spriteDataEnd-spriteData)
	copyDataToVera(spriteMore,SPRITEDATA+spriteDataEnd-spriteData,spriteMoreEnd-spriteMore)

    lda VERA_DC_video
    ora #SPRITEENABLE
    sta VERA_DC_video

	jsr setupSomeSprites



//    addressRegister(0,SPRITEREGBASE,1,0)
//    addressRegister(1,SPRITEREGBASE + 8,1,0)

	
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
    cli    
  	restoreVeraAddrInfo()    
	rts
}


setupSomeSprites:{
	ldx #0
spraddr:
	txa
	asl
	asl
	clc
	adc SpriteArray.addressTableLo,x
	sta SpriteArray.addressTableLo,x
	inx
	cpx #8
	bne spraddr

	ldx #0
spraddr1:
	txa
	asl
	asl
	asl
	asl

	clc
	adc #$a8
	sta SpriteArray.addressTableLo+8,x
	bcc l2
	inc SpriteArray.addressTableHi+8,x
l2:
	inx
	cpx #14
	bne spraddr1

	ldx #0			//sprite 0
	lda #10
	sta SpriteArray.xLo,x
	sta SpriteArray.yLo,x
	lda #0
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #1
	sta SpriteArray.xDelta,x
	sta SpriteArray.yDelta,x
	lda #3
	sta SpriteArray.speedxCtrl,x
	lda #5
	sta SpriteArray.speedyCtrl,x
	lda #4
	sta SpriteArray.frameCtrl,x
inx							//sprite 1
	lda #40
	sta SpriteArray.xLo,x
	sta SpriteArray.yLo,x
	lda #2
	sta SpriteArray.xHi,x
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #-1
	sta SpriteArray.xDelta,x
	lda #0
	sta SpriteArray.yDelta,x
	lda #7
	sta SpriteArray.speedxCtrl,x
	lda #0
	sta SpriteArray.speedyCtrl,x
		lda #30
	sta SpriteArray.frameCtrl,x
inx						//sprite 2
	lda #$f7
	sta SpriteArray.xLo,x
	lda #1
	sta SpriteArray.xHi,x
	lda #$fd
	sta SpriteArray.yLo,x
	lda#4
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #-1
	sta SpriteArray.xDelta,x
	lda #-2
	sta SpriteArray.yDelta,x
	lda #1
	sta SpriteArray.speedxCtrl,x
	lda #7
	sta SpriteArray.speedyCtrl,x
		lda #15
	sta SpriteArray.frameCtrl,x
inx								//sprite 3
	lda #20
	sta SpriteArray.xLo,x
	lda #87
	sta SpriteArray.yLo,x
	lda#6
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #3
	sta SpriteArray.xDelta,x
	lda #0
	sta SpriteArray.yDelta,x
	lda #1
	sta SpriteArray.speedxCtrl,x
	lda #5
	sta SpriteArray.speedyCtrl,x
		lda #10
	sta SpriteArray.frameCtrl,x
inx					//sprite 4
	lda #20
	sta SpriteArray.xLo,x
	lda #80
	sta SpriteArray.yLo,x
	lda #6
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x
	lda #-4
	sta SpriteArray.xDelta,x
	lda #0
	sta SpriteArray.yDelta,x
	lda #1
	sta SpriteArray.speedxCtrl,x
	lda #5
	sta SpriteArray.speedyCtrl,x
		lda #3
	sta SpriteArray.frameCtrl,x
inx					///sprite 5
	lda #8
	sta SpriteArray.xLo,x
	lda #15
	sta SpriteArray.yLo,x
	lda #8
	sta SpriteArray.imagePtr,x
	lda #0
	sta SpriteArray.status,x //enable
	lda #2
	sta SpriteArray.xDelta,x
	lda #1
	sta SpriteArray.yDelta,x
	lda #1
	sta SpriteArray.speedxCtrl,x
	lda #7
	sta SpriteArray.speedyCtrl,x
	lda #6
	sta SpriteArray.frameCtrl,x
	lda #$a0
	sta SpriteArray.ATTR2,x
	lda #$8a //#14  // set bit 7 for reversing sequence
	sta SpriteArray.numFrames,x

rts

}
*=$6000
//#import "SpriteArray.asm"
.align $100
spriteData:
.import binary "C:\c64\MySource\X16 - SpriteEngine\invaders.SPR"
spriteDataEnd:

spriteMore:
.import binary "C:\c64\MySource\X16 - SpriteEngine\flip10.RAW"
spriteMoreEnd:
