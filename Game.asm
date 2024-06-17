.cpu _65c02
#importonce 

#import "Lib\constants.asm"
#import "Lib\petscii.asm"
#import "Lib\macro.asm"
#import "Lib\kernal_routines.asm"


*=$0801
	BasicUpstart2(main)
	
main: {
	jsr Music.IRQ_SoundSetup

	jsr titleScreen.playTitleScreen
	
	jsr Music.Restore_INT
	wai
	rts

}
#import "TitleScreen.asm"
//#import "playTitleMusic.asm"