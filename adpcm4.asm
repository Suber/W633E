;AdPcmflag   b0-- ch0 b1--ch1,b2--ch2,b3--ch3,b4--ch4,b5--ch5
;adp_ch_index  0 表示用第一通道，1表示第二通道 .........
/* ================================================================= */	
VarRM[0:127]={

adp_ch_index

AdpcmSample
adp_vol
AdPcmflag
adp_unmber
adp_spi_adr0
adp_spi_adr1
adp_data_temp

};
// ********************************************************************	
VarRM[128:511]={



};

;// dx is return converted PCM numbers
;/////Notice: TRD16P201A Serial  should add Filter OverFlow check procedure.
#ifdef _TRD16P201A_
SampelConvert:
		push	i0
		call	RestoreToBuff1
		i0  = 	SUMLH
		cx		= 0x07f;
		MACOP  = 1 ; 	
		nop 	
SampelConvert_lp:
		jfa 		filter_out1	// check filter buffer availed
		jmp		adpcm_dec		
filter_out1:
		ar		= FLTO;		// get filter out, and start delay 4 cycle to get next filter out								
//---------------------- Rounding from 16-bit to 12-bit
  		if an jmp  	rounding_neg
rounding_pos:
  		slc  		ar 
  		if an jmp  	rounding_pos_sat
  		jmp  		rounding_ok
rounding_pos_sat:  
  		ar  		= 0x7fff
  		jmp  		rounding_ok
rounding_neg:
  		slc  		ar 
  		if an jmp  	rounding_neg_ok
  		ar  		= 0x8000
rounding_neg_ok:  
  		ar  		= ar + 0x0008
rounding_ok:  
;-------------------------------------------------------  			
		ar  =  rm[adp_vol]   ;
		mx = ar
		ar		=FLTO
      		MR		=MX*AR
      		bx		= rm[i0]
      		ar		=mr1
      		rm[i0++]		= ar+bx
       		Ar		=Mr2
       		Bx		=Rm[i0]
       		rm[i0++] 		= Ar+Bx+c
       	
		loop		SampelConvert_lp
Sampel_End:		
		call	SaveToBuff1
		pop	i0
		rets
;;//////////////////////////////////////////////////////////////////			
#else
SampelConvert:
		push  i0 
	
		call	RestoreToBuff1
		
		i0  = 	SUMLH
		cx		= 0x07f;
		MACOP  = 1 ; 
		nop 		
SampelConvert_lp:
		jfa 		filter_out1	// check filter buffer availed
		jmp		adpcm_dec		
filter_out1:
		ar  =  rm[adp_vol]   ;
		mx = ar
		ar		=FLTO
      		MR		=MX*AR
      		bx		= rm[i0]
      		ar		=mr1
      		rm[i0++]		= ar+bx
       		Ar		=Mr2
       		Bx		=Rm[i0]
       		rm[i0++] 		= Ar+Bx+c		
		
		loop		SampelConvert_lp
Sampel_End:		
		call	SaveToBuff1
		
		pop  i0 
		rets	
#endif					
;///////////////////////////////////////////////////////////////////////////////////////////////		
adpcm_dec:
		// ************************************************
		//--- Decoder Start
		// ************************************************				
		ar 		= rm[FrameSample1]
		if nz jmp adpcm_next_sampe
	
		// End Check
		// --------Header Sample ---------------
		;---------------------------------
		bx = rm[adp_spi_adr0]
		ar = rm[adp_spi_adr1]
     		pch 	=Send_SPI_address
    		lcall 	Send_SPI_address
    		pch 	= Get_2_BYTE
    		lcall 	Get_2_BYTE
    		ar = rm[adp_spi_adr0]
		ar = ar +2
		rm[adp_spi_adr0] = ar
		ar = rm[adp_spi_adr1]
		ar   += c
		rm[adp_spi_adr1] = ar 
    		ar 	=io[SPI_DAT]   ; 
    		rm[adp_data_temp] =ar						
		;//---------------------------------------
		ah 		= 0xFF;
		sf 		= ar - 0xff;
		if eq jmp adpcm_end
		// silence check
		sf 		= ar - 0xEF;
		if eq jmp adpcm_silence
		
		//--------Header Sample ---------------						
		ar		=rm[adp_data_temp]; pm[p0++]			
		//--------------------------------------		
		ADPHD		= ar		// 16bit header
		;clr		ar.b0		// not silence frame
		ar    =  0	
		rm[ZeroFrame_s] = ar           ;
		jmp 		adpcm_next_sampe
