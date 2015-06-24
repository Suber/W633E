/*---------------------------------------------------------------------------------------------------------------------------
SPI ��ʼ��
---------------------------------------------------------------------------------------------------------------------------*/
SPI_Initial:
    	CALL  	SET_SPI_CS_ctrl
    	Set     	io[STATUS].b8 		//; Enable SPI Control
    	CALL  	SET_SPI_CS
    	ar    	= 0x11			;
    	ah    	= speed			; // speed
   	 io[SPI_CTL]   = ar			; // send_data = 1;
    	clr     io[SPI_CTL].b4     // send_data = 0;
    	pch     =Check_Tran_OK
    	lcall     Check_Tran_OK
    	rets
/*---------------------------------------------------------------------------------------------------------------------------
SPI   �趨CsΪ�����
---------------------------------------------------------------------------------------------------------------------------*/
SET_SPI_CS_ctrl:
	#ifdef SPI_TYPE2
  	set     io[ioc_pD].b4 // cs=1
	#endif
	#ifdef SPI_TYPE1
  	set     io[ioc_pA].b3// cs=1
	#endif
	#ifdef TRD16P201A_SPI
  	set     io[ioc_pD].b10 // cs=1
	#endif
  	rets
/*---------------------------------------------------------------------------------------------------------------------------
SPI   �趨CsΪ�ߵ�ƽ
---------------------------------------------------------------------------------------------------------------------------*/
SET_SPI_CS:
	#ifdef SPI_TYPE2
    	set     io[Portd].b4 // cs=1
    	set   io[SPI_CTL].b11
	#endif
	#ifdef SPI_TYPE1
    	set     io[PortA].b3 // cs=1
    	set   io[SPI_CTL].b11
	#endif
	#ifdef TRD16P201A_SPI
    	set     io[PortD].b10 // cs=1
	#endif
  	rets
/*---------------------------------------------------------------------------------------------------------------------------
SPI   �趨CsΪ�͵�ƽ
---------------------------------------------------------------------------------------------------------------------------*/
CLR_SPI_CS:
	#ifdef SPI_TYPE2
    	clr     io[Portd].b4 // cs=0
    	clr   io[SPI_CTL].b11
	#endif
	#ifdef SPI_TYPE1
    	clr     io[PortA].b3 // cs=0
    	clr   io[SPI_CTL].b11
	#endif
	#ifdef TRD16P201A_SPI
    	clr     io[PortD].b10 // cs=0
	#endif
  	rets
/*---------------------------------------------------------------------------------------------------------------------------
SPI   �鿴CS��״̬
---------------------------------------------------------------------------------------------------------------------------*/
TEST_SPI_CS:
	#ifdef SPI_TYPE2
    	test    io[Portd].b4 // cs=1
	#endif
	#ifdef SPI_TYPE1
    	test    io[PortA].b3 // cs=1
	#endif
	#ifdef TRD16P201A_SPI
    	test    io[PortD].b10 // cs=1
	#endif
  	rets
/*---------------------------------------------------------------------------------------------------------------------------
��flash��ȡ4��byte����
---------------------------------------------------------------------------------------------------------------------------*/
Get_4_BYTE_nowait:
		ar 	= 0x24;
Get_4_BYTE1_nowait:
		ah 	= SPI_Speed; // speed
		io[SPI_CTL] 	= ar;	// receive_data = 1;
		clr 	io[SPI_CTL].b5     	// receive_data = 0;
		rets
/*---------------------------------------------------------------------------------------------------------------------------
��flash��ȡ1��byte����
---------------------------------------------------------------------------------------------------------------------------*/
Get_1_BYTE_nowait:
		ar 	= 0x21;
		jmp	Get_4_BYTE1_nowait
/*---------------------------------------------------------------------------------------------------------------------------
��flash��ȡ2��byte����
---------------------------------------------------------------------------------------------------------------------------*/
Get_2_BYTE_nowait:
		ar 	= 0x22;
		jmp	Get_4_BYTE1_nowait
/*---------------------------------------------------------------------------------------------------------------------------
��flash��ȡ3��byte����
---------------------------------------------------------------------------------------------------------------------------*/
Get_3_BYTE_nowait:
		ar 	= 0x23;
		jmp	Get_4_BYTE1_nowait
/*---------------------------------------------------------------------------------------------------------------------------
��flash��ȡ8��byte����
---------------------------------------------------------------------------------------------------------------------------*/
Get_8_BYTE_nowait:
		ar 	= 0x28;
		jmp	Get_4_BYTE1_nowait
		
/*--------------------------------------------------------------------------------------------------------------------
��flashȡ���Ĵ���
ʹ�õ��Ĵ��� Ar  P1
--------------------------------------------------------------------------------------------------------------------*/
Read_onebyte:
		set 	io[SPI_CTL].B6
		clr 	io[SPI_CTL].b6

		AR	=io[SPI_DAT];
		set 	io[SPI_CTL].b5
		clr 	io[SPI_CTL].b5
		AH	=0
		rm[DMD]=ar
		P1++
		RETS

Get_4_BYTE:
		ar 	= 0x24;
Get_4_BYTE1:
		ah 	= SPI_Speed; // speed
		io[SPI_CTL] 	= ar;	// receive_data = 1;
		clr 	io[SPI_CTL].b5     	// receive_data = 0;
		jmp	Check_Tran_OK

