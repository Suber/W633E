// ***************************************************************************************
init_intVectTable:
    // eable int-vector table access
    set   io[STATUS].b13
    cx    = 7;
    ar    = 0;
    P0  = # INTVB_ENTRY_TABLE
    // Int7~1
init_intVectTable_lp:
    AR  =PM[P0++]
    io[intVect]   = ar;
    loop    init_intVectTable_lp

    // Dis-int-vector table access
    clr   io[STATUS].b13
    rets
INTVB_ENTRY_TABLE:
DW #INTVB7_ENTRY,#INTVB6_ENTRY,#INTVB5_ENTRY,#INTVB4_ENTRY,#INTVB3_ENTRY,#INTVB2_ENTRY,#INTVB1_ENTRY,#INTVB0_ENTRY