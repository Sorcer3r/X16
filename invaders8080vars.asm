#importonce

.align $100
gamevars8080:{
waitOnDraw:	        .byte	0	//2000 Cleared by alien-draw and set by next-alien. This ensures no alien gets missed while drawing.
            	    .byte	0	//2001 
alienIsExploding:	.byte	0	//2002 Not-0 if an alien is exploding, 0 if not exploting
expAlienTimer:	    .byte	0	//2003 Time (ISR ticks) left in alien-explosion
alienRow:	        .byte	0	//2004 Row number of current alien (cursor)
alienFrame:	        .byte	0	//2005 Animation frame number (0 or 1) for current alien (cursor)
alienCurIndex:	    .byte	0	//2006 Alien cursor index (from 0 to 54)
refAlienDYr:	    .byte	0	//2007 Reference alien delta Yr
refAlienDXr:	    .byte	0	//2008 Reference alien deltaXr
refAlienYr:	        .byte	0	//2009 Reference alien Yr coordinate
refAlienXr:	        .byte	0	//200A Reference alien Xr coordinate
alienPosLSB:	    .byte	0	//200B Alien cursor bit pos (LSB)
alienPosMSB:	    .byte	0	//200C Alien cursor bit pos (MSB)
rackDirection:	    .byte	0	//200D Value 0 if rack is moving right or 1 if rack is moving left
rackDownDelta:	    .byte	0	//200E Constant value of alien rack dropping after bumping screen edge
                    .byte	0	//200F 
obj0TimerMSB:	    .byte	0	//2010 
obj0TimerLSB:	    .byte	0	//2011 Wait 128 interrupts (about 2 secs) before player task starts
obj0TimerExtra:	    .byte	0	//2012 
obj0HanlderLSB: 	.byte	0	//2013 
oBJ0HanlderMSB: 	.byte	0	//2014 Player handler code at 028E
playerAlive:	    .byte	0	//2015 Player is alive (FF=alive). Toggles between 0 and 1 for blow-up images.
expAnimateTimer:	.byte	0	//2016 Time till next blow-up sprite change (reloaded to 5)
expAnimateCnt:	    .byte	0	//2017 Number of changes left in blow-up sequence
plyrSprPicL:      	.byte	0	//2018 Player sprite descriptor ... picture LSB
plyrSprPicM:    	.byte	0	//2019 Player sprite descriptor ... picture MSB
playerYr:	        .byte	0	//201A Player sprite descriptor ... location LSB
playerXr:	        .byte	0	//201B Player sprite descriptor ... location MSB
plyrSprSiz:	        .byte	0	//201C Player sprite descriptor ... size of sprite
nextDemoCmd:       	.byte	0	//201D Next movement command for demo
hidMessSeq:	        .byte	0	//201E Set to 1 after 1st of 2 sequences are entered for hidden-message display
                	.byte	0	//201F Appears to be unused
obj1TimerMSB:	    .byte	0	//2020 
obj1TimerLSB:	    .byte	0	//2021 
obj1TimerExtra:	    .byte	0	//2022 All 0's ... run immediately
obj1HandlerLSB:	    .byte	0	//2023 
obj1HandlerMSB:	    .byte	0	//2024 Shot handler code at 03BB
plyrShotStatus:	    .byte	0	//2025 0 if available, 1 if just initiated, 2 moving normally, 3 hit something besides alien, 5 if alien explosion is in progress, 4 if alien has exploded (remove from active duty)"
blowUpTimer:	    .byte	0	//2026 Sprite blow-up timer
obj1ImageLSB:	    .byte	0	//2027 
obj1ImageMSB:   	.byte	0	//2028 Sprite image at 1C90 (just one byte)
obj1CoorYr:	        .byte	0	//2029 Player shot Y coordinate
obj1CoorXr:	        .byte	0	//202A Player shot X coordinate
obj1ImageSize:	    .byte	0	//202B Size of shot image (just one byte)
shotDeltaX:     	.byte	0	//202C Shot's delta X
fireBounce: 	    .byte	0	//202D 1 if button has been handled but remains down
                	.byte	0	//202E 
	                .byte	0	//202F 
obj2TimerMSB:	    .byte	0	//2030 
obj2TimerLSB:	    .byte	0	//2031 
obj2TimerExtra:	    .byte	0	//2032 GO-3 runs when this is 1. GO-4 runs when this is 2. (copied to 2080 in game loop)
obj2HandlerLSB:	    .byte	0	//2033 
obj2HandlerMSB:	    .byte	0	//2034 Handler code at 0476
rolShotStatus:	    .byte	0	//2035 
rolShotStepCnt:	    .byte	0	//2036 
rolShotTrack:	    .byte	0	//2037 A 0 means this shot tracks the player
rolShotCFirLSB:	    .byte	0	//2038 Pointer to column-firing table LSB (not used for targeting)
rolShotCFirMSB:	    .byte	0	//2039 Pointer to column-firing table MSB (not used for MSB counter
rolShotBlowCnt:	    .byte	0	//203A 
rolShotImageLSB:	.byte	0	//203B 
rolShotImageMSB:	.byte	0	//203C 
rolShotYr:	        .byte	0	//203D 
rolShotXr:	        .byte	0	//203E 
rolShotSize:	    .byte	0	//203F 
obj3TimerMSB:	    .byte	0	//2040 
obj3TimerLSB:	    .byte	0	//2041 
obj3TimerExtra:	    .byte	0	//2042 
obj3HandlerLSB:	    .byte	0	//2043 
obj3HandlerMSB:	    .byte	0	//2044 Handler code at 04B6
pluShotStatus:	    .byte	0	//2045 
pluShotStepCnt:	    .byte	0	//2046 
pluShotTrack:	    .byte	0	//2047 A 1 means this shot does not track the player
pluShotCFirLSB:	    .byte	0	//2048 Pointer to column-firing table LSB
pluShotCFirMSB:	    .byte	0	//2049 Pointer to column-firing table MSB
pluShotBlowCnt:	    .byte	0	//204A 
pluShotImageLSB:	.byte	0	//204B 
pluShotImageMSB:	.byte	0	//204C 
pluShotYr:  	    .byte	0	//204D 
pluSHotXr:	        .byte	0	//204E 
pluShotSize:	    .byte	0	//204F 
obj4TimerMSB:	    .byte	0	//2050 
obj4TimerLSB:	    .byte	0	//2051 
obj4TimerExtra:	    .byte	0	//2052 
obj4HandlerLSB:	    .byte	0	//2053 
obj4HandlerMSB:	    .byte	0	//2054 Handler code at 0682
squShotStatus:	    .byte	0	//2055 
squShotStepCnt:	    .byte	0	//2056 
squShotTrack:	    .byte	0	//2057 A 1 means this shot does not track the player
squShotCFirLSB:	    .byte	0	//2058 Pointer to column-firing table LSB
squShotCFirMSB:	    .byte	0	//2059 Pointer to column-firing table MSB
squSHotBlowCnt:	    .byte	0	//205A 
squShotImageLSB:	.byte	0	//205B 
squShotImageMSB:	.byte	0	//205C 
squShotYr:	        .byte	0	//205D 
squShotXr:	        .byte	0	//205E 
squShotSize:	    .byte	0	//205F 
endOfTasks:	        .byte	0	//2060 FF marks the end of the tasks list
collision:	        .byte	0	//2061 Set to 1 if sprite-draw detects collision
expAlienLSB:	    .byte	0	//2062 
expAlienMSB:	    .byte	0	//2063 Exploding alien picture 1CC0
expAlienYr:	        .byte	0	//2064 Y coordinate of exploding alien
expAlienXr:	        .byte	0	//2065 X coordinate of exploding alien
expAlienSize:	    .byte	0	//2066 Size of exploding alien sprite (16 bytes)
playerDataMSB:	    .byte	0	//2067 Current player's data-pointer MSB (21xx or 22xx)
playerOK:	        .byte	0	//2068 1 means OK, 0 means blowing up"
enableAlienFire:	.byte	0	//2069 1 means aliens can fire, 0 means not"
alienFireDelay:	    .byte	0	//206A Count down till aliens can fire (2069 flag is then set)
oneAlien:	        .byte	0	//206B 1 when only one alien is on screen
temp206C:       	.byte	0	//206C Holds the value ten ... number of characters in each ""=xx POINTS"" string but gets set to 18 in mem copy before game."
invaded:	        .byte	0	//206D Set to 1 when player blows up because rack has reached bottom
skipPlunger:	    .byte	0	//206E When there is only one alien left this goes to 1 to disable the plunger-shot when it ends
                	.byte	0	//206F 
otherShot1:	        .byte	0	//2070 When processing a shot, this holds one of the other shot's info"
otherShot2:	        .byte	0	//2071 When processing a shot, this holds one of the other shot's info"
vblankStatus:	    .byte	0	//2072 80=screen is being drawn (don't touch), 0=blanking in progress (ok to change)"
aShotStatus:	    .byte	0	//2073 Bit 0 set if shot is blowing up, bit 7 set if active"
aShotStepCnt:	    .byte	0	//2074 Count of steps made by shot (used for fire reload rate)
aShotTrack:	        .byte	0	//2075 0 if shot tracks player or 1 if it uses the column-fire table
aShotCFirLSB:	    .byte	0	//2076 Pointer to column-firing table LSB
aShotCFirMSB:	    .byte	0	//2077 Pointer to column-firing table MSB
aShotBlowCnt:	    .byte	0	//2078 Alen shot blow up counter. At 3 the explosion is drawn. At 0 it is done.
aShotImageLSB:	    .byte	0	//2079 Alien shot image LSB
aShotImageMSB:	    .byte	0	//207A Alien shot image MSB
alienShotYr:	    .byte	0	//207B Alien shot delta Y
alienShotXr:	    .byte	0	//207C Alien shot delta X
alienShotSize:	    .byte	0	//207D Alien shot size
alienShotDelta:	    .byte	0	//207E Alien shot speed. Normally -1 but set to -4 with less than 9 aliens
shotPicEnd:	        .byte	0	//207F the last picture in the current alien shot animation
shotSync:	        .byte	0	//2080 All 3 shots are synchronized to the GO-2 timer. This is copied from timer in the game loop
tmp2081:	        .byte	0	//2081 Used to hold the remember/restore flag in shield-copy routine
numAliens:	        .byte	0	//2082 Number of aliens on screen
saucerStart:	    .byte	0	//2083 Flag to start saucer (set to 1 when 2091:2092 counts down to 0)
saucerActive:	    .byte	0	//2084 Saucer is on screen (1 means yes)
saucerHit:	        .byte	0	//2085 Saucer has been hit (1 means draw it but don't move it)
saucerHitTime:	    .byte	0	//2086 Hit-sequence timer (explosion drawn at 1F, score drawn at 18)"
saucerPriLocLSB:	.byte	0	//2087 Mystery ship print descriptor ... coordinate LSB
saucerPriLocMSB:	.byte	0	//2088 Mystery ship print descriptor ... coordinate MSB
saucerPriPicLSB:	.byte	0	//2089 Mystery ship print descriptor ... message LSB
saucerPriPicMSB:	.byte	0	//208A Mystery ship print descriptor ... message MSB
saucerPriSize:	    .byte	0	//208B Mystery ship print descriptor ... number of characters
saucerDeltaY:	    .byte	0	//208C Mystery ship delta Y
sauScoreLSB:	    .byte	0	//208D Pointer into mystery-ship score table (MSB)
sauScoreMSB:	    .byte	0	//208E Pointer into mystery-ship score table (LSB)
shotCountLSB:	    .byte	0	//208F Bumped every shot-removal. Saucer's direction is bit 0. (0=2/29, 1=-2/E0)"
shotCountMSB:	    .byte	0	//2090 Read as two-bytes with 208F, but never used as such."
tillSaucerLSB:	    .byte	0	//2091 
tillSaucerMSB:	    .byte	0	//2092 Count down every game loop. When it reaches 0 saucer is triggerd. Reset to 600.
waitStartLoop:	    .byte	0	//2093 1=in wait-for-start loop, 0=in splash screens"
soundPort3:	        .byte	0	//2094 Current status of sound port (out $03)
changeFleetSnd:	    .byte	0	//2095 Set to 1 in ISR if time to change the fleet sound
fleetSndCnt:	    .byte	0	//2096 Delay until next fleet movement tone
fleetSndReload:	    .byte	0	//2097 Reload value for fleet sound counter
soundPort5:	        .byte	0	//2098 Current status of sound port (out $05)
extraHold:	        .byte	0	//2099 Duration counter for extra-ship sound
tilt:	            .byte	0	//209A 1 if tilt handling is in progress
fleetSndHold:	    .byte	0	//209B Time to hold fleet-sound at each change
                    .fill $24,0 //209C-20BF unused bytes went here
isrDelay:	        .byte	0	//20C0 Delay counter decremented in ISR
isrSplashTask:	    .byte	0	//20C1 1=In demo, 2=Little-alien and Y, 4=shooting extra 'C'"
splashAnForm:	    .byte	0	//20C2 Image form (increments each draw)
splashDeltaX:	    .byte	0	//20C3 Delta X
splashDeltaY:	    .byte	0	//20C4 Delta Y
splashYr:	        .byte	0	//20C5 Y coordinate
splashXr:	        .byte	0	//20C6 X coordinate
splashImageLSB:	    .byte	0	//20C7 
splashImageMSB:	    .byte	0	//20C8 Base image 1BA0 (small alien with upside down Y)
splashImageSize:	.byte	0	//20C9 Size of image (16 bytes)
splashTargetY:	    .byte	0	//20CA Target Y coordinate
splashReached:	    .byte	0	//20CB Reached target Y flag (1 when reached)
splashImRestLSB:	.byte	0	//20CC Base image for restore 1BA0 is small alien with upside down Y
splashImRestMSB:	.byte	0	//20CD 
twoPlayers:	        .byte	0	//20CE 1 for yes, 0 means 1 player"
aShotReloadRate:	.byte	0	//20CF Based on the MSB of the player's score ... how fast the aliens reload their shots
                    .fill $15,0 //20D0 - 20E4 ; This is where the alien-sprite-carying-the-Y ...
                                // ; ... lives in ROM ???
player1Ex:	        .byte	0	//20E5 Extra ship has been awarded = 0
player2Ex:      	.byte	0	//20E6 Extra ship has been awarded = 0
player1Alive:	    .byte	0	//20E7 1 if player is alive, 0 if dead (after last man)"
player2Alive:	    .byte	0	//20E8 1 if player is alive, 0 if dead (after last man)"
suspendPlay:	    .byte	0	//20E9 1=game things are moving, 0=game things are suspended"
coinSwitch:	        .byte	0	//20EA 1=switch down, 0=switch up (used to debounce coin switch)"
numCoins:	        .byte	0	//20EB number of coin credits in BCD format (99 max)
splashAnimate:	    .byte	0	//20EC 0 for animation during splash and 1 for not. This alternates after every cycle.
demoCmdPtrLSB:	    .byte	0	//20ED pointer to demo commands LSB 1663
demoCmdPtrMSB:	    .byte	0	//20EE pointer to demo commands MSB
gameMode:	        .byte	0	//20EF 1=game running, 0=demo or splash screens"
                	.byte	0	//20F0 
adjustScore:	    .byte	0	//20F1 Set to 1 if score needs adjusting
scoreDeltaLSB:	    .byte	0	//20F2 Score adjustment (LSB)
scoreDeltaMSB:	    .byte	0	//20F3 Score adjustment (MSB)
HiScorL:	        .byte	0	//20F4 Hi-score descriptor ... value LSB
HiScorM:	        .byte	0	//20F5 Hi-score descriptor ... value MSB
HiScorLoL:	        .byte	0	//20F6 Hi-score descriptor ... location LSB
HiScorLoM:	        .byte	0	//20F7 Hi-score descriptor ... location MSB
P1ScorL:	        .byte	0	//20F8 Hi-score descriptor ... value LSB
P1ScorM:	        .byte	0	//20F9 Hi-score descriptor ... value MSB
P1ScorLoL:	        .byte	0	//20FA Hi-score descriptor ... location LSB
P1ScorLoM:	        .byte	0	//20FB Hi-score descriptor ... location MSB
P2ScorL:	        .byte	0	//20FC Hi-score descriptor ... value LSB
P2ScorM:	        .byte	0	//20FD Hi-score descriptor ... value MSB
P2ScorLoL:	        .byte	0	//20FE Hi-score descriptor ... location LSB
P2ScorLoM:	        .byte	0	//20FF Hi-score descriptor ... location MSB

.align $100                     //Player 1 specific data 
                                // 
P1Data:             .fill $fb,0 //2100:2136 Player 1 alien ship indicators (0=dead) 11*5 = 55
                                //2137:2141 Unused 11 bytes (room for another row of aliens?)
                                //2142:21F1 Player 1 shields remembered between rounds 44 bytes * 4 shields ($B0 bytes)
                                //21F2:21FA Unused 9 bytes
p1RefAlienDX:	    .byte	0	//21FB Player 1 reference-alien delta X
p1RefAlienY:	    .byte	0	//21FC Player 1 reference-alien Y coordinate
p1RefAlienX:	    .byte	0	//21FD Player 1 reference-alien X coordiante
p1RackCnt:	        .byte	0	//21FE Player 1 rack-count (starts at 0 but get incremented to 1-8)
p1ShipsRem:	        .byte	0	//21FF Ships remaining after current dies

//.align $100                     //Player 2 specific data 
                                // 
P2Data:             .fill $fb,0 //2200:2236 Player 2 alien ship indicators (0=dead) 11*5 = 55
                                //2237:2241 Unused 11 bytes (room for another row of aliens?)
                                //2242:22F1 Player 2 shields remembered between rounds 44 bytes * 4 shields ($B0 bytes)
                                //22F2:22FA Unused 9 bytes
p2RefAlienDX:	    .byte	0	//22FB Player 2 reference-alien delta X
p2RefAlienYr:	    .byte	0	//22FC Player 2 reference-alien Y coordinate
p2RefAlienXr:	    .byte	0	//22FD Player 2 reference-alien X coordinate
p2RackCnt:	        .byte	0	//22FE Player 2 rack-count (starts at 0 but get incremented to 1-8)
p2ShipsRem:	        .byte	0	//22FF Ships remaining after current dies
}