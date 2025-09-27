/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  hh1_generator.c 
//  --------------------------------------------
//  Program to collect data from local SDRAM using proc 1, 
//  transfer via link to proc 2 and 4, also xfer via MMS to proc 3.
//  This program also gives examples of timing diagnostics and
//  simulated input pacing using interrupts, as well as the use
//  16-bit space for computation.
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

#include <def21160.h>
#include <21160.h>
#include <stdio.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"
#include "extint0.h"
asm("#include <def21160.h>");

#define INIT_SDRAM           0                     // set flag to init SDRAM with incrementing pattern
#define LINE_SIZE            1024                  // line data = 1024 4-byte pixels (2048 2-bytes pixels)
#define LINE_PKT             LINE_SIZE/4           // each processor recieves 1/4 of line data (packet)
#define FRAME_SIZE           128  				   // 128 lines per frame for this test
#define TOTAL_PIXELS         LINE_SIZE*FRAME_SIZE  // total number of pixels (32-bit words)
#define NUM_FRAMES			 4					   // 4 frames
#define FREQ 				 300				   // Hz frame rate

#define FILE_SDRAM1      0x800000              // addr of beginning of SDRAM
#define FILE_SDRAM2      0x1000000             // addr of beginning of SDRAM

#define MMS_FACTOR           0x100000              // multiplier with proc ID
#define HH_PROC3_ID          3                     // Processor 3 is the HH for some process
#define BLOCK1_OFFSET        0x58000               // "safe" area in DM of HH_PROC3
#define MMS_POINTER          (HH_PROC3_ID * MMS_FACTOR) + BLOCK1_OFFSET


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines for diagnostic metrics
/////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct
{
    volatile int timer_intr;
	volatile int link4_count;	
}status_t;
status_t stat[32];
volatile int pkt_cnt = 0;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Globals Variables
/////////////////////////////////////////////////////////////////////////////////////////////////////////

int Line_Freq  = FREQ;
int Num_Frames = NUM_FRAMES;
int Frame_Size = FRAME_SIZE;
int Total_Pixels = TOTAL_PIXELS;

int done = 0;			// host pc flag
int input = 0;			// host pc flag
int output= 0;
int frame_cnt = 0;		// host pc flag

int sbuf = 0;								// next index in in_data (last index in fft_data)
int lbuf = 0;								// actual index of in_data and fft_data
int rxbuf = 0;								// index of rcvd_P2 , rcvd_P4 and rcvd_P3
int ticks;
int *sdram1 = (int *)FILE_SDRAM1;    // pointer to SDRAM raw input
int *sdram2 = (int *)FILE_SDRAM2;    // pointer to SDRAM raw input
int offset1, offset2;
unsigned int *ptr;                                 // pointer used for the MMS xfers 0x58000

volatile int tx_data = 0;                          // timer interrupt flag
volatile int rx_data = 0;                          // link4 interrupt flag (bypass cable)
int rxpkts, txpkts = 0;

int in_data[2][LINE_SIZE];                         // ping-pong input data buffer
int out_data[2][LINE_SIZE];				           // ping-pong output data buffer
int fft_data[2][LINE_PKT];                         // ping-pong processing buffer
int rcvd_P3[4][LINE_PKT];                          // 4-deep rx data buffer
int rcvd_P2[4][LINE_PKT];                          // 4-deep rx data buffer
int rcvd_P4[4][LINE_PKT];                          // 4-deep rx data buffer


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interrupt Service Rutines 
/////////////////////////////////////////////////////////////////////////////////////////////////////////

int calc_timer_ticks(int hz)
{
    return(80000000/hz);
}

void timer_interrupt(int sig)
{
		asm("BIT TGL flags FLG2;");		// Toggle Line-Trigger
	 	if(pkt_cnt < 32) pkt_cnt++;
		stat[pkt_cnt].timer_intr = timer_on();

	tx_data = 1;
}

void link4_handler(int sig)
{
	stat[pkt_cnt].link4_count = timer_on();
	rx_data = 1;
}

