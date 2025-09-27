//**********************************************************
//
//  DMA transfers between internal and external SHARC memory.
//  ---------------------------------------------------------
//  extint.h : Support for DMA transfers between internal and external memory.
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
//    Ver.  Dates     Changes                                
//    ----  --------  ---------------------------------------
//
//**********************************************************

#ifndef FALSE
#define FALSE   0
#define TRUE    (!FALSE)
#endif

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

// DMAC bit definitions
#define DMAC_DEN          0x00000001      // DMA enable 
#define DMAC_CHEN         0x00000002      // Chaining enable 
#define DMAC_TRANS        0x00000004      // Enable DMAC transmit 
#define DMAC_32EXT_48INT  0x000000c0      // Pack 32-bit external to 48-bit internal
#define DMAC_MASTER       0x00000400      // Enable bus mastering 
#define DMAC_FLUSH        0x00004000      // flush port buffer 
#define DMAC_BURST        0x00080000      // Burst enable 
#define CP_PCI            0x80000         // Program-Controlled Interrupts bit
#define CP_MAF            0x1ffff         // Valid memory address field bits

//**********************************************************

// The following are the dmac settings for the calls, made globals so they can be changed during testing

extern int dmac_ext_to_int;
extern int dmac_int_to_ext;

int extmem_to_intmem(int *extsrc, int *intdest, int int_count, int ext_count, int incr, int dma_channel, 
                     int flags, int wait, int use_timer);
int intmem_to_extmem(int *intsrc, int *extdest, int int_count, int ext_count, int incr, int dma_channel,
                     int flags, int wait, int use_timer);
int intmem_to_epb(int *intsrc, int num_to_copy, int dma_channel, int wait );

//**********************************************************
 
// End of file extint.h
 
//**********************************************************
