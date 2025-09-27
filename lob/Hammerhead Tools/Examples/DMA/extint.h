//**********************************************************
//
//  DMA transfers between internal and external SHARC memory.
//  ---------------------------------------------------------
//  extint.h : Perform DMA memory transfers between internal and external memory.
//
//  PROVIDED BY:
//  ------------
//  BittWare Research Systems, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph: 603-226-0404
//  Fax: 603-226-6667
//  WWW: www.bittware.com
//  E-mail: support@bittware.com
//
//  Copyright 2001, BittWare, Inc.
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//
//    Ver.  Dates     Changes                                
//    ----  --------  ---------------------------------------
//
//**********************************************************

#ifndef FALSE
#define FALSE   0
#define TRUE    (!FALSE)
#endif

#ifndef SetIOP
#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)
#endif

//**********************************************************

// The following are the dmac settings for the calls, made globals so they can be changed during testing

extern int dmac_ext_to_int;
extern int dmac_int_to_ext;

int extmem_to_intmem( int *extsrc, int *intdest, int num_to_copy, int dma_channel, int wait );
int intmem_to_extmem( int *intsrc, int *extdest, int num_to_copy, int dma_channel, int wait );
int intmem_to_epb( int *intsrc, int num_to_copy, int dma_channel, int wait );

//**********************************************************
 
// End of file extint.h
 
//**********************************************************
