.cpu _65c02
#importonce 

// No self modifying code is used in this program

// need to fix so starX is 0-159 + sign bit
// and y = 0-119 + sign bit
// then redo calc to add 160 to x if +ve
/// and 120 to y if +ve 
// before calc pos


#import "Lib\constants.asm"
#import "Lib\macro.asm"

.const maxDepth = 64 
.const numStars = 50

*=$22 "zeropage" virtual

// 16 bit maths storage
Xlo:        .byte $00
Xhi:        .byte $00
F:          .byte $00
Ylo:        .byte $00
Yhi:        .byte $00

// used by math routine
resLo:      .byte $00
resHi:      .byte $00

// random number storage
rndLo:     .byte $00
rndHi:     .byte $00


*=$0801
	BasicUpstart2(shoot)

shoot:{
    lda #$a5
    sta rndLo
    sta rndHi

    jsr setDisplay
	jsr clearScreen
    jsr initStarField

    lda #$00
    sta VERAAddrBank    // turn off bank 1 and step unless we need it
main1:
    //wai
l1:
    lda VERAINTENABLE
    and #$40
    beq l1
    lda #200
l2:
    cmp VERASCANLINE
    bne l1


//set colour0
    // stz VERAAddrLow
    // lda #$fa
    // sta VERAAddrHigh
    // lda #1
    // sta VERAAddrBank
    // lda #255
    // sta VERADATA0

    // lda #$00
    // sta VERAAddrBank    // turn off bank 1 and step until we need it
    ldx #numStars-1            // star counter 99-0

doAllStars:

    lda starsZ,x
    bne starExists      // if Z = 0 then 
    jsr createNewStar   // create a new one
starExists:
    jsr clearStar
    jsr calcBitmapPos8bpp
    jsr drawStar
    dec starsZ,x
    dex
    bpl doAllStars

//break()
//resetColor0
    // stz VERAAddrLow
    // lda #$fa
    // sta VERAAddrHigh
    // lda #1
    // sta VERAAddrBank
    // lda #0
    // sta VERADATA0

    bra main1
    rts
}

initStarField:{
    ldx #numStars-1
initNextStar:
    jsr createNewStar
    //jsr calcBitmapPos8bpp // do this so we have a calculated vera address in the array
    dex
    bpl initNextStar
    rts
}

createNewStar:{
    jsr rand16
    and #maxDepth-1
    //inc           // make non zero . do i need?
    sta starsZ,x
getY: 
    jsr rand16
    cmp #120
    bcs getY        // try again until <120
// maxYlimit:
//     cmp #120
//     bcc goodY       // if < 120 then OK
//                     // otherwise, we know carry is set
//     sbc #120      // so sub 120  
//     bra maxYlimit   // and check again
//goodY:
    sta starsY,x
//    stz starsYSign,x
    jsr rand16
//    bpl doneY
    and #$01
    sta starsYSign,x
//    inc starsYSign,x
//doneY:
getX:
    jsr rand16
    cmp #160
    bcs getX
    // bcc goodX
    // sbc #160
// goodX:
    sta starsX,x
//    stz starsXSign,x
    jsr rand16
//    bpl done
//    inc starsXSign,x
    and #$01
    sta starsXSign,x
done:    
    rts
}

//turn on/off star x from data
drawStar:{
    lda starsAddLo,x
    sta VERAAddrLow
    lda starsAddHi,x
    sta VERAAddrHigh
    lda VERADATA0            // white
    ora starsData,x
    sta VERADATA0
    rts
}

clearStar:{
    lda starsAddLo,x
    sta VERAAddrLow
    lda starsAddHi,x
    sta VERAAddrHigh
    lda starsData,x
    eor #$ff                // invert bits
    and VERADATA0
    sta VERADATA0
    rts
}
// set 320x240 1 bpp
setDisplay:{
    stz VERACTRL   //$9f25

    lda #64
    sta VERA_DC_hscale   //$9f2a

    ldx #64
    stx VERA_DC_vscale   //$9f2b

    ldy #%11010001  // Sprite and Layer0 enable, Output VGA,
    sty VERA_DC_video   //$9f29 

    lda #%00000100     //T256C=0, Bitmap mode, colour depth = 1bpp
    sta VERA_L0_config   //$9f2d
    stz VERA_L0_mapbase   //$9f2e
    stz VERA_L0_tilebase   //$9f2f
    stz $9f30   //L0_HSCROLL_L
    stz $9f31   //L0_HSCROLL_H
    stz $9f32   //L0_VSCROLL_L
    stz $9f33   //L0_VSCROLL_H
    rts
}
//clear bitmap screen

