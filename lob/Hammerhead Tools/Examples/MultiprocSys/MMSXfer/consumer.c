//*********************************************************
//
//  consumer.c 
//  --------------------------------------------
//  Program to perform some calculation on a buffer of incoming raw data
//  via PCI bus.  The output is written to SDRAM.
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
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0   04/16/01  rpc	  Create for Hammerhead
//
//*********************************************************

#include <def21160.h>
#include <21060.h>
#include <signal.h>
#include <macros.h>

#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)

#define NPROCS               4                  // number of processors running this code
#define PACKET_IN_SIZE       256                // size of an input data set
#define PACKET_OUT_SIZE      256                // size of an output data set
#define DATA_IN_BUF_SIZE     PACKET_IN_SIZE*64  // input buffer size
#define SDRAM_BUF_SIZE       PACKET_OUT_SIZE*64 // SDRAM buffer size
#define IN_DATA_BUFF_START   0x58000            // address of input buffer
#define SDRAM_BASE           0x800000           // address of SDRAM start

int done = 0;
int pkts_rcvd = 0;
int *in_buffp;                                  // pointer to input buffer
int *in_buff_start;                             // pointer to start of input buffer
int out_buffp[PACKET_OUT_SIZE];                 // output array for DATA
int in_headp;                                   // 0-based head buffer pointer
int in_tailp;                                   // 0-based tail buffer pointer
int *sdram_out_p;                               // SDRAM buffer pointer 

//*********************************************************
//
//
//
//*********************************************************
void main(void)
{
    int i = 0, j;
	int my_pid;

    init_HH_manual(0xc, 0x1ce1b86, 2, 0x10);
     
    asm("bit set MODE2 0x00060000;"); // Set up to output on FLAGS 2&3
	asm("bit clr FLAGS 0x0000000c;"); // turn off LEDs

	my_pid = get_proc_ID();

    // Initialization.
	SetIOP(MSGR0, 0);  // MSGR0 is the input head pointer, updated by the gen program
	SetIOP(MSGR1, 0);  // MSGR1 is the input tail pointer, updated by this process
	in_buffp = (int *)IN_DATA_BUFF_START;

	asm("bit set FLAGS 0x00000004;");  //turn on one LED

	for(;;)
	{
		// Get current tail pointer and calc SDRAM pointer for this block
		in_tailp = GetIOP(MSGR1);
		sdram_out_p = (int *)(SDRAM_BASE + ((my_pid - 1) * PACKET_OUT_SIZE) + (in_tailp * NPROCS));
	   
		// Wait till data is available -- generator process will set 
		// a new MSGR0, the head pointer
		while((in_headp = GetIOP(MSGR0)) == in_tailp)
		{
			 if((++i % 1000000) == 0)
			 {
			    asm("bit tgl FLAGS 0x0000000c;");  //toggle LEDs
			 }
		}   

	    // There is data; perform some number crunching
		pkts_rcvd++;
		for(j = 0; j < PACKET_IN_SIZE; j++)
		{
		    out_buffp[j] = in_buffp[j];
		}

	    // DMA output to SDRAM
	    intmem_to_extmem(out_buffp,          // source for DMA
                         sdram_out_p,        // dest 
						 PACKET_OUT_SIZE,    // size of xfer
						 1,                  // increment
						 10,                 // DMA chan
						 1);                 // wait flag

		in_tailp += PACKET_IN_SIZE;
		if(in_tailp == DATA_IN_BUF_SIZE)
		{
			in_tailp = 0;
		}
		SetIOP(MSGR1, in_tailp);

		in_buffp += PACKET_IN_SIZE;
		if((int)in_buffp == IN_DATA_BUFF_START + DATA_IN_BUF_SIZE)
		{
			in_buffp = (int *)IN_DATA_BUFF_START;
		}
	}
}

//*********************************************************
// End of file consumer.c
//*********************************************************
