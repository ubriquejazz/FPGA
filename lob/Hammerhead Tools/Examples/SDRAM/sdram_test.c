/*****************************************************************************\
*                                                                             *
*  sdram_test.c : Source for Hammerhead sdram test.                           *
*                                                                             *
*  BittWare, Inc.                                                             *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Tel: 603-226-0404                                                          *
*  Fax: 603-226-6667                                                          *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*  Copyright 2001, BittWare, Inc.
*
*  The user is hereby granted a non-exclusive license to use and or 
*  modify this software provided that it runs on BittWare hardware.  
*  Usage of this software on non-BittWare hardware without the express 
*  written permission of BittWare is strictly prohibited.
*
*	Ver		Author	Date	 	Changes                                       *
*	---		------	----		-------			  					          *
*	1.0		rlh		11/11/99	Create for Hammerhead PCI					  *
*	1.1		rpc		03/28/01	Cleanup                 					  *
*                                                                             *
\*****************************************************************************/
#include <def21160.h>
#include "memory_tests.h"

// Fill in base address and size of sdram for initial test
#define	SDRAM_BASE_ADDRESS			0x800000
#define SDRAM_SIZE					0x10000
#define NUMBER_OF_TEST_LOOPS_TO_RUN	1000

#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
  	
// Globals for test results and status
int total_error_count;
int errors[11];
int current_num_loops;
int done;

// Globals for test parameters
// Use globals for the test start address, length, and number of loops so that we can change these with the debugger/emulator
// to test internal, external, or MMS as desired
// Init them to the defs from above
int	*sdram_base = (int *) SDRAM_BASE_ADDRESS;
int	sdram_size = SDRAM_SIZE;
int num_loops_to_run = NUMBER_OF_TEST_LOOPS_TO_RUN;


void main(void)
{
	int errs;

// Run the memory tests
	total_error_count = 0;
	current_num_loops = 0;
	done = 0;

// Set any required wait states, memory bank size, sdram control, etc.
	SetIOP(WAIT, 0x01CE1B86); /* SDRAM: EB0AM =10; EB0WS=001; Rest at default mode 0, wait 7 */
	SetIOP(SYSCON, 0x1C000);  /* Set BHD (bit 16) and MSIZE (bits 12-15) to 12 for 32 MW (2**(13+msize))  */

	while(current_num_loops < num_loops_to_run)
	{
	// Verify even and odd bits in each location
		errs = static_pattern_test(sdram_base, sdram_size, 0xaaaaaaaa);
		errors[0] +=errs;
		total_error_count += errs;
		
		errs = static_pattern_test(sdram_base, sdram_size, 0x55555555);
		errors[1] += errs;
		total_error_count += errs;

	// Set all bits and clear all bits
        errs = static_pattern_test(sdram_base, sdram_size, 0xffffffff);
		errors[2] += errs;
		total_error_count += errs;

		errs = static_pattern_test(sdram_base, sdram_size, 0x00000000);
		errors[3] += errs;
		total_error_count += errs;

	// Run a counting pattern through
	    errs = incrementing_pattern_test(sdram_base, sdram_size, 0, 1);
		errors[4] += errs;
		total_error_count += errs;
	
	// Verify alternating bits in memory and on the bus for each subsequent location
	    errs = alternating_pattern_test(sdram_base, sdram_size, 0x55555555, 0xaaaaaaaa);
		errors[5] += errs;
		total_error_count += errs;

	// Run a decrementing pattern
	    errs = incrementing_pattern_test(sdram_base, sdram_size, 0xffffffff, -1);
		errors[6] += errs;
		total_error_count += errs;
	
	// Walk a zero through a location (tests independence of data lines)
	    errs = walking_zero_test(sdram_base, 0, 31);
		errors[7] += errs;
		total_error_count += errs;
	
	// Walk a one through a location (test independence of data lines)
	    errs = walking_one_test(sdram_base, 0, 31);
		errors[8] += errs;
		total_error_count += errs;
	
	// Write the address as the data
	    errs = data_address_test(sdram_base, sdram_size);
		errors[9] += errs;
		total_error_count += errs;

	// Write the complement of the address as the data
	    errs = data_address_complement_test(sdram_base, sdram_size);
		errors[10] += errs;
		total_error_count += errs;

		current_num_loops++;
	}

	done = 1;
}
