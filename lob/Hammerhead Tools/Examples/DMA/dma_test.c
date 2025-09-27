//*********************************************************
//
//  Internal <-> External DMA Example
//  ---------------------------------
//  dma_test.c : Program to demonstrate DMA between 
//               SHARC internal and external memory.
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
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0    3/31/98  reddog  Initial coding.
//	  2.0	12/23/99  rlh	  Modify for Hammerhead
//								- update DMA channels and DMAC settings
//								- add multi-run support
//
//*********************************************************
#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include <macros.h>
#include "extint.h"

//*********************************************************

#define BUFFER_SIZE     	1024		// Size of tx and rx internal buffers for the test, which is also DMA size
#define BLOCKS_PER_RUN		1024		// Number of buffers to transfer each run	

//*********************************************************

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

//*********************************************************

// Global variables for host to access.

int errors[BLOCKS_PER_RUN];		// Number of errors per run - only tracks errors in last run
int xmt_buf[BUFFER_SIZE];		// Internal Tx buffer
int rcv_buf[BUFFER_SIZE];		// Internal Rx buffer

int	number_of_runs = 10;		// Default number of runs
int done;
int total_errors;				// Total number of errors
int *ms0;
int	external_offset	= 0;		// Offset into external for buffer


//*********************************************************
//
//
//
//*********************************************************
int main( void )
{
    int i;
	int run;
	int block;
	int pattern_upper_word;

    // Set any required wait states, memory bank size, sdram control, etc.
    init_HH_manual(0xc, 0x1ce1b86, 2, 0x10);
       
    // Initialization.
    done = FALSE;
	total_errors = 0;

    ms0 = (int *)(get_ms_base(0) + external_offset);

	// Run the test multiple times
	for (run = 0; run < number_of_runs; run++)
	{
		// On each run, transfer multiple blocks
		for (block = 0; block < BLOCKS_PER_RUN; block++)
		{
			// Preset buffers with different data each block
			pattern_upper_word = block << 16;
		     for( i=0 ; i<BUFFER_SIZE ; i++ )
		    {
		        xmt_buf[i] = i | pattern_upper_word;
		        rcv_buf[i] = 0;
		    }
		
		    // Transfer data from internal to external memory.
		    intmem_to_extmem( (int *)xmt_buf,   // Source buffer.
		                      ms0,              // Destination buffer.
		                      BUFFER_SIZE,      // Buffer size.
		                      10,               // DMA Channel
		                      TRUE );           // Wait for DMA to complete?
				 
		    errors[block] = 0;
		 
		    // Transfer from external back into internal
		    extmem_to_intmem( ms0,              // Source buffer.
		                      (int *)rcv_buf,   // Destination buffer.
		                      BUFFER_SIZE,      // Buffer size.
		                      10,               // DMA Channel
		                      TRUE );           // Wait for DMA to complete?
		
		    // Check for errors between what was DMAd out and in
		    for(i = 0; i < BUFFER_SIZE ; i++)
		    {
		        if(xmt_buf[i] != rcv_buf[i])
				{
		            errors[block]++;
				}
		    }
	
	  		// Update the total error count
			total_errors += errors[block];	
		}
  	}

    done = TRUE;
}

//*********************************************************

// End of file dma_test.c

//*********************************************************