clearScreen:{
    stz VERAAddrLow   //$9f20
    stz VERAAddrHigh   //$9f21
    lda #%00010000
    sta VERAAddrBank   //$9f22 - Bank 0, step 1
    lda #$00   //sets the color to fill screen with (pixels off)

    // Clear 320x240@1c bitmap VRAM ($0:0000 to $0:2580)
    ldy #$f0        // 240 lines
LoopA_Y:
    ldx #$28        // 40 bytes/line
LoopA_X:
    sta VERADATA0  //$9f23
    //jsr delay
    dex
    bne LoopA_X
    dey
    bne LoopA_Y
    rts
}

delay:{
    pha
    lda #$FF
!loop:
    dec
    bne !loop-
    pla
    rts
}

// calculate bitmap position for star x on 8bpp 320*240
// position in starsXLo,starsXHi,starsY,starsZ
// star to calc in x
// result in starsAddLo,x starsAddHi,x starsData,x
calcBitmapPos8bpp:{
    lda starsZ,x
    tay
    lda depthTable,y    // Z multiplier (1/z)
    tay
    phy                 // save Z multiplier for later
    lda starsY,x
    jsr mul8            // Y*A = resHi.resLo
    lda starsYSign,x
    bne belowCenter
    lda #120
    sec
    sbc resHi           // centre line - scaled Y in resLo
    bra calcYLine
belowCenter:
    lda #120          // no need to clc its clear            
    adc resHi           // centre line + scaled Y in resLo
calcYLine:
    tay
    lda Atable40H,y
    sta starsAddHi,x
    tya
    and #$1f
    tay
    lda Atable40L,y
    sta starsAddLo,x
    ply                 // get Z multiplier
    lda starsX,x
    jsr mul8            // Y*A = resHi.resLo
    lda starsXSign,x
    bne rightOfCenter
    lda #160
    sec
    sbc resHi           // centre line - scaled x in resHi
    bra calcXPos
rightOfCenter:
    lda resHi           // no CLC since carry is clear here
    adc #160          // centre line + scaled x in resHi
    bcc calcXPos 
    tay
    lda #$20            // add 256pixels to address (256/8=32)
    clc
    adc starsAddLo,x
    sta starsAddLo,x
    lda starsAddHi,x
    adc #$00
    sta starsAddHi,x
    tya
calcXPos:
    pha
    lsr
    lsr
    lsr
    clc
    adc starsAddLo,x
    sta starsAddLo,x
    lda starsAddHi,x
    adc #$00
    sta starsAddHi,x
    pla
    and #$07            // work out which bit is set for this star
    tay
    lda AtableBit,y
    sta starsData,x
    rts
}


//  Multiplies two 8-bit factors to produce a 16-bit product
//  in about 153 cycles.
//  A = Muliplier
//  Y = multiplicand
//  return high 8 bits in A, low 8 bits in resLo
//  destroys Y
mul8:{
  lsr       // prime the carry bit for the loop
  sta resLo
  sty resHi
  lda #$00
  ldy #$08
loop:
//   At the start of the loop, one bit of multiplier has already been
//   shifted out into the carry.
  bcc noadd
  clc
  adc resHi
noadd:
  ror
  ror resLo  // pull another bit out for the next iteration
  dey        // inc/dec don't modify carry, only shifts and adds do
  bne loop
  sta resHi
  rts
}

// 16 bit random generator, returns rndLo in a
// rndLo rndHi must be init to non-zero
rand16:{
    lsr rndHi       // shift state >> 1 (hi first)
    ror rndLo
    bcc NoXor       // if shifted out bit = 0, done

    // Apply feedback taps
    lda rndHi
    eor #$B4        // taps mask (10110100)
    sta rndHi
NoXor:
    lda rndLo       // return low byte as random
    rts
}

// starfield storage
.align $100
starsX:         .fill numStars,0     // 0-159
starsXSign:     .fill numStars,0     // sign 0 = left of center, 1 = right of centre
.align $100
starsY:         .fill numStars,0     // 0-119 
starsYSign:     .fill numStars,0     // sign 0 = above centre, 1 = below centre
.align $100
starsZ:         .fill numStars,0     // depth maxdepth
starsData:       .fill numStars,0     // byte of data with bit set to show star
.align $100
starsAddLo:      .fill numStars,0
starsAddHi:      .fill numStars,0

// 1/z depth table for distance calc. handles as a fraction for 8*8 calc
.align $100
depthTable:     .byte $00
                .fill maxDepth-1, (1/(i+1))*255

// table for 40 wide screen addresses (16 bit) in Vera from 0
Atable40L:      .fill 32,(i*40) & 255
AtableBit:      .fill 8,$80>>i
.align $100
Atable40H:      .fill 240,((i*40)>>8) & 255



theEnd: