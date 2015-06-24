keyscanini:
    // KeyScan I/O Port initial
    //AR    = 0xC000
    //IO[IOC_PA]  = AR    // PortA ->Input
    //ar  =0
    //IO[IOC_PA]  = AR    // PortA ->Input
    // KeyScan variable initial
    //CX    = MARTRIXLINE ;3
    ar = 0xf0
    IO[IOC_PA] |= ar  //PortA.b4 PortA.b5 PortA.b6 PortA.b7 Output
    ar = 0x0f
    IO[PortA] &= ar
    
    ar = 0x3f         //0x1f
    IO[IOC_PB] |= ar  //PortB.b0 PortB.b1 PortB.b2 PortB.b3 PortB.b4 Output
    ar = 0xC0
    IO[PortB] &= ar
    
    ar = 0x7f
    IO[IOC_PB] &= ar  //PortB.b7 Input
    ar = 0x80
    IO[IOC_PC] = ar  // PortC.b0~b6 -> Input
    ;;IO[IOC_PC] |= ar  // PortC.b7 -> Output
    
    INITKEY_FLAG:
    I0    = scnkeyvuff
    AR    =0
    RM[I0++]  =AR
    AR    =0xff;0XFF
    ah    =0
    RM[I0++]  =AR
    RM[I0++]  =AR
    //lOOP    INITKEY_FLAG
    rets

    
    
VolumeUp:         	//        03: VOLUME UP
	pch = MidivouleUp	
	lcall	MidivouleUp
	Jmp	Keyrelease

VolumeDown:       //        04: VOLUME DOWN
	pch = Midivouledown
	lcall	Midivouledown
    jmp   Keyrelease



StopAll:            //        05: STOP
    // clear all key press Stop all
    Pch	=Midioff
    Lcall	Midioff
    RETS    //jmp nochabgevolume1


DirectKEY:

    AR    = IO[Real_T]
    rm[_31us] =ar
    i0    = keypressbuff
    R1    = 0
    ar    = 0;
    RM[MTASKREQ]  = AR;
    rm[TOTALKEY]  = ar
SCANKEYLOOP:

    I1    =scnkeyvuff

    ax    = RM[I1++];RM[KEY_FLAG] Key_State_temp
    bx    = RM[I1++];RM[DIRKEY] Key_State_New
    dx    = RM[I1++];RM[DKTIMER]  Key_State_Old

    ar    = io[PortA]
    AR    =AR^0XFF

    ah    =0
    AX    =ar
    AR         ^=bX
    R0    =AR

    ar    =ax
    bx    =ar

    ar    =R0
    JNZ   Restart_Debounce//jeq   Restart_Debounce

    AR    =rm[_last31us]
    R2    =AR
    ar    =rm[_31us]

    ar    -=R2
    r0              = rm[i1]
    ar    +=r0
    rm[i1]    =ar
    R2    =0x800   // times
    sf    =ar-R2
    jnc   KM@EXIT //jGE   KM@EXIT
    ar    =0
    rm[i1]    = ar      // reset debounce
    ar    = dx
    ax    = ar
    ar    = bx
    dx    = ar
    r0    = 0
    ar    = ar ^ Ax

    jzr     KM@EXIT //jeq   KM@EXIT
    r3    =ar
    ax    &=ar

keyreleasez:
    R2    = 1
    push cx
    cx    =7
    KM@L005@RUN_CMDT:
    test    r3.b0
    jzr    KM@L005@RUN_CMD
    //jNz   KM@L005@RUN_CMDt1
    //jmp   KM@L005@RUN_CMD
    KM@L005@RUN_CMDt1:
    clr   r0.b7
    test    ax.b0
    jNz   KM@L005@RUN_CMDt2
    set   r0.b7
    KM@L005@RUN_CMDt2:
    ar    =keypressbuff
    ar    +=0x0f
    sf    =ar-i0
    jnc   KM@L005@RUN_CMDEXIT
    AR    =R2
    AR    |=R0
    rm[i0++]  =AR
    RM[MTASKREQ]  = AR;
    R1++;
    KM@L005@RUN_CMD:
    sra   r3
    sra   ax
    ar    =r3
    jeq            KM@L005@RUN_CMDEXIT
    r2++
    LOOP    KM@L005@RUN_CMDT
    KM@L005@RUN_CMDEXIT:
    pop cx

Restart_Debounce:
    ar    =0
    rm[i1]    =ar
KM@EXIT:
    I1    =scnkeyvuff

    RM[I1++]  = ax    ; save to RM
    RM[I1++]  = bx
    RM[I1++]  = dx

    AR=   3
    ar    =ar^cx
    jnz   KM@EXIT1
    ar    =r1
    jnz   KM@EXIT2 // skip key board


KM@EXIT1:

//    LOOP    SCANKEYLOOP
KM@EXIT2:
    AR    =rm[_31us]
    rm[_last31us] =ar
    AR    =R1
    RM[TOTALKEY]  =AR

KM@EXIT3:
//    POP CX
    RETS


checkKey:
    AR    = RM[MTASKREQ]
    //IO[PortB]   = AR;     // Output Display Key status
    jzr     checkKeyret
    ar    =RM[TOTALKEY]
    ar--
    cx    = ar
TotalkeypressRelease:
    i1    =keypressbuff
    ar    =cx
    i1    +=ar
    AR    =RM[I1]
    ar--
    RM[MTASKREQ]  =AR

    TEST    AR.B7 // KEY RELEASE NOT USE
    JNZ             Keyrelease

    p0    = #functionswitch
    p0    +=ar
    ar    =RM[MTASKREQ]
    P0	=Pm[P0]
    fjmp  pm[p0]
    
Keyrelease:
		Clr	Ar.b7
    p0    = #Releaskey_proc
    p0    +=ar
    P0	=Pm[P0]
    fjmp  pm[p0]
    nop
    LOOP    TotalkeypressRelease

checkKeyret:
    AR    =0
    RM[MTASKREQ]  =AR
    rets

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DealLoopPlay:
		;;push ax
		;;push p0
		ax = 0x0FFFF
    ar = rm[loop_play_flag]
    sf = ar - ax
    jnz  Deaend

    ar = rm[_MIDIFLAG]
    test ar.b1
    jnz Deaend
	
    ar = rm[PlayFlag]
    jnz Deaend
    
    ar = rm[AdPcmflag]
    ar &= 0x0002
    jnz Deaend
    
    ar = rm[loop_play_length]
    jzr ClrLoopPlay
    
    //////
    ;;i1	=Flag1  
    ;;ar  = 1   
    ;;rm[i1] = ar
    /////

    ar = 0
    rm[timer_05ms] = ar
    
    ar = rm[loop_play_addr]
    p0 = ar
    ar = pm[p0]
    
    test ar.b15
    jzr  PlayWav
    clr ar.b15
    
    dsi
    ax = 0
    rm[AdPcmflag] = ax
    eni
    
		rm[PlayMidi] 	=	ar
		p0++
		rm[loop_play_addr] = p0
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand
		ar = rm[loop_play_length]
		ar--
		rm[loop_play_length] = ar 
    pch = Deaend
    ljmp Deaend
        
PlayWav:
		;;push ar
		;;pop ar
    rm[adp_unmber] = ar
    p0++
    rm[loop_play_addr] = p0
    ar = 1 
    rm[adp_ch_index] = ar 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    ar = rm[loop_play_length]
		ar--
		rm[loop_play_length] = ar 
    pch = Deaend
    ljmp Deaend

ClrLoopPlay:
    ar = 0
    rm[loop_play_flag] = ar
    rm[PlayFlag] = ar
    rm[_MIDIFLAG] = ar
    ar = rm[Mode_flag]
		jzr Deaend
    pch = StopAlllPlaying
    lcall StopAlllPlaying
    ar = rm[Mode_flag]
    sf = ar - 4
    jnz Deaend
    
    ar = 0x0ffff
    rm[loop_play_flag] = ar   
    ar = #TestPlayAllT
    rm[loop_play_addr] = ar
		ar = 0x0080
	  rm[loop_play_length] = ar
	  
