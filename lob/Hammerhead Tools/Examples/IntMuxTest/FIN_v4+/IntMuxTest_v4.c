/*****************************************************************************\
*                                                                             *
*  IntMuxTest_v4.c : Test of Hammerhead SharcFIN v4 Interrupt Multiplexer.    *
*                                                                             *
*		This test is to verify the interrupt multiplexer in the Hammerhead    *
*		the SharcFIN.  It verifies (as much as possible) that each HH		  *
*		can interrupt all the others using the int mux and is intended to	  *
*		be run on all* processors simultaneously.                             *
*                                                                             *
*      *(1-, 2- or 4-processor boards can be tested by altering global        *
*       variable num_processors)                                              *
*																			  *
*  Copyright (2000) BittWare, Inc.                                       	  *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Tel: 603-226-0404                                                          *
*  Fax: 603-226-6667                                                          *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*	Ver		Author	Date	 	Changes                                       *
*	---		------	----		-------			  					          *
*	1.0		rlh		06/07/00	Create for Hammerhead PCI	                  *
*   1.1     rpc     10/03/00    Modify to test 1, 2 or 4 processor boards     *  
*   1.2     rpc     11/01/00    Use MMS space instead of SDRAM shared locs    *  
*   1.3     rpc     05/23/01    This version to test SHARC FIN version 4      *  
*                                                                             *
\*****************************************************************************/

// Default settings for test parameters
#define DEFAULT_MSIZE							0xC			// Size of external banks - 32 MW
#define	DEFAULT_FIN_EXTERNAL_BANK				2			// MS of SharcFIN
#define DEFAULT_NUMBER_OF_TEST_LOOPS_TO_RUN		1			// Test loops
#define WAIT_TIMEOUT							10000		// Timeout counter for int to be acked
#define READY_WAIT_TIMEOUT						0			// Timeout for test synch with other processors
#define NUM_SOURCES_PER_PROC                    2           // Each proc can source FLAG0 and FLAG1
#define NUM_RECEIVERS_PER_PROC                  1           // Each proc can only rx on IRQ0
#define DEFAULT_NPROCS                          4           // default to 4-processor cluster

#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)

// Include def file for the processor
#include <def21160.h>
#include <signal.h>

// Include def file for the SharcFIN
#include "fin160A.h"

// Globals for test results and status
int current_num_loops;
int done;
int num_processors = DEFAULT_NPROCS;
int sources_per_proc = NUM_SOURCES_PER_PROC;      
int receivers_per_proc = NUM_RECEIVERS_PER_PROC;    
int total_error_count;

volatile int *test_number_ptr;	// A shared global that all 4 processors use, located at MSGR1 of P1
int test_results[32][6];		// This array stores test results, which have the following info for each
								// test: test number, processor id of irq rx, irq number, int cfg reg of rx, 
								// flgs reg, irqs reg
int errors[32];

// Globals for test parameters
// Init them to the defs from above
int	*fin_base;													// Set based on msize and fin_external_bank
int fin_external_bank = DEFAULT_FIN_EXTERNAL_BANK;				// Bank number (MS) for SharcFIN
int msize = DEFAULT_MSIZE;										// Bank size
int num_loops_to_run = DEFAULT_NUMBER_OF_TEST_LOOPS_TO_RUN;		// Number of times to run test
int my_pid;				                                        // My processor id

// The IRQ handlers save the context and then clear the int cfg mask which disables the interrupt and
// tells the interrupter that he can go on to the next test, because we got the interrupt
void irq0_isr(int signum)
{
	int local_test_number;
	volatile int *my_int_cfg_reg;

// OK, we got an IRQ0, let's figure things out and store the context
	local_test_number = *test_number_ptr;
	my_int_cfg_reg = (volatile int *) (fin_base + FIN_INT_CFG_H1I0 + ((my_pid - 1) * 2));

	test_results[local_test_number][0] = local_test_number;
	test_results[local_test_number][1] = my_pid;
	test_results[local_test_number][2] = 0;
	test_results[local_test_number][3] = *(my_int_cfg_reg);
	test_results[local_test_number][4] = *(volatile int *)(fin_base + FIN_FLGS_STATUS);
	test_results[local_test_number][5] = *(volatile int *)(fin_base + FIN_IRQS_STATUS);

// Now, let's turn off the mask completely which will shut off the int and tell the interrupter
// that he can go on to the next test
	*(my_int_cfg_reg) = 0x0;
}

