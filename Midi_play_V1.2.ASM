;****************************************************************************
;           TRD16IDE Midi (PCM12) Demo Code , TRITAN Technology Inc.
;                     
;****************************************************************************
;
#include "Midi_Play_v1.2.INC" 

 
#define	speed	0x00
#define   SPI_Speed 0x00
//#define TRD16P201A_SPI
#define SPI_TYPE1
;#define   SPI_TYPE2
#define   RamEndAddr 0x07ff
#define   keyboardsongnumber 0
#define   GetVoiceKeyNOVolData  0x7f    
#define   MAX_Midi_Volume 0x00ff
#define Spi_Offset_High_WORD 0x00
#define Spi_Offset_High_byte 0x00
#define Spi_Offset_Low_WORD  0x00 
#define Pitch_wheel_Beat 0x20


    ORG     0000H
RSTB_ENTRY:
    PCH=  SYS_PROG_ENTRY

    LJMP  SYS_PROG_ENTRY
    ;;------------------------
    ORG     0004H
    ;;------------------------
WAKEUP_ENTRY:
    PCH=  WAKEUP_PROC
    LJMP  WAKEUP_PROC
    ;;------------------------
    ORG     0020H
// ********************************************************************
WAKEUP_PROC:
    ar    = 3
    io[intena]  =ar
    
    IO[CLRWDT]  = AR
    
    pch = SPI_Initial
		lcall SPI_Initial 
	
    pch	= Rel_powerdown_cmd
		lcall	Rel_powerdown_cmd
		pch	= wait_flash_ready
		lcall	wait_flash_ready
	
		pch = keyscanini
    lcall keyscanini
    
    ar = 0
		rm[Mode_flag] = ar
    
    // Circular bufer setup
    i0    = MidiPCMBuf
    rm[MidiPcmIn] = i0;
    rm[MidiPcmOut] = i0;

    // Length = 256
    //ar    = 8   // 2^8=256 ==> CBL
    ar    = 9   // 2^9=512 ==> CBL
    CBL   = ar
    
    jmp StartMainLoop
    
    
    cx    = RamEndAddr;
    cx--
    cx--
    ar    = 0;
    i1    = 2
Power_on_init_clr_SRAM2:
    rm[i1++]  = ar;
    loop    Power_on_init_clr_SRAM2
    
    jmp main_loop
    
clrcountmain_loo2:
    ar    =rm[Haltflag]
    clr   ar.b2
    rm[Haltflag] =ar
    ar    =0
    rm[counthalt] =ar
    jmp   main_loo2
/* ================================================================= */
// ------------- Main Program Start --------------------------------
/* ================================================================= */
SYS_PROG_ENTRY:
    call    Power_on_init
    
    
PAGE1ENTRY:
		
		;-------------
    IO[CLRWDT]  = AR
    ;----------
    
    ar = 0xFFFF
		rm[adp_vol] = ar    ;adpcm音量控制 (对所有adpcm 通道起作用)
		ar		= 0x1FFF ;当前通道下 adpcm-采样设定 
		rm[AdpcmSample]  = ar

		clr IO[PortA].b4                                    
		clr IO[PortA].b5                                    
		clr IO[PortA].b6                                    
		clr IO[PortA].b7                                    
		clr IO[PortB].b0                                    
		clr IO[PortB].b1                                    
		clr IO[PortB].b2                                    
		clr IO[PortB].b3                                    
		clr IO[PortB].b4
			
		test io[PortB].b7
		jzr  Melody
		ar = 0
		rm[timer_05ms] = ar
		ENI
    //ENA     INT0
    //ENA     INT1
    ENA     INT2 
    ar = 1
    rm[waitflag] = ar
    ax = 0x4e20