Deaend:
    ;;pop p0
    ;;pop ax
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DealGameOnPlay:
		;;push ax
		;;push bx
		;;push cx
		;;push dx
		ar = rm[Mode_flag]
		jzr EndDealGameOnPlay   ;;normal mode ignore
		
		sf = ar - 5
		jzr EndDealGameOnPlay   ;;sleep mode ignore
		
		sf = ar - 4
		jge EndDealGameOnPlay   ;;test mode ignore
		
		ar = rm[gmode_state]
		sf = ar - 1
		jzr WaitWavPlayFinish   ;;;;gmode_state = 1 (wait start wav play finish)
		
		sf = ar - 2
		jzr WaitLoopPlayFinish
		
		sf = ar - 3
		jzr Gmode_to4
		
		sf = ar - 4
		jzr WaitWavPlayFinish
		
		sf = ar - 5
		jzr WaitLoopPlayFinish
		
		sf = ar - 6
		jzr  Gmode_to6
		
		sf = ar - 7 
		jzr WaitLoopPlayFinish
		
		sf = ar - 8
		jzr WaitWavPlayFinish
		
		sf = ar - 9
		jzr WaitWavPlayFinish
		
		sf = ar - 10
		jzr WaitWavPlayFinish 
		
		sf = ar - 12
		jzr WaitLoopPlayFinish
		
		sf = ar - 13
		jzr WaitLoopPlayFinish
		
		sf = ar - 14
		jzr WaitLoopPlayFinish
		
		sf = ar - 15
		jzr WaitLoopPlayFinish
		
		sf = ar - 19
		jzr WaitWavPlayFinish
		
		sf = ar - 20
		jzr WaitWavPlayFinish
		
		sf = ar - 21
		jzr WaitLoopPlayFinish
		
		sf = ar - 22
		jzr WaitWavPlayFinish
		
		sf = ar - 23
		jzr WaitLoopPlayFinish
		
		sf = ar - 24
		jzr WaitAllPlayFinish
		
		sf = ar - 25
		jzr WaitKeyVolumeFinish
		
WaitMidiPlayFinish:
		ar = rm[PlayFlag]
		jnz EndDealGameOnPlay
		
		pch = Gmode_to7
		ljmp Gmode_to7
		
WaitWavPlayFinish:
		ar = rm[AdPcmflag]      ;;;;wait wav play finish
    jnz EndDealGameOnPlay
    
    ar = rm[gmode_state]
    sf = ar - 1
    jzr Gmode_to2
    
    sf = ar - 4
    jzr Gmode_to5 
    
    sf = ar - 8
    jzr GmodetoSwitch
    
    sf = ar - 9
    jzr Gmode_toSleep
    
    sf = ar - 10
    jzr Gmode_to11
    
    sf = ar - 19
    jzr Gmode_to20
    
    sf = ar - 20
    jzr Gmode_to21
    
    sf = ar - 22
    jzr Gmode_to23
    
WaitLoopPlayFinish:           
    ar = rm[loop_play_flag]
	  jnz EndDealGameOnPlay    ;;loop play not end
	  
	  ar = rm[gmode_state]
    sf = ar - 2
    jzr Gmode_to3
    
    sf = ar - 5
    jzr Gmode_to6
    
    sf = ar - 6
    jzr Gmode_to7
    
    sf = ar - 7
    jzr Gmode_to8
    
    sf = ar - 12
    jzr Gmode_to13
    
    sf = ar - 13
    jzr Gmode_toSleep
    
    sf = ar - 14
    jzr Gmode_to3
    
    sf = ar - 15
    jzr Gmode_to16
    
    sf = ar - 21
    jzr Gmode_to22
    
    sf = ar - 23
    jzr Gmode_to6

WaitAllPlayFinish:
    pch = StopAlllPlaying
    lcall StopAlllPlaying
		
    ar = rm[AdPcmflag]      ;;;;wait wav play finish
    jnz EndDealGameOnPlay
    
    ar = rm[PlayFlag]
    jnz EndDealGameOnPlay

    ar = rm[_MIDIFLAG]
    test ar.b1
    jnz EndDealGameOnPlay
    
    ar = 0 
    rm[timcount] = ar
    
    ar = rm[mykeyoldvalue]
    
    ax = ar
    
    
    
    ar = rm[Mode_flag]
    sf = ar - 1
    jzr Play1
 
 		ar = ax
 		
 		sf = ar - 27
 		jge Play1
 		
Play2: 		
 		p0 = #Music_Key2_table
 		pch = PlayKeyValue
 		ljmp PlayKeyValue
 		
Play1:
		p0 = #Music_Key_table
		
PlayKeyValue:
		ar = ax
    p0 += ar
    ar = pm[p0]
    
    rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
   	ar = 25
    rm[gmode_state] = ar
    
    pch = EndDealGameOnPlay
    ljmp EndDealGameOnPlay
    

WaitKeyVolumeFinish:
		ar = rm[AdPcmflag]      ;;;;wait key volume finish
    jnz EndDealGameOnPlay
   	
   	ar = 10
    rm[gmode_state] = ar
   	
		pch = EndDealGameOnPlay
    ljmp EndDealGameOnPlay
		
Gmode_to2:
		ar = 2
		rm[gmode_state] = ar		;;;;gmode_state = 2
   
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = #G1G2G3OnSameTableEntry
    p0 = ar
    ar = rm[Mode_flag]
    ar--
    p0 += ar
    ar = pm[p0]
    rm[loop_play_addr] = ar
    ar = 5
    rm[loop_play_length] = ar
		
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay

Gmode_to3:
		ar = 3
		rm[gmode_state] = ar		;;;;gmode_state = 3
		
		ar = rm[Mode_flag]
		ar--
		bx = ar
		p1 = #G1G2G3MaxCount
		p1 += ar
		ax = pm[p1]
		
		i1 = game1count
		i1 += ar
		
		ar = rm[i1]
		sf = ar - ax
		jle  Gmode_to3_end
		
		ar = 0               ;;clear 
		rm[i1] = ar
		
Gmode_to3_end:    

		ar = 0x0000
		rm[repeat_flag] = ar   ;;clear repeat flag
		
    pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
		
Gmode_to4:
		ar = 4         
		rm[gmode_state] = ar    ;;;;gmode_state = 4
		
		ar = rm[Mode_flag]
		ar--
		bx = ar	
		i1 = game1count
		i1 += ar	
		ar = rm[i1]

    dx = ar
    ar = bx
		p0 = #G1G2G3EntryAddr
		p0 += ar
		ar = pm[p0]
		p0 = ar
		ar = dx
		p0 += ar
		ar = pm[p0]

    rm[adp_unmber] = ar  
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
		
Gmode_to5:
		ar = 5
		rm[gmode_state] = ar   ;;;;gmode_state = 5
		
		ar = rm[Mode_flag]
		ar--
		bx = ar	
		
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    
		p0 = #G1G2G3WaitEntryAddr
		ar = bx
		p0 += ar
		ar = pm[p0]
    rm[loop_play_addr] = ar
    
    p0 = #G1G2G3WaitPlayLengthEntry
    ar = rm[repeat_flag]
    p0 += ar
    ar  = pm[p0]
    p0 = ar
    ar = bx
    p0 += ar
    
    ar = pm[p0]
    rm[loop_play_length] = ar
    
    ar = 0
		rm[answer_disable] = ar  ;;;;enable sw1-45
		
		ar = 1
		rm[one_flag] = ar
		
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
		
Gmode_to6:
		ar = 6
		rm[gmode_state] = ar   ;;;;gmode_state = 6
		
		ar = rm[one_flag]
		jzr  WaitEnd
		
		ar = 0
		rm[wait_count] = ar
		ar = 1
		rm[wait_en] = ar
	
		;;ar = 0x0ffff
    ;;rm[loop_play_flag] = ar
    ;;ar = #MidiWaitT
    ;;rm[loop_play_addr] = ar
    ;;ar = 2
    ;;rm[loop_play_length] = ar
    
    ar = 3
		rm[PlayMidi] 	=	ar
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand
    
    ar = 0
    rm[one_flag] = ar
    
    pch = WaitEndEnd
    ljmp WaitEndEnd
    

WaitEnd:
		ar = rm[wait_count]
		ax = 0x4E20
		sf = ar - ax
		jle  WaitEndEnd
		
		ar = 0
		rm[wait_en] = ar
		rm[wait_count] = ar
		
		pch = Gmode_to7
		ljmp Gmode_to7
		
WaitEndEnd:
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay	

Gmode_to7:
		ar = 7
		rm[gmode_state] = ar   ;;;;gmode_state = 7   ;;bgm.mid end
		
	  ar = 0x0ffff
		rm[answer_disable] = ar  ;;;;disable sw1-54
		
		ar = rm[timcount]
		ar++
		rm[timcount] = ar
		
		ar = rm[ngcount]
		ar++
		rm[ngcount] = ar
		
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = #Bubu01208T
	  rm[loop_play_addr] = ar
	  ar = 4
	  rm[loop_play_length] = ar

		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay	  
	  
Gmode_to8:
		ar = 8
		rm[gmode_state] = ar   ;;;;gmode_state = 8
		
		ar = rm[timcount]
	  sf = ar - 3
	  jzr Gmode_to9
		
		ar = rm[ngcount]
	  sf = ar - 3
	  jzr Gmode_to17
	  
	  ar = rm[Mode_flag]
	  sf = ar - 1
	  jzr G1NgCount
		
		ar = 0x005A
		rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
    pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
		
	G1NgCount:
	  ar = rm[ngcount]
	  sf = ar - 2
	  jzr Gmode_toRemind 
		
		ar = 0
		rm[repeat_flag] = ar
		
		pch = Gmode_to4
		ljmp Gmode_to4
		
