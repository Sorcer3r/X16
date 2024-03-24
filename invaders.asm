.cpu _65c02
#importonce
#import "SpriteArray.asm"
#import "Lib\constants.asm"
#import "Lib\macro.asm"
#import "gameVars.asm"
#import "SpriteEngine.asm"

invaders:{

// build 11*5 array 1st row is lowest
addInvader:{
stz game.status
lda #2 
sta game.numFrames
sta game.imagePtr
lda #55
sta game.xLo
sta game.yLo
stz game.xHi
stz game.yHi
lda #12
sta game.ATTR1
lda #$50
sta game.ATTR2
lda #1
sta game.xDelta
stz game.yDelta
stz game.speedxTicks
stz game.speedyTicks
stz game.frameTicks
stz game.speedxCtrl
stz game.speedyCtrl
stz game.frameCtrl
jsr spriteEngine.insertIntoArray
brk

}
}