/*****************************************************************************\
*                                                                             *
*  SportTDM.c : Source for SHARC serial port TDM test.                        *
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
*     1.0      04/15/96 - Initial coding                                      *
*     2.0      05/17/99 - Standard test changed to test TDM mode              *
*	  3.0	rlh	11/11/99	Updated for Hammerhead PCI						  *
*                                                                             *
\*****************************************************************************/
#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include "sport.h"

/**********************************************************/
                                /* DMA Chain pointer bit definitions */
#define CP_PCI 0x80000          /* Program-Controlled Interrupts bit */
#define CP_MAF 0x1ffff          /* Valid memory address field bits   */

#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)

/**********************************************************/
#ifdef GENERATE
volatile int generate = 1;
#else
volatile int generate = 0;
#endif

int sport_to_test = 0;
int done = 0;
volatile int num_loops;
volatile int rx_loops;
volatile int tx_loops;
volatile int rx_done;
volatile int tx_done;
volatile int generate;
volatile int errors;

/* set up copies of sport defines to allow for easy select of sport 0 or 1 */
volatile struct __sport_structure *sport_iop;
int stctl, srctl, tx, rx, tdiv, tcnt, rdiv, rcnt, mtcs, mrcs, mtccs, mrccs, spath, spcnt;
int sig_spri, sig_spti, tcp, tgp, rcp, rgp;

/**********************************************************/

/* DMA chaining Transfer Control Blocks */
typedef struct {
   unsigned   lpath3;     /* for mesh mulitprocessing  */
   unsigned   lpath2;     /* for mesh multiprocessing  */
   unsigned   lpath1;     /* for mesh multiprocessing  */
   unsigned   db;         /* General purpose register  */
   unsigned   gp;         /* General purpose register  */
   unsigned** cp;         /* Chain Pointer to next TCB */
   unsigned   c;          /* Count register            */
   int        im;         /* Index modifier register   */
   unsigned * ii;         /* Index register            */
} _tcb;

int clkdiv = 3;
int fsdiv = 2000; //1023;  //Frame sync every (32 words * 32 bits) - 1
int mdf = 15;

#define MAX_LOOPS       1024
#define NUM_BUFS        2
#define BLK_SIZE        256
unsigned rx_buf[NUM_BUFS][BLK_SIZE];         /* receive buffer */
unsigned tx_buf[NUM_BUFS][BLK_SIZE];         /* transmit buffer */
unsigned data_buf[6][BLK_SIZE];       /* transmit data */
int error_buf[2][BLK_SIZE];       /* transmit data */

_tcb rx_tcb[2] = { {0, 0, 0, 0, 0, 0, BLK_SIZE, 1, 0},      /* receive tcb */
                   {0, 0, 0, 0, 0, 0, BLK_SIZE, 1, 0} };    /* receive tcb */
_tcb tx_tcb[2] = { {0, 0, 0, 0, 0, 0, BLK_SIZE, 1, 0},      /* transmit tcb */
                   {0, 0, 0, 0, 0, 0, BLK_SIZE, 1, 0} };    /* transmit tcb */