Gmode_to9:
		ar = 9
		rm[gmode_state] = ar   ;;;;gmode_state = 9
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = #ThankYouT
	  rm[loop_play_addr] = ar
	  ar = 3
	  rm[loop_play_length] = ar
	  
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
		
Gmode_to11:
		ar = 11
		rm[gmode_state] = ar   ;;;;gmode_state = 11
		
		ar = 0
		rm[wait_en] = ar
		rm[wait_count] = ar
		
		ax = rm[mykeyoldvalue]
		ar = rm[Mode_flag]
		ar--
		bx = ar
		
		p0 = #KeyEntryT
		p0 += ar
		ar = pm[p0]
		p0 = ar
		
		ar = bx
		i0 = game1count
		i0 += ar
		ar = rm[i0]   
		
		p0 += ar
		
		ar = pm[p0]
		
		sf = ar - ax
		jzr Gmode_to12
		
		pch = Gmode_to15
		ljmp Gmode_to15

Gmode_to12:
		ar = 12
		rm[gmode_state] = ar   ;;;;gmode_state = 12

		ar = 0x0ffff
    rm[loop_play_flag] = ar
    
    p0 = #RightAnswerT
    ar = rm[okcount]
    p0 += ar 
    ar = pm[p0]
   
    rm[loop_play_addr] = ar
		ar = 4
	  rm[loop_play_length] = ar
	  
	  ar = 0
	  rm[ngcount] = ar
	  
	  ar = rm[okcount]
	  ar++
	  rm[okcount] = ar
	  
	  pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay

Gmode_to13:
		ar = 13
		rm[gmode_state] = ar   ;;;;gmode_state = 13

		ax = 0x0005
		
		ar = rm[Mode_flag]
		sf = ar - 3
		jnz cmpOKOK
		
		ax = 0x0003
		
 cmpOKOK:
 		ar = rm[okcount]
		sf = ar - ax
		jzr Gmode_to9
		
		pch = Gmode_to14
		ljmp Gmode_to14
		
  ;;PlayGoodJob:
		;;ar = 0x0ffff
    ;;rm[loop_play_flag] = ar
    ;;ar = #GoodJobT
		;;rm[loop_play_addr] = ar
		;;ar = 4
	  ;;rm[loop_play_length] = ar
	  
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
			
Gmode_to14:
		ar = 14
		rm[gmode_state] = ar   ;;;;gmode_state = 14
		ar = rm[Mode_flag]
		sf = ar - 1
		jnz PlayNextQu
				
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = #NextQuT1
    rm[loop_play_addr] = ar
		ar = 4
	  rm[loop_play_length] = ar
	  
	  pch = EndGmode14
		ljmp EndGmode14

	PlayNextQu:
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = #NextQuT
    rm[loop_play_addr] = ar
		ar = 3
	  rm[loop_play_length] = ar

EndGmode14:	  
	  ar = rm[Mode_flag]
		ar--
		
		i0 = game1count
		i0 += ar
		ar = rm[i0]
		ar++
		rm[i0] = ar
	  
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay

Gmode_to15:
		ar = 15
		rm[gmode_state] = ar   ;;;;gmode_state = 15
		
		ar = rm[ngcount]
		ar++
		rm[ngcount] = ar
		
		ar--
		p0 = #WrongAnswerT
		p0 += ar
		
	PlayWrongAnswer:
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    
    ar = pm[p0]
    
    rm[loop_play_addr] = ar
		ar = 4
	  rm[loop_play_length] = ar
	  
	  
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay

Gmode_to16:
		ar = 16
		rm[gmode_state] = ar   ;;;;gmode_state = 16
		
		ar = rm[ngcount]
		sf = ar - 3
		jzr Gmode_to17
		
		sf = ar - 2
		jzr G2modeSwitch
		
		pch = SeToGmode_to4
		ljmp SeToGmode_to4
		
G2modeSwitch:
		ar = rm[Mode_flag]
		sf = ar - 2
		jzr SeToGmode_to4
		
		pch = Gmode_toRemind
		ljmp Gmode_toRemind
		
SeToGmode_to4:

		ar = 1
		rm[repeat_flag] = ar
		
		pch = Gmode_to4
		ljmp Gmode_to4
		
Gmode_to17:
		ar = 17
		rm[gmode_state] = ar   ;;;;gmode_state = 17
		
		ax = 0x0005
		
		ar = rm[Mode_flag]
		sf = ar - 3
		jnz cmpOK
		
  cmpOK3:
		ax = 0x0003
		
  cmpOK:
		ar = 0
		rm[ngcount] = ar
		
		ar = rm[okcount]
		ar++
		rm[okcount] = ar
		
		sf = ar - ax
		jzr Gmode_to9
		
		pch = Gmode_to14
		ljmp Gmode_to14

GmodetoSwitch:
		ar = rm[Mode_flag]
		sf = ar - 2            ;;;; G2 directly to C3
		jzr Deal2Gm4
		
		ar = rm[ngcount]
		sf = ar - 2
		jzr Gmode_toRemind

Deal2Gm4:		
		ar = 1
		rm[repeat_flag] = ar
		pch = Gmode_to4
		ljmp Gmode_to4
		
Gmode_toSleep:
		ar = 5
		rm[Mode_flag] = ar
		pch = EndDealGameOnPlay
		ljmp EndDealGameOnPlay
	 
Gmode_toRemind:
		ar = 18                ;;;;Remind(18)
		rm[gmode_state] = ar   ;;;;gmode_state = 18
		
		;;pch = Gmode_to20
		;;ljmp Gmode_to20
		
;;Gmode_to19:
		;;ar = 19                
		;;rm[gmode_state] = ar   ;;;;gmode_state = 19
		
		;;ar = 0x005A
		;;rm[adp_unmber] = ar
    ;;ar = 1 
    ;;rm[adp_ch_index] = AR 
    ;;pch   = play_adpcm_inti
    ;;lcall	play_adpcm_inti
    
    ;;pch = EndDealGameOnPlay
    ;;ljmp EndDealGameOnPlay

Gmode_to20:
		ar = 20               
		rm[gmode_state] = ar   ;;;;gmode_state = 20
		
		ar = rm[Mode_flag]
		ar--
		bx = ar	
		i1 = game1count
		i1 += ar	
		ar = rm[i1]

    dx = ar
    ar = bx
		p0 = #G1G2G3EntryAddr3
		p0 += ar
		ar = pm[p0]
		p0 = ar
		ar = dx
		p0 += ar
		ar = pm[p0]

    rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
		
		ar = 0
		rm[answer_disable] = ar  ;;;;enable sw1-54
		
		pch = EndDealGameOnPlay
    ljmp EndDealGameOnPlay
    
Gmode_to21:
		ar = 21               
		rm[gmode_state] = ar   ;;;;gmode_state = 21
		
  
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    ar = rm[Mode_flag]
    sf = ar - 1
    jzr RT1
    ar = #RemindT3
    jmp PlayRemind
RT1:
		ar = #RemindT1
		
PlayRemind:
    rm[loop_play_addr] = ar
    
    ar = rm[Mode_flag]
    sf = ar - 1
    jzr Ar2
    
    ar = 3
    
    pch = SetLength
    ljmp SetLength
    
 Ar2:
 		ar = 2

 SetLength:		
	  rm[loop_play_length] = ar
	  
		pch = EndDealGameOnPlay
    ljmp EndDealGameOnPlay

Gmode_to22:
		ar = 22               
		rm[gmode_state] = ar   ;;;;gmode_state = 22
		
		ar = rm[Mode_flag]
		ar--
		bx = ar	
		i1 = game1count
		i1 += ar	
		ar = rm[i1]

    dx = ar
    ar = bx
		p0 = #G1G2G3EntryAddr2
		p0 += ar
		ar = pm[p0]
		p0 = ar
		ar = dx
		p0 += ar
		ar = pm[p0]

    rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
		pch = EndDealGameOnPlay
    ljmp EndDealGameOnPlay

Gmode_to23:
		ar = 23              
		rm[gmode_state] = ar   ;;;;gmode_state = 23
		
		ar = rm[Mode_flag]
		sf = ar - 1
		jzr PlayRemindG1
		sf = ar - 3
		jzr PlayRemindG3  
		
  PlayRemindG3:
		ar = 0x0ffff
		rm[loop_play_flag] = ar
		ar = #G3RemindT
		rm[loop_play_addr] = ar
		ar = 3
	  rm[loop_play_length] = ar
	  
	  pch = EndDealGameOnPlayW
    ljmp EndDealGameOnPlayW
	  
  PlayRemindG1:
		ar = 0x0ffff
		rm[loop_play_flag] = ar
		ar = #G1RemindT
		rm[loop_play_addr] = ar
		ar = 4
	  rm[loop_play_length] = ar
	  
