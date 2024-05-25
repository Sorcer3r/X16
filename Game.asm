.cpu _65c02
#import "zeroPage.asm"
#import "Int.asm"
#import "screen.asm"
#import "player.asm"
#import "gameVars.asm"
#import "invaders8080vars.asm"
#import "invaders8080code.asm"

*=$0801
	BasicUpstart2(main)
main: {
	backupVeraAddrInfo()

    jsr spriteEngine.copyGFXtoVera
	jsr spriteEngine.buildSpriteAddressTable

	// todo  mod colour pallete to make 5 full green 0f0


    lda VERA_DC_video
    ora #SPRITEENABLE
    sta VERA_DC_video
	lda #DCSCALEx2				// screen will be 640/2 * 480/2  320*240 . so Y hi not needed anywhere in this code!
	sta VERA_DC_hscale
	sta VERA_DC_vscale
	lda #VRAM_lowerchars >>9
	and #$fc
	sta VERA_L1_tilebase

	//jsr screen.cls
	//jsr screen.scoreText
	//jsr setupSomeSprites  //this is garbage code but got some sprites active :)

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
	restoreVeraAddrInfo() 
	lda #$40			// first line int is line 64 for red colour1
	sta VERASCANLINE 
	lda VERAINTENABLE  
	and #$7f		// clear bit 8 line int
	ora #$07		// enable vsync and line and sprite collision ints
	sta VERAINTENABLE
    //cli    

//  start here
	jmp inv8080.reset

}
