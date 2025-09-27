/*****************************************************************************\
*                                                                             *
*  StaticInterrupt.c : Source for Hammerhead SharcFIN static interrupts test  *
*                                                                             *
*		This test is to verify that statically mapped interrupts are working, *
*       and is intended to be run on all 4 cluster processors simultaneously. *
*                                                                             *
*																			  *
*  Copyright (2001) BittWare, Inc.                                       	  *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Tel: 603-226-0404                                                          *
*  Fax: 603-226-6667                                                          *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*	Ver		Author	Date	 	Changes                                       *
*	---		------	----		-------			  					          *
*	1.0		rpc		05/24/01	Create for Hammerhead    	                  *
*                                                                             *
\*****************************************************************************/
#include <def21160.h>
#include <signal.h>
asm("#include <def21160.h>");

// Default settings for test parameters
#define WAIT_TIMEOUT		1000000	// Timeout counter for int to be acked
#define NUM_TEST_LOOPS		32		// Number of times to loop through this test
#define NPROCS              4       // default number of processors

#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)

// Globals for test results and status
int done = 0;
int num_tests = NUM_TEST_LOOPS;
int master = 0;
int nprocs = NPROCS;
volatile int irq1_intr_count = 0;
volatile int irq2_intr_count = 0;
volatile int test_number = 0;	

// Globals for test parameters
// Init them to the defs from above
int my_pid;				// My processor id

void delay(int wait)
{
	while(--wait)
	{
		asm("nop;");
  	}
}

void irq1_isr(int signum)
{
    irq1_intr_count++;
}

void irq2_isr(int signum)
{
    irq2_intr_count++;
}

/////////////////////////////////////////////////////////////////////////////////////////////////
void main (void) 
{
	volatile int *p1_rdy, *p2_rdy, *my_rdy;
	volatile int *p3_rdy, *p4_rdy; 
	volatile int ready_condition = 0;

// Set any required wait states, memory bank size, sdram control, etc.
// (Note that if this is being run through diag21k we don't need to do this)
    SetIOP(SYSCON, 0x1c000);  /* Set MSIZE */
	SetIOP(WAIT, 0x01CE1b86); /* SDRAM: EB0AM =10; EB0WS=001; Rest at default mode 0, wait 7 */

// We'll use the start of SDRAM as a place to put our shared test number and some ready flags
// to synch the multiprocessors
// First, let's figure out who we are and clear our ready flag
	my_pid = (GetIOP(SYSTAT) & 0xf00) >> 8;
	my_rdy = (volatile int *) MSGR0;
	*my_rdy = 0;

// Now let's set up the rest of the shareds
	p1_rdy = (volatile int *) MSGR0 + 0x100000;
	p2_rdy = (volatile int *) MSGR0 + 0x200000;
	p3_rdy = (volatile int *) MSGR0 + 0x300000;
	p4_rdy = (volatile int *) MSGR0 + 0x400000;

	if(master)
	{
		//  Init the flags as outputs, making sure they are deasserted first
		asm("bit set flags FLG1;");
		asm("bit set flags FLG3;");
		asm("bit set mode2 FLG1O;");
		asm("bit set mode2 FLG3O;");
	}
	else
	{
		//  Make my interrupts edge sensitive and install my ISRs
	   	asm("bit set mode2 IRQ1E;"); /* make IRQ1 edge sensitive */
	   	asm("bit set mode2 IRQ2E;"); /* make IRQ2 edge sensitive */
	   	asm("bit clr mode1 NESTM;"); /* disable interrupt nesting */
	   	interrupt(SIG_IRQ1, irq1_isr);
	   	interrupt(SIG_IRQ2, irq2_isr);
	}

// OK, we're ready to go so set our ready flag and wait for the others to be set
	*my_rdy = 1;

	while(!ready_condition)
	{
	    ready_condition = (nprocs == 4) ? (*p1_rdy && *p2_rdy && *p3_rdy && *p4_rdy) :
                          (nprocs == 2) ? (*p1_rdy && *p2_rdy) : 1;
   	}

    if(master)
	{
		for(test_number = 0; test_number < num_tests; test_number++)
		{
		    // FLG1 test //////////////////
			// Assert the flag
			asm("bit clr flags FLG1;");
	
		    // Now, wait a bit
            delay(1000);	

			// Deassert the flag
			asm("bit set flags FLG1;");
	
	
		    // FLG3 test //////////////////
			// Assert the flag
			asm("bit clr flags FLG3;");
	
		    // Now, wait a bit
            delay(1000);	
	
			// Deassert the flag
			asm("bit set flags FLG3;");
		}
	}
	else
	{
        delay(1000000);
		//idle();
	}

	*my_rdy = 0;
	done = 1;
}
