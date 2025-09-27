//*********************************************************
//
//  hh_generator.c 
//  --------------------------------------------
//  Program to collect data from local SDRAM using proc 1, 
//  transfer via link to proc 2, also xfer via MMS to proc 3.
//  This program also gives examples of timing diagnostics and
//  simulated input pacing using interrupts, as well as the use
//  16-bit space for computation.
//
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
//  Copyright (c) 2001
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0   03/13/01  rpc	  Creation
//
//*********************************************************
#include <def21160.h>
#include <21060.h>
#include <stdio.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"
#include "extint0.h"

#define INIT_SDRAM           1                     // set flag to init SDRAM with incrementing pattern
#define DIAGNOSTICS          0                     // set flag for diagnostics
#define SIXTEEN_BIT          0                     // set flag to use 16-bit space

#define RAW_PKT              1024                  // raw frame data=1024 3-byte pixels (in each 4-bytes)
#define LINK_PKT             RAW_PKT/4             // each link sends 1/4 of raw data
#define NPKTS                4*1024                // 4k frame packets for this test
#define FILE_NWORDS          RAW_PKT*NPKTS         // total number of file (32-bit) words
#define FILE_SDRAM_ADDR      0x800000              // addr of beginning of SDRAM
#define MMS_FACTOR           0x100000              // multiplier with proc ID
#define HH_PROC3_ID          3                     // Processor 3 is the HH for some process
#define BLOCK1_OFFSET        0x58000               // "safe" area in DM of HH_PROC3
#define MMS_POINTER          (HH_PROC3_ID * MMS_FACTOR) + BLOCK1_OFFSET

#if DIAGNOSTICS
// defines for diagnostic metrics

typedef struct
{
    volatile int timer_intr;
	volatile int chan10_count;
	volatile int chan11_count;
	volatile int link2_count;
	volatile int link3_count;
}status_t;

status_t stat[25];
volatile int pkt_cnt = 0;

void DMAC10_complete(int sig)
{
    stat[pkt_cnt].chan10_count = timer_on();
}

void DMAC11_complete(int sig)
{
    stat[pkt_cnt].chan11_count = timer_on();
}

void link2_complete(int sig)
{
    stat[pkt_cnt].link2_count = timer_on();
}

void link3_complete(int sig)
{
    stat[pkt_cnt].link3_count = timer_on();
}

#endif

// Globals
int done = 0;
int offset = 0;
int sbuf = 0;
int lbuf = 0;
int ticks;
int *sdram_input_file = (int *)FILE_SDRAM_ADDR;    // pointer to SDRAM raw input
unsigned int *ptr;                                 // pointer used for the MMS xfers
volatile int tx_data = 0;                          // timer interrupt flag
int in_data[2][RAW_PKT];                           // ping-pong input data buffer

#if SIXTEEN_BIT
int out_data[2][RAW_PKT];                          // ping-pong output data buffer
int outp0 = (int)out_data[0];
int outp1 = (int)out_data[1];
volatile unsigned int *p16;
volatile unsigned int *p16_0;
volatile unsigned int *p16_1;
#endif

int calc_timer_ticks(int khz)
{
    return(80000000/(khz*1000));
}

void timer_interrupt(int sig)
{
#if DIAGNOSTICS
	if(pkt_cnt < 25) pkt_cnt++;
	stat[pkt_cnt].timer_intr = timer_on();
#endif
	tx_data = 1;
}