EndDealGameOnPlayW:
	  ar = 1
		rm[one_flag] = ar

EndDealGameOnPlay:
    ;;pop dx
    ;;pop cx
    ;;pop bx 
		;;pop ax
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DealKeyMseeage:
		;;push i0
		;;push i1
		;;push ax
		;;push bx
		
		i0 = mykeycnt
		ar = rm[i0]
		
		ax = 1000
		
		sf = ar - ax
		jne Dend
		
		ax = rm[mycheckkeybuff]
		
		ar = ax
		sf = ar - 61
		jnz  Game3
		
		IO[CLRWDT]  = AR
		
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestGame3
	
		ar = 5
		rm[Mode_flag] = ar
    
    ;;ar = 0
    ;;rm[loop_play_addr] = ar
    ;;rm[loop_play_length] = ar
    ;;rm[loop_play_flag] = ar
    ;;rm[loop_play_num] = ar
    
		;;pch = StopAlllPlaying
		;;lcall StopAlllPlaying
		
		;;ar = 0
		;;rm[_MIDIFLAG] = ar
		;;rm[AdPcmflag] = ar
		
		pch = Dend
		ljmp Dend		
		
Game3:
		sf = ar - 60
		jzr DealG3
		ar = rm[Mode_flag]
		jzr Game2ClearLoopPlayFlag
		sf = ar - 4
		jzr Game2ClearLoopPlayFlag
		ar = ax
		pch = Game2
		ljmp Game2
		
DealG3:
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestGame3
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		
		
		ar = 3
		rm[Mode_flag] = ar
	  pch = G1toG3Deal
	  ljmp G1toG3Deal
	  	
TestGame3:
		ar = 0x0ffff
    rm[loop_play_flag] = ar   
    ar = #TestPlayAllT
    rm[loop_play_addr] = ar
		ar = 0x0080
	  rm[loop_play_length] = ar
	  
		pch = Dend
		ljmp Dend
		
Game2ClearLoopPlayFlag:
		ar = 0   
		rm[loop_play_flag] = ar
		rm[loop_play_num] = ar
		ar = ax
Game2:
		sf = ar - 59
		jnz  Game1
		
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestGame2
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 2
		rm[Mode_flag] = ar
	  pch = G1toG3Deal
	  ljmp G1toG3Deal
		
TestGame2:
		ar = rm[count_num]
		p0 = #TestPlayModeT
		p0 += ar
		ar = pm[p0]
		test ar.b15
		jzr TestGame2Wav
		
		clr ar.b15
		rm[PlayMidi] 	=	ar
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand
		
		pch = Dend
		ljmp Dend
		
TestGame2Wav:
		rm[adp_unmber] = ar
    ar = 2 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
		pch = Dend
		ljmp Dend
		
Game1:		
		sf = ar - 58
		jnz  MymidiStart
		
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestGame1
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 1
		rm[Mode_flag] = ar
	  pch = G1toG3Deal
	  ljmp G1toG3Deal

TestGame1:
		ar = rm[count_num]
		ar++
		sf = ar - 116
		jle copy_count
		ar = 0
copy_count:		
		rm[count_num] = ar
		
		ar = 93
    rm[adp_unmber] = ar
    ar = 2 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
		
		pch = Dend
		ljmp Dend
		
G1toG3Deal:
    ar = 1
    rm[gmode_state] = ar  ;;;;start game mode
    ar = 0x0ffff
    rm[answer_disable] = ar ;;;;disable sw1-54
    
    ar = rm[Mode_flag]   
		ar--
		
    i0 = game1count
    i0 += ar
    ar = rm[i0] 
    ar++
    rm[i0] = ar
    
    ar = 0
    rm[okcount] = ar
    rm[ngcount] = ar
    rm[timcount] = ar
    
    rm[loop_play_addr] = ar
    rm[loop_play_length] = ar
    rm[loop_play_flag] = ar
    rm[loop_play_num] = ar
    
    ar = 0x0001         
    rm[gmode_state] = ar
    
    ar = rm[Mode_flag]   
		ar--
    p0 = #G1G2G3OnTable
    p0 += ar
    
    
    ar = pm[p0]
    
		pch = PlayMyWav
		ljmp PlayMyWav
		
MymidiStart:		
		sf = ar - 55
		jnz  Mymidi
				
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestModeM1 

		ar = 0
		rm[Mode_flag] = ar
		ar = 1
		rm[gmode_state] = ar
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 109
		pch = PlayMyWavCh2
		ljmp PlayMyWavCh2
		
TestModeM1:
		ar = 0
		rm[PlayMidi] 	=	ar
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand
		
		pch = Dend
		ljmp Dend
		
Mymidi:
		sf = ar - 56
		jnz  Mymidi1
		
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestModeM2
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 0
		rm[Mode_flag] = ar
		ar = 1
		rm[gmode_state] = ar
		
		ar = 112
		pch = PlayMyWavCh2
		ljmp PlayMyWavCh2
		
TestModeM2:	
		ar = 1
		rm[PlayMidi] 	=	ar
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand
		
		pch = Dend
		ljmp Dend
		
Mymidi1:
		sf = ar - 57
		jnz Myplaywav
		
		ar = rm[Mode_flag]
		sf = ar - 4
		jzr TestModeM3

		ar = 0
		rm[Mode_flag] = ar
		ar = 1
		rm[gmode_state] = ar
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 111
		pch = PlayMyWavCh2
		ljmp PlayMyWavCh2
		
TestModeM3:		
		ar = 2
		rm[PlayMidi] 	=	ar
		pch =	PlayMidiCommand
		lcall	PlayMidiCommand

	  pch = Dend
		ljmp Dend
		
PlayMyWavCh2:

    rm[adp_unmber] = ar
    ar = 0
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti
    
		pch = Dend
		ljmp Dend

Myplaywav:
		ar = rm[Mode_flag]
		jzr NormalModeSw1to54
		
		sf = ar - 4
		jzr TestModeSw1to54
		
GameModeSw1to54:		
		ar = rm[answer_disable]
		jnz GameModeSw1to54End
		
		pch = StopAlllPlaying
		lcall StopAlllPlaying
		
		ar = 0x0ffff
		rm[answer_disable] = ar    ;;;;disable all key
		
		ar = 0
		rm[timcount] = ar
		
		ar = 0x0018                  
		rm[gmode_state] = ar      ;;;;gmode_state = 24  wait stop all playing finish
		
		ar = rm[mycheckkeybuff]
		rm[mykeyoldvalue] = ar
		
		ar = 0
		rm[PlayFlag] = ar
		rm[_MIDIFLAG] = ar
		
GameModeSw1to54End:
		
		pch = Dend
		ljmp Dend
	
NormalModeSw1to54:
    ar = ax
    sf = ar - 27
    jge ClearOldKeyValue
    
    bx = rm[mykeyoldvalue]
		ar = bx
    sf = ar - ax
    jnz  TestModeSw1to54
    
    bx = 0
    rm[mykeyoldvalue] = bx
    
SwitchT_Play: 
		
		ar = 0x0ffff
    rm[loop_play_flag] = ar
    
    ar = ax
    p0 = #Music1_6T
		p0 += ar
		ar = pm[p0]
    rm[loop_play_addr] = ar
    
    ar = ax
    p0 = #Music1_6_Num_T
    p0 += ar
    ar = pm[p0]
	  rm[loop_play_length] = ar

		pch = Dend
		ljmp Dend

TestModeSw1to54:
		bx = rm[mycheckkeybuff]
		rm[mykeyoldvalue] = bx
		pch = LoadKeyTable
		ljmp LoadKeyTable
		
ClearOldKeyValue:	
    bx = 0
    rm[mykeyoldvalue] = bx
    
    ar = ax
    sf = ar - 44
    jle LoadKeyTable
    
    sf = ar - 50
    jge LoadKeyTable
    
    ar = ar - 45
    
    p0 = #AnimalT
    
    p0 += ar
    
    ar = pm[p0]
		
		pch = PlayMyWav
		ljmp PlayMyWav
    
LoadKeyTable:    
		ar = #Music_Key_table
		ar += ax			
		p0 = ar
	
		ar = pm[p0]
	
PlayMyWav:

    rm[adp_unmber] = ar
    ar = 1 
    rm[adp_ch_index] = AR 
    pch   = play_adpcm_inti
    lcall	play_adpcm_inti

