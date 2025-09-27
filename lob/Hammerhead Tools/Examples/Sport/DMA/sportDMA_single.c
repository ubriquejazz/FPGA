/*****************************************************************************\
*                                                                             *
*  SportDMA.c : Source for SHARC serial port DMA test.                        *
*                                                                             *
*  PROVIDED BY:                                                               *
*  ------------                                                               *
*  BittWare Research Systems, Inc.                                            *
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
*    Version   Changes                                                        *
*    --------  -------------------------------------------------------        *
*     1.0      04/15/96     Initial coding                                    *
*     2.0   rpc 06/16/00    Updated for Hammerhead PCI -- single processor,   *
*                           DMA to SDRAM and back, compare.                   *
*                                                                             *
\*****************************************************************************/

#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include "sport.h"

/**********************************************************/
#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

#define CLOCKSPD    (float) 40000000.0	// External Clock Rate
#define MAX_LOOPS       0x100
#define BLK_SIZE        128

/**********************************************************/
int err_log[MAX_LOOPS];
int rx_buf[BLK_SIZE];         /* receive buffer */
int tx_buf[BLK_SIZE];         /* transmit buffer */

#ifdef GENERATE
volatile int generate = 1;
#else
volatile int generate = 0;
#endif

int sport_to_test = 1;
volatile int errors;
volatile int num_loops;
volatile int tx_intr;
volatile int rx_intr;
volatile int cur_errs;
volatile int tx_time;
volatile int all_tx_time;
volatile int counter = MAX_LOOPS;

float DataRate;
int done;

/* set up copies of sport defines to allow for easy select of sport 0 or 1 */
volatile struct __sport_structure *sport_iop;
int stctl, srctl, tx, rx, tdiv, tcnt, rdiv, rcnt, mtcs, mrcs, mtccs, mrccs, spath, spcnt;
int sig_spri, sig_spti, tcp, tgp, rcp, rgp;

