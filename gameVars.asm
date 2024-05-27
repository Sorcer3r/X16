#importonce 

// all game variables

.const SPRITEALIENBASE = $13000
.const SPRITESHOTBASE = SPRITEALIENBASE + (64*14)           // add alien size * num alien images
.const SPRITESHIELDBASE = SPRITESHOTBASE + (32*15)         // add shot size * num shot images 
.const SPRITESPACESHIPBASE = SPRITESHIELDBASE + (32 * 24)   // add$ shield size * num shield images 
.const PALETTEBASE = $1FA00
game:{

arrayLoad:{
    status:         .byte 0     // bit 7: 0 = active,1=unused. 5:0 frame number (offset for imagePtr)
    imagePtr:       .byte 0     // image number 0-255 base. offset with status
    xLo:            .byte 0     // x 0:7
    xHi:            .byte 0     // x 8:15 / only 8:9 used by vera but kept full 16bit for sign
    yLo:            .byte 0     // y 0:7
    yHi:            .byte 0     // y 8:15 / only 8:9 used by vera but kept full 16bit for sign
    ATTR1:          .byte $0c   // as VERA reg 6: Collision Mask(7:4) zDepth(3:2) vFlip(1) hFlip(0)
    ATTR2:          .byte $50   // as VERA reg 7: height(7:6) width(5:4) palette (3:0)
    xDelta:         .byte 0     // x movement delta -128($80) to +127($7f). extended to 16 bit in engine      
    yDelta:         .byte 0     // y movement delta -128($80) to +127($7f). extended to 16 bit in engine
    speedxTicks:    .byte 0     // cycle counter for movement speed. incremented each frame by engine
    speedyTicks:    .byte 0     // cycle counter for movement speed. incremented each frame by engine
    frameTicks:     .byte 0     // cycle counter for frame animation. incremented each frame by engine
    speedxCtrl:     .byte 0     // do move when speedxTicks = speedxCtrl. reset speedxTicks
    speedyCtrl:     .byte 0     // do move when speedyTicks = speedyCtrl. reset speedyTicks
    frameCtrl:      .byte 0     // when frameTicks = frameCtrl, change frame number(Status). numFrames(7:6) determines sequence.  reset frameTicks
    numFrames:      .byte 0     // bit 7: normal(0)/reversing(1). bit 6  current direction up(0) down(1) 5:0 Number of frames for this sprite
    }


}