Dend:
		;;pop bx
		;;pop ax
		;;pop i1
		;;pop i0
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MyCheckKey:
		;;push i0
		;;push i1
		;;push ax
		;;push bx
		;;push cx
		
		cx = 16
		i0 = mycheckkeycnt                                  
		i1 = myscankeycnt  
		ar = rm[i1]
		sf = ar - 1
		
		jzr clear_debounce
		
		ar = rm[key_debounce]
		ar++
		ax = 1000
		sf = ar - ax
		jnz copy_debounce
		
		ar = 0
		rm[key_debounce] = ar
		
		pch = clearall
		ljmp clearall
		
copy_debounce:
		rm[key_debounce] = ar
		pch = comp
		ljmp comp
		
clear_debounce:
		ar = 0
		rm[key_debounce] = ar
comp:
		ar = rm[i1]
		ax = ar
		ar = rm[i0]
		sf = ax -ar
		jnz copy
		i0++
		i1++
		loop comp
		pch = cntadd1
		ljmp  cntadd1
		
copy:
    cx = 16	
    i0 = mycheckkeycnt                                  
		i1 = myscankeycnt
co:
		ar = rm[i1]
		rm[i0] = ar
		i0++
		i1++
		loop co

clearkeycnt:		
		i0 = mykeycnt
		ar = rm[i0]
		ax = 1001              ;;;;skip when powen on because of mykeycnt = 1001
		sf = ar - ax
		jzr MyCheckKeyEnd
		ar = 0
		rm[i0] = ar
		pch = MyCheckKeyEnd
		ljmp MyCheckKeyEnd
		
cntadd1:
		ax = 1000
		i0 = mykeycnt
		ar = rm[i0]
		ar++
		sf = ar - ax
		jle  copymykeycnt
		
		ar = 1001
		
copymykeycnt:
		rm[i0] = ar
		pch = MyCheckKeyEnd
		ljmp MyCheckKeyEnd
		
clearall:
		cx = 35
		i0 = myscankeycnt   ;; clear en
		ar = 0
cl0:		
		rm[i0++] = ar
		loop cl0
		 
MyCheckKeyEnd:
		;;pop cx
		;;pop bx
		;;pop ax
		;;pop i1
		;;pop i0
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
MyKeyscan:                                                  
				;;push ax                                             
				;;push bx                                             
				;;push cx                                             
				;;push dx                                             
				                                          
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				                                                    
				i0 = myscankeybuff                                  
				i1 = myscankeycnt                                             
				ar = 0                                              
				ax = ar                                             
				bx = ar                                             
				cx = ar                                             
				dx = ar
				rm[i1] = ar           ;;清按键数                                             
				                                                    
				ah = 0                                              
				ar = IO[PortC]                                      
				ar &= 0x7f                                          
				                                                    
				jnz MyKeyscanHWErrorDeal                            
		                                                        
				set IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4
				p0 = #TL0                               
                                                            
Myscanstart:				                                        
				ar = IO[PortC]                                      
				jzr L1                                              
				test ar.b0                                          
				jzr H1                                              
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b0                                          
				jzr H1                                              
				bx = 0                                              
				rm[i0++] = PM[p0]  
				dx = rm[i1]
				dx++
				rm[i1] = dx                        
				pch = L1                                            
				ljmp L1        ;;屏蔽其他按键                       
H1:     
				p0++                                                    
				test ar.b1                                          
				jzr  H2                                             
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b1                                          
				jzr  H2                                             
				bx = 1                                              
				rm[i0++] = PM[p0]
				dx = rm[i1]
				dx++
				rm[i1] = dx                                          
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
H2:     
				p0++                                                  
				test ar.b2                                          
				jzr  H3                                             
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b2                                          
				jzr H3                                              
				bx = 2                                              
				rm[i0++] = PM[p0]   
				dx = rm[i1]
				dx++
				rm[i1] = dx                                        
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
H3:     
				p0++                                                    
				test ar.b3                                          
				jzr  H4                                             
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b3                                          
				jzr  H4                                             
				bx = 3                                              
				rm[i0++] = PM[p0]     
				dx = rm[i1]
				dx++
				rm[i1] = dx                                      
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
H4:	    
				p0++                                                    
				test ar.b4                                          
				jzr H5                                              
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b4                                          
				jzr H5                                              
				bx = 4                                              
				rm[i0++] = PM[p0]  
				dx = rm[i1]
				dx++
				rm[i1] = dx                                         
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
H5:     
				p0++                                                    
				test ar.b5                                          
				jzr H6                                              
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b5                                          
				jzr H6                                              
				bx = 5                                              
				rm[i0++] = PM[p0] 
				dx = rm[i1]
				dx++
				rm[i1] = dx                                         
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
H6:     
				p0++                                                    
				test ar.b6                                          
				jzr  L1                                             
				nop                                                 
				nop                                                 
				nop                                                 
				test ar.b6                                          
				jzr  L1                                             
				bx = 6                                              
				rm[i0++] = PM[p0] 
				dx = rm[i1]
				dx++
				rm[i1] = dx                                          
				pch = L1                                            
				ljmp L1			;;屏蔽其他按键	                        
L1:     
				p0 = #TL1                                                    
				test IO[PortA].b4                                   
				jzr L2                                              
				clr IO[PortA].b4                                    
				set IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 1                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
				                                                    
L2:     
				p0 = #TL2                                                    
				test IO[PortA].b5                                   
        jzr L3                                              
        clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				set IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 2                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
                                                            
L3:     
				p0 = #TL3                                                    
				test IO[PortA].b6                                   
				jzr L4                                              
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				set IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 3                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
				                                                    
L4:     
				p0 = #TL4                                                    
				test IO[PortA].b7                                   
				jzr  L5                                             
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				set IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 4                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
				                                                    
L5:     
				p0 = #TL5                                                    
				test IO[PortB].b0                                   
				jzr  L6                                             
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				set IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 5                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
				                                                    
L6:     
				p0 = #TL6                                                    
				test IO[PortB].b1                                   
				jzr L7                                              
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				set IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 6                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
                                                            
L7:     
				p0 = #TL7                                                    
				test IO[PortB].b2                                   
				jzr L8                                              
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				set IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 7                                              
				pch = Myscanstart                                   
				ljmp Myscanstart                                    
                                                            
L8:     
				p0 = #TL8                                                    
				test IO[PortB].b3                                   
				jzr  L0                                             
				clr IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				set IO[PortB].b4                                    
				ax = 8                                              
				pch = Myscanstart                                  
				ljmp Myscanstart                                   
				                                                    
L0:     
				p0 = #TL0                                                    
				test IO[PortB].b4                                   
				jzr  L1                                             
				set IO[PortA].b4                                    
				clr IO[PortA].b5                                    
				clr IO[PortA].b6                                    
				clr IO[PortA].b7                                    
				clr IO[PortB].b0                                    
				clr IO[PortB].b1                                    
				clr IO[PortB].b2                                    
				clr IO[PortB].b3                                    
				clr IO[PortB].b4                                    
				ax = 0                                              
				pch = MyKeyscanEnd                                   
				ljmp MyKeyscanEnd                                    
				                                                    
				;;clr IO[PortA].b4                                  
				;;set IO[PortA].b5                                  
				;;ar = IO[PortC]                                    
				;;jzr  L1                                           
				                                                    
MyKeyscanHWErrorDeal:                                       
        ;;                                                  
        ;; Hardware Error!                                       
				;;                                                  
								                                            
MyKeyscanEnd:                                               
				;;pop dx                                              
				;;pop cx                                              
				;;pop bx                                              
				;;pop ax                                              
				rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

//---------------------------------------
F_IOSetDelayTimer:	
	push			cx
	cx		=	0x0020
L_IOSetDelayTimerLoop:	
	IO[CLRWDT]	=	ar
	nop
	loop		L_IOSetDelayTimerLoop
	pop			cx
	rets
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StopAlllPlaying:
		pch = StopAll                  
		lcall StopAll
    
    ar = 0
    rm[PlayFlag] = ar
		rm[AdPcmflag] = ar
		
    ;;cx = 0x00ff
        
    ;;i0 = SUMLH
    
;;clrSUMLH:
    ;;ar = 0
    ;;RM[i0++] = ar
    ;;loop clrSUMLH

    IO[CLRWDT] = AR
    
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Wait30s:
		;;push ax
		ar = rm[waitflag]
		sf = ar - 2
		jnz ClearCount
		
		ar = rm[mycheckkeycnt]
		jnz ClearCount

		ar = rm[Mode_flag]
		
		sf = ar - 1
		jzr ClearCount
		
		sf = ar - 2
		jzr ClearCount
		
		sf = ar - 3
		jzr ClearCount
		
		ax = 0x0EA46
		
		ar = rm[timer_05ms]
		
		sf = ar - ax
		jnz Wait30sEnd
		
		ar = 5
		rm[Mode_flag] = ar ;;enter sleep
		
ClearCount:
		ar = 0
		rm[timer_05ms] = ar
