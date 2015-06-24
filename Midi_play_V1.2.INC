/* ================================================================= */	
;===== Melody.inc is Added by TT65DevIDE at Tue Sep 30 14:48:29 2008 =====
/* ================================================================= */	


// =====================
//      COMMON I/O      
// =====================

STATUS       EQU    00H       ;R/W, BIT0: Zero.
                              ;R/W, BIT1: Carry.
                              ;R/W, BIT2: Overflow.
                              ;R/W, BIT3: Negative.
                              ;R/W, BIT7: Global Interrupt Enable.
                              ;R/W, BIT[12:8]: SD_EN,NH_EN,TFT_EN,TMSEN,SPI_EN.
                              ;R/W, BIT13: Interrupt Vector Table Access Enable.
                              ;R/W, BIT14: Filter Buffer Available.
                              ;R/W, BIT15: Parser Buffer Available.
INTENA       EQU    01H       ;R/W, Int Enable.
INTREQ       EQU    02H       ;R/W, Int Request.
IntVect      EQU    03H       ;R/W, Interrupt Table
IOC_PA       EQU    04H       ;R/W, PortA IO control. ('0' = input,'1' = output)
IOC_PB       EQU    05H       ;R/W, PortB IO control. ('0' = input,'1' = output)
IOC_PC       EQU    06H       ;R/W, PortC IO control. ('0' = input,'1' = output)
IOC_PD       EQU    0CH       ;R/W, PortD IO control. ('0' = input,'1' = output)
PortA        EQU    07H       ;R/W, General input/output port.
PortB        EQU    08H       ;R/W, General input/output port.
PortC        EQU    09H       ;R/W, General input/output port.
PortD        EQU    0AH       ;R/W, General output port.
SPH_CTL      EQU    0BH       ;W,   Specical Peripheral control register.
SPI_CTL      EQU    0DH       ;R/W, Serial interface control register.
SPI_DAT      EQU    0EH       ;R/W, Serial interface data.
SD_CTL       EQU    0FH       ;R/W, SD card interface control register.
SD_DAT       EQU    10H       ;R/W, SD card interface data.
SD_RSP       EQU    11H       ;R/W, SD card interface response register.
DACL         EQU    16H       ;W, DAC output L Channel.
DACR         EQU    17H       ;W, DAC output R Channel.
ClrWDT       EQU    1DH       ;W, Clear Watch-dog reset.
Real_T       EQU    1DH       ;R, System Real-Time Counter, base on 31.25us
IOP_IX       EQU    1EH       ;W, Programming IO Port index .
IOP_DAT      EQU    1FH       ;W, Programming IO Port Data .

// ********************************************************************	
VarRM[0:127]={
	RAM0,RAM1
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	myscankeycnt,
	myscankeybuff[16],
	mycheckkeycnt,
	mycheckkeybuff[16],
	mykeycntEn,
	mykeycnt,
	;;mykeyvalue[3],
	mykeyoldvalue,
	count_num,
	Mode_flag,
	loop_play_addr,    ;;play table start addr
	loop_play_length,  ;;0-play all loop >0 
	loop_play_flag,    ;;0x0ffff-enable loop play 0-disable
	loop_play_num,     ;; current play num
	timer_05ms,
	game1count,
	game2count,
	game3count,
	okcount,
	ngcount,
	timcount,
	gmode_state,
	answer_disable,
	waitflag,
	key_debounce,
	one_flag,
	wait_count,
	wait_en,
	repeat_flag,
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	counthalt
	Haltflag
	
	
	_31us
	_last31us
	TOTALKEY	
	
	
	MidiPcmIn
	MidiPcmOut
	_MIDIFLAG	// 
	// B3 :lauch midi after play voice			midi请求播放的标志
	PlayFlag
	Midi_bank0[41]
;/////////---------------
PCMIN_PTR, PCMOU_PTR
FrameSample1
ZeroFrame_s
read_flag
ADPCM_Data1



;////////////////
};
// ********************************************************************	
VarRM[128:511]={
BaseOn128#StackBuf[32]
Baseon32#Midi_bank1[208]
Midi_bank1_1[8]
AdpcmFiltBuf[90]
};
// ********************************************************************	
#define 	Optimal_RM 
VarRM[512:4095]={
Baseon256#Midi_bank2[1000]	
Baseon512#MidiPCMBuf[512]

//-------- for scan key
scnkeyvuff[4]
keypressbuff[16]
//-------- for scan key



};

// ********************************************************************	
ShareVar={

};

External Label {              
//_0_
};
