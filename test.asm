.cpu _65c02
.const CHROUT = $FFD2
.const STOP = $FFE1
.const EXTAPI = $FEAB
.const MOUSE_CONFIG = $FF68
.const SCREEN_MODE = $FF5F

.const TMP1 = $22
.const r0 = $02

start:
        sec
        jsr SCREEN_MODE //; get the screen size to pass to MOUSE_CONFIG
        lda #1
        //jsr MOUSE_CONFIG
loop:
        wai //; wait for interrupt
        lda #9 //; ps2data_raw
        jsr EXTAPI
//        beq aftermouse
        stx TMP1
        ora #0
//        beq afterkbd
        beq aftermouse
        jsr print_hex_byte
        lda #13
        jsr CHROUT
        bra aftermouse
afterkbd:
        ldx TMP1
        beq aftermouse
        ldx #0
printloop:
        lda r0,x
        phx
        jsr print_hex_byte
        plx
        inx
        cpx TMP1
        bne printloop
        lda #13
        jsr CHROUT
aftermouse:
        jsr STOP
        bne loop
done:
        rts

print_hex_byte:
        jsr byte_to_hex
        jsr CHROUT
        txa
        jsr CHROUT
        rts

byte_to_hex:
        pha
        and #$0f
        tax
        pla
        lsr
        lsr
        lsr
        lsr
        pha
        txa
        jsr @hexify
        tax
        pla
@hexify:
        cmp #10
        bcc @nothex
        adc #$66
@nothex:
        eor #%00110000
        rts