Get_1_BYTE:
		ar 	= 0x21;
		jmp	Get_4_BYTE1

Get_2_BYTE:
		ar 	= 0x22;
		jmp	Get_4_BYTE1
Get_8_BYTE:
		ar 	= 0x28;
		jmp	Get_4_BYTE1
Get_3_BYTE:
		ar 	= 0x23;
		jmp	Get_4_BYTE1
		
/*--------------------------------------------------------------------------------------------------------------------
�ȴ����ݴ������
--------------------------------------------------------------------------------------------------------------------*/
Check_Tran_OK:
		test 		io[SPI_CTL].b7
		Jzr		Check_Tran_OK//JEQ		Check_Tran_OK


		set 		io[SPI_CTL].b6     // tran_data_ok = 1
		clr 		io[SPI_CTL].b6     // tran_data_ok = 0
		rets
/*--------------------------------------------------------------------------------------------------------------------
����Ҫ��ȡ��λ�ã�
�����ַ  BX  AX ��L  H)
--------------------------------------------------------------------------------------------------------------------*/
Send_SPI_address:
		PCH	=	TEST_SPI_CS
		LCALL	TEST_SPI_CS
		JNZ		Send_SPI_address1
		set 		io[SPI_CTL].b6     // tran_data_ok = 1
		clr 		io[SPI_CTL].b6     // tran_data_ok = 0
		PCH	=	SET_SPI_CS
		LCALL	SET_SPI_CS
Send_SPI_address1:
		PCH	=	CLR_SPI_CS
		LCALL	CLR_SPI_CS
	
		ah		=0x03
		io[SPI_DAT]	= xchg	ar;		
		ar		=bx
		io[SPI_DAT] 	= xchg ar;
		ar 		= 0x14;
		ah 		= SPI_Speed; // speed
		io[SPI_CTL] 	= ar;	// send_data = 1;
		clr 		io[SPI_CTL].b4     // send_data = 0;
		call  		Check_Tran_OK
		rets
/*---------------------------------------------------------------------------------------------------------------------------
����Ӧ�ú�ǰ����һ����
Ar Bx�ǵ�ַ BX�ǵ�λ AR �Ǹ�λ
---------------------------------------------------------------------------------------------------------------------------*/
Send_SPI_address_noWait:
		PCH		=TEST_SPI_CS
		LCALL		TEST_SPI_CS
		JNZ		Send_SPI_address_noWait1		;���CS Ϊ�߽�����һ��
		set 		io[SPI_CTL].b6    
		clr 		io[SPI_CTL].b6    
		PCH		=SET_SPI_CS
		LCALL		SET_SPI_CS
Send_SPI_address_noWait1:
		PCH		=SET_SPI_CS
		LCALL		SET_SPI_CS

		PCH		=CLR_SPI_CS
		LCALL		CLR_SPI_CS
		
		ah		=0x03
		io[SPI_DAT]	= xchg	ar;
		ar		=bx
		io[SPI_DAT] 	= xchg ar;

		ar 		= 0x14;
		ah 		= SPI_Speed; // speed
		io[SPI_CTL] 	= ar;	// send_data = 1;
		clr 		io[SPI_CTL].b4     // send_data = 0;
		rets

//------------------------------------------------------------              
cs_reset: 
		set		io[SPI_CTL].b6
		clr		io[SPI_CTL].b6
		Set		io[porta].b3
		Clr		io[porta].b3
		rets
		
//-------------------------------------------------------------
Deep_powerdown_cmd:
		//COMMAND B9H WRITE ENABLE
		Call		cs_reset      
		
		ar          	= 0x00B9
		io[SPI_DAT]	= ar 
		  
		ar          	= 0x11
		ah          	= 0x10
		io[SPI_CTL]	=ar 
		
		clr         	io[SPI_CTL].b4
		call        	Check_Tran_OK
		
		;SET_SPI_CS
		set 		io[Porta].b3 // cs=1
		
		rets
		
//-------------------------------------------------------------
Rel_powerdown_cmd:
		//COMMAND ABH WRITE ENABLE
		Call		cs_reset      
		
		ar          	= 0x00ab
		io[SPI_DAT]	=ar 
		
		ar          	= 0x11
		ah         	= 0x10
		io[SPI_CTL]	=ar 
		
		clr         	io[SPI_CTL].b4
		call        	Check_Tran_OK
		
		;SET_SPI_CS
		set 	   	io[Porta].b3 // cs=1
		rets

		
wait_flash_ready:      
		io[ClrWDT]	= ar;			// Clear Watch Dog          
		call		read_status_cmd
		test		ar.b0
		if nz 		jmp  wait_flash_ready  ;=1,busy,=0,ready
		rets 
		
//-------------------------------------------------------------
read_status_cmd:                
		//COMMAND 05H READ STATUS
		Call		cs_reset         
		
		ar          	= 0x05
		io[SPI_DAT]	= ar 
		
		ar          	= 0x11
		ah          	= 0x10
		io[SPI_CTL]	=ar 
		
		clr         	io[SPI_CTL].b4
		call        	check_tran_ok
		
		// read ready or busy
		ar          	= 0x21
		ah          	= 0x50
		io[SPI_CTL]	=ar 
		
		clr         	io[SPI_CTL].b5
		call        	check_tran_ok
		
		ar          	=io[SPI_DAT]
		
		;SET_SPI_CS
		set 		io[Porta].b3 // cs=1 
		
		rets
		  