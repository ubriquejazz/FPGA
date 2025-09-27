//*********************************************************
//
//  hh_consumer.c 
//  --------------------------------------------
//  Program to receive data from hh_generator process over link ports.
//  This code is designed to run on processor 2.
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

#define RAW_PKT              1024                  // raw frame data=1024 3-byte pixels (in each 4-bytes)
#define LINK_PKT             RAW_PKT/4             // each link sends 1/4 of raw data
#define NPKTS                4*1024                // 4k frame packets for this test

//Globals
int done = 0;
int rxbuf = 0;
int rxpkts = 0;
volatile int rx_data = 0;
int rcvd_data[32][2*LINK_PKT];                     // 32-deep rx data buffer

void link5_handler(int signum)
{
    rx_data = 1;
}

//*********************************************************
//
//
//
//*********************************************************
void main(void)
{
    // prepare processor for operation
    init_HH_manual(0xc, 0x01ce1b86, 2, 0x10);

	// interrupt each time link 5 completes
    interrupt(SIG_LP5I, link5_handler); 
	
	do
	{
		// Receive data from HH_PROC1
        link_dma_noint_rcv((int *)&rcvd_data[rxbuf][0], // source buffer
		             LINK_PKT,         // buffer size
					 4,                 // link port
					 4,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function

 		link_dma_noint_rcv((int *)&rcvd_data[rxbuf][LINK_PKT], // source buffer
		             LINK_PKT,         // buffer size
					 5,                 // link port
					 5,                 // link buffer
					 1,                 // link speed
					 8,                 // link bit width
					 32,                // data element bit width
					 1,                 // data stride
					 0,                 // wait for completion?
					 NULL);             // no abort function

		// update buffer managers
		rxbuf = ++rxbuf % 32;

		// wait for timer flag
		while(rx_data == 0)
		{
			idle;
	    }

		// reset flag
        rx_data = 0;

	}while(++rxpkts < NPKTS);

	done = 1;
}

//*********************************************************
// End of file hh_consumer.c
//*********************************************************
