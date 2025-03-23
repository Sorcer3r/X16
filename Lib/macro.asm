.cpu _65c02
#importonce


// macro files
#import "constants.asm"
<<<<<<< HEAD
#import "\c64\MySource\XInvaders8080\zeroPage.asm"

.label veraAddr = $00fc  //: .byte 0,0,0,0

// 2 byte nop 65c02
.macro skip1Byte() {  
    .byte $24  // $42 etc dont work in emulator
}

// 3 byte nop 65c02
.macro skip2Bytes() {  
=======

*=*
.label veraAddr = $0100  //: .byte 0,0,0,0

.macro skip1Byte() {  // 2 byte nop 65c02
    .byte $24  // $42 etc dont work in emulator
}

.macro skip2Bytes() {  // 3 byte nop 65c02
>>>>>>> ea2c3ad874949ee70d5f63055848e174a7146777
    .byte  $2c  // $dc and $fc dont work in emulater
}

// 65c02 STP
.macro break(){         
    .byte $db
}

.macro addressRegister(control,address,increment,direction){
	.if (control == 0){
        // CTRL Bit 0 Controls which Data Byte to use,
        // either DATA0 or DATA1 respectively
        // using DATA0
        lda VERACTRL
        and #%11111110
		sta VERACTRL
	} else {
        // using DATA1
        lda VERACTRL
		ora #$01
		sta VERACTRL
	}
	lda #address
	sta VERAAddrLow
	lda #address>>8
	sta VERAAddrHigh
    lda #(increment<<4 ) | address>>16 | direction<<3
	sta VERAAddrBank
}

<<<<<<< HEAD
.macro loadHL(number){
    lda #<number
    sta HL
    lda #>number
    sta HL+1

}

.macro loadDE(number){
    lda #<number
    sta DE
    lda #>number
    sta DE+1
}

.macro loadBC(number){
    lda #<number
    sta BC
    lda #>number
    sta BC+1
}

.macro saveRegs(){
    ldx #$00
!:
    lda HL,x
    sta HLstack,x
    inx
    cpx #$06
    bne !-


}
.macro restoreRegs(){
    ldx #$00
!:
    lda HLstack,x
    sta HL,x
    inx
    cpx #$06
    bne !-

}





.macro addressRegisterByHL(control,addressHiBit,increment,direction) {
	
	.if (control == 0){
        // CTRL Bit 0 Controls which Data Byte to use,
        // either DATA0 or DATA1 respectively

        // using DATA0
        lda VERACTRL
        and #%11111110
		sta VERACTRL
	} else {
        // using DATA1
        lda VERACTRL
		ora #$01
		sta VERACTRL
	}
    lda HL
	//lda #address
	sta VERAAddrLow

	lda HL+1
    clc
    adc #$b0
    //lda #address>>8
	sta VERAAddrHigh
	
	lda #(increment<<4 ) | addressHiBit | direction<<3
	sta VERAAddrBank

}


.macro resetVera() {
	
=======
.macro resetVera(){
>>>>>>> ea2c3ad874949ee70d5f63055848e174a7146777
    lda #$80
    sta VERACTRL
}

.macro backupVeraAddrInfo(){
    lda VERACTRL
    sta veraAddr
    lda VERAAddrLow
    sta veraAddr + 1
    lda VERAAddrHigh
    sta veraAddr + 2
    lda VERAAddrBank
    sta veraAddr + 3
}

<<<<<<< HEAD
.macro restoreVeraAddrInfo()
{
=======
.macro restoreVeraAddrInfo(){
    lda veraAddr
    sta VERACTRL
    lda veraAddr + 1
    sta VERAAddrLow
    lda veraAddr + 2
    sta VERAAddrHigh
>>>>>>> ea2c3ad874949ee70d5f63055848e174a7146777
    sta veraAddr + 3
    lda VERAAddrBank
    lda veraAddr + 2
    sta VERAAddrHigh
    lda veraAddr + 1
    sta VERAAddrLow
    lda veraAddr
    sta VERACTRL
}

<<<<<<< HEAD

.macro setDCSel(dcSel)
{
=======
.macro setDCSel(dcSel){
>>>>>>> ea2c3ad874949ee70d5f63055848e174a7146777
    lda VERACTRL
    and #%10000001
    ora #dcSel<<1
    sta VERACTRL
 }

.macro copyVERAData(source,destination,bytecount){ // max 256 bytes
    // source greater than dest - regular copy
    .if (source > destination) {
    addressRegister(0,source,1,0)
    addressRegister(1,destination,1,0)
    } else {
    // source below dest - do backwards starting at end
    addressRegister(0,source + bytecount,1,1)
    addressRegister(1,destination+bytecount,1,1)
    }
    ldy #bytecount
copyloop:
    lda VERADATA0
    sta VERADATA1
    dey
    bpl copyloop
}

.macro copyDataToVera(source,destination,bytecount){     // source is x16 memory . dest is vera location, bytecount max 65535. destroys a
addressRegister(0,destination,1,0)
lda counter: $deaf
lda #bytecount & $ff
sta counter
lda #(bytecount >> 8) & $ff
sta counter+1
lda #source & $ff
sta copyFrom
lda #(source >>8) & $ff
sta copyFrom + 1

loop:
lda copyFrom: $deaf
sta VERADATA0
inc copyFrom
bne skip1
inc copyFrom+1
skip1:
dec counter
bne loop
dec counter+1
bpl loop
}