Wait30sEnd:
		;;pop ax
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
compPB5:
		test io[PortB].b5
    jzr n000
    clr io[PortB].b5
    pch = bacc
    ljmp bacc
n000:
		set io[PortB].b5 
bacc:		 	
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Rampdown_Process:

		MACOP		= 0x02;
		ar		= 0x09
		CBL		= ar 
		cx		= 0x03
		;;ar		= rm[Ramp_UpDown]
		ax		= ar
		i0		= rm[MidiPcmOut];
    Dec_fill_lp:
		ar		= rm[i0]
		bx		= ar
		ar		= 0x00
		rm[i0++]	= ar
		ar		= bx
		mx		= ar 
		ar		= ax
		mr		= mx*ar;
		ar		= mr1
		io[DACL]	= ar 
		io[DACR]	= ar;
		ar		= ax
		ax 		= 0x010
		ar		-= ax
		;;rm[Ramp_UpDown]	= ar 
		Jnc		_RampdownEnd
		ax		= ar 
		
		nop
		loop		Dec_fill_lp
		
		
		rm[MidiPcmOut]	= i0;
		ar		= ax
		;;rm[Ramp_UpDown]	= ar 
		Jmp		popStack1
		
_RampdownEnd:
		ar		= 0x00
		;;rm[Ramp_Flag] = ar 
		
		call		clr_PCMBuf
popStack1:
		
	exit_Rampdown:
		rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clr_PCMBuf:
		IO[CLRWDT]	=	ar
		
    cx=0x1ff
    ar=0
    i0=MidiPCMBuf
clr_PCMBuf_loop:
    rm[i0++]=ar
     		
    nop
    loop clr_PCMBuf_loop
    ar		= MidiPCMBuf.n0
    ah		= MidiPCMBuf.n1
    rm[MidiPcmIn]	= ar;
    rm[MidiPcmOut]	= ar; 
    ar		= 0;
    FLTI		= ar;
    FLTI		= ar;
    FLTI		= ar;
    FLTI		= ar;
     		
    ADPPCM		= ar 
    ADPPCM		= ar
    ADPPCM		= ar
    ADPPCM		= ar
    FLTA		= ar;
    ar		= FLTO	
     		
 		
 		IO[CLRWDT]	=	ar
 		cx	= 	25
 		I0	=	AdpcmFiltBuf
 		i0++		
 		i0++
 		ar	=	0x0000
 		
L_ClearAdpcmLoop:   
		rm[i0++]	=	ar
		
    nop	      	
	  loop		L_ClearAdpcmLoop
	      	
    rets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
/*-----------------------------------------------------------------------------
Midi 播放
------------------------------------------------------------------------------*/
PlayMidiCommand:    //        02: MIDI NUMBER
    // clear all key press midi play first


    //call    offAllKeyPress
    CALL StopMidi
    ar    =rm[_MIDIFLAG]
    set   ar.b3 // start midi
    rm[_MIDIFLAG] =ar

    rets
    
/*-------------------------------------------------------
播放下一个mid
-------------------------------------------------------*/      
PlayNextMidiCommand:  //        08: Play next midi
    // clear all key press midi play first
    CALL StopMidi
    ar    =rm[_MIDIFLAG]
    set   ar.b3 // start midi
    rm[_MIDIFLAG] =ar
    ar=rm[PlayMidi]
    ar++
    rm[PlayMidi]=ar
    rets
/*-------------------------------------------------------
Midi停止播放
-------------------------------------------------------*/      
StopMidi:
    dsi
    ar  =0
    rm[_MIDIFLAG] =ar     // clear all midi event
    rm[PlayFlag] = ar
    Pch	=Midioff
    Lcall	Midioff
    eni
    rets

changeIns:
	Ax		=0				//;instrument
	ar		=0				//;channel
	i0		=CH_program
	i0		+=ar
	rm[i0]		=ax
	Rets
	
Pianokey1:

	Ar		=0x44
	Rm[MTASKREQ]	=Ar
	Ar		=0x0b44			//;instrument  high byte is channel information
	Rm[Speehnumber]	=Ar
	Ar		=0x7fff
	Rm[NoteBeat]	=Ar
	Ar		=0x03f
	Rm[KeyOnvolume]	=Ar
	Pch		=MIdiKeyon_init
	Lcall		MIdiKeyon_init
	Rets
Pianokey2:
	Ar		=0x45
	Rm[MTASKREQ]	=Ar
	Ar		=0x0c00			//;instrument  high byte is channel information
	Rm[Speehnumber]	=Ar
	Ar		=0x7fff
	Rm[NoteBeat]	=Ar
	Ar		=0x03f
	Rm[KeyOnvolume]	=Ar
	Pch		=MIdiKeyon_init
	Lcall		MIdiKeyon_init
	Rets
		
stop_Pianokey1:
		Cx		=15
stop_Pianokey1_Loop:
		Ar		=Cx
		I1		=CHBuf
		Slz		Ar,2
		Slz		Ar,2
		I1		+=Ar
		Ar		=13
		I1		+=Ar
		Ar		=Rm[I1]
		Xchg		Ar
		Ah		=0
		Sf		=Ar-0x0b
		If Zr		Jmp stop_Pianokey1_release
		Loop		stop_Pianokey1_Loop
		Jmp		stop_Pianokey1_end
		
stop_Pianokey1_release:

		 i0      =ADSRPARA
   		 ar      =Cx
    		 ar      +=0x10
    		 i0      +=ar
    		AR      = RM[I0]
    		SRA     AR,2
    		SRA     AR,2
   		 BX      =0X0F00
    		BX      =AR&BX  			//; for fast keyoff
    		SET     BX.B14
    		SET     BX.B15

    		i0    = ADSRstatusCNT
    		ar      = Cx
    		i0    += ar
    		rm[i0]  =Bx
stop_Pianokey1_end:
		Rets
		
		
stop_Pianokey2:
		Cx		=15
stop_Pianokey2_Loop:
		Ar		=Cx
		I1		=CHBuf
		Slz		Ar,2
		Slz		Ar,2
		I1		+=Ar
		Ar		=13
		I1		+=Ar
		Ar		=Rm[I1]
		Xchg		Ar
		Ah		=0
		Sf		=Ar-0x0c
		If Zr		Jmp stop_Pianokey2_release
		Loop		stop_Pianokey2_Loop
		Jmp		stop_Pianokey2_end
		
stop_Pianokey2_release:
		i0      =ADSRPARA
   		 ar      =Cx
    		 ar      +=0x10
    		 i0      +=ar
    		AR      = RM[I0]
    		SRA     AR,2
    		SRA     AR,2
   		 BX      =0X0F00
    		BX      =AR&BX  			//; for fast keyoff
    		SET     BX.B14
    		SET     BX.B15

    		i0    = ADSRstatusCNT
    		ar      = Cx
    		i0    += ar
    		rm[i0]  =Bx
stop_Pianokey2_end:
		Rets
		
	
	
DONOTHING:
		Rets	
functionswitch:
DW   	#PlayMidiCommand     //        01: MIDI NUMBER
DW   	#PlayNextMidiCommand   //        00: Play next midi
DW  	#changeIns    
DW  	#Pianokey1           //        05: StopAll
DW   	#Pianokey2          //        05: StopAll
DW   	#StopMidi   
DW   	#TempoUp_10              //        06: TEMPO DOWN    jmp   RepeatMidi  
DW   	#Keyrelease

Releaskey_proc:
DW   	#DONOTHING
DW   	#DONOTHING 
DW   	#DONOTHING 
DW   	#stop_Pianokey1 
DW   	#stop_Pianokey2 
DW   	#DONOTHING 
DW   	#DONOTHING 
DW   	#DONOTHING 
DW   	#DONOTHING 
DW   	#DONOTHING 

key_table:
TL0:
dw	45,
dw	56,
dw	37,
dw  27,
dw  19,
dw  10,
dw  1,

TL1:
dw	47,
dw	46,
dw	38,
dw  28,
dw  20,
dw  11,
dw  2,

TL2:
dw	49,
dw	48,
dw	39,
dw  29,
dw  21,
dw  12,
dw  3,

TL3:
dw	57,
dw	0,
dw	40,
dw  30,
dw  22,
dw  13,
dw  4,

TL4:
dw	59,
dw	50,
dw	41,
dw  31,
dw  23,
dw  14,
dw  5,

TL5:
dw	58,
dw	51,
dw	42,
dw  32,
dw  24,
dw  15,
dw  6,

TL6:
dw	54,
dw	52,
dw	36,
dw  35,
dw  55,
dw  18,
dw  9,

TL7:
dw	0,
dw	60,
dw	44,
dw  34,
dw  26,
dw  17,
dw  8,

TL8:
dw	53,
dw	61,
dw	43,
dw  33,
dw  25,
dw  16,
dw  7,

