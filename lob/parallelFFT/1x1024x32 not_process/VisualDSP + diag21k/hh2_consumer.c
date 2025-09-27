//***********************************************************************
//
//  hh2_consumer.c 
//  --------------------------------------------
//  Program to receive data from hh_generator process over link ports.
//  This code is designed to run on processor 2.
//
//***********************************************************************

#include <def21160.h>
#include <21160.h>
#include <stdio.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"

#define LINE_SIZE            1024                  // line data = 1024 4-byte pixels (2048 2-bytes pixels)
#define LINE_PKT             LINE_SIZE/4           // each processor recieves 1/4 of line data (packet)
#define FRAME_SIZE           128                   // 128 lines per frame for this test

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Globals Variables
/////////////////////////////////////////////////////////////////////////////////////////////////////////

int Frame_Size = FRAME_SIZE;

int done = 0;
int rxbuf = 0;
int txbuf = 0;
int rxpkts, txpkts = 0;
volatile int rx_data = 0;           // interrupt flag
int fft_data[4][LINE_PKT];			// 4-deep output data buffer
int rcvd_P1[4][LINE_PKT];         	// 4-deep rx data buffer

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Functions Definitions
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void link4_handler(int signum)
{
		rx_data = 1;
}

void LinkTX_P1(int txbuf)
{
		link_dma_noint_xmt((int *)&fft_data[txbuf][0], // source buffer
		             LINE_PKT,        	// buffer size
					 5,                 // link port
					 5,                 // link buffer
					 2,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function 
}

void LinkRX_P1(int rxbuf)
{
	link_dma_noint_rcv((int *)&rcvd_P1[rxbuf][0], // source buffer
		             LINE_PKT,          // buffer size
					 4,                 // link port
					 4,                 // link buffer
					 1,                 // link speed
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

	for(i = 0; i < LINE_PKT; i++)
		fft_data[txbuf][i] = rcvd_P1[txbuf][i];
}

//***********************************************************************************
//
//***********************************************************************************
void main(void)
{
	int i, j;

	// prepare processor for operation
    init_HH_manual(0xc, 0x01ce1b86, 2, 0x10);

do
{

	rxbuf = 0;
	rxpkts = 0;

/////////////////////////////////////////////////////////
// 1st Iteration
/////////////////////////////////////////////////////////

	// interrupt each time link 4 completes
	interrupt(SIG_LP4I, link4_handler);

	// Receive data from HH_PROC1
	LinkRX_P1(rxbuf);

	while(rx_data == 0);
	rx_data = 0;
	rxpkts++;

	// inhibit interrupt
	clear_interrupt(SIG_LP4I);

	// update buffer managers
	txbuf = rxbuf;
	++rxbuf;
	rxbuf = rxbuf % 4;

/////////////////////////////////////////////////////////
// Star main loop
/////////////////////////////////////////////////////////
	do
	{
		// interrupt each time link 4 completes
		interrupt(SIG_LP4I, link4_handler);

		// Receive data from HH_PROC1
		LinkRX_P1(rxbuf);

		// Do some computation here
		Processing(txbuf);		
		// Send 1/4 raw data to HH_PROC1 by the Link5
		LinkTX_P1(txbuf);
		txpkts++;

		while(rx_data == 0);
		rx_data = 0;
		rxpkts++;

		// inhibit interrupt
		clear_interrupt(SIG_LP4I);

		// update buffer managers
		txbuf = rxbuf;
		++rxbuf;
		rxbuf = rxbuf % 4;		

	}while(rxpkts < Frame_Size);
	
/////////////////////////////////////////////////////////
// End of the main loop. 
/////////////////////////////////////////////////////////

// Do some computation here
   Processing(txbuf);		

// Send 1/4 raw data to HH_PROC1 by the Link5
   LinkTX_P1(txbuf);
   txpkts++;

}while (!done);

}
