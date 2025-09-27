/*****************************************************************************\
*                                                                             *
*  sportest.c : Source for Hammerhead polled serial port test.                *
*                                                                             *
*  PROVIDED BY:                                                               *
*  ------------                                                               *
*  BittWare Research Systems, Inc.                                            *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Tel: 800-848-0435 (US/Canada)                                              *
*  Tel: 603-226-0404 (International)                                          *
*  Fax: 603-226-6667                                                          *
*  BBS: 603-226-6668                                                          *
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
*     1.0      04/15/96 - Initial coding                                      *
*     2.0      06/14/00 - rpc - Upgrade for Hammerhead
*                                                                             *
\*****************************************************************************/

/* ADSP-21060 System Register bit definitions */

#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include "sport.h"

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif
/**********************************************************/

#define PROC_CLOCK_FREQ 80000000

/* Slow enough to see count go up. */

#define S_CLOCK_FREQ      320000
#define FS_FREQ            10000

int clkdiv = 15;
int fsdiv = 31;
int sport_to_test = 1;
int done = 0;

/**********************************************************/

#define MAX_LOOPS (6 * 1024)

volatile int tbuf;
volatile int rbuf;
volatile int num_loops;
volatile int errors;

/* set up copies of sport defines to allow for easy select of sport 0 or 1 */
volatile struct __sport_structure *sport_iop;
int stctl, srctl, tx, rx, tdiv, tcnt, rdiv, rcnt, mtcs, mrcs, mtccs, mrccs, spath, spcnt;
int sig_spri, sig_spti, tcp, tgp, rcp, rgp;


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
  SetIOP(tdiv, ((fsdiv<<16) & 0xffff0000)+(clkdiv & 0x0000fff) );
  SetIOP(rdiv, ((fsdiv<<16) & 0xffff0000)+(clkdiv & 0x0000fff) );

  /* Clear Multi-Channel Stuff. */
  SetIOP(mrcs, 0);
  SetIOP(mrccs, 0);
  SetIOP(mtcs, 0);
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

}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void select_sport (int sport) 
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
    SetIOP(SYSCON, GetIOP(SYSCON) & ~0x0800);

    /* Initialize SPORT */
    select_sport(sport_to_test);
    setup_sport();

#ifdef XMT_FIRST

    num_loops = 0;
    errors = 0;

    do
    {
      /* Prepare data. */
      rbuf = 0xdeadcafe;
      switch( (num_loops * 6) / MAX_LOOPS )
      {
        case( 0 ):
          /* Walk a one. */
          tbuf  = 0x00000001 << (num_loops % 32);
          break;
        case( 1 ):
          /* Walk a zero. */
          tbuf  = ~( 0x00000001 << (num_loops % 32) );
          break;
        case( 2 ):
          /* As / 5s. */
          tbuf  = (num_loops % 2) ? 0xAAAAAAAA : 0x55555555;
          break;
        case( 3 ):
          /* 5As. */
          tbuf  = (num_loops % 2) ? 0x5A5A5A5A : 0xA5A5A5A5;
          break;
        case( 4 ):
          /* Self-address complement */
          tbuf  = ( ( (num_loops) << 16 ) & 0xffff0000) + ((~num_loops) & 0x0000ffff);
          break;
        default:
          /* Self-address */
          tbuf  = ( ( (~num_loops) << 16 ) & 0xffff0000) + ((num_loops) & 0x0000ffff);
          break;
      }
  
      /* Wait for transmit buffer to empty. */
        while(GetIOP(stctl) & 0xC0000000)
	        ;

		/* Transmit. */
	    SetIOP(tx, tbuf);
	    
		/* Wait for receive buffer to have something. */
		while((GetIOP(srctl) & 0xC0000000) == 0)
		    ;
		
		/* Receive. */
		rbuf = GetIOP(rx);
		
		/* Check */
		if(tbuf != rbuf)
		{
		    errors++;
		}

    }while(++num_loops < MAX_LOOPS);
  
#else

    for(num_loops = 0; num_loops < MAX_LOOPS; num_loops++)
    {
      /* Wait for receive buffer to have something. */
      while((GetIOP(srctl) & 0xC0000000) == 0)
	      ;

      /* Receive. */
      rbuf = GetIOP(rx);

      /* Wait for transmit buffer to empty. */
      while(GetIOP(stctl) & 0xC0000000);

      /* Transmit. */
      SetIOP(tx, rbuf);
    }

#endif

    done = 1;
}

/**********************************************************/
/* End of file sportest.c */
/**********************************************************/