Music_Key_table:
dw  0x0000
dw  0x0000
dw  0x0002
dw  0x0004
dw  0x0006
dw  0x0008
dw  0x000A
dw  0x000C
dw  0x000E
dw  0x0010
dw  0x0012
dw  0x0014
dw  0x007A
dw  0x0018
dw  0x001A
dw  0x001C
dw  0x001E
dw  0x0020
dw  0x0022
dw  0x0024
dw  0x0026
dw  0x0028
dw  0x002A
dw  0x002C
dw  0x002E
dw  0x0030
dw  0x0032

dw  0x0034
dw  0x0035
dw  0x0036
dw  0x0037
dw  0x0038
dw  0x0039
dw  0x003A
dw  0x003B
dw  0x003C
dw  0x003D

dw  0x003F
dw  0x0041
dw  0x003E
dw  0x0040
dw  0x0045
dw  0x0043
dw  0x0042
dw  0x0044

dw  0x004B
dw  0x004D
dw  0x004F
dw  0x0051
dw  0x0053
dw  0x0046
dw  0x0047
dw  0x0048
dw  0x0049
dw  0x004A

Music_Key2_table:
dw  0x0000
dw  0x0072
dw  0x0073
dw  0x0074
dw  0x0007
dw  0x0009
dw  0x000B
dw  0x0075
dw  0x000F
dw  0x0076
dw  0x0013
dw  0x0077
dw  0x0078
dw  0x0019
dw  0x001B
dw  0x001D
dw  0x001F
dw  0x0021
dw  0x0023
dw  0x0079
dw  0x0027
dw  0x0029
dw  0x002B
dw  0x002D
dw  0x002F
dw  0x0031
dw  0x0033

StartModeOnTable:
dw  0x8006
dw  0x008F
dw  0x0061
dw  0x0000   ;;end

G1G2G3OnTable:
dw  0x0055
dw  0x006B
dw  0x0056

G1G2G3OnSameTableEntry:
dw  #G1OnTable
dw  #G2OnTable
dw  #G3OnTable

G1OnTable:
dw  0x008F
dw  0x0071
dw  0x008F
dw  0x005F
dw  0x008F
dw  0x0000   ;;end

G2OnTable:
dw  0x008F
dw  0x0071
dw  0x008F
dw  0x0089
dw  0x008F
dw  0x0000   ;;end

G3OnTable:
dw	0x008F
dw  0x0071
dw  0x008F
dw	0x005E
dw  0x008F
dw  0x0000  ;;end

G1G2G3MaxCount:
dw  25
dw  43
dw  14

G1G2G3EntryAddr:
dw  #MusicT2_1
dw  #MusicT3_1
dw  #MusicT4_1

G1G2G3EntryAddr2:
dw #MusicT2_1
dw #MusicT3_1
dw #MusicT4_2

G1G2G3EntryAddr3:
dw  #MusicT2_2
dw  #MusicT3_1
dw  #MusicT4_1

MusicT2_1:
dw  0x0010
dw  0x000A
dw  0x0030
dw  0x001C
dw  0x0024
dw  0x0006
dw  0x0028
dw  0x0018
dw  0x002C
dw  0x0004
dw  0x0020
dw  0x0026
dw  0x0008
dw  0x002E
dw  0x0022
dw  0x000E
dw  0x0000
dw  0x002A
dw  0x0012
dw  0x000C
dw  0x0032
dw  0x0014
dw  0x001A
dw  0x0002
dw  0x001E
dw  0x0016

MusicT2_2:
dw  0x0076
dw  0x000B
dw  0x0031
dw  0x001D
dw  0x0079
dw  0x0007
dw  0x0029
dw  0x0019
dw  0x002D
dw  0x0074
dw  0x0021
dw  0x0027
dw  0x0009
dw  0x002F
dw  0x0023
dw  0x000F
dw  0x0072
dw  0x002B
dw  0x0013
dw  0x0075
dw  0x0033
dw  0x0077
dw  0x001B
dw  0x0073
dw  0x001F
dw  0x0078

MusicT3_1:
dw  0x001F
dw  0x0077
dw  0x002B
dw  0x003A
dw  0x0045
dw  0x000F
dw  0x001D
dw  0x0035
dw  0x0033
dw  0x0040
dw  0x0009
dw  0x0013
dw  0x0037
dw  0x0031
dw  0x0042
dw  0x0029
dw  0x0039
dw  0x0007
dw  0x0019
dw  0x003D
dw  0x0044
dw  0x0075
dw  0x0074
dw  0x003C
dw  0x0021
dw  0x002D
dw  0x003E
dw  0x002F
dw  0x0034
dw  0x0079
dw  0x003F
dw  0x0078
dw  0x0038
dw  0x0027
dw  0x0073
dw  0x001B
dw  0x0043
dw  0x003B
dw  0x0023
dw  0x000B
dw  0x0076
dw  0x0041
dw  0x0036
dw  0x0072

MusicT4_1:
dw  0x0050
dw  0x0054
dw  0x004E
dw  0x0052
dw  0x004C
dw  0x0050
dw  0x004E
dw  0x0054
dw  0x0050
dw  0x004C
dw  0x0052
dw  0x0054
dw  0x004E
dw  0x0052
dw  0x004C

MusicT4_2:
dw  0x004F
dw  0x0053
dw  0x004D
dw  0x0051
dw  0x004B
dw  0x004F
dw  0x004D
dw  0x0053
dw  0x004F
dw  0x004B
dw  0x0051
dw  0x0053
dw  0x004D
dw  0x0051
dw  0x004B

Game1AskT:
dw  0x008F
dw  0x0059
dw  0x008F
dw  0x0000

Game2AskT:
dw  0x008F
dw  0x0059
;;dw  0x008F
;;dw  0x005F
;;dw  0x008F
;;dw  0x0000

Game3AskT:
dw  0x008F
dw  0x0059
dw  0x008F
;;dw  0x005E
;;dw  0x008F
;;dw  0x0000

MidiWaitT:
dw  0x008F
dw  0x8003
dw  0x0000

G1G2G3WaitEntryAddr:
dw  #Game1AskT
dw  #Game2AskT
dw  #Game3AskT

G1G2G3WaitPlayLength:
dw  0x0003
dw  0x0002
dw  0x0002

G1G2G3RWaitPlayLength:
dw  0x0003
dw  0x0002
dw  0x0003

G1G2G3WaitPlayLengthEntry:
dw  #G1G2G3WaitPlayLength
dw	#G1G2G3RWaitPlayLength

Bubu01208T:
dw  0x0090
dw  0x8004
dw  0x0090
dw  0x0069
dw  0x0000

;;GoodJobT:
;;dw  0x0090
;;dw  0x006E
;;dw  0x0090
;;dw  0x0062
;;dw  0x0000

NextQuT:
dw  0x0090
dw  0x005C
dw  0x0090
dw  0x0000

NextQuT1:
dw  0x0091
dw  0x008F
dw  0x005C
dw  0x0090
dw  0x0000

RightAnswerT:
dw  #RightAnswerT0
dw  #RightAnswerT1
dw  #RightAnswerT2
dw  #RightAnswerT0
dw  #RightAnswerT1

RightAnswerT0:
dw  0x008F
dw  0x8005
dw  0x008F
dw  0x0063
dw  0x0000

RightAnswerT1:
dw  0x008F
dw  0x8005
dw  0x008F
dw  0x0064
dw  0x0000

RightAnswerT2:
dw  0x008F
dw  0x8005
dw  0x008F
dw  0x0065
dw  0x0000

WrongAnswerT:
dw  #WrongAnswerT0
dw  #WrongAnswerT1
dw  #WrongAnswerT2


WrongAnswerT0:
dw  0x8004
dw  0x008F
dw  0x0066
dw  0x0090
dw  0x0000

WrongAnswerT1:
dw  0x8004
dw  0x008F
dw  0x0067
dw  0x0090
dw  0x0000

WrongAnswerT2:
dw  0x8004
dw  0x008F
dw  0x0069
dw  0x0090
dw  0x0000

RemindT3:
dw  0x0090
dw  0x0058
dw  0x0090
dw  0x0000

RemindT1:
dw  0x0090
dw  0x007E
dw  0x0000

G1RemindT:
dw  0x008F
dw  0x0058
dw  0x008F
dw	0x0059
dw  0x0000

G3RemindT:
dw  0x008F
dw  0x0057
dw  0x0090
;;dw  0x0090
dw  0x0000

ThankYouT:
dw  0x0090
dw  0x0062
dw  0x0090
dw  0x0000

AnimalT:
dw  0x008A
dw  0x008B
dw  0x008C
dw  0x008D
dw  0x008E