/* Make speed and frame sync globals so that we can play with them in the emulator */
int clkdiv = 0;  
int fsdiv = 31;  

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
/* Serial port transmit DMA complete */
void spt_asserted(int sig_num)
{
#ifdef GENERATE
   tx_time -= timer_off();		// Turn off timer and track time spent
   all_tx_time += tx_time;
   tx_intr++;
#endif
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
/* Serial port receive DMA complete */
void spr_asserted(int sig_num)
{
  int i;

  rx_intr++;

  if(generate)
  {
     cur_errs = 0;
     for(i = 0; i < BLK_SIZE; i++)
	 {
	   if(rx_buf[i] != tx_buf[i])
 	   {
	     cur_errs++;
	   }
	   tx_buf[i] += 5;
	 }
	 errors += cur_errs;
     err_log[rx_intr-1] = cur_errs;  // this logs the block error count
	 //err_log[rx_intr-1] = rx_buf[0];  // this logs the first rx data item
  }
  else
  {
    for(i = 0; i < BLK_SIZE; i++)
    {
      tx_buf[i] = rx_buf[i];
    }
  }

  sport_iop->rxc.spen = 0;  // Disable SPORT receive
  sport_iop->rxc.sden = 0;  // Disable receive DMA    
  SetIOP(II1, (int)rx_buf); // Load address of data to receive
  SetIOP(IM1, 1);           // Load stride
  SetIOP(C1, BLK_SIZE);     // Load word count
  sport_iop->rxc.sden = 1;  // Enable receive DMA
  
  sport_iop->txc.spen = 0;  // Disable SPORT transmit
  sport_iop->txc.sden = 0;  // Disable transmit DMA
  SetIOP(II3, (int)tx_buf); // Load address of data to xmit
  SetIOP(IM3, 1);           // Load stride
  SetIOP(C3, BLK_SIZE);     // Load word count
  sport_iop->txc.sden = 1;  // Enable transmit DMA

  if(++num_loops < counter)
  {
#ifdef GENERATE
  	  timer_set(0x1FFFFF, 0x1FFFFF); // Set and turn on timer to track tx time
      tx_time = timer_on();
#endif
	  sport_iop->rxc.spen = 1;       // Enable SPORT receive
	  sport_iop->txc.spen = 1;       // Enable SPORT transmit
  }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void setup_sport(void)
{
	/* Turn off serial port */
	SetIOP(stctl, 0);
	SetIOP(srctl, 0);
	
	/* Set transmit frame sync and clock divisor. */
	SetIOP(tdiv, ((fsdiv<<16) & 0xffff0000)+(clkdiv & 0x0000fff));
	SetIOP(rdiv, ((fsdiv<<16) & 0xffff0000)+(clkdiv & 0x0000fff));
	
	/* Clear Multi-Channel Stuff. */
	SetIOP(mrcs,  0);
	SetIOP(mrccs, 0);
	SetIOP(mtcs,  0);
	SetIOP(mtccs, 0);
	
	/* RECEIVE CONTROL REGISTER */
	sport_iop->rxc.nch   = 0;    /* multichannel number of channels - 1  */
	sport_iop->rxc.mce   = 0;    /* multichannel enable                  */
	sport_iop->rxc.spl   = 0;    /* Loop back configure (test)           */
	sport_iop->rxc.d2dma = 0;    /* Enable 2-dimensional DMA array       */
	sport_iop->rxc.schen = 0;    /* Rx DMA chaining enable               */
	sport_iop->rxc.sden  = 0;    /* Rx DMA enable                        */
	sport_iop->rxc.lafs  = 0;    /* Late RFS (alternate)                 */
	sport_iop->rxc.ltfs  = 0;    /* Active low RFS                       */
	sport_iop->rxc.irfs  = 0;    /* Internally generated RFS             */
	sport_iop->rxc.rfsr  = 1;    /* RFS Required                         */
	sport_iop->rxc.ckre  = 0;    /* Data and FS on clock rising edge     */
	sport_iop->rxc.gclk  = 0;    /* Enable clock only during transmission*/
	sport_iop->rxc.iclk  = 0;    /* Internally generated Rx clock        */
	sport_iop->rxc.pack  = 0;    /* Pack two 16b rx's into 32b word      */
	sport_iop->rxc.slen  = 31;   /* Data word length minus one           */
	sport_iop->rxc.sendn = 0;    /* Data word endian 1 = LSB first       */
	sport_iop->rxc.dtype = 0;    /* Data type specifier                  */
	sport_iop->rxc.spen  = 1;    /* Enable (clear for MC operation)      */
	
	/* TRANSMIT CONTROL REGISTER */
	sport_iop->txc.mdf   = 0;    /* multichannel frame delay (MFD)       */
	sport_iop->txc.schen = 0;    /* Tx DMA chaining enable               */
	sport_iop->txc.sden  = 0;    /* Tx DMA enable                        */
	sport_iop->txc.lafs  = 0;    /* Late TFS (alternate)                 */
	sport_iop->txc.ltfs  = 0;    /* Active low TFS                       */
	sport_iop->txc.ditfs = 0;    /* Data independent TFS                 */
	sport_iop->txc.itfs  = 1;    /* Internally generated TFS             */
	sport_iop->txc.tfsr  = 1;    /* TFS Required                         */
	sport_iop->txc.ckre  = 0;    /* Data and FS on clock rising edge     */
	sport_iop->txc.gclk  = 0;    /* Enable clock only during transmission*/
	sport_iop->txc.iclk  = 1;    /* Internally generated Tx clock        */
	sport_iop->txc.pack  = 0;    /* Unpack 32b words into two 16b tx's   */
	sport_iop->txc.slen  = 31;   /* Data word length minus one           */
	sport_iop->txc.sendn = 0;    /* Data word endian 1 = LSB first       */
	sport_iop->txc.dtype = 0;    /* Data type specifier                  */
	sport_iop->txc.spen  = 1;    /* Enable (clear for MC operation)      */
	
	SetIOP(II3, (int)tx_buf);     // Load address of data to xmit
	SetIOP(IM3, 1);           // Load stride
	SetIOP(C3, BLK_SIZE);     // Load word count
	
	SetIOP(II1, (int)rx_buf);     // Load address of data to receive
	SetIOP(IM1, 1);           // Load stride
	SetIOP(C1, BLK_SIZE);     // Load word count
	
	if(generate)
	{
	    timer_set(0x1FFFFF, 0x1FFFFF);		// Turn on timer to track tx time
	    tx_time = timer_on();
	    sport_iop->txc.sden = 1;  // Enable the first DMA transmit
	    sport_iop->rxc.sden = 1;  // Enable the first DMA receive
	}
	else
	{
	    sport_iop->rxc.sden = 1;  // Enable the first DMA receive
	}
	
	/* Enable sport xmit & rcv irqs */
	interruptf(sig_spri, spr_asserted);
	interruptf(sig_spti, spt_asserted); 
}

void select_sport(int sport) 
{
  switch(sport)
  {
    case 0:
      stctl		= STCTL0;
      srctl		= SRCTL0;
      tx		= TX0;
      rx		= RX0;
      tdiv		= TDIV0;
      tcnt		= TCNT0;
      rdiv		= RDIV0;
      rcnt		= RCNT0;
	  mtcs		= MTCS0;
      mrcs		= MRCS0;
      mtccs		= MTCCS0;
      mrccs		= MRCCS0;
      spath		= SPATH0;
      spcnt		= SPCNT0;
      sig_spri  = SIG_SPR0I;
      sig_spti	= SIG_SPT0I;
      tcp		= CP2;
      tgp       = GP2;
      rcp		= CP0;
	  rgp		= GP0;
      sport_iop = &sport0_iop;
	  break;
    case 1:
      stctl		= STCTL1;
      srctl		= SRCTL1;
      tx		= TX1;
      rx		= RX1;
      tdiv		= TDIV1;
      tcnt		= TCNT1;
      rdiv		= RDIV1;
      rcnt		= RCNT1;
	  mtcs		= MTCS1;
      mrcs		= MRCS1;
      mtccs		= MTCCS1;
      mrccs		= MRCCS1;
      spath		= SPATH1;
      spcnt		= SPCNT1;
      sig_spri  = SIG_SPR1I;
      sig_spti	= SIG_SPT1I;
      tcp		= CP3;
      tgp       = GP3;
      rcp		= CP1;
	  rgp		= GP1;
      sport_iop = &sport1_iop;
      break;
    default:
      break;
  }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void main(void)
{
    int i;

	/* Initialize data. */
	for(i = 0 ; i < BLK_SIZE; i++)
	{
		if(generate) 
		{
			tx_buf[i] = i;
			rx_buf[i] = 0xcabba6e5;
		}
		else 
		{
			tx_buf[i] = 0xdeaddead;
			rx_buf[i] = 0xbeefbeef;
		}
	}
	
	if(generate) // waste some time
	{
	    for(i = 0; i < 1000000; i++)
		    asm("nop;");
	}

	num_loops = 0;  
	errors = 0;
	rx_intr = 0;
	tx_intr = 0;
	done = 0;
	tx_time = 0;
	all_tx_time = 0;
	DataRate = 0.0;
	
	/* Initialize SPORTS. */
	select_sport(sport_to_test);
	setup_sport();

	if(generate)
	{
		while(tx_intr < MAX_LOOPS)
		{
		    idle();
		}

		DataRate = (float) (MAX_LOOPS * BLK_SIZE * 32) / ((float) all_tx_time / (CLOCKSPD *2));
	}
    else
	{
		while(rx_intr < MAX_LOOPS)
		{
		    idle();
		}
	}

	done = 1;
}

/**********************************************************/
/* End of file SportDMA.c */
/**********************************************************/
