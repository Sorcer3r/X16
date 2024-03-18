#importonce
// Sprite Array
//
// 128 sprites uses 2k + 512 bytes for vera sprite image address table
// sprites can be mix of size and 4 or 8 bpp since location of each is stored in seperate table
// and indexed with sprite frame number in array

// for ref: using standard map sprites are $13000 - $1afff ($7fff bytes)
// this is space for 256 16*16 sprites at 16 colours

.align $100 
SpriteArray:
{

    .label TOTALSPRITES = 128   // allowable values 2,4,8,16,32,64,128 only
    .label TOTALFRAMES = 256    // number of frames in sprite image data 

    // masks
    .label hFlip = %00000001
    .label vFlip = %00000010
    .label zDepth = %00001100
    .label collision = %11110000
    .label height = %11000000
    .label width = %00110000
    .label palette = %00001111

    status:     .fill TOTALSPRITES,$80  // bit 7: 0 = active,1=unused. 6:0 frame number (offset for imagePtr)
    imagePtr:   .fill TOTALSPRITES,0    // image number 0-255 base. offset with status
    xLo:        .fill TOTALSPRITES,0    // x 0:7
    xHi:        .fill TOTALSPRITES,0    // x 8:15 / only 8:9 used by vera but kept full 16bit for sign
    yLo:        .fill TOTALSPRITES,0    // y 0:7
    yHi:        .fill TOTALSPRITES,0    // y 8:15 / only 8:9 used by vera but kept full 16bit for sign
    ATTR1:      .fill TOTALSPRITES,$0c   // as VERA reg 6: Collision Mask(7:4) zDepth(3:2) vFlip(1) hFlip(0)
    ATTR2:      .fill TOTALSPRITES,$50   // as VERA reg 7: height(7:6) width(5:4) palette (3:0)
    xDelta:     .fill TOTALSPRITES,1    // x movement delta -128($80) to +127($7f). extended to 16 bit in engine      
    yDelta:     .fill TOTALSPRITES,-1    // y movement delta -128($80) to +127($7f). extended to 16 bit in engine
    speedxTicks: .fill TOTALSPRITES,0    // cycle counter for movement speed. incremented each frame by engine
    speedyTicks: .fill TOTALSPRITES,0    // cycle counter for movement speed. incremented each frame by engine
    frameTicks: .fill TOTALSPRITES,0    // cycle counter for frame animation. incremented each frame by engine
    speedxCtrl:  .fill TOTALSPRITES,1    // do move when speedCtr = speed. reset speedTicks
    speedyCtrl:  .fill TOTALSPRITES,40    // do move when speedCtr = speed. reset speedTicks
    frameCtrl:  .fill TOTALSPRITES,17    // inc frame number(Status) when frameCtr = frames. reset frameTicks
    numFrames:  .fill TOTALSPRITES,2    // Number of frames for this sprite

    // address table contains location of spriteimage in VERA space
    // as per reg 0 and 1 of each VERA sprite
    // *** if all sprites are same size/depth then can be calculated instead***
    // index by imagePtr + frameNumber. Keep frames for each sprite together
    // this allows mixing of sprite sizes and 16/256 colour
    // Lo table: Address (12:5)
    // Hi Table:  bit 7 = Mode	bits 3:0 = Address (16:13)    
    addressTableLo: .fill TOTALFRAMES,128
    addressTableHi: .fill TOTALFRAMES,9
}