/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
/* Serial port transmit DMA complete */
void spt_asserted( int sig_num )
{
  int buf;
  int count;
  int dbuf;
  unsigned *tbptr, *rbptr, *dbptr;

  buf = GetIOP(tgp);
  tx_loops++;

  if(generate)
  {
    dbuf = (tx_loops-1) % 6;
	tbptr = (unsigned *) &tx_buf[buf];
    dbptr = (unsigned *) &data_buf[dbuf];
	for(count = 0; count < BLK_SIZE; count++)
	  *tbptr++ = *dbptr++;
  }
  else
  {
	tx_done = 1;
    if (tx_done && rx_done)
	{
      tx_done = 0;
	  rx_done = 0;

	  tbptr = (unsigned *) &tx_buf[buf];
	  rbptr = (unsigned *) &rx_buf[buf];
      for( count=0 ; count<BLK_SIZE ; count++ )
	  	*tbptr++ = *rbptr++;
	}
  }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
/* Serial port receive DMA complete */
/* (copies received data buffers to transmit data buffers) */
void spr_asserted( int sig_num )
{
  int buf;
  int count,count2;
  int dbuf;
  unsigned *tbptr, *rbptr;
  
  rx_loops++;

  buf = GetIOP(rgp);
  if( generate )
  {
	if (rx_loops > 4  && num_loops < MAX_LOOPS)  
	{
      num_loops++;
	  dbuf = (num_loops-1) % 6;
      for( count=0 ; count<BLK_SIZE ; count++ )
        if( rx_buf[buf][count] != (data_buf[dbuf][count]) )
		{
		  if(!errors)
		  {
            for(count2 = 0; count2 < BLK_SIZE; count2++)
			{
				error_buf[0][count2] = data_buf[dbuf][count2];
				error_buf[1][count2] = rx_buf[buf][count2];
			}
		  }
		  errors++;
		}
	}
  }
  else
  {
	if (rx_loops > 4  && num_loops < MAX_LOOPS + 1) num_loops++;
	rx_done = 1;
    if (tx_done && rx_done)
	{
      tx_done = 0;
	  rx_done = 0;

	  tbptr = (unsigned *) &tx_buf[buf];
	  rbptr = (unsigned *) &rx_buf[buf];
      for( count=0 ; count<BLK_SIZE ; count++ )
	  	*tbptr++ = *rbptr++;
	}
  }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void setup_sport( void )
{
	/* Turn off serial port */
	SetIOP(stctl, 0);
	SetIOP(srctl, 0);
	
	/* Set transmit frame sync and clock divisor. */
	sport_iop->rdiv.rckdiv = clkdiv;
	sport_iop->rdiv.rfsdiv = fsdiv;
	sport_iop->tdiv.tckdiv = clkdiv;
	sport_iop->tdiv.tfsdiv = fsdiv;
	
	/* Set Multi-Channel Stuff. */
	sport_iop->mrcs = (generate) ? 0xff00ff00 : 0x00ff00ff;
	sport_iop->mtcs = (generate) ? 0x00ff00ff : 0xff00ff00;
	sport_iop->mrccs = 0;
	sport_iop->mtccs = 0;
	
	/* RECEIVE CONTROL REGISTER */
	sport_iop->rxc.nch   = 31;   /* multichannel number of channels - 1  */
	sport_iop->rxc.spl   = 0;    /* Loop back configure (test)           */
	sport_iop->rxc.d2dma = 0;    /* Enable 2-dimensional DMA array       */
	sport_iop->rxc.schen = 1;    /* Rx DMA chaining enable               */
	sport_iop->rxc.sden  = 1;    /* Rx DMA enable                        */
	sport_iop->rxc.lafs  = 0;    /* Late RFS (alternate)                 */
	sport_iop->rxc.lrfs  = 0;    /* Active low RFS                       */
	sport_iop->rxc.irfs  = (generate) ? 1 : 0; /* Internally generated RFS */
	sport_iop->rxc.rfsr  = 1;    /* RFS Required                         */
	sport_iop->rxc.ckre  = 0;    /* Data and FS on clock rising edge     */
	sport_iop->rxc.gclk  = 0;    /* Enable clock only during transmission*/
	sport_iop->rxc.iclk  = (generate) ? 1 : 0; /* Internally generated Rx clock */
	sport_iop->rxc.pack  = 0;    /* Pack two 16b rx's into 32b word      */
	sport_iop->rxc.slen  = 31;   /* Data word length minus one           */
	sport_iop->rxc.sendn = 0;    /* Data word endian 1 = LSB first       */
	sport_iop->rxc.dtype = 0;    /* Data type specifier                  */
	sport_iop->rxc.spen  = 0;    /* Enable (clear for MC operation)      */
	
	/* TRANSMIT CONTROL REGISTER */
	sport_iop->txc.mdf   = mdf;    /* multichannel frame delay (MFD)     */
	sport_iop->txc.schen = 1;    /* Tx DMA chaining enable               */
	sport_iop->txc.sden  = 1;    /* Tx DMA enable                        */
	sport_iop->txc.lafs  = 0;    /* Late TFS (alternate)                 */
	sport_iop->txc.ltfs  = 0;    /* Active low TFS                       */
	sport_iop->txc.ditfs = 0;    /* Data independent TFS                 */
	sport_iop->txc.itfs  = 0;    /* Internally generated TFS             */
	sport_iop->txc.tfsr  = 1;    /* TFS Required                         */
	sport_iop->txc.ckre  = 0;    /* Data and FS on clock rising edge     */
	sport_iop->txc.gclk  = 0;    /* Enable clock only during transmission*/
	sport_iop->txc.iclk  = 0;    /* Internally generated Tx clock        */
	sport_iop->txc.pack  = 0;    /* Unpack 32b words into two 16b tx's   */
	sport_iop->txc.slen  = 31;   /* Data word length minus one           */
	sport_iop->txc.sendn = 0;    /* Data word endian 1 = LSB first       */
	sport_iop->txc.dtype = 0;    /* Data type specifier                  */
	sport_iop->txc.spen  = 0;    /* Enable (clear for MC operation)      */
	
	/* Enable sport xmit & rcv irqs */
	interrupts(sig_spri, spr_asserted);
	interrupts(sig_spti, spt_asserted);
	
	/* Set up Transmit Transfer Control Block for chained DMA */
	tx_tcb[0].ii = &tx_buf[0][0];    /* DMA source buffer address                */
	tx_tcb[1].ii = &tx_buf[1][0];    /* DMA source buffer address                */
	tx_tcb[0].gp = 1;
	tx_tcb[1].gp = 0;
	tx_tcb[0].cp = &tx_tcb[1].ii;/* define ptr to next TCB (point to self)   */
	tx_tcb[1].cp = &tx_tcb[0].ii;/* define ptr to next TCB (point to self)   */
	SetIOP(tcp, (((int)&tx_tcb[0].ii) & CP_MAF) | CP_PCI);
	                           /* define ptr to current TCB (kick off DMA) */
	
	/* Set up Receive Transfer Control Block for chained DMA */
	rx_tcb[0].ii = &rx_buf[0][0];    /* DMA destination buffer address           */
	rx_tcb[1].ii = &rx_buf[1][0];    /* DMA destination buffer address           */
	rx_tcb[0].gp = 1;
	rx_tcb[1].gp = 0;
	rx_tcb[0].cp = &rx_tcb[1].ii;/* define ptr to next TCB (point to self)   */
	rx_tcb[1].cp = &rx_tcb[0].ii;/* define ptr to next TCB (point to self)   */
	SetIOP(rcp, (((int)&rx_tcb[0].ii) & CP_MAF) | CP_PCI);
	                           /* define ptr to current TCB (kick off DMA) */
	
	// Set MCE last!!
	sport_iop->rxc.mce   = 1;    /* multichannel enable                  */
}

void select_sport (int sport) 
{
  switch (sport)
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
	int counter;
	
	/* Initialize data. */
	for(i = 0; i < 6; i++)
		data_buf[i][0] = i;
	
	for(i = 1; i < BLK_SIZE; i++)
	{
		data_buf[0][i] = 0xa5a5a5a5;
		data_buf[1][i] = 0xaaaaaaaa;
		data_buf[2][i] = 0x55555555;
		data_buf[3][i] = i;
		data_buf[4][i] = ~i;
		data_buf[5][i] = 0x5a5a5a5a;
	}
	
	for(i = 0; i < BLK_SIZE; i++)
	{
		if(generate)
		{
			tx_buf[0][i] = 0xbeefbeef;
			tx_buf[1][i] = 0xbeefbeef;
			rx_buf[0][i] = 0xdeaddead;
			rx_buf[1][i] = 0xdeaddead;
		}
		else
		{
			tx_buf[0][i] = 0xcabba6e5;
			tx_buf[1][i] = 0xcabba6e5;
			rx_buf[0][i] = 0x60babe60;
			rx_buf[1][i] = 0x60babe60;
		}
	}

	counter = 0;  
	errors = 0;
	num_loops = 0;
	rx_loops = 0;
	tx_loops = 0;
	rx_done = 0;
	tx_done = 0;
	
	asm("#include <def21160.h>");
	asm("bit set mode2 IRQ1E;"); /* make IRQ1 edge sensitive */
	asm("bit clr mode1 NESTM;"); /* disable interrupt nesting */
	
	/* Initialize SPORTS. */
	select_sport(sport_to_test);
	setup_sport();
	counter = (generate) ? MAX_LOOPS : MAX_LOOPS+1;  
	
	/* Wait for program completion */
	while(num_loops < counter)
	{
	}
	
	/* Turn off serial port. */
	//SetIOP(stctl, 0);
	//SetIOP(srctl, 0);
	
	done = 1;
}

/**********************************************************/
/* End of file SportTDM.c */
/**********************************************************/
