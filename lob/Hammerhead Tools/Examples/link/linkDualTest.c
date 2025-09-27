/*****************************************************************************\
*                                                                             
*  linkdualtest.c : Source for Dual Link Test for Hammerhead                          
*                                                                             
*		This test is to verify transfers between link ports on the Hammerhead.
*       The link traffic is transmitted on one link (global link1), and       
*       received on another (global link2).  This allows the transfers to     
*       involve numerous processors, as long as each pair shares two link     
*       connections.                          
*            
*  BittWare, Inc.                                       	  
*  33 North Main Street                                                       
*  Concord, NH  03301                                                         
*  Tel: 603-226-0404                                                          
*  Fax: 603-226-6667                                                          
*  E-mail: support@bittware.com                                               
*                                                                             
*  Copyright 2001, BittWare, Inc.
*
*  The user is hereby granted a non-exclusive license to use and or 
*  modify this software provided that it runs on BittWare hardware.  
*  Usage of this software on non-BittWare hardware without the express 
*  written permission of BittWare is strictly prohibited.
*
*	Ver		Author	Date	 	Changes                                       
*	---		------	----		-------			  					          
*	1.0		rlh		11/10/99	First cut - hard code link ports              
*   1.1     rlh     12/06/99    Next pass - add 48 bit tests                    
*                                                                             
\*****************************************************************************/
#include <def21160.h>
#include <sysreg.h>
#include <21160.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"

#define SIZE (1024)
#define MAX_LOOPS 1000

#define STATUS_OK           0
#define STATUS_USER_ABORT   1
#define STATUS_TIMEOUT      2

#define SetIOP(addr, val)  *((volatile int *)(addr)) = (val)
#define GetIOP(addr)       *((volatile int *)(addr))

#ifndef FALSE
#define FALSE 0
#define TRUE (!FALSE)
#endif

#ifndef NULL
#define NULL (void *)0
#endif
/*------------------- Global Variables ----------------------------*/
// For 48 bit testing, use 40 bit float buffers in pm, which means 48 bit accesses
float segment ("seg_pm40") pm tx48_buf[SIZE];
float segment ("seg_pm40") pm rx48_buf[SIZE];

// For 32 bit word size testing, use int buffers in dm 
int tx32_buf[SIZE];
int rx32_buf[SIZE];

// Use globals for test settings
int link1 = 2;      // link1 for tx
int link2 = 3;		// link2 for rx
int num_loops_to_run = MAX_LOOPS;
int linkspeed = 0;		
int linkwidth = 8;
int wordsize = 32;
int current_num_loops = 0;
int done = 0;
int status;

/*------------------------ Status to host ------------------------*/
int errors[2][2][4];		// [Two wordsizes] x [two link widths] x [4 speeds] //
int total_error_count;

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int do_abort( void )
{
    if( status != STATUS_OK )
    {
        return( TRUE );
    }

	return(FALSE);
}