wait10s:
		;;;;;;;;;;;;;;;;;;;;;;;
		IO[CLRWDT]  = AR
		;;;;;;;;;;;;;;;;;;;;;;;
    ar = rm[timer_05ms]
    sf = ar - ax
    jnz wait10s
    
    ar = io[PortC]
    ar &= 0x7f
 
    jnz StartMainLoop

    ar = 5
    rm[Mode_flag] = ar
    pch = SleepM
    ljmp SleepM
		
Melody:
		ar = 0
		
		clr IO[PortA].b4                                    
		clr IO[PortA].b5                                    
		clr IO[PortA].b6                                    
		clr IO[PortA].b7                                    
		clr IO[PortB].b0                                    
		clr IO[PortB].b1                                    
		clr IO[PortB].b2                                    
		clr IO[PortB].b3                                    
		clr IO[PortB].b4
		
		set IO[PortB].b2
		test IO[PortC].b4
		jzr  N00
		
		ar = 5
		rm[Mode_flag] = ar
		
		pch = SleepM
    ljmp SleepM
    
N00:
		set IO[PortB].b2
		test IO[PortC].b4
		jzr N1
		
    ar = 5
		rm[Mode_flag] = ar
		pch = SleepM
    ljmp SleepM
N1:
		clr IO[PortB].b2
		set IO[PortA].b4
		test IO[PortC].b1
		jzr  N2
		
		ar = 5
		rm[Mode_flag] = ar
		pch = SleepM
    ljmp SleepM
N2:    
		clr IO[PortA].b4
		set IO[PortA].b7
		test IO[PortC].b0
		jzr  IfSwitchTestMode
		
		ar = 5
		rm[Mode_flag] = ar
		pch = SleepM
    ljmp SleepM
    
IfSwitchTestMode:
		clr IO[PortA].b4                                    
		clr IO[PortA].b5                                    
		clr IO[PortA].b6                                    
		clr IO[PortA].b7                                    
		clr IO[PortB].b0                                    
		clr IO[PortB].b1                                    
		clr IO[PortB].b2                                    
		clr IO[PortB].b3                                    
		clr IO[PortB].b4
		nop
		nop
		
		set IO[PortB].b1
		nop
		nop
		nop
		nop
		test IO[PortC].b0
		nop
		nop
		nop
		test IO[PortC].b0
		jzr StartModeStart
		
		clr IO[PortB].b1 
		set IO[PortA].b4
		nop
		nop
		nop
		nop
		test IO[PortC].b2
		nop
		nop
		nop
		test IO[PortC].b2
		jzr  StartModeStart
		
		
		
TestModeStart:
		ar = 93
    rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
		ar = 4
		rm[Mode_flag] = ar
		
		ar = 2
		rm[waitflag] = ar
		
		pch = StartMainLoop
		ljmp StartMainLoop
    
StartModeStart:
		ar = 2
		rm[waitflag] = ar
    ar = 0x0ffff
    rm[loop_play_flag] = ar
    p0 = #StartModeOnTable
    ar = p0
    rm[loop_play_addr] = ar
    ar = 3
    rm[loop_play_length] = ar 
		ar = 0
		rm[Mode_flag] = ar
		
		ar = 0x03E9
   	rm[mykeycnt] = ar ;;;;disable key when power on
   	
StartMainLoop: 
;   		ar = 9
;    		rm[adp_unmber] = ar 
;    		rm[adp_ch_index] = AR 
;    		pch   = play_adpcm_inti
;    		lcall	play_adpcm_inti
;    		ar = 2
;    		rm[adp_unmber] = ar 
;    		rm[adp_ch_index] = AR 
;    		pch   = play_adpcm_inti
;    		lcall	play_adpcm_inti
;    		ar = 3
;    		rm[adp_unmber] = ar 
;    		rm[adp_ch_index] = AR 
;    		pch   = play_adpcm_inti
;    		lcall	play_adpcm_inti
;    		ar = 4
;    		rm[adp_unmber] = ar 
;    		rm[adp_ch_index] = AR 
;    		pch   = play_adpcm_inti
;    		lcall	play_adpcm_inti
;    		ar = 5
;    		rm[adp_unmber] = ar 
;    		rm[adp_ch_index] = AR 
;    		pch   = play_adpcm_inti
;    		lcall	play_adpcm_inti
    		
    		;;pch   = PlayNextMidiCommand
    		;;lcall	PlayNextMidiCommand
    		
    		;;ar = 3
				;;rm[PlayMidi] 	=	ar
				;;pch =	PlayMidiCommand
				;;lcall	PlayMidiCommand
				
    		ENI
    		ENA     INT0
    		ENA     INT1
    		ENA     INT2
    		
