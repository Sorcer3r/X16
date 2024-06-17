.cpu _65c02
#importonce 

MMtitleScreen:{        
    
// M
.align $100
M_RED:
.byte RED << 4,0,0,0,RED << 4
.byte RED << 4,RED << 4,0,RED << 4,RED << 4
.byte RED << 4,0,RED << 4,0,RED << 4
.byte RED << 4,0,0,0,RED << 4
.byte RED << 4,0,0,0,RED << 4

//A
A_YELLOW:
.byte 0,YELLOW << 4,YELLOW << 4,YELLOW << 4,0
.byte YELLOW << 4,0,0,0,YELLOW << 4
.byte YELLOW << 4,0,0,0,YELLOW << 4
.byte YELLOW << 4,YELLOW << 4,YELLOW << 4,YELLOW << 4,YELLOW << 4
.byte YELLOW << 4,0,0,0,YELLOW << 4

//N
N_GREEN:
.byte GREEN << 4,0,0,0,GREEN << 4
.byte GREEN << 4,GREEN << 4,0,0,GREEN << 4
.byte GREEN << 4,0,GREEN << 4,0,GREEN << 4
.byte GREEN << 4,0,0,GREEN << 4,GREEN << 4
.byte GREEN << 4,0,0,0,GREEN << 4

//I
I_LIGHTBLUE:
.byte LIGHT_BLUE << 4,LIGHT_BLUE << 4,LIGHT_BLUE << 4,0,0
.byte 0,LIGHT_BLUE << 4,0,0,0
.byte 0,LIGHT_BLUE << 4,0,0,0
.byte 0,LIGHT_BLUE << 4,0,0,0
.byte LIGHT_BLUE << 4,LIGHT_BLUE << 4,LIGHT_BLUE << 4,0,0

//C
C_PURPLE:
.byte 0,PURPLE << 4,PURPLE << 4,PURPLE << 4,0
.byte PURPLE << 4,0,0,0,PURPLE << 4
.byte PURPLE << 4,0,0,0,0
.byte PURPLE << 4,0,0,0,PURPLE << 4
.byte 0,PURPLE << 4,PURPLE << 4,PURPLE << 4,0

//M
M_LIGHTBLUE:
.byte LIGHT_BLUE << 4,0,0,0,LIGHT_BLUE << 4
.byte LIGHT_BLUE << 4,LIGHT_BLUE << 4,0,LIGHT_BLUE << 4,LIGHT_BLUE << 4
.byte LIGHT_BLUE << 4,0,LIGHT_BLUE << 4,0,LIGHT_BLUE << 4
.byte LIGHT_BLUE << 4,0,0,0,LIGHT_BLUE << 4
.byte LIGHT_BLUE << 4,0,0,0,LIGHT_BLUE << 4

//I
I_PURPLE:
.byte PURPLE << 4,PURPLE << 4,PURPLE << 4,0,0
.byte 0,PURPLE << 4,0,0,0
.byte 0,PURPLE << 4,0,0,0
.byte 0,PURPLE << 4,0,0,0
.byte PURPLE << 4,PURPLE << 4,PURPLE << 4,0,0

//N
N_RED:
.byte RED << 4,0,0,0,RED << 4
.byte RED << 4,RED << 4,0,0,RED << 4
.byte RED << 4,0,RED << 4,0,RED << 4
.byte RED << 4,0,0,RED << 4,RED << 4
.byte RED << 4,0,0,0,RED << 4

//E
E_YELLOW:
.byte YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,YELLOW<< 4
.byte YELLOW<< 4,0,0,0,0
.byte YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,0
.byte YELLOW<< 4,0,0,0,0
.byte YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,YELLOW<< 4,YELLOW<< 4

//R
R_GREEN:
.byte GREEN<< 4,GREEN<< 4,GREEN<< 4,GREEN<< 4,0
.byte GREEN<< 4,0,0,0,GREEN<< 4
.byte GREEN<< 4,GREEN<< 4,GREEN<< 4,GREEN<< 4,0
.byte GREEN<< 4,0,GREEN<< 4,0,0
.byte GREEN<< 4,0,0,GREEN<< 4,GREEN<< 4

charY:
.byte 0,1,0,1,0         // y offset  
.byte 0 //padding
charTopRowX:
.byte 7,13,19,25,29      //top row - MANIC
charBotRowX:
.byte 7,13,17,23,29      //bottom row - MINER

// topRow:
// .byte 0,1,2,3,4
// botRow:
// .byte 5,6,7,8,9
}