adpcm_silence:	
		;ar		=rm[adp_data_temp]; pm[p0++]		
		;xchg ar
		;ah=0	
		;set		ar.b0;		// silence frame
		ar  = 1 ;
		rm[ZeroFrame_s] = ar;
		// Clear S1, S2, S3, S4
		ar  		= 0;
		ADPPCM	 	= ar;	// s4
		ADPPCM	 	= ar;	// s3
		ADPPCM 		= ar;	// s2
		ADPPCM 		= ar;	// s1
		
		jmp 		adpcm_next_sampe
adpcm_end:				
		p1 =  #bit_clr_flag   ;
   		ar  =  rm[adp_ch_index]
   		p1 = p1 + ar
   		ar  = pm[p1]
   		bx = rm[AdPcmflag]
		ar = ar & bx
		rm[AdPcmflag] = ar
		jmp	Sampel_End
adpcm_next_sampe:		
		ar		= rm[ZeroFrame_s]
		;test 		ar.b0
		jnz 	adpcm_silence_sample
		// normal sample
		// --------Get new Sample ---------------
		jmp Get_One_Sample
Get_One_Sample_End:						
		ADPDAT 		= ar;			// 8 bit-stram								
adpcm_silence_sample:
		ar 		= rm[FrameSample1]
		ar++;
		ax=0x20
		sf 		= ar - ax;
		if nz jmp 	adpcm_exit
		ar 		= 0;
adpcm_exit:		
		rm[FrameSample1] = ar;						
		jmp filter_out1

;///////////////////////////////////////////////////////////////////////////////////////////////
Get_One_Sample:			
		ar		= rm[read_flag] ;
		sf		= ar-4
		if eq jmp Sample
		ar++
		rm[read_flag]	= ar
		ar=rm[ADPCM_Data1]
		jmp SendDelta			
Sample:
		ar		= 1
		rm[read_flag]	= ar
		;-----------------------------
		bx = rm[adp_spi_adr0]
		ar = rm[adp_spi_adr1]
     		pch 	=Send_SPI_address
    		lcall 	Send_SPI_address
    		pch 	= Get_2_BYTE
    		lcall 	Get_2_BYTE
    		ar = rm[adp_spi_adr0]
		ar = ar +2
		rm[adp_spi_adr0] = ar ;
		ar = rm[adp_spi_adr1]
		ar   += c
		rm[adp_spi_adr1] = ar 
    		ar 	=io[SPI_DAT]   ; 
		;ar		= pm[p0++]
		xchg ar
		rm[ADPCM_Data1]	= ar
SendDelta:
		ax		= ar
		slz ar,2
		slz ar,2
		rm[ADPCM_Data1]	= ar
		ar		= 0xf000
		ar		= ar&ax
		xchg ar		
		jmp	Get_One_Sample_End
		
;/////////////////////////////////////////////
play_adpcm_inti:
	dsi
	push	bx
	push	p1
	push	i1
    	
  ar = rm[adp_ch_index] ;
	p1 = #adpcm_filt_tab
	p1 = p1  + ar
	ar = pm[p1]
	i1   = AdpcmFiltBuf
	i1  = i1 + ar
	ar =  0 
	rm[i1++]		=ar;ADPPCM		//;0
	rm[i1++]		=ar		//;1
	rm[i1++]		=ar		//;2
	rm[i1++]		=ar		//;3
	rm[i1++]		=ar;FLTA			//;4
	ar = rm[AdpcmSample]  
	;ar		= 0x1FFF ;---adpcm-采样设定 
	rm[i1++]		=ar			//;fltp
	ar = 0x003f
	rm[i1++]		=ar 	//FLTG			//;6     -----
	ar  = 0
	rm[i1++]		=  ar ;ADPHD			//;7
	ar = 4
	rm[i1++]		=  ar ;read_flag                 ;8
	ar = 0
	rm[i1++]		=  ar  ;FrameSample1           ;9
	RM[I1++]		=  ar  ;ZeroFrame_s           10
	RM[I1++]		=  ar  ;ADPCM_Data1          11
	;-------------------------
	ar = rm[adp_unmber]
    	slz  ar
    	slz  ar
    	ar  = ar + 8 ; ---
    	bx = ar
     	Ar	=0
     	pch 	=Send_SPI_address
    	lcall 	Send_SPI_address
    	pch 	= Get_4_BYTE
    	lcall 	Get_4_BYTE
    	;---
    	Rm[I1++]	=io[SPI_DAT]   ;12 
   	Rm[I1++]	=io[SPI_DAT]   ;13
	;-------------------
	p1 =  #bit_set_flag  
   	ar  =  rm[adp_ch_index]
   	p1 = p1 + ar
   	ar  = pm[p1]
   	bx = rm[AdPcmflag]
	ar = ar | bx
	rm[AdPcmflag] = ar
   	;------///////---
   	pop	i1  ;
   	pop	p1
   	pop	bx
   	eni
	rets 	
		