main_loop:
		
		ar = 0xFFFF
		rm[adp_vol] = ar    ;adpcm音量控制 (对所有adpcm 通道起作用)
		ar		= 0x1FFF ;当前通道下 adpcm-采样设定 
		rm[AdpcmSample]  = ar
		
		ENI
		;;pch = compPB5
		;;lcall compPB5
		
		;;set io[PortB].b5
		;;cx = 0x03ff
;;loopcc:
		;;nop
		;;nop
		;;loop loopcc
		
		;;clr io[PortB].b5
		
		;;pch = compPB5
		;;lcall compPB5
		
    ar    =rm[_MIDIFLAG]
    test    ar.b1
    jnz     main_loo2
    test    ar.b15
    jnz     main_loo2

    ar    = rm[PlayFlag]
    jnz     main_loo2
    ar    =io[porta]
    ar    &=0x1f
    jnz   clrcountmain_loo2
    
    ar    =rm[Haltflag]
    set   ar.b2
    rm[Haltflag] =ar
    ar    =rm[counthalt]
    test    ar.b6
    jzr   main_loo2
;    nop
;    dsi	int0
;    halt
;    nop
    
main_loo2:
		push  p0 
		push  i0
		push  i1
    PCH   =even_process
    Lcall   even_process
    pop  i1
		pop  i0 
		pop  p0
main_loop1:
    call    WaitPCM_Empty_size
    if AN jmp   No_EmptyPCM
    
    ar = rm[Haltflag]
    test ar.b2
    jzr main_loop3
    ar = rm[counthalt]
    ar++
    rm[counthalt] =ar

main_loop3:
    IO[CLRWDT]  = AR
    PCH = Ch_SampleProcess
    LCALL Ch_SampleProcess

No_EmptyPCM:
    	IO[CLRWDT]  = AR
SleepM:    
    	ar = rm[Mode_flag]
			sf = ar - 5
			jzr Sleep_Run
			jmp main_loop
			
Sleep_Run:

;;WaitWavFinish:
			;;IO[CLRWDT]  = AR
			;;ar = rm[AdPcmflag]      ;;;;wait wav play finish
    	;;jnz main_loop
    	    	
    	ar = 0
      rm[loop_play_addr] = ar
      rm[loop_play_length] = ar
      rm[loop_play_flag] = ar
      rm[loop_play_num] = ar
      rm[mykeycnt] = ar
      
    	pch = StopAlllPlaying
		  lcall StopAlllPlaying
		  

		  pch = Rampdown_Process
    	lcall Rampdown_Process
    
    	pch = clr_PCMBuf
    	lcall  clr_PCMBuf
    	
    	;;pch = Pwm_Process
    	;;lcall Pwm_Process
		  
			ar = rm[PlayFlag]
    	jnz main_loop
    	
    	ar = rm[AdPcmflag]
    	jnz main_loop
    	
    	;;ar = io[PortC]
    	;;ar &= 0x7f
    	;;nop
    	;;nop
    	;;nop
    	;;ar = io[PortC]
    	;;ar &= 0x7f
    	
    	;;jnz main_loop
    
    	;;pch = Rampdown_Process
    	;;lcall Rampdown_Process
    
    	;;pch = clr_PCMBuf
    	;;lcall  clr_PCMBuf
    	
    	;;pch = Pwm_Process
    	;;lcall Pwm_Process
    	
			pch = Deep_powerdown_cmd
			lcall	Deep_powerdown_cmd 
			
			;;ar = 0
			;;cx = 0x01ff
			
			;;i0 = MidiPCMBuf
			