TestPlayModeT:
dw	0x8006
dw  0x0061
dw	0x0000 ;;;;
dw  0x0072
dw	0x0002
dw	0x0073
dw  0x0004
dw  0x0074
dw  0x0006
dw	0x0007
dw	0x0008
dw	0x0009
dw	0x000A
dw	0x000B
dw	0x000C
dw	0x000D
dw	0x000E
dw	0x000F
dw	0x0010
dw	0x0076
dw	0x0012
dw  0x0013
dw  0x0014
dw	0x0077
dw  0x0016
dw  0x0078
dw	0x0018
dw  0x0019
dw  0x001A
dw  0x001B
dw  0x001C
dw  0x001D
dw  0x001E
dw  0x001F
dw  0x0020
dw	0x0021
dw	0x0022
dw	0x0023
dw	0x0024
dw	0x0079
dw	0x0026
dw  0x0027
dw	0x0028
dw	0x0029
dw	0x002A
dw	0x002B
dw	0x002C
dw	0x002D
dw	0x002E
dw	0x002F
dw	0x0030
dw	0x0031
dw	0x0032
dw	0x0033
dw	0x006D
dw	0x0034
dw	0x0035
dw	0x0036
dw	0x0037
dw	0x0038
dw	0x0039
dw	0x003A
dw	0x003B
dw	0x003C
dw	0x003D
dw	0x003F
dw	0x0041
dw	0x003E
dw	0x0040
dw	0x0045
dw	0x0043
dw	0x0042
dw	0x0044
dw	0x0070
dw	0x004B
dw	0x004C
dw	0x004D
dw	0x004E
dw	0x004F
dw	0x0050
dw	0x0051
dw	0x0052
dw	0x0053
dw	0x0054
dw	0x006F
dw	0x0046
dw	0x0047  
dw 	0x0048  
dw  0x0049  
dw	0x004A 
dw	0x0055
dw	0x0071 
dw	0x0059
dw	0x8003
dw	0x8004
dw	0x0066
dw	0x0067
dw	0x0069
dw	0x0063
dw	0x0064
dw	0x0065
dw	0x005B
dw	0x007E
dw	0x005C
dw	0x006B
dw	0x005F
dw	0x005A
dw	0x006E
dw	0x006A
dw	0x0062
dw	0x0060
dw	0x0056
dw	0x005E
dw	0x006C
dw	0x0057
dw	0x8005
dw	0x8003
dw	0x0000

TestPlayAllT:
dw  0x8006
dw  0x008F
dw  0x0061
dw	0x0000 ;;;;
dw  0x0072
dw	0x0002
dw	0x0073
dw  0x0004
dw  0x0074
dw  0x0006
dw	0x0007
dw	0x0008
dw	0x0009
dw	0x000A
dw	0x000B
dw	0x000C
dw	0x000D
dw	0x000E
dw	0x000F
dw	0x0010
dw	0x0076
dw	0x0012
dw  0x0013
dw  0x0014
dw	0x0077
dw  0x0016
dw  0x0078
dw	0x0018
dw  0x0019
dw  0x001A
dw  0x001B
dw  0x001C
dw  0x001D
dw  0x001E
dw  0x001F
dw  0x0020
dw	0x0021
dw	0x0022
dw	0x0023
dw	0x0024
dw	0x0079
dw	0x0026
dw  0x0027
dw	0x0028
dw	0x0029
dw	0x002A
dw	0x002B
dw	0x002C
dw	0x002D
dw	0x002E
dw	0x002F
dw	0x0030
dw	0x0031
dw	0x0032
dw	0x0033
dw	0x006D
dw	0x0034
dw	0x0035
dw	0x0036
dw	0x0037
dw	0x0038
dw	0x0039
dw	0x003A
dw	0x003B
dw	0x003C
dw	0x003D
dw	0x003F
dw	0x0041
dw	0x003E
dw	0x0040
dw	0x0045
dw	0x0043
dw	0x0042
dw	0x0044
dw	0x0070
dw	0x004B
dw	0x004C
dw	0x004D
dw	0x004E
dw	0x004F
dw	0x0050
dw	0x0051
dw	0x0052
dw	0x0053
dw	0x0054
dw	0x006F
dw	0x0046
dw	0x0047  
dw 	0x0048  
dw  0x0049  
dw	0x004A 
dw	0x0055
dw	0x0071 
dw	0x0059
dw	0x8003
dw  0x008F
dw	0x8004
dw  0x008F
dw	0x0066
dw	0x0067
dw	0x0069
dw	0x0063
dw	0x0064
dw	0x0065
dw	0x005B
dw	0x007E
dw	0x005C
dw	0x006B
dw	0x005F
dw	0x005A
dw	0x006E
dw	0x006A
dw	0x0062
dw	0x0060
dw	0x0056
dw	0x005E
dw	0x006C
dw	0x0057
dw	0x8005
dw	0x008F
dw  0x8003
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0091
dw  0x0000



KeyEntryT:
dw  #KeyT2_1
dw  #KeyT3_1
dw  #KeyT4_1

KeyT2_1:
dw  9  
dw  6
dw  25
dw  15
dw  19
dw  4
dw  21 
dw  13
dw  23
dw  3
dw  17
dw  20
dw  5
dw  24
dw  18
dw  8
dw  1
dw  22
dw  10
dw  7
dw  26
dw  11
dw  14
dw  2
dw  16
dw  12

KeyT3_1:
dw  16
dw  11
dw  22
dw  33
dw  41
dw  8
dw  15
dw  28
dw  26
dw  40
dw  5
dw  10
dw  30
dw  25
dw  43
dw  21
dw  32
dw  4
dw  13
dw  36
dw  44
dw  7
dw  3
dw  35
dw  17
dw  23
dw  39
dw  24
dw  27
dw  19
dw  37
dw  12
dw  31
dw  20
dw  2
dw  14 
dw  42
dw  34
dw  18
dw  6
dw  9
dw  38
dw  29
dw  1

KeyT4_1:
dw  47
dw  49
dw  46
dw  48
dw  45
dw  47
dw  46  
dw  49
dw  47
dw  45
dw  48
dw  49
dw  46 
dw  48
dw  45

KeySW1:
dw  0x0072
dw	0x008F
dw	0x007F
dw	0x0000

KeySW2:
dw	0x0073
dw	0x0000

KeySW3:
dw	0x0074
dw  0x008F
dw	0x0080
dw	0x0000

KeySW4:
dw	0x0007
dw	0x0000

KeySW5:
dw	0x0009
dw	0x008F
dw  0x0081
dw	0x0000

KeySW6:
dw	0x000B
dw	0x0000

KeySW7:
dw	0x000D
dw	0x0000

KeySW8:
dw	0x000F
dw	0x008F
dw	0x0082
dw  0x0000

KeySW9:
dw	0x0076
dw	0x0000

KeySW10:
dw	0x0013
dw	0x0000

KeySW11:
dw	0x0077
dw	0x0000

KeySW12:
dw	0x0078
dw	0x008F
dw	0x0083
dw	0x0000

KeySW13:
dw	0x0019
dw	0x008F
dw	0x0084
dw	0x0084
dw	0x0000

KeySW14:
dw	0x001B
dw	0x0000

KeySW15:
dw	0x001D
dw	0x0000

KeySW16:
dw	0x001F
dw	0x008F
dw	0x0085
dw	0x0000

KeySW17:
dw  0x0021
dw  0x0000

KeySW18:
dw  0x0023
dw	0x0000

KeySW19:
dw	0x0079
dw	0x0000

KeySW20:
dw	0x0027
dw	0x008F
dw	0x0086
dw	0x0000

KeySW21:
dw  0x0029
dw	0x0000

KeySW22:
dw	0x002B
dw  0x008F
dw	0x0087
dw	0x0000

KeySW23:
dw  0x002D
dw	0x0000

KeySW24:
dw	0x002F
dw	0x008F
dw	0x0088
dw	0x0000

KeySW25:
dw	0x0031
dw	0x0000

KeySW26:
dw  0x0033
dw	0x0000

Music1_6T:
dw  0x0000
dw	#KeySW1
dw	#KeySW2
dw	#KeySW3
dw	#KeySW4
dw	#KeySW5
dw	#KeySW6
dw	#KeySW7
dw	#KeySW8
dw	#KeySW9
dw	#KeySW10
dw	#KeySW11
dw  #KeySW12
dw	#KeySW13
dw	#KeySW14
dw	#KeySW15
dw	#KeySW16
dw	#KeySW17
dw	#KeySW18
dw	#KeySW19
dw	#KeySW20
dw	#KeySW21
dw	#KeySW22
dw	#KeySW23
dw	#KeySW24
dw	#KeySW25
dw	#KeySW26

Music1_6_Num_T:
dw	0x0000
dw	0x0003
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0001
dw	0x0001
dw	0x0003
dw	0x0004
dw	0x0001
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0001
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0003
dw	0x0001
dw	0x0001

