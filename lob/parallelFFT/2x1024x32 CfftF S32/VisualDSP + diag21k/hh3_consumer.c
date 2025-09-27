//***********************************************************************
//
//  hh3_consumer.c 
//  --------------------------------------------
//  Program to receive data from hh_generator process over link ports.
//  This code is designed to run on processor 3.
//
//***********************************************************************

#include <def21160.h>
#include <21160.h>
#include <filter.h>
#include <complex.h>
#include <stdio.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"
#include "extint0.h"
#include "fin.h"
asm("#include <def21160.h>");

#define LINE_SIZE            2*1024                  // line data = 1024 4-byte pixels (2048 2-bytes pixels)
#define LINE_PKT             LINE_SIZE/4           // each processor recieves 1/4 of line data (packet)
#define FRAME_SIZE           128                   // 128 lines per frame for this test
#define IN_DATA_BUFF_START   0x58000               // address of input buffer
#define FFT_SIZE			 64
#define NSTAGES			 	 2

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

int Frame_Size = FRAME_SIZE;

int done = 0;
int rxbuf = 0;					
int txbuf = 0;
int rxpkts, txpkts = 0;

volatile int rx_data = 0;           // interrupt flag

int fft_data[2][LINE_PKT];			// 2-deep output data buffer
int *in_buffp;                      // pointer to input buffer

int rcvd_P1[2][LINE_PKT];         	// 2-deep rx data buffer
int rcvd_P1p0 = (int)rcvd_P1[0];
int rcvd_P1p1 = (int)rcvd_P1[1];

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Functions Definitions
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void irq0_isr(int signum)
{
		rx_data = 1;
}

void LinkTX_P1(int txbuf)
{
		link_dma_noint_xmt((int *)&fft_data[txbuf][0], // source buffer
		             LINE_PKT,        	// buffer size
					 1,                 // link port
					 1,                 // link buffer
					 2,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function 
}

//////////////////////////////////////////////////////////////////////////////
// FFT of rcvd_P1[txbuf][0] in fft_data[rxbuf][0]
//////////////////////////////////////////////////////////////////////////////
void Processing(int txbuf)
{
	int i, j;


	///////////////////// 1st FFT  /////////////////////
	for (i=0, j=0; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=0; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 2nd FFT  /////////////////////
	for (i=0,j=64; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=64; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 3th FFT  /////////////////////
	for (i=0,j=128; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=128; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 4th FFT  /////////////////////
	for (i=0,j=192; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=192; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 5th FFT  /////////////////////
	for (i=0,j=256; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=256; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 6th FFT  /////////////////////
	for (i=0,j=320; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=320; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 7th FFT  /////////////////////
	for (i=0,j=384; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);


	for (i=0,j=384; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}

	///////////////////// 8th FFT  /////////////////////
	for (i=0,j=448; i<FFT_SIZE; i+=2)
		{
		input_r[i] =(float)in_buffp[j++];
		input_i[i]  =(float)in_buffp[j++];

		input_r[i+1] = 0;
		input_i[i+1]  = 0;
		}

	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);

	for (i=0,j=448; i<32; i++)
		{
		fft_data[txbuf][j++] = (int)(input_r[i]);
		fft_data[txbuf][j++] = (int)(input_i[i]);
		}
}


//***********************************************************************************
//
//***********************************************************************************
void main(void)
{
	int i, j;
	int msize;
	int	*fin_base;						// based address of SHARC FIN
	volatile int *int_cfg_reg;			// Interrupt Multiplexer Register

	// Prepare processor for operation
    init_HH_manual(0xc, 0x01ce1b86, 2, 0x10);

	// Get base address of the SHARC FIN
    msize = (GetIOP(SYSCON) & 0xF000) >> 12;
	fin_base = (int *) (0x800000 + (2 * (0x2000 << msize)));

	// IRQ0 on HH3 drived by FLG0 on HH1
	int_cfg_reg = (volatile int *)(fin_base + FIN_HH3_IRQ0);
	*(int_cfg_reg) = B_H1F0_MSK;

	//  Make my interrupts edge sensitive and install my ISRs
   	asm("bit set mode2 IRQ0E;"); /* make IRQ0 edge sensitive */
   	asm("bit clr mode1 NESTM;"); /* disable interrupt nesting */

	// interrupt each time the master processor writes on MMS
   	interrupt(SIG_IRQ0, irq0_isr);
	twidfftf(twid_r,twid_i,FFT_SIZE); 

do
{

	rxbuf = 0;
	rxpkts = 0;

/////////////////////////////////////////////////////////
// 1st Iteration  (rxbuf = 0)
/////////////////////////////////////////////////////////
	while(rx_data == 0);
	rx_data = 0;
	rxpkts++;

	// first reading from the internal memory with rxbuf = 0
	// acording to the first writting by the master processor
	in_buffp =  (rxbuf) ? (int *)IN_DATA_BUFF_START + LINE_PKT :(int *)IN_DATA_BUFF_START;

	// update buffer managers
	txbuf = rxbuf;
	rxbuf = (rxbuf+1) % 2;

/////////////////////////////////////////////////////////
// Star main loop
/////////////////////////////////////////////////////////
	do
	{
		// Do some computation here
		for(i = 0; i < LINE_PKT; i++)
			fft_data[txbuf][i] = 0; //in_buffp[i];
		Processing(txbuf);		

		while(rx_data == 0);
		rx_data = 0;
		rxpkts++;

		// read now from the internal memory
		in_buffp =  (rxbuf) ? (int *)IN_DATA_BUFF_START + LINE_PKT :(int *)IN_DATA_BUFF_START;

		// Send 1/4 raw data to HH_PROC1 by the Link1
		LinkTX_P1(txbuf);
		txpkts++;

		// update buffer managers
		txbuf = rxbuf;
		rxbuf = (rxbuf+1) % 2;		

	}while(rxpkts < Frame_Size * NSTAGES);

/////////////////////////////////////////////////////////
// End of the main loop. 
/////////////////////////////////////////////////////////

// Do some computation here
	for(i = 0; i < LINE_PKT; i++)
		fft_data[txbuf][i] = 0; //in_buffp[i];
    Processing(txbuf);		

// Send 1/4 raw data to HH_PROC1 by the Link5
   LinkTX_P1(txbuf);
   txpkts++;

}while(!done);

}
