/*****************************************************************************
*  linkpt2pttest.c : Source for point-to-point Link Test for Hammerhead                          
*                                                                             
*		This test is to verify transfers between link ports on the Hammerhead.
*       The link traffic is transmitted on link port (global link_to_use), and       
*       received on the same link.  This allows the transfers to nvolve numerous 
*       processors, as long as each pair shares at least one link connection.   
*
*       Note that this test is useful for testing external link ports connections 
*       on the same board, or on different DSP boards.                       
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
*	1.0		rpc		7/10/00		Create for Hammerhead             
*	1.1		rpc		7/25/01		Cleanup            
*
*****************************************************************************/
#include <def21160.h>
#include <sysreg.h>
#include <21160.h>
#include <signal.h>
#include <macros.h>
#include "linkdma.h"
asm( "#include <def21160.h>" );

#define SIZE 2048

#define MAX_LOOPS 250

// Assume a 40 MHz clock.
#define CLOCK_RATE 40000000

#define STATUS_OK           0
#define STATUS_USER_ABORT   1
#define STATUS_TIMEOUT      2

// Timeout if test not complete in 15 seconds.
#define MAX_MILLISECONDS 60000

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

#ifndef FALSE
#define FALSE 0
#define TRUE (!FALSE)
#endif

/*------------------- Global Variables ----------------------------*/


// For 48 bit testing, use 40 bit float buffers in pm, which means 48 bit accesses

float segment ("seg_pm40") pm tx48_buf[SIZE];
float segment ("seg_pm40") pm rx48_buf[SIZE];


// For 32 bit word size testing, use int buffers in dm 

int tx32_buf[SIZE];
int rx32_buf[SIZE];

// Use globals for test settings
#ifdef MASTER
int link1 = 2;
int link2 = 2;
#else
int link1 = 4;
int link2 = 4;
#endif

// Test control bits; clearing a bit disables the corresponding test.
//  Link port width:     nibble  byte
int link_width_enable[2] = {1,    1};
//  Data item size:      32bit  48bit
int data_size_enable[2] = {1,     1};
//  Link clock speed: CCLK/4  CCLK  CCLK/2 CCLK/3            
int speed_enable[4]   = {1,     1,     1,     1};

int linkspeed;
int wordsize;
int linkwidth;
int test_count = 0;
int middle_proc = 0; // Used to setup a long test chain
volatile int timer_interrupt_count;
int status;

/*------------------------ Status to host */
int errors[2][2][4];		// (Two wordsizes) x (two link widths) x (4 speeds)
int total_error_count;

