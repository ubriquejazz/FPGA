//*********************************************************
//
//  Internal <-> External DMA Speed Test Example
//  --------------------------------------------
//  dma_speed_test.c : Program to demonstrate DMA speed between 
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
//    1.0    5/18/00	rlh		Create based on dma_test.c
//
//*********************************************************

#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include <macros.h>
#include "extint.h"

//*********************************************************

#define BUFFER_SIZE     	1024		// Size of tx and rx internal buffers for the test, which is also DMA size
#define CLOCKSPD    (float) 40000000.0	// External Clock Rate

//*********************************************************

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

//*********************************************************
// Global variables for host to access.

int internal_buffer[BUFFER_SIZE];			// Internal buffer - used for both tx and rx
int	number_of_loops = 0x100;				// Default number of loops
int current_loop;
int done;
int errors;									// Errors found in data at end of test
int *external_buffer = (int *) 0x800000;	// Default address of external buffer
float ReadRate, WriteRate;
float LoopRate;
int XferTime;

//*********************************************************
//
//
//
//*********************************************************
int main(void)
{
    int i, msize;

	// Check to make sure Syscon is at least set for 4 MW external banks - if it's less, set it to this
	// This allows this code to be run from diag21k or from the emulator, since via diag21k msize
	// should already be set based on SDRAM size, but from the emulator it won't be.
    msize = (GetIOP(SYSCON) & 0xF000) >> 12;
	if (msize < 9)								// Bank size = 2 ** (msize + 13) -> we want at least 2**22
	{
		SetIOP(SYSCON,(GetIOP(SYSCON) | (0x9 << 12)));
	}

	// Set WAIT to what it should be for the Hammerhead
	SetIOP(WAIT, 0x01CE1B86); /* SDRAM: Synch, 1 wait state; FLASH: Asynch, 7 waits; SharcFIN: Synch, 1 wait */
      
    // Initialization.
    done = FALSE;
	errors = 0;
	ReadRate = 0.0;
	WriteRate = 0.0;
			
	// Preset the buffer with a simple counter pattern

	for(i = 0; i < BUFFER_SIZE; i++)
	{
		internal_buffer[i] = i;
	}

	// Run the prescribed number of loops, where each loop DMAs the block from internal to external
	// and then back to internal again
	// To Test int to ext speed, do all int to ext first, then do all exts to ints
	for(current_loop=0; current_loop<number_of_loops; current_loop++)
	{

	    // Transfer data from internal to external memory.
	    XferTime = intmem_to_extmem((int *)internal_buffer,   	// Source buffer.
			              	        external_buffer,            // Destination buffer.
	        		       	        BUFFER_SIZE,      			// Buffer size.
	                    	  		10,                			// DMA Channel
		                      		TRUE );           			// Wait for DMA to complete?
		if (XferTime) WriteRate += LoopRate = ((float)BUFFER_SIZE/(float)XferTime)* 2.0 * CLOCKSPD * 4.0;
	}
	if (WriteRate) WriteRate /= number_of_loops;

	for (current_loop=0; current_loop<number_of_loops; current_loop++)
	{
	   // Transfer from external back into internal
	    XferTime = extmem_to_intmem( external_buffer,           // Source buffer.
	                                 (int *)internal_buffer,   	// Destination buffer.
	                                 BUFFER_SIZE,      			// Buffer size.
	                                 10,                		// DMA Channel
	                                 TRUE );           			// Wait for DMA to complete?

		if (XferTime) ReadRate += LoopRate = ((float)BUFFER_SIZE/(float)XferTime)* 2.0 * CLOCKSPD * 4.0;
 	}

    // OK, the DMAs are all done, so check for errors between what was originally DMAd out
	// and what we now have after it has been bounced back and forth number of loops times
	if (ReadRate) ReadRate /= number_of_loops;

	for( i=0 ; i<BUFFER_SIZE ; i++ )
    {
        if( internal_buffer[i] != i )
		{
            errors++;
		}
    }
	
    // Done, so return;
    done = TRUE;
}

//*********************************************************

// End of file dma_speed_test.c

//*********************************************************
