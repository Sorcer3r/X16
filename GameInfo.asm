//
// raster line = 2 * (display line * 8)
//
//   screen size 320 * 240 .  x/y scale factor 2
//   16+8  * 11 = 264
//   320 - 264 = 56

//   56 / 4 = 14 steps one end to other at 4 pixels / frame


// offset left edge by x = 28 
// aliens 16+ 8 each across

// 30 rows.
// 3 rows top for score etc

// 1  SCORE
// 2  -------blank
// 3  0000
//                         // top of shot is here in the blank line . guess @ scanline = 56?
// 4  -----blank
// 5  spaceship            // y = 32
// 6
// 7
// 8 top row aliens        // y = 64
// 9 blank
// 10 2nd row alien        // y = 72
// 11 blank
// 12 3 row alien          // y = 88
// 13 blank
// 14 4 row alien          // y = 104
// 15 blank
// 16 5 row bttom alien    // y = 120     
// 17
// 18
// 19
// 20
// 21
// 22   7 blanks
// 23
// 24  base hi     /y = 192 
// 25  base lo
// 26  blnk
// 27  play ship   // y = 216
// 28 blank
// 29 solid line ________
// 30 lies remainig        //y = e0 224


//tileset
// 0-25 ABCDEFGHIJKLMNOPQRSTUVWXYZ
// 26-35 0123456789
// 36-40  <> =*
//



// sprites 10 16x8(64).txt     alien(2frames) 10pt 20pt 30pt, player base(4 frames) player, 2 explosion frames , alien exlpoded
// 640 bytes $280  - stored at $13000 + $40 per sprite , Vera addr is +2 per sprite
// starts $13000 ends $1327f
// sprites 0-9

// shots 15 8x8(32).txt        player shot, player shot explosion. wiggle(4) plunger(4) target(4) alien shot explosion
//  480 bytes $1e0 - stored at $13280 + $20 per sprite, Vera addr is +1 per sprite
//  start $13280 ends  $1345f
// sprites 10-24

// shieldbase 24 8x8(32).txt   4 stages TL TC TR BL BC BR  start is complete(0), (1-3) destroy pixels each stage 
//  768 bytes $300 - stored at $13460 + $20 per sprite. + $c0 to next stage of a sprite(1-3)
// vera addr is +1 per sprite, +6 per stage
// start $13460 ends $1375f  
// sprites 25-48

// spaceship 2 32x8(128).txt   spaceship + exploding spaceship
// 256 bytes $100  - stored at $13800 + $100 per sprite, vera addr is + 4 per sprite
// starts $13760 ends $1395f
// sprites 49,50