int num_loops_to_run = MAX_LOOPS;
int current_num_loops=0;
int done;

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

    if( timer_interrupt_count > MAX_MILLISECONDS )
    {
        status = STATUS_TIMEOUT;
        return( TRUE );
    }

    return( FALSE );
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int test_links(int link1, int link2, int test_master, int linkspeed, int linkwidth, int wordsize)
{
 	int   i;
 	int test_errors;

	current_num_loops = 0;
	test_errors = 0;


    // Clear LAR.
    SetIOP( LAR, (GetIOP(LAR) | 0777777) );

 	if (test_master)
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
		            tx32_buf[i] = i+1; //(i + current_num_loops);
		            rx32_buf[i] = 0xCAFEDEAD;
		        }

   	     	/* transmit on link1 */	
		     	link_dma_xmt( (int *) &tx32_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
		
		    /* receive on link2 */	        
				link_dma_rcv( (int *) &rx32_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
	 
	        /* check for errors; deliberately skip buf[0] */
		 		for (i=1;i<SIZE;i++)
		        {
		            if(tx32_buf[i] != rx32_buf[i])
		            {
              			test_errors++;
		            }
		        }
		   	}
			else // wordsize is 48
			{
			// Init buffers
		        for (i=0;i<SIZE;i++)
		        {
		            tx48_buf[i] = (float) (i + current_num_loops) * (float) (i + current_num_loops) * (float) (i + current_num_loops);
		            rx48_buf[i] = 0xCAFEDEAD;
		        }

	     	/* transmit on link1 */
		     	link_dma_xmt((int *) &tx48_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL);
		
		    /* receive on link2 */  
				link_dma_rcv((int *) &rx48_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL);

	        /* check for errors; deliberately skip buf[0] */
  				for (i=1;i<SIZE;i++)
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
	// We're the slave, so we receive the tx's and send them back
	    do
	    {
	        current_num_loops++;
	
			if (wordsize == 32)
			{

			/* init receive buffer */
		      for (i=0;i<SIZE;i++)
			  {
		         rx32_buf[i] = 0xbeef4a1e;
		      }

			/* receive buffer via link1 */	
			  link_dma_rcv( (int *) &rx32_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
		
			/* move rx'd data into tx buffer  */
		
		      for (i=0;i<SIZE;i++)
			  {
		        tx32_buf[i] =  rx32_buf[i];
			  }
		
		  	/* transmit tx buffer out via link2 */
		      link_dma_xmt( (int *) &tx32_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );

			  if(middle_proc) // if this processor is in the middle of a link chain
			  {
				  /* init receive buffer */
			      for (i=0;i<SIZE;i++)
				  {
			         rx32_buf[i] = 0xbeef4a1e;
			      }
				/* receive buffer via link2 */	
				  link_dma_rcv( (int *) &rx32_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
			
				/* move rx'd data into tx buffer  */
			
			      for (i=0;i<SIZE;i++)
				  {
			        tx32_buf[i] =  rx32_buf[i];
				  }
			
			  	/* transmit tx buffer out via link1 */
			      link_dma_xmt( (int *) &tx32_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
			  }
		  	}
			else	// we're doing 48 bit transfers
			{
		        for (i=0;i<SIZE;i++)
		        {
		            rx48_buf[i] = 0xfadeb1ac;
		        }
	       
			/* receive buffer via link1 */		
				link_dma_rcv((int *) &rx48_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
		
		  	/* move rx'd data into tx buffer  */		
		        for (i=0;i<SIZE;i++)
		        {
		            tx48_buf[i] =  rx48_buf[i];
		        }
		
		       /* transmit tx buffer out via link2 */		
		        link_dma_xmt((int *) &tx48_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );

				if(middle_proc) // if this processor is in the middle of a link chain
				{
			        for (i=0;i<SIZE;i++)
			        {
			            rx48_buf[i] = 0xfadeb1ac;
			        }
	       
				/* receive buffer via link2 */		
					link_dma_rcv((int *) &rx48_buf[0], SIZE, link2, link2, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
			
			  	/* move rx'd data into tx buffer  */		
			        for (i=0;i<SIZE;i++)
			        {
			            tx48_buf[i] =  rx48_buf[i];
			        }
			
			       /* transmit tx buffer out via link1 */		
			        link_dma_xmt((int *) &tx48_buf[0], SIZE, link1, link1, linkspeed, linkwidth, wordsize, 1, TRUE, NULL );
				}
			}
		} while( (current_num_loops < num_loops_to_run) && !do_abort() );
  	}

  return( test_errors );
}



/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int main( int argc, char * argv[] )
{
    int i,j;
	int master = 0;

	done = 0;
	total_error_count = 0;

#ifdef MASTER
	master = 1;
#endif

   asm( "BIT SET MODE1 NESTM;" );

   // Make  blinking LEDs
   asm("bit set mode2 FLG2O|FLG3O;");			
   asm("bit set FLAGS FLG2;");
   asm("bit clr FLAGS FLG3;");

    // Turn on imdw0 and turn off rnd32 for the 48 bit tests
	SetIOP( SYSCON, GetIOP(SYSCON) | IMDW0);
	sysreg_bit_clr(sysreg_MODE1,RND32);
    SetIOP( SYSCON, GetIOP( SYSCON ) & 0xffffffcf );

    // Run the set of tests described in the test enables
        wordsize = 32;
		for (i = 0; i < 2; i++)
		{			
		    linkwidth = 4;
			for (j = 0; j < 2; j++)
			{
				for (linkspeed = 0; linkspeed < 4; linkspeed++)
				{
					if(data_size_enable[i] && link_width_enable[j] && speed_enable[linkspeed])
					{
			            asm("bit tgl FLAGS FLG2|FLG3;");  // toggle FLG2 & FLG3
						errors[i][j][linkspeed]
							= test_links(link1, link2, master, linkspeed, linkwidth, wordsize);
						total_error_count += errors[i][j][linkspeed];
						test_count++;
					}

 				 } // linkspeed
				 linkwidth += 4;
			} // j
			wordsize += 16;
		} // i

	done = 1;
	return(total_error_count);
}



/**********************************************************/

/* End of file linktest.c */

/**********************************************************/