//*********************************************************
//
//
//
//*********************************************************
void main(void)
{
    int i;

    init_Hammerhead();

#if SIXTEEN_BIT
	// pointers to 16-bit space init
	outp0 *= 2;
	outp1 *= 2;
	p16_0 = (volatile unsigned int *)(outp0); // initialize ptr to out_data[0] in 16-bit space
	p16_1 = (volatile unsigned int *)(outp1); // initialize ptr to out_data[1] in 16-bit space
	p16 = p16_0;
#endif

#if INIT_SDRAM
    ptr = (unsigned int *)sdram_input_file;
    for(i = 0; i < FILE_NWORDS; i++)
	{
	    *ptr++ = i;
	}
#endif

    // Set up a timer interrupt to pace simulated input
	timer_off();
	ticks = calc_timer_ticks(16); // calc cycles needed to simulate a N kHz frame rate
	timer_set(ticks, ticks);
	interrupt(SIG_TMZ0, timer_interrupt);

#if DIAGNOSTICS
	interrupt(SIG_LP2I, link2_complete);
	interrupt(SIG_LP3I, link3_complete);
	interrupt(SIG_EP0I, DMAC10_complete);
	interrupt(SIG_EP1I, DMAC11_complete);
#endif
	timer_on();

	extmem_to_intmem((int *)sdram_input_file + offset,    // Source buffer
          	         (int *)in_data[sbuf],                // Destination buffer
	       	         RAW_PKT,                             // internal word count
	       	         RAW_PKT,                             // external word count
					 1,                                   // External Increment (EM)
        	  		 10,                                  // DMA Channel
                     DMAC_DEN | DMAC_MASTER | DMAC_BURST, // flags for this xfer
             		 0,            	                      // Wait for DMA to complete?
					 0);                                  // Use timer?

    sbuf = 1;
	offset += RAW_PKT;      // word offset into SDRAM
	
	// wait for timer flag
	while(tx_data == 0)
	{
    }

	// reset flag
    tx_data = 0;

    // SDRAM is already loaded with test data from file; start main loop
	do
	{
		// Transfer data from external to internal memory.
		extmem_to_intmem((int *)sdram_input_file + offset,    // Source pointer
          	             (int *)in_data[sbuf],                // Destination buffer
	       	             RAW_PKT,                             // internal word count
	       	             RAW_PKT,                             // external word count
						 1,                                   // External Increment (EM)
            	  		 10,                                  // DMA Channel
                         DMAC_DEN | DMAC_MASTER | DMAC_BURST, // flags for this xfer
                 		 0,            	                      // Wait for DMA to complete?
						 0);                                  // Use timer?

        // Do some computation here
#if SIXTEEN_BIT
        for(i = 0; i < RAW_PKT; i++)
		{
		    p16[i] = (in_data[lbuf][i] & 0xff) << 2;  // copy LS byte into 16-bit space, shift by 2
		}
#endif
		// Send 1/2 raw data to HH_PROC2
        link_dma_noint_xmt((int *)&in_data[lbuf][0], // source buffer
		             LINK_PKT,          // buffer size
					 2,                 // link port
					 2,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function

 		link_dma_noint_xmt((int *)&in_data[lbuf][LINK_PKT], // source buffer
		             LINK_PKT,          // buffer size
					 3,                 // link port
					 3,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function

		// Transfer data from internal mem to MMS on HH_PROC3 (double buffered)
		ptr = (lbuf) ? (unsigned int *)MMS_POINTER + RAW_PKT : (unsigned int *)MMS_POINTER;
		intmem_to_extmem((int *)in_data[lbuf],                 // Source pointer
		                 (int *)ptr,                           // Dest pointer
	       	             RAW_PKT,                              // internal word count
	       	             RAW_PKT,                              // external word count
						 1,                                    // External Increment (EM)
            	  		 11,                                   // DMA Channel
                         DMAC_DEN | DMAC_TRANS | DMAC_MASTER,  // flags for this xfer
                 		 0,            	                       // Wait for DMA to complete?
						 0);                                   // Use timer?

		// update buffer managers
		lbuf = sbuf;
		sbuf = (sbuf) ? 0 : 1;	
#if SIXTEEN_BIT
		p16  = (sbuf) ? p16_0 : p16_1;
#endif
	    offset += RAW_PKT;      // word offset into SDRAM

		// wait for timer flag
		while(tx_data == 0)
		{
	    }

		// reset flag
        tx_data = 0;

	}while(offset < FILE_NWORDS);


	// Ship out last buffer of data
    link_dma_noint_xmt((int *)&in_data[lbuf][0], // source buffer
	             LINK_PKT,          // buffer size
				 2,                 // link port
				 2,                 // link buffer
				 1,                 // link speed
				 8,                 // link bit width
				 32,                // data element bit width
				 1,                 // data stride
				 0,                 // wait for completion?
				 NULL);             // no abort function

	link_dma_noint_xmt((int *)&in_data[lbuf][LINK_PKT], // source buffer
	             LINK_PKT,          // buffer size
				 3,                 // link port
				 3,                 // link buffer
				 1,                 // link speed
				 8,                 // link bit width
				 32,                // data element bit width
				 1,                 // data stride
				 0,                 // wait for completion?
				 NULL);             // no abort function

	// Transfer data from internal to MMS on HH_PROC3 (double buffered)
	ptr = (lbuf) ? (unsigned int *)MMS_POINTER + RAW_PKT : (unsigned int *)MMS_POINTER;
	intmem_to_extmem((int *)in_data[lbuf],                 // Source pointer
	                 (int *)ptr,                           // Dest pointer
       	             RAW_PKT,                              // internal word count
       	             RAW_PKT,                              // external word count
					 1,                                    // External Increment (EM)
        	  		 11,                                   // DMA Channel
                     DMAC_DEN | DMAC_TRANS | DMAC_MASTER,  // flags for this xfer
             		 0,            	                       // Wait for DMA to complete?
					 0);                                   // Use timer?
	timer_off();
	done = 1;
}

//*********************************************************
// End of file hh_generator.c
//*********************************************************
