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
#include <string.h>
#include <signal.h>
#include <macros.h>
#include <filter.h>
#include <complex.h>
#include <matrix.h> 
#include "linkdma.h"
#include "extint0.h"
asm("#include <def21160.h>");

#define INIT_SDRAM           1                     // set flag to init SDRAM with incrementing pattern
#define N					 1024 
#define LINE_SIZE            1024*2                // line data = 1024 8-byte pixels (complex_float pixels)
#define LINE_PKT             LINE_SIZE/4           // each processor recieves 1/4 of line data (packet)
#define FRAME_SIZE           128  				   // 32 lines per frame for this test
#define TOTAL_PIXELS         LINE_SIZE*FRAME_SIZE  	// total number of pixels (32-bit words)
#define NUM_FRAMES			 4					   	// 4 frames
#define FREQ				 300				 	// Hz frame rate

#define SDRAM_ADDR1       	 0x800000              // addr of beginning of SDRAM1
#define SDRAM_ADDR2       	 0x1000000             // addr of beginning of SDRAM2
#define MMS_FACTOR           0x100000              // multiplier with proc ID
#define HH_PROC3_ID          3                     // Processor 3 is the HH for some process
#define BLOCK1_OFFSET        0x58000               // "safe" area in DM of HH_PROC3
#define MMS_POINTER          (HH_PROC3_ID * MMS_FACTOR) + BLOCK1_OFFSET
#define FFT_SIZE			 64

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Defines for diagnostic metrics
/////////////////////////////////////////////////////////////////////////////////////////////////////////

typedef struct
{
    volatile int timer_intr;
	volatile int processed;	
}status_t;
status_t stat[32];
volatile int pkt_cnt = 0;

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Globals Variables
/////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma align 64 
float dm input_r[FFT_SIZE]; 
#pragma align 64 
float pm input_i[FFT_SIZE]; 

float dm temp_r[FFT_SIZE]; 
float pm temp_i[FFT_SIZE]; 

float dm twid_r[FFT_SIZE/2]; 
float pm twid_i[FFT_SIZE/2]; 

int Line_Freq 		= FREQ;
int Num_Frames 		= NUM_FRAMES;
int Frame_Size 		= FRAME_SIZE;
int Total_Pixels	= TOTAL_PIXELS;

int done = 0;			// host pc flag
int input = 0;			// host pc 		semaphore
int output = 0;			// master dsp 	semaphore
int frame_cnt = 0;		// host pc flag
int rxpkts, txpkts = 0;

int sbuf = 0;								// next index in in_data (last index in fft_data)
int lbuf = 0;								// actual index of in_data and fft_data
int rxbuf = 0;								// index of rcvd_P2 , rcvd_P4 and rcvd_P3
int ticks;

int *sdram_input1 = (int *)SDRAM_ADDR1;    	// pointer to SDRAM1 raw input
int *sdram_input2 = (int *)SDRAM_ADDR2;    	// pointer to SDRAM2 raw output
int offset1, offset2;
int *ptr;                         			// pointer used for the MMS xfers 0x58000

volatile int tx_data = 0;                   // timer interrupt flag
volatile int rx_data = 0;                   // link4 interrupt flag (bypass cable)
volatile int stage = 1;

int out_data[2][LINE_SIZE];			// ping-pong output data buffer
int in_data[2][LINE_SIZE];         	// ping-pong input data buffer
int fft_data[2][LINE_PKT];         	// ping-pong processing buffer

int rcvd_P3[2][LINE_PKT];                          // 4-deep rx data buffer
int rcvd_P2[2][LINE_PKT];                          // 4-deep rx data buffer
int rcvd_P4[2][LINE_PKT];                          // 4-deep rx data buffer


/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Interrupt Service Rutines 
/////////////////////////////////////////////////////////////////////////////////////////////////////////

int calc_timer_ticks(int hz)
{
    return(80000000/hz);
}

void timer_interrupt(int sig)
{
	if (stage == 1)
	{
		asm("BIT TGL flags FLG2;");		// Toggle Line-Trigger
	 	if(pkt_cnt < 32) pkt_cnt++;
		stat[pkt_cnt].timer_intr = timer_on();
	}
	tx_data = 1;
}