void irq1_isr(int signum)
{
	int local_test_number;
	volatile int *my_int_cfg_reg;

// OK, we got an IRQ0, let's figure things out and store the context
	local_test_number = *test_number_ptr;
	my_int_cfg_reg = (volatile int *) (fin_base + FIN_INT_CFG_H1I0 + ((my_pid - 1) * 2));

	test_results[local_test_number][0] = local_test_number;
	test_results[local_test_number][1] = my_pid;
	test_results[local_test_number][2] = 1;
	test_results[local_test_number][3] = *(my_int_cfg_reg);
	test_results[local_test_number][4] = *(volatile int *)(fin_base + FIN_FLGS_STATUS);
	test_results[local_test_number][5] = *(volatile int *)(fin_base + FIN_IRQS_STATUS);

// Now, let's turn off the mask completely which will shut off the int and tell the interrupter
// that he can go on to the next test
	*(my_int_cfg_reg) = 0x0;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
void main (void) 
{
	int i,j;
	volatile int *p1_ready_ptr, *p2_ready_ptr, *my_ready_ptr;
	volatile int *p3_ready_ptr, *p4_ready_ptr; 
	int my_test_number;
	int num_tests;
	int tests_per_proc;
	int mask;
	int flag;
	int cfg_offset;
	volatile int ready_condition = 0;
	volatile int *int_cfg_reg;
	int wait;

// Set any required wait states, memory bank size, sdram control, etc.
// (Note that if this is being run through diag21k we don't need to do this)
	SetIOP(WAIT,0x01CE1b86); /* SDRAM: EB0AM =10; EB0WS=001; Rest at default mode 0, wait 7 */
//	SetIOP( SYSCON, (GetIOP(SYSCON) | (msize << 12)));	/* Set MSIZE */

// We'll use the start of SDRAM as a place to put our shared test number and some ready flags
// to synch the multiprocessors
// First, let's figure out who we are and clear our ready flag
	my_pid = (GetIOP(SYSTAT) & 0xf00) >> 8;
	my_ready_ptr = (volatile int *) MSGR0;
	*my_ready_ptr = 0;

// Just spin for a bit as a test to see if shared bus hogs are causing problems
	for (i=0;i<1000000;i++)
	{
		asm("nop;");
	}

// Now let's set up the rest of the shareds
	p1_ready_ptr 	= (volatile int *) MSGR0 + 0x100000;
	p2_ready_ptr 	= (volatile int *) MSGR0 + 0x200000;
	p3_ready_ptr 	= (volatile int *) MSGR0 + 0x300000;
	p4_ready_ptr 	= (volatile int *) MSGR0 + 0x400000;
	test_number_ptr = (volatile int *) MSGR1 + 0x100000; //Proc 1's MMS keeps test number

// Clear the error counter and test result tables; process variables
// sources_per_proc are flag 0 and flag1, receivers are IRQ0 and IRQ1;
// and vary geometrically with the number of processors
	done = 0;
	total_error_count = 0;
	tests_per_proc = num_processors * sources_per_proc * receivers_per_proc;
	num_tests = num_processors * tests_per_proc;
	*test_number_ptr = 0;
	for (i = 0; i < num_tests; i++)
	{
		errors[i] = 0;
		for (j = 0; j < 6; j++)
			test_results[i][j] = 0;
	}

// Compute the base address of the SharcFIN based on Syscon's MSize and the external bank global
    msize = (GetIOP(SYSCON) & 0xF000) >> 12;
	fin_base = (int *) (0x800000 + (fin_external_bank * (0x2000 << msize)));

//  Init the flags as outputs, making sure they are deasserted first
  	asm("#include <def21160.h>");
	asm("bit set flags FLG0;");
	asm("bit set mode2 FLG0O;");
	asm("bit set flags FLG1;");
	asm("bit set mode2 FLG1O;");
	
//  Make my interrupts edge sensitive and install my ISR
   	asm("bit set mode2 IRQ0E;"); /* make IRQ0 edge sensitive */
   	asm("bit clr mode1 NESTM;"); /* disable interrupt nesting */
   	interrupt(SIG_IRQ0, irq0_isr);

// OK, we're ready to go, so set our ready flag and wait for the others to be set
// If we timeout waiting, set the error counter to indicate a problemn and get out of here!
	*my_ready_ptr = 1;

	wait = 0;
	while(!ready_condition)
	{
	    ready_condition = (num_processors == 4) ? (*p1_ready_ptr && *p2_ready_ptr && *p3_ready_ptr && *p4_ready_ptr) :
		                  (num_processors == 2) ? (*p1_ready_ptr && *p2_ready_ptr) : 1;  // Single proc case is ready already.
		wait++;
		if ((wait > READY_WAIT_TIMEOUT) && (READY_WAIT_TIMEOUT != 0))
		{
			total_error_count = 0xdeadbeef;
			return;
		}
   	}
 
// Run until all [num_tests] tests are done (note that this processor only acts as the source for 
// some of them)
	while (*test_number_ptr < num_tests)
	{
	// Check if I'm the interrupter - I handle a block based on my processor id
		if (((*test_number_ptr / tests_per_proc) + 1) == my_pid)
		{
		// Ok, I'm in the driver's seat
		// Figure out what flag I'm going to drive, the mask value to use, and whose mask to open
		// I will generate [tests_per_proc] tests in all, first using flag0 and then flag1 to test 
		// that I can cause an interrupt into every processor's irq0 and irq1 with it

			my_test_number = *test_number_ptr % tests_per_proc;   // Derive my own 0-based test number
			flag = my_test_number % 2;                            // flag is 0 or 1
			mask = 0x1 << ((my_pid-1)*2 + flag);                  // The mask rotates through [tests_per_proc] bits
			cfg_offset = (my_test_number == 0 || my_test_number == 1) ? 0 :
                         (my_test_number == 2 || my_test_number == 3) ? 2 :
                         (my_test_number == 4 || my_test_number == 5) ? 4 : 6;
			int_cfg_reg = (volatile int *)(fin_base + FIN_INT_CFG_H1I0 + cfg_offset);
                                                                  // Rotate through [receivers_per_proc] int cfg regs
	  	// OK, go ahead and open the mask and assert the flag
  			*(int_cfg_reg) = mask;
		    if(flag == 0)
			{
			    asm("bit clr flags FLG0;");
			}
			else
			{
			    asm("bit clr flags FLG1;");
			}

	    // Now, wait for the mask to be cleared by the interrupt receiver
			wait = 0;
			while (*(int_cfg_reg) & 0xFF)
			{
			// If we timeout waiting for the mask to be cleared, store the test number in the
			// error table, clean up, and go on to the next test
				wait++;
				if (wait > WAIT_TIMEOUT)
				{
					errors[total_error_count] = *test_number_ptr;
					total_error_count++;
					*(int_cfg_reg) = 0x00;			// Clear the mask ourselves
			  	}
		  	}

		// Deassert the flag
		    if(flag == 0)
			{
			    asm("bit set flags FLG0;");
			}
			else
			{
			    asm("bit set flags FLG1;");
			}

		// Go on to the next test
			*test_number_ptr = *test_number_ptr + 1;
		}
	}

// That's all folks!
	*my_ready_ptr = 0;
	done = 1;
}