;;ClrMidiPCMBuf:
			;;rm[i0++] = ar			
			;;loop ClrMidiPCMBuf
			
			
			
			clr		Io[Status].B8 
    	
    	
    	ar = 0x0F
			io[IOC_PA] = ar
	
			ar = 0x09
			io[PortA]	= ar

    	ar = io[IOC_PB]			//pb.7 1khz检测口
    	ax = 0x0000
			ar = ar & ax
    	io[IOC_PB] = ar
    	ar = io[PortB]
    	ax = 0x0000
    	ar = ar & ax
    	io[PortB]	= ar
    	
			ar	=	0x00FF
    	io[IOC_PC] = ar
    	ar =	0x00FF
    	io[PortC] = ar
    	
    	pch = F_IOSetDelayTimer
    	lcall F_IOSetDelayTimer
    	pch =	F_IOSetDelayTimer
    	lcall F_IOSetDelayTimer
    	pch = F_IOSetDelayTimer
    	lcall F_IOSetDelayTimer
    		
			nop
			dsi
    	dsi	int2
			DSI	INT1
    	DSI	INT0
			HALT
	
			NOP
			NOP
			NOP
			NOP
			NOP
    	jmp   main_loop
    
;//   |----------|--------------------|---------------------|  size 256
;//             PCMIN_PTR  PCMOU_PTR
;// return AN=1 is less 64
WaitPCM_Empty_size:
    ar    = rm[MidiPcmIn]
    ax    = rm[MidiPcmOut]
    // -----------------------------------
    ar    = ax - ar;
    if an jmp   GetPCM_Empty_IN_GT // -
    jmp   GetPCM_Empty_next
GetPCM_Empty_IN_GT:
    // length = (256 - PCMIN_PTR + PCMOU_PTR)&0x0FF
    ax    = 512;//ax    = 256;
    ar    = ax + ar;
    //ah    = 0;
GetPCM_Empty_next:
    // Check empty size > 128
    //sf    = ar - 65
    ax    = 0x081 //129
    sf    = ar-ax
    rets

///////////////////////////////////////////////////////////////////////////////////////////////
Power_on_init:
    //bp  = StackBottom   // Stack pointer initial at bottom of 128+32
    ar =StackBuf
    bp =31
    bp+=ar
    // Clear All SRAM 4K
    clr     io[STATUS].b8
    cx    = RamEndAddr;
    cx--
    cx--
    ar    = 0;
    i1    = 2
Power_on_init_clr_SRAM:
    rm[i1++]  = ar;
    loop    Power_on_init_clr_SRAM

    // Circular bufer setup
    i0    = MidiPCMBuf
    rm[MidiPcmIn] = i0;
    rm[MidiPcmOut] = i0;

    // Length = 256
    //ar    = 8   // 2^8=256 ==> CBL
    ar    = 9   // 2^9=512 ==> CBL
    CBL   = ar

    call    init_intVectTable
    PCH   =keyscanini
    lcall  keyscanini
    
    //timer2 , 2kHz	
		ar		=	0x01
		io[IOP_IX]	=	ar 
		ar 		= 	0x3fff
		io[IOP_DAT]	=	ar 
		
    ar    = 0
    rm[PlayMidi]  = ar
    
    Pch	=PowerOnmidSet
    Lcall	PowerOnmidSet
    
    
    	pch =SPI_Initial
    	lcall SPI_Initial    
    	
      	Bx	=4  ; 前4个byte为 文件个数
     	Ar	=0
     	pch 	=Send_SPI_address
    	lcall 	Send_SPI_address
    	pch 	= Get_4_BYTE
    	lcall 	Get_4_BYTE
  
   	I1	=Midi_address
   	Rm[I1++]	=io[SPI_DAT]
   	Rm[I1++]	=io[SPI_DAT]

