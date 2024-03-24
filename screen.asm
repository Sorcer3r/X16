.cpu _65c02
#import "Lib\macro.asm"
#import "Lib\constants.asm"

screen:{

cls:{
addressRegister(0,VRAM_layer1_map,2,0)
addressRegister(1,VRAM_layer1_map+1,2,0)
ldy #30
lda #0
cls1:
ldx #0
cls2:
stz VERADATA0
stz VERADATA1
dex
bne cls2
dey
bne cls1
rts
}

scoreText:{
	addressRegister(0,VRAM_layer1_map+22,2,0)
	addressRegister(1,VRAM_layer1_map+23,2,0)
	ldx #$0
score1:
	lda topLine,x
	bmi nextLine
	sta VERADATA0
	lda #$01
	sta VERADATA1
	inx
	bne score1
nextLine:
	addressRegister(0,VRAM_layer1_map+26+512,2,0)
	addressRegister(1,VRAM_layer1_map+27+512,2,0)
	ldx #$00
score2:
	lda secondLine,x
	bmi bottomLine
	sta VERADATA0
	lda #$01
	sta VERADATA1
	inx
	bne score2
bottomLine:
	addressRegister(0,VRAM_layer1_map+(28*256),1,0)
	ldx #40
	ldy #$01
	lda #62
botline1:
	sta VERADATA0
	sty VERADATA0
	dex
	bne botline1
	rts
topLine: .byte 18,2,14,17,4,36,27,37,38,38,7,8,63,18,2,14,17,4,255
secondLine: .byte 26,26,26,26,38,38,38,38,38,38,26,26,26,26,255
}

timer:
{
    ldx #3
!:
    inc tick,x
    lda tick,x
    cmp #10
    bne t1
    lda #0
    sta tick,x
    dex
    cpx #$ff
    bne !-
t1:
    addressRegister(0,VRAM_layer1_map+2,1,0)
    ldx #0
!:
    lda tick,x
    clc
    adc #26
    sta VERADATA0
    lda #1
    sta VERADATA0
    inx
    cpx #4
    bne !-
rts
tick: .byte 0,0,0,0
}

}