int test_links(int link1, int link2, int test_master, int linkspeed, int linkwidth, int wordsize)
{
 	int   i;
 	int test_errors;

	current_num_loops = 0;
	test_errors = 0;

    // Clear LAR.
    SetIOP( LAR, (GetIOP(LAR) | 0777777) );

    // 11/01/99 - rlh - use globals for test settings
	if(test_master)
	{
	    // We're the test master, we start the tx/rx loops and do the error checks 
	    do
	    {
	        current_num_loops++;	
	
			if (wordsize == 32)
			{
   			    /* init transmit and receive buffers */
      			for (i=0;i<SIZE;i++)
		        {
		            tx32_buf[i] = (i + current_num_loops);
		            rx32_buf[i] = 0xCAFEDEAD;
		        }

   	     	    /* transmit out link1 and receive on link2 */
		     	link_dma_xmt((int *) &tx32_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, FALSE, NULL);
		
		        /* receive buffer via link */
				link_dma_rcv((int *) &rx32_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL);

	            /* check for errors */
		 		for (i=0; i<SIZE; i++)
		        {
		            if( tx32_buf[i] != rx32_buf[i] )
		            {
              			test_errors++;
		            }
		        }
		   	}
			else		// wordsize is 48
			{
			    // Init buffers
		        for (i=0; i<SIZE; i++)
		        {
		            tx48_buf[i] = (float) (i + current_num_loops) * (float) (i + current_num_loops) * (float) (i + current_num_loops);
		            rx48_buf[i] = 0xCAFEDEAD;
		        }

	     	    /* transmit out link1 and receive on link2 */
		     	link_dma_xmt( (int *) &tx48_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, FALSE, NULL );
		
		        /* receive buffer via link */   
				link_dma_rcv( (int *) &rx48_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
	 
			    // Check for errors
  				for (i=0; i<SIZE; i++)
		        {
		            if( tx48_buf[i] != rx48_buf[i] )
		            {
		                test_errors++;
		            }
		        }
		 	}
	    } while( (current_num_loops < num_loops_to_run) && !do_abort() );
  	}
	else
	{
	    // We're the Rx, so we receive the tx's and send them back
	    do
	    {
	        current_num_loops++;
	
			if (wordsize == 32)
			{
			    /* init receive buffer */
		        for (i=0; i<SIZE; i++)
		        {
		            rx32_buf[i] = 0xbeef4a1e;
		        }

			    /* receive buffer via link */
			    link_dma_rcv((int *)&rx32_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
		
			    /* move rx'd data into tx buffer  */
		        for (i=0; i<SIZE; i++)
		        {
		            tx32_buf[i] =  rx32_buf[i];
		        }
		
		  	    /* transmit tx buffer out via link */
		        link_dma_xmt( (int *) &tx32_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, FALSE, NULL );
		  	}
			else	// we're doing 48 bit transfers
			{
		        for (i=0; i<SIZE; i++)
		        {
		            rx48_buf[i] = 0xfadeb1ac;
		        }
	       
			    /* receive buffer via link */
				link_dma_rcv( (int *) &rx48_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
		
		  	    /* move rx'd data into tx buffer  */
		        for (i=0; i<SIZE; i++)
		        {
		            tx48_buf[i] =  rx48_buf[i];
		        }
		
		        /* transmit tx buffer out via link */
		        link_dma_xmt( (int *) &tx48_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, FALSE, NULL );
			}
		} while( (current_num_loops < num_loops_to_run) && !do_abort() );
  	}
    return(test_errors);
}


/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void main(void)
{
    int i, j, l;
	int initiator;

	done = 0;
	initiator = 0;
	total_error_count = 0;

#ifdef TX_FIRST
	initiator = 1;
#endif

    asm( "#include <def21160.h>" );
    asm( "BIT SET MODE1 NESTM;" );
	asm( "bit set MODE2 FLG2O|FLG3O;" );
	asm( "bit clr FLAGS FLG3;" );

    // Turn on imdw0 and turn off rnd32 for the 48 bit tests
	SetIOP(SYSCON, GetIOP(SYSCON) | IMDW0);
	sysreg_bit_clr(sysreg_MODE1, RND32);

    SetIOP(SYSCON, GetIOP( SYSCON ) & 0xffffffcf);

    // 11/01/99 - rlh - use globals for test settings
    // Just use whatever link1 and link2 have been set to (either via the host or emulator)

		wordsize = 32;
		for (i=0; i < 2; i++)
		{
			linkwidth = 4;
			
			for (j=0; j<2; j++)
			{
				for (linkspeed = 0; linkspeed < 4; linkspeed++)
				{
					errors[i][j][linkspeed]
						= test_links(link1, link2, initiator, linkspeed, linkwidth, wordsize);
					total_error_count += errors[i][j][linkspeed];

				    // Delay between tests to let previous transfers complete
					for(l=0; l<(SIZE * 10); l++);
					asm("bit tgl FLAGS FLG2|FLG3;");
 				 }

				 linkwidth += 4;
			}
			wordsize += 16;
		}

	done = 1;
}

/**********************************************************/
/* End of file linkdualtest.c */
/**********************************************************/