void link4_handler(int sig)
{
	stat[pkt_cnt++].processed = timer_on();
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
	ptr = (lbuf) ? (int *)MMS_POINTER + LINE_PKT : (int *)MMS_POINTER;
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
					 2,                 // link speed
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
					 2,                 // link speed
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
		
	///////////////////// 1st FFT  /////////////////////
	for (i=0, j=0; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=0; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 2nd FFT  /////////////////////
	for (i=0,j=64; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=64; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 3th FFT  /////////////////////
	for (i=0,j=128; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=128; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 4th FFT  /////////////////////
	for (i=0,j=192; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=192; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 5th FFT  /////////////////////
	for (i=0,j=256; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=256; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 6th FFT  /////////////////////
	for (i=0,j=320; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=320; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 7th FFT  /////////////////////
	for (i=0,j=384; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);


	for (i=0,j=384; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 8th FFT  /////////////////////
	for (i=0,j=448; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_data[lbuf][j++];
		input_i[i]  =(float)in_data[lbuf][j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, 
		temp_r,temp_i, 
		twid_r,twid_i,FFT_SIZE);

	for (i=0,j=448; i<32; i++)
		{
		fft_data[lbuf][j++] = (int)(input_r[i]);
		fft_data[lbuf][j++] = (int)(input_i[i]);
		}
}


////////////////////////////////////////////////////////////////////////////
// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P3[sbuf] + rcvd_P4[rxbuf]
////////////////////////////////////////////////////////////////////////////

void Compose_Line(int sbuf, int rxbuf, int post_p)
{
	int 	i, j=0;
	float 	pi = 3.141516;
	complex_float temp, exponent;
	int 	*paux;
	
	// Initialiazation
	paux = &out_data[sbuf][0];
	for(i = 0; i < N; i++)
	{
		*paux 	  = 0;				
		*(paux+1) = 0;
		paux = paux + 2;

	}
	exponent.re = 0;
	exponent.im = 2 * pi / N;


	// Compose output buffer
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

	if (post_p)
	{
	    for(i = 0; i < 32; i++)
		{
	    	for(j = 0; j < 32; j++)
			{
				temp.re = (float)(*paux);	
				temp.im = (float)(*(paux+1));
				
				exponent.im = exponent.im * i * j;
				temp = cmltf( temp, cexp(exponent));
				
				*paux 	  = (int)temp.re;
				*(paux+1) = (int)temp.im;
				paux = paux + 2;
			}
		}

	}
}

//*************************************************************************************************
//
// one of the two stages in the fft algorithm that computes the FFT of the pieces of line
// using pipeline will improve the line-process time...
//
//*************************************************************************************************
int Process_Frame(int *orig, int *dest, int post_p)
{
	offset1 = 0;		
	offset2 = 0;		
	rxbuf = 0;
	sbuf = 0;		// next index in in_data (last index in fft_data)
	lbuf = 0;		// actual index of in_data and fft_data

/////////////////////////////////////////////////////////////////////////////////////
// 1st Iteration (sbuf = 0)
/////////////////////////////////////////////////////////////////////////////////////
	extmem_to_intmem((int *)orig + offset1,    	// Source buffer
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
	extmem_to_intmem((int *)orig + offset1,    // Source pointer
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
		extmem_to_intmem((int *)orig + offset1,    	  // Source pointer
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
		Compose_Line(sbuf, rxbuf, post_p);

		// Transfer data from internal to external memory.
		intmem_to_extmem((int *)out_data[sbuf],		 	    // xfer source
						 (int *)dest + offset2, 	// Source pointer
	       	             LINE_SIZE,                           // internal word count
	       	             LINE_SIZE,                           // external word count
						 1,                                   // External Increment (EM)
            	  		 13,                                  // DMA Channel
                         dmac_int_to_ext, 			  		  // flags for this xfer
                 		 0,            	                      // Wait for DMA to complete?
						 0);                                  // Use timer?

		// Update buffer managers
		lbuf = sbuf;
		sbuf = (sbuf) ? 0 : 1;

		rxbuf = (rxbuf + 1) % 2;		
		offset1 += LINE_SIZE;		// word offset into SDRAM
		offset2 += LINE_SIZE;		// word offset into SDRAM

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
	Compose_Line(sbuf, rxbuf, post_p);
	
	// Transfer data from internal to external memory.
	intmem_to_extmem((int *)out_data[sbuf],				  // xfer source
					 (int *)dest + offset2, 	  // Source pointer
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
	rxbuf = (rxbuf + 1) % 2;		

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
				//
	// fft_data[sbuf] + rcvd_P2[rxbuf] +  rcvd_P4[rxbuf] +  rcvd_P3[rxbuf]
	Compose_Line(sbuf, rxbuf, post_p);

	// Transfer data from internal to external memory.
	intmem_to_extmem((int *)out_data[sbuf],			    // xfer source
					 (int *)dest + offset2,  	// Source pointer
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

    return 0;
} 

//*************************************************************************************************
//
//*************************************************************************************************
void Transpose_Frame(int *orig, int *dest)
{
	int i, j, k, offs = 0;	
	long double a[32][32]; 
	long double a_transpose[32][32]; 
	long double *pa, *pb;
	
	//pa = a[0];
	pa = (long double *)orig;
	pb = (long double *)dest;	
	
	for (k=0; k<Frame_Size; k++)
	{
	    transpmd ((long double *)a_transpose, pa, 32, 32);
	    
        for (i=0; i<32; i++)
	      for (j=0; j<32; j++)
		    pb[i*32+ j] = a_transpose[i][j];

	    pa = pa + LINE_SIZE/2;
	    pb = pb + LINE_SIZE/2;
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
	twidfftf(twid_r,twid_i,FFT_SIZE); 

#if INIT_SDRAM
    ptr = (int *)sdram_input1;
    for(i = 0; i < Total_Pixels; i++)
	{
	    *ptr++ = 1;
		*ptr++ = 0;
	}

	ptr = (int *)sdram_input2;
    for(i = 0; i < Total_Pixels; i++)
	{
	    *ptr++ = 0;
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
		stat[pkt_cnt++].processed 	= 0;
	}

	// Set up a timer interrupt to pace simulated input
	timer_off();
	ticks = calc_timer_ticks(Line_Freq);	// calc cycles needed to simulate a N Hz frame rate
	timer_set(ticks, ticks);
	interrupt(SIG_TMZ0, timer_interrupt);
	interrupt(SIG_EP1I, DMAC11_complete);

	//for (frame_cnt = 0; frame_cnt < Num_Frames; frame_cnt++ )
	do
	{
		while (!input)
		{
			idle;
		}
		input = 0;				// semaphore
		Transpose_Frame(sdram_input2, sdram_input1);

		pkt_cnt = 0;	stage = 1;
		timer_on();
		Process_Frame(sdram_input1, sdram_input2, 1);
		
		stage = 2;
		Transpose_Frame(sdram_input2, sdram_input1);
		Process_Frame(sdram_input1, sdram_input2, 0);

		asm("BIT TGL flags FLG3;");		// Toggle Buffer-Trigger
		frame_cnt++;
		output = 1;				// semaphore

	}while (!done);
	timer_off();

}