;/////////////////////////////////////////////////////////
SaveToBuff1:
	push p1
	push i0
	ar = rm[adp_ch_index]  ;
	p1 = #adpcm_filt_tab
	p1 = p1  + ar
	ar = pm[p1]
	i0   = AdpcmFiltBuf
	i0  = i0 + ar
	rm[i0++]		=ADPPCM		//;0
	rm[i0++]		=ADPPCM		//;1
	rm[i0++]		=ADPPCM		//;2
	rm[i0++]		=ADPPCM		//;3
	rm[i0++]		=FLTA			//;4
	rm[i0++]		=FLTP			//;5
	i0++			//FLTG			//;6     -----
	rm[i0++]		=ADPHD			//;7
	ar		= rm[read_flag]	       	 ;8 flag
	rm[i0++]		= ar
	ar		= rm[FrameSample1]	        ;9 adpcm data  每个word 4bit 的个数 
	rm[i0++]		= ar
	ar 	=	rm[ZeroFrame_s]                 ;10
	rm[i0++]=	ar
	
	ar = rm[ADPCM_Data1]
	rm[i0++]=	ar				;11
	
	ar = 	rm[adp_spi_adr0]                        ;12
	rm[i0++]		= ar
	ar = 	rm[adp_spi_adr1]                        ;13
	rm[i0++]		= ar
	pop	i0
	pop 	p1 
	rets
;----------------------------------
RestoreToBuff1:
	push p1
	push	i0
	ar = rm[adp_ch_index]
	p1 = #adpcm_filt_tab
	p1 = p1  + ar
	ar = pm[p1]
	i0   = AdpcmFiltBuf
	i0  = i0 + ar
	ADPPCM		= rm[i0++]		//;0
	ADPPCM		= rm[i0++]		//;1
	ADPPCM		= rm[i0++]		//;2
	ADPPCM		= rm[i0++]		//;3
	FLTA		= rm[i0++]		//;4
	FLTP		= rm[i0++]		//;5
	FLTG		= rm[i0++]		//;6
	ADPHD		= rm[i0++]		//;7
	ar 	        = rm[i0++]               ;8  read_flag
	rm[read_flag]   = ar
	ar 	        = rm[i0++]              ;9  FrameSample1
	rm[FrameSample1]   = ar
	Ar		=FLTO                   
	ar 	        = rm[i0++]          	 ;10  ZeroFrame_s
	rm[ZeroFrame_s] =  ar 
	
	ar 	        = rm[i0++]          	 ;11  ADPCM_Data1
	rm[ADPCM_Data1] = ar
	ar 	        = rm[i0++]              ;12  adpcm spi adr0
	rm[adp_spi_adr0] = ar 
	ar 	        = rm[i0++] 		;13  adpcm spi adr1
	rm[adp_spi_adr1] = ar 
	pop	i0
	pop  p1
 	rets	
adpcm_filt_tab: ;6ch  adpcm buf
	dw	0,14,28,42,56,70,84;
;////////////////////////////////////////////////////
Adpcm6chPlay:
	ar = 5  ;6ch adpcm
loop_check_adp_ch:	
	rm[adp_ch_index] = AR 
	p1 =  #bit_set_flag  
   	ar  =  rm[adp_ch_index]
   	p1 = p1 + ar
   	ar  = pm[p1]
   	bx = rm[AdPcmflag]
	ar = ar & bx
	jeq	Check_adpcm_next_ch
	pch   = SampelConvert
	lcall	SampelConvert
Check_adpcm_next_ch:	
	ar = rm[adp_ch_index]
	ar --
	test  ar.b15
	jeq	loop_check_adp_ch
	rets 
;//////////////////////////////////////////////////////
bit_set_flag:
		DW	0x1
		DW	0x2
		DW	0x4
		DW	0x8
		DW	0x10
		DW	0x20
		DW	0x40
		DW	0x80
		DW	0x100
		DW	0x200
		DW	0x400
		DW	0x800
		DW	0x1000
		DW	0x2000
		DW	0x4000
		DW	0x8000
bit_clr_flag:
		DW	0xfffe
		DW	0xfffd
		DW	0xfffb
		DW	0xfff7
		DW	0xffef
		DW	0xffdf
		DW	0xffbf
		DW	0xff7f
		DW	0xfeff
		DW	0xfdff
		DW	0xfbff
		DW	0xf7ff
		DW	0xefff
		DW	0xdfff
		DW	0xbfff
		DW	0x7fff
;//////////////////////////////////////////////