void DMAC11_complete(int sig)
{
	asm("bit clr flags FLG0;");		// FLAG0 connected to HH3-IRQ0 via SharcFIN
									// (edge-sensitive, active on low level)
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Transmission Functions
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void LinkTX_P2(int lbuf)
{
	// Send in_data[lbuf][1*LINE_PKT] to HH_PROC2
	link_dma_noint_xmt((int *)&in_data[lbuf][LINE_PKT], // source buffer
		             LINE_PKT,          // buffer size
					 2,                 // link port
					 2,                 // link buffer
					 2,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function
}

void LinkTX_P4(int lbuf)
{
	// Send in_data[lbuf][3*LINE_PKT] to HH_PROC4
	link_dma_noint_xmt((int *)&in_data[lbuf][3*LINE_PKT], // source buffer
		             LINE_PKT,          // buffer size
					 1,                 // link port
					 1,                 // link buffer
					 2,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function
}

void LinkTX_P3(int lbuf)
{
	// Deassert the flag (edge-sensitive, active on low level)
	asm("bit set flags FLG0;");

	// Send in_data[lbuf][2*LINE_PKT] to MMS on HH_PROC3 (double buffered)
	ptr = (lbuf) ? (unsigned int *)MMS_POINTER + LINE_PKT : (unsigned int *)MMS_POINTER;
	intmem_to_extmem((int *)&in_data[lbuf][2*LINE_PKT],     // Source pointer
	                 (int *)ptr,                           // Dest pointer
	   	             LINE_PKT,                             // internal word count
	   	             LINE_PKT,                             // external word count
					 1,                                    // External Increment (EM)
           	  		 11,                                   // DMA Channel
                     DMAC_DEN | DMAC_TRANS | DMAC_MASTER,  // flags for this xfer
                     0,            	                       // Wait for DMA to complete?
					 0);                                   // Use timer?
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Reception Functions
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void LinkRX_P4(int rxbuf)
{
	// Receive data from HH_PROC4 to rcvd_P4[rxbuf][0]
	link_dma_noint_rcv((int *)&rcvd_P4[rxbuf][0], // source buffer
		             LINE_PKT,          // buffer size
					 5,                 // link port
					 5,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function
}

void LinkRX_P3(int rxbuf)
{
	// Receive data from HH_PROC3 to rcvd_P3[rxbuf][0]
	link_dma_noint_rcv((int *)&rcvd_P3[rxbuf][0], // source buffer
		             LINE_PKT,          // buffer size
					 4,                 // link port
					 4,                 // link buffer
					 2,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function
}

void LinkRX_P2(int rxbuf)
{
	// Receive data from HH_PROC2 to rcvd_P2[rxbuf][0]
	link_dma_noint_rcv((int *)&rcvd_P2[rxbuf][0], // source buffer
		             LINE_PKT,          // buffer size
					 3,                 // link port
					 3,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function
}

////////////////////////////////////////////////////////////////////////////
// fft: in_data[lbuf][0*LINE_PKT] --> fft_data[lbuf][0]
////////////////////////////////////////////////////////////////////////////

void Processing(int lbuf)
{
	int i, j;

	for (i=0; i< LINE_PKT; i++)
		fft_data[lbuf][i] = in_data[lbuf][i];
}


////////////////////////////////////////////////////////////////////////////
// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P3[sbuf] + rcvd_P4[rxbuf]
////////////////////////////////////////////////////////////////////////////

void ComposeLine(int sbuf, int rxbuf)
{
	int i, j=0;

	for (i=0; i< LINE_PKT; i++)
	{
		out_data[sbuf][j++] = fft_data[sbuf][i];
	}

	for (i=0; i< LINE_PKT; i++)
	{
		out_data[sbuf][j++] = rcvd_P2[rxbuf][i];
	}

	for (i=0; i< LINE_PKT; i++)
	{
		out_data[sbuf][j++] = rcvd_P3[rxbuf][i];
	}
	
	for (i=0; i< LINE_PKT; i++)
	{
		out_data[sbuf][j++] = rcvd_P4[rxbuf][i];
	}

}


//*************************************************************************************************
//
//											M	A	I	N
//
//*************************************************************************************************
void main(void)
{
    int i, j;

    init_Hammerhead();
	Total_Pixels = LINE_SIZE * Frame_Size;
	
#if INIT_SDRAM
    ptr = (unsigned int *)sdram1;
    for(i = 0; i < TOTAL_PIXELS; i++)
	{
	    *ptr++ = i;
	}
#endif

	// Init the flags as outputs
	asm("bit set mode2 FLG0O;");
	asm("bit set mode2 FLG2O;");
	asm("bit set mode2 FLG3O;");
	
	// Init the statistic array
	for (pkt_cnt=0; pkt_cnt<32; pkt_cnt++)
	{
		stat[pkt_cnt++].timer_intr  = 0;
		stat[pkt_cnt++].link4_count	= 0;
	}

	// Set up a timer interrupt to pace simulated input
	timer_off();
	ticks = calc_timer_ticks(Line_Freq);		// calc cycles needed to simulate a N kHz frame rate
	timer_set(ticks, ticks);
	interrupt(SIG_TMZ0, timer_interrupt);
	interrupt(SIG_EP1I, DMAC11_complete);

//for (frame_cnt = 0; frame_cnt < NUM_FRAMES; frame_cnt++ )
do
{
	pkt_cnt = 0;
	offset1 = 0;		
	offset2 = 0;		
	rxbuf = 0;
	sbuf = 0;		// next index in in_data (last index in fft_data)
	lbuf = 0;		// actual index of in_data and fft_data

	while (!input)
	{
		idle;
	}
	input = 0;
	timer_on();

/////////////////////////////////////////////////////////////////////////////////////
// 1st Iteration (sbuf = 0)
/////////////////////////////////////////////////////////////////////////////////////
	extmem_to_intmem((int *)sdram1 + offset1,    // Source buffer
          	         (int *)in_data[sbuf],                // Destination buffer
	       	         LINE_SIZE,                           // internal word count
	       	         LINE_SIZE,                           // external word count
					 1,                                   // External Increment (EM)
        	  		 10,                                  // DMA Channel
                     DMAC_DEN | DMAC_MASTER | DMAC_BURST, // flags for this xfer
             		 0,            	                      // Wait for DMA to complete?
					 0);                                  // Use timer?

    sbuf = 1;
	offset1 += LINE_SIZE;    // word offset into SDRAM
	
	while(tx_data == 0); 	// wait for timer flag
    tx_data = 0;

/////////////////////////////////////////////////////////////////////////////////////
// 2nd Iteration (sbuf = 1; lbuf = 0)
/////////////////////////////////////////////////////////////////////////////////////
	extmem_to_intmem((int *)sdram1 + offset1,    // Source pointer
      	             (int *)in_data[sbuf],                // Destination buffer
       	             LINE_SIZE,                           // internal word count
       	             LINE_SIZE,                           // external word count
					 1,                                   // External Increment (EM)
           	  		 10,                                  // DMA Channel
                     DMAC_DEN | DMAC_MASTER | DMAC_BURST, // flags for this xfer
               		 0,            	                      // Wait for DMA to complete?
					 0);                                  // Use timer?

	LinkTX_P2(lbuf); 	// Send in_data[lbuf][1*LINE_PKT] to HH_PROC2 
	LinkTX_P3(lbuf);	// Send in_data[lbuf][2*LINE_PKT] to HH_PROC3
						// writing in MMS with lbuf = 0
	LinkTX_P4(lbuf);	// Send in_data[lbuf][3*LINE_PKT] to HH_PROC4
	txpkts++;

	Processing(lbuf);		// fft: in_data[lbuf][0*LINE_PKT] --> fft_data[lbuf][0]
		
	lbuf = sbuf;			// update buffer managers 
	sbuf = (sbuf) ? 0 : 1;

	offset1 += LINE_SIZE;    // word offset into SDRAM

	while(tx_data == 0); 	// wait for timer flag
    tx_data = 0;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Star main loop
/////////////////////////////////////////////////////////////////////////////////////////////////////////
	do
	{
		// Transfer data from external to internal memory.
		extmem_to_intmem((int *)sdram1 + offset1,    // Source pointer
          	             (int *)in_data[sbuf],                // Destination buffer
	       	             LINE_SIZE,                           // internal word count
	       	             LINE_SIZE,                           // external word count
						 1,                                   // External Increment (EM)
            	  		 10,                                  // DMA Channel
                         DMAC_DEN | DMAC_MASTER | DMAC_BURST, // flags for this xfer
                 		 0,            	                      // Wait for DMA to complete?
						 0);                                  // Use timer?

		LinkTX_P2(lbuf); 	// Send in_data[lbuf][1*LINE_PKT] to HH_PROC2 
		LinkTX_P3(lbuf);	// Send in_data[lbuf][2*LINE_PKT] to HH_PROC3
		LinkTX_P4(lbuf);	// Send in_data[lbuf][3*LINE_PKT] to HH_PROC4
		txpkts++;

		// interrupt each time link 4 completes
		interrupt(SIG_LP4I, link4_handler);

		LinkRX_P4(rxbuf); 	// Receive data from HH_PROC4 to rcvd_P4[rxbuf][0]
		LinkRX_P3(rxbuf); 	// Receive data from HH_PROC3 to rcvd_P3[rxbuf][0]
		LinkRX_P2(rxbuf);	// Receive data from HH_PROC2 to rcvd_P2[rxbuf][0]

		Processing(lbuf);	// fft: in_data[lbuf][0*LINE_PKT] --> fft_data[lbuf][0]

		while(rx_data == 0);
		rx_data = 0;
		rxpkts++;

		// inhibit interrupt
		clear_interrupt(SIG_LP4I);

		// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P4[rxbuf] +  rcvd_P3[rxbuf]
		ComposeLine(sbuf, rxbuf);

		// Transfer data from internal to external memory.
		intmem_to_extmem((int *)&out_data[sbuf],				// xfer source
						 (int *)sdram2 + offset2,  				// Source pointer
	       	             LINE_SIZE,                           // internal word count
	       	             LINE_SIZE,                           // external word count
						 1,                                   // External Increment (EM)
            	  		 13,                                  // DMA Channel
          			     dmac_int_to_ext, 					  // flags for this xfer
          			     0,            	                      // Wait for DMA to complete?
						 0);                                  // Use timer?

		// Update buffer managers
		lbuf = sbuf;
		sbuf = (sbuf) ? 0 : 1;

		++rxbuf; rxbuf = rxbuf % 2;		
		offset1 += LINE_SIZE;		// word offset into SDRAM
		offset2 += LINE_SIZE;		// word offset into SDRAM

		// stat[pkt_cnt].link3_count = timer_on();

		while(tx_data == 0);		// wait for timer flag
        tx_data = 0;

	}while(offset1 < Total_Pixels);

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// End of the main loop. 
/////////////////////////////////////////////////////////////////////////////////////////////////////////

	LinkTX_P2(lbuf); 	// Send in_data[lbuf][1*LINE_PKT] to HH_PROC2 
	LinkTX_P3(lbuf);	// Send in_data[lbuf][2*LINE_PKT] to HH_PROC3
	LinkTX_P4(lbuf);	// Send in_data[lbuf][3*LINE_PKT] to HH_PROC4
	txpkts++;

	// interrupt each time link 4 completes
	interrupt(SIG_LP4I, link4_handler);

	LinkRX_P4(rxbuf); 	// Receive data from HH_PROC4 to rcvd_P4[rxbuf][0]
	LinkRX_P3(rxbuf); 	// Receive data from HH_PROC3 to rcvd_P3[rxbuf][0]
	LinkRX_P2(rxbuf);	// Receive data from HH_PROC2 to rcvd_P2[rxbuf][0]

	Processing(lbuf);	// fft: in_data[lbuf][0*LINE_PKT] --> fft_data[lbuf][0]

	while(rx_data == 0);
	rx_data = 0;
	rxpkts++;

	// inhibit interrupt
	clear_interrupt(SIG_LP4I);

	// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P3[rxbuf] + rcvd_P4[rxbuf]
	ComposeLine(sbuf, rxbuf);
	
	// Transfer data from internal to external memory.
	intmem_to_extmem((int *)&out_data[sbuf],					// xfer source
					 (int *)sdram2 + offset2, 		// Source pointer
       	             LINE_SIZE,                           // internal word count
       	             LINE_SIZE,                           // external word count
					 1,                                   // External Increment (EM)
           	  		 13,                                  // DMA Channel
                     dmac_int_to_ext, 					  // flags for this xfer
                     0,            	                      // Wait for DMA to complete?
					 0);                                  // Use timer?

	// Update buffer managers
	lbuf = sbuf;
	sbuf = (sbuf) ? 0 : 1;

	++rxbuf; rxbuf = rxbuf % 2;		
	offset2 += LINE_SIZE;		// word offset into SDRAM
	
	while(tx_data == 0);		// wait for timer flag
    tx_data = 0;

/////////////////////////////////////////////////////////////////////////////////////
// Ship out last buffer of data
/////////////////////////////////////////////////////////////////////////////////////

 	// Receive data from HH_PROC4, HH_PROC3 and HH_PROC2
	LinkRX_P4(rxbuf);
	LinkRX_P3(rxbuf); 
	LinkRX_P2(rxbuf); 
	rxpkts++;
	
	// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P4[rxbuf] +  rcvd_P3[rxbuf]
	ComposeLine(sbuf, rxbuf);

	// Transfer data from internal to external memory.
	intmem_to_extmem((int *)&out_data[sbuf],			  // xfer source
					 (int *)sdram2 + offset2,		      // Source pointer
       	             LINE_SIZE,                           // internal word count
       	             LINE_SIZE,                           // external word count
					 1,                                   // External Increment (EM)
           	  		 13,                                  // DMA Channel
                     dmac_int_to_ext, 					  // flags for this xfer
                     0,            	                      // Wait for DMA to complete?
					 0);                                  // Use timer?

	while(tx_data == 0); 	// wait for timer flag
    tx_data = 0;

/////////////////////////////////////////////////////////////////////////////////////

	while(tx_data == 0); 	// wait for timer flag
    tx_data = 0;
	
	asm("BIT TGL flags FLG3;");		// Toggle Buffer-Trigger
	frame_cnt++;
	output = 1;				// semaphore
		
}while (!done);

timer_off();

}