;	I1	=Midi_address
;	Ar	=0
;	Rm[I1++]	=Ar
;	Rm[I1++]	=Ar
    
    Pch	=MidiInfInital
    Lcall	MidiInfInital
  
  
    AR    =MAX_Midi_Volume
    rm[Midi_Volume] = ar    
    
    rets	
    
INTVB7_ENTRY:
INTVB6_ENTRY:
INTVB5_ENTRY:
INTVB4_ENTRY:
INTVB3_ENTRY:
INTVB2_ENTRY:
        ;;ar=IO[INTREQ]
        ;;ar &= 0x03
        ;;IO[INTREQ]=ar
        CLR IO[INTREQ].B2 ;Clear Int2 Request!!
        
        ar = rm[timer_05ms]
        ar++
        rm[timer_05ms] = ar 
        
        ar = rm[wait_en]
        jzr Next_w
        
        ar = rm[wait_count]
        ar++
        rm[wait_count] = ar
        
Next_w:
        ar = rm[waitflag]
        sf = ar - 1
        jzr W10s
        
        pch = bac
        ljmp bac 
        
W10s:
        test io[PortC].b7
        jzr n0
        clr io[PortC].b7
        pch = bac
        ljmp bac
n0:
				set io[PortC].b7  
bac:				       
        reti
INTVB0_ENTRY:

    CLR     IO[INTREQ].B0 ;Clear Int0 Request!!
    
    ar =rm[Mode_flag]
    sf = ar - 5
    jzr MuteAll
    ar = 0
		jmp Dac_out
		   
MuteALl:
		ar = 0x000f
    io[18] = ar
    ar = 0
    io[DACL] = ar
    io[DACR] = ar
    jmp Int0End
    
Dac_out:
    
    push  cbl
    push    i0
    i0    = rm[MidiPcmOut];
    ar  =9
    cbl =ar
    ar =0
    io[DACL]  = rm[i0]; // output DAC L
    rm[i0++]=ar
    io[DACL]  = rm[i0]; // output DAC L
    rm[i0++]=ar
    io[DACL]  = rm[i0]; // output DAC L
    rm[i0++]=ar
    io[DACL]  = rm[i0]; // output DAC L
    rm[i0++]=ar
    rm[MidiPcmOut] = i0;
    pop   i0
    pop CBL
Int0End:    
    RETI


INTVB1_ENTRY:
    CLR     IO[INTREQ].B1 ;Clear Int0 Request!!
    AR    =RM[TEMPOcount]
    JNZ   _NOTBEATTIME
    ar    =rm[TEMPOcountbak]

    RM[TEMPOcount]=ar
    ar    =rm[_MIDIFLAG]
    set   ar.b4
    rm[_MIDIFLAG]=ar


    _NOTBEATTIME:
    AR    =RM[TEMPOcount]
    AR--
    RM[TEMPOcount]=AR
    RETI

////////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------
//   System call midi event process

SysReliabilityChk:
  		ar 		= rm[RAM0]
  		sf		= ar - 0x0007
  		jnz  		SysReliabilityChk_error 	; wait for watch-dog reset
  		ar		= rm[RAM1]
  		sf		= ar - 0x0006
  		jnz  		SysReliabilityChk_error 	; wait for watch-dog reset
  		rets
SysReliabilityChk_error:
		Nop
		Jmp	  SysReliabilityChk_error
;////////////////////////////////////////////////////						
#include	"system_inti.asm"
#include	"user_code.asm"
#include "MIDILIB.ASM"
#include	"Spi_ctrl.asm"
#include	"adpcm4.asm"
;DecodeTab:
;	DW "OrchestraHit_8K_8000_4-16.PAM"
;dw "red_01.PAM"