
even_process:
		pch	= SysReliabilityChk
		lcall	SysReliabilityChk
		
		;;set IO[PortB].b5
		ar = rm[Mode_flag]
		sf = ar - 5
		jzr even_process_end
		
		eni
 		pch	=	MyKeyscan
		lcall	MyKeyscan
		eni
		pch	=	MyCheckKey
		lcall	MyCheckKey
		eni
		pch = DealKeyMseeage
		lcall DealKeyMseeage
		eni
		pch = DealLoopPlay
		lcall DealLoopPlay
		eni
		pch = DealGameOnPlay
		lcall DealGameOnPlay
		eni
		pch = Wait30s
		lcall Wait30s
		
		;;clr IO[PortB].b5
		
even_process_end:
		eni
		IO[CLRWDT] = AR
		PCH	= WaitPCM_Empty_size
		Lcall	WaitPCM_Empty_size
		if AN jmp even_process1
		RETS
		
even_process1:
		Pch	= PlaySynthy
		Lcall	PlaySynthy
		
		IO[CLRWDT] 	= AR
		rets

/*-----------------------------------------------------------------------------------
function: midi mark event
input:	Ar  midi mark volume
-----------------------------------------------------------------------------------*/
MidiMarkProc:
		Rets
		
/*-----------------------------------------------------------------------------------
function: to mixed other channel sound
-----------------------------------------------------------------------------------*/
OtherSoundadd:
	pch   = Adpcm6chPlay
	lcall	Adpcm6chPlay
		
;	pop  MACOP
	Rets
		
;//////////////////////////		
/*-----------------------------------------------------------------------------------
function:  new note event
-----------------------------------------------------------------------------------*/
NewnoteSet:
		Rets
		
		
/*-------------------------------------------------------
一个小节完成
-------------------------------------------------------*/
_S_A_MeasureFinished:
  
        RETS                             
/*-------------------------------------------------------
一拍結束進來
-------------------------------------------------------*/                                     
_S_A_BeatFinished:               
  
        RETS                             
/*-------------------------------------------------------
半拍結束進來
-------------------------------------------------------*/                                       
_S_HalfABeatFinished:         
  
        RETS
                                
/*-------------------------------------------------------
弯音幅度调整
-------------------------------------------------------*/
_S_MidiPitchWheels:
        //; Do not change any of the registers, in addition to AR
        AR = Pitch_wheel_Beat
        RETS
        
/*-------------------------------------------------------
新音符处理前 
Ar＝1不播放当前音符
-------------------------------------------------------*/
_S_BeforeANotePlayed:
	Ar	=1
	Rets
/*-----------------------------------------------------------------------------------
tempo 改变  从40～3320改变
-----------------------------------------------------------------------------------*/	
TempoUp_10:         
    ar    =rm[_MIDIFLAG]
    test    ar.b1 		//;stop midi
    jzr   nochabgetempo
    
    i0  = templevelcnt
    ar  =rm[i0]
    ar++
    test ar.b4
    jzr TempoUp_10_1
TempoUp_10_2:   
    ar  =0
TempoUp_10_1:         
    rm[i0]  =ar
    p1  = #tempstep
    p1  +=ar
    ar  =pm[p1]
    AR++
    JZR   TempoUp_10_2
    AR--
    bx  =ar
    ar  =rm[TEMPO1]
    ar  +=bx
    TEST  AR.B15
    JNZ TempoUp_10
    BX  =40
    SF  =AR-BX
    JNC      TempoUp_10_3
    rm[TEMPO1]=ar
    PCH =init_Tempo
    Lcall	init_Tempo
    Jmp	nochabgetempo
TempoUp_10_3:
    AR  =40
    rm[TEMPO1]=ar
    PCH =init_Tempo
     Lcall	init_Tempo
	Jmp	nochabgetempo
    
TempoUp:            //        06: TEMPO UP
    ar    =rm[_MIDIFLAG]
    test    ar.b1 // stop midi
    jzr   nochabgetempo
    
    i0  =rm[TEMPO1]
    i0++
    ar  =320
    sf=ar-i0
    jnc nochabgetempo
    ar    =i0
    rm[TEMPO1] =ar
   PCH =init_Tempo
   Lcall	init_Tempo
nochabgetempo:
    rets

TempoDwon:            //        07: TEMPO DOWN
    ar    =rm[_MIDIFLAG]
    test    ar.b1 // stop midi
    jzr   nochabgetempo
    
    ar  =rm[TEMPO1]
    jzr nochabgetempo
    ar--
    jzr nochabgetempo
    rm[TEMPO1] =ar
   PCH =init_Tempo
   Lcall	init_Tempo
   Rets
      
tempstep:
  dw 00,10,20,30,20,10,0,65526,65516,65506,65516,65526,65535
/*-----------------------------------------------------------------------------------
midi 音量减
-----------------------------------------------------------------------------------*/
Midivouledown:
	ar    =rm[Midi_Volume]
    	ar    -=0x10
    	ax    =60
    	sf    =ax -ar
    	jnc   VolumeDown1
    	ar    =60 ;0x0
    	jmp   VolumeDown1
VolumeDown1:
    	rm[Midi_Volume]=ar
    	pch = UpdateVolume
    	lcall UpdateVolume
	Rets
/*-----------------------------------------------------------------------------------
midi 音量增加
-----------------------------------------------------------------------------------*/
MidivouleUp:
    ar    =rm[Midi_Volume]
    ar    +=0x10
    sf  = ar- MAX_Midi_Volume
    jnc update_maxm_volume
    test  ar.b8
    jzr   MidivouleUp1
update_maxm_volume:   
    al    =MAX_Midi_Volume
    ah    =0
    jmp   MidivouleUp1
MidivouleUp1:
    	rm[Midi_Volume]=ar
    	pch = UpdateVolume
    	lcall UpdateVolume
    	Rets
/*-------------------------------------------------------
音量更新
-------------------------------------------------------*/
UpdateVolume:
    PUSH CX
    i0  = CHBuf
    i1  =Org_CH_VOL   
    cx  =15
    ar    = rm[PlayFlag]  
    r3    =ar

  UpdateVolume0:    
    test  r3.b0
    jzr   UpdateVolume2
    ar    =0x0d
    i0  +=ar
    ar  =rm[i1]
    al  =0
    dx  =ar
    xchg  ar
    MX  =ar
    ar  =rm[i1]
    ah  =0
    MR  =MX*AR
    ar  |=DX
    rm[i1]  =ar
    ar  =7
    i0  -=ar
    AR  =RM[I0]
    AH  =0
    dx  =ar
    ar  =MR0
    al  =0
    XCHG  AR
    MX  =AR
    AR  =rm[Midi_Volume]
    MR  =MX*AR
    AR  =MR0
    AL  =0
    ar  |=dx
    RM[I0]  =AR
    AR    =0X0A
    jmp   UpdateVolume3
  UpdateVolume2:  
    ar  =0x10
  UpdateVolume3:  
    I0    +=AR
    i1++
    sra r3
    LOOP  UpdateVolume0
    POP CX
    rets

//;包络控制部分的table
SUSTAINLEVEL:
		dw      0,20h,40h,60h,80h,0a0h,0C0h,0e0h
		dw      100h,120h,140h,160h,180h,1a0h,1c0h,1e0h
susvalue:
		dw      1122H,3444H		//;1*1000h+1*100h+2*10h+2,3*1000h+4*100h+4*10h+4
		dw      4556H,6777H		//;4*1000h+5*100h+5*10h+6,6*1000h+7*100h+7*10h+7
panlevel:

		dw      0000h,0018h,0040h,0058h,0080h,0098h,00c0h,00ffh
		dw      0ff00h,0ff00h,0C000h,9800h,8000h,5800h,4000h,1800h

Attack_table2:
		dw      3ffh,273h,24ch,21dh,1f6h,1d3h,1b6h
		dw      195h,17bh,161h,147h,134h,11bh
		dw      107h,0f7h,0e4h,0d2h,0c4h,0b8h
		dw      0abh,09bh,08eh,084h,07bh,073h
		dw      069h,05eh,055h,04dh,046h,040h
		dw      03bh,036h,032h,02eh,027h,020h
		dw      01ch,017h,013h,010h,00dh,00ah
		dw      007h,004h,002h,000h                     ; 47
Attack_table1:
		dw      3ffh,28ch,265h,235h,210h,1edh,1d0h
		dw      1aeh,194h,17ah,160h,14dh,134h
		dw      120h,110h,0feh,0ebh,0ddh,0d1h
		dw      0c4h,0b4h,0a7h,09dh,094h,08dh
		dw      083h,077h,06eh,066h,05fh,059h
		dw      054h,050h,04ch,047h,040h,03ah
		dw      035h,030h,02ch,029h,026h,023h
		dw      020h,01eh,01bh,019h,018h,016h
		dw      014h,013h,011h,010h,00fh,00eh
		dw      00dh,00dh,00ch,00bh,00ah,00ah
		dw      008h,007h,005h,004h,003h,001h
		dw      000h                                    ;68
LEVELPRECENT:
Dw   0000h, 3851h, 70A3h, 9999h, 0B333h, 0C7AEh, 0D47Ah, 0E147h
Dw   0E666h, 0E8F5h, 0EB85h, 0EE14h, 0F0A3h, 0F333h, 0F5C2h, 0F851h
LEVELPRECENT1:
LEVELPOINT:
		DW 450,450,450,225,163,102,102,40,20,20,20,20,20,20,20,1,1


