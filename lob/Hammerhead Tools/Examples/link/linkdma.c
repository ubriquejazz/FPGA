/*****************************************************************************\
*                                                                             
*  linkdma.c : Source for link port transfer functions/utilities for Hammerhead                          
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
*                                                                             
\*****************************************************************************/
#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include "linkdma.h"

#ifndef SetIOP
#define SetIOP(addr, val)  *((volatile int *)(addr)) = (val)
#define GetIOP(addr)       *((volatile int *)(addr))
#endif

#ifndef FALSE
   #define FALSE 0
   #define TRUE (!FALSE)
#endif

#ifndef NULL
   #define NULL 0L
#endif


// Link DMA status table and registers
int link_dma_done_status[6]   = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
int link_dma_index_offset[6]  = {II4,   II5,   II6,   II7,   II8,   II9};
int link_dma_stride_offset[6] = {IM4,   IM5,   IM6,   IM7,   IM8,   IM9};
int link_dma_length_offset[6] = {C4,    C5,    C6,    C7,    C8,    C9};
int link_dma_stat_bit[6]      = {0x10,  0x20,  0x40,  0x80,  0x100, 0x200};

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void LP0I_handler (int id)
{
    link_dma_done_status[0] = TRUE;
}

void LP1I_handler (int id)
{
    link_dma_done_status[1] = TRUE;
}

void LP2I_handler (int id)
{
    link_dma_done_status[2] = TRUE;
}

void LP3I_handler (int id)
{
    link_dma_done_status[3] = TRUE;
}

void LP4I_handler (int id)
{
    link_dma_done_status[4] = TRUE;
}

void LP5I_handler (int id)
{
    link_dma_done_status[5] = TRUE;
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void set_dma_interrupt(int lbuf)
{
    switch(lbuf)
    {
      case 0:
        interrupt(SIG_LP0I, LP0I_handler);
        break;
      case 1:
        interrupt(SIG_LP1I, LP1I_handler);
        break;
      case 2:
        interrupt(SIG_LP2I, LP2I_handler);
        break;
      case 3:
        interrupt(SIG_LP3I, LP3I_handler);
        break;
      case 4:
        interrupt(SIG_LP4I, LP4I_handler);
        break;
      case 5:
        interrupt(SIG_LP5I, LP5I_handler);
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
int link_dma_done(int lbuf)
{
    return(link_dma_done_status[lbuf]);
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_xmt(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()))
{
    int temp;
	unsigned int lctlx;
	unsigned int speed_mask;
	unsigned int ctlbits;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable transmit channel and clear all settings */
  	SetIOP(lctlx, GetIOP(lctlx) & ~(0x3ff << ((10*lbuf)%30)));

    temp = GetIOP(LAR);        /* Update Link Assigment Register with new map */
    temp &= ~(7 << (3 * lbuf));
    temp |= (link << (3 * lbuf));      /* Map link buffer to tx link port */    
	SetIOP(LAR, temp);         /* Update Link Assigment Register with new map */
  
    speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask));  

   	// Use 8 bit link port width unless specified for 4 bit
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));
   
    // Enable interrupt.
    set_dma_interrupt(lbuf);

    /* clear completion flag */
    link_dma_done_status[lbuf] = FALSE;

    /* set transmit parms */
    SetIOP(link_dma_index_offset[lbuf],  (int)buf); /* Index  */
    SetIOP(link_dma_stride_offset[lbuf], stride);   /* stride */
    SetIOP(link_dma_length_offset[lbuf], buflen);   /* length (down-counter) */

	/* Enable channel */
    /* Set ctl for word size, Tx, no chain, DMA, and lbuf enable */
    ctlbits = (bit_width == 48) ? 0x1b : 0x0b;

	SetIOP(lctlx, GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30)));
 
    /* wait for xfer to complete */
    if(wait)
    {
        if(abort_func == NULL)
        {
            while(!link_dma_done(lbuf))
                ;
        }
        else
        {            
            while((!link_dma_done(lbuf)) && !(abort_func()))
			    ;        
		}
    }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_rcv(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()))
{
    int temp;
	unsigned int lctlx;
	unsigned int speed_mask;
	unsigned int ctlbits;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable receive channel */
    SetIOP(lctlx, GetIOP(lctlx) & ~(0x3FF << ((10*lbuf) % 30)));

    temp = GetIOP(LAR);        /* Update Link Assigment Register with new map */
    temp &= ~(7 << (3 * lbuf));
    temp |= (link << (3 * lbuf));      /* Map link buffer to rx link port */
    SetIOP(LAR, temp);         /* Update Link Assigment Register with new map */

	speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask)); 
 
	// Use 8 bit link port width unless specified for 4 bit
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));
   
    // Enable interrupt.
    set_dma_interrupt(lbuf);

    /* clear completion flag */
    link_dma_done_status[lbuf] = FALSE;

    /* set parms */
    SetIOP(link_dma_index_offset[lbuf],  (int)buf); /* Index  */
    SetIOP(link_dma_stride_offset[lbuf], stride);   /*  */
    SetIOP(link_dma_length_offset[lbuf], buflen);   /* length (down-counter) */

   /* Enable channel */
   /* Set ctl for word size, Rx, no chain, DMA, and lbuf enable */
    ctlbits = (bit_width == 48) ? 0x13 : 0x03;

	SetIOP(lctlx, GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30)));
 
    /* wait for receive to complete */
    if(wait)
    {
        while(!link_dma_done(lbuf))
		    ;
    }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int link_dma_noint_done(int lbuf)
{
    return((GetIOP(DMASTAT) & link_dma_stat_bit[lbuf]) == 0);
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_noint_xmt(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()))
{
    int temp;
	unsigned int lctlx;
	unsigned int speed_mask;
	unsigned int ctlbits;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable transmit channel and clear all settings */
  	SetIOP(lctlx, GetIOP(lctlx) & ~(0x3ff << ((10*lbuf)%30)));

    temp = GetIOP(LAR);        /* Update Link Assigment Register with new map */
    temp &= ~(7 << (3 * lbuf));
    temp |= (link << (3 * lbuf));      /* Map link buffer to tx link port */
    SetIOP(LAR, temp);         /* Update Link Assigment Register with new map */
  
    speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask));  

   	// Use 8 bit link port width unless specified for 4 bit 
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));
   
    /* set transmit parms */
    SetIOP(link_dma_index_offset[lbuf],  (int)buf); /* Index  */
    SetIOP(link_dma_stride_offset[lbuf], stride); /* stride */
    SetIOP(link_dma_length_offset[lbuf], buflen); /* length (down-counter) */

	/* Enable channel */
    /* Set ctl for word size, Tx, no chain, DMA, and lbuf enable */

	ctlbits = (bit_width == 48) ? 0x1b : 0x0b;

	SetIOP(lctlx, (GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30))));
 
    /* wait for xfer to complete */
    if(wait)
    {
        if(abort_func == NULL)
        {
            while(!link_dma_noint_done(lbuf))
            {    
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
            }
        }
        else
        {            
            while((!link_dma_noint_done(lbuf)) && !(abort_func()))
            {    
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
            }
        }
    }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_noint_rcv(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()))
{
    int temp;
	unsigned int lctlx;
	unsigned int speed_mask;
	unsigned int ctlbits;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable receive channel */
    SetIOP(lctlx, GetIOP(lctlx) & ~(0x3FF << ((10*lbuf) % 30)));

    temp = GetIOP(LAR);        /* Update Link Assigment Register with new map */
    temp &= ~(7 << (3 * lbuf));
    temp |= (link << (3 * lbuf));      /* Map link buffer to rx link port */
    SetIOP(LAR, temp);         /* Update Link Assigment Register with new map */

	speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask)); 
 
	// Use 8 bit link port width unless specified for 4 bit
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));
   
    /* set parms */
    SetIOP(link_dma_index_offset[lbuf],  (int)buf); /* Index  */
    SetIOP(link_dma_stride_offset[lbuf], stride); /* stride */
    SetIOP(link_dma_length_offset[lbuf], buflen); /* length (down-counter) */

   /* Enable channel */
    /* Set ctl for word size, Rx, no chain, DMA, and lbuf enable */
    ctlbits = (bit_width == 48) ? 0x13 : 0x03;

	SetIOP(lctlx, GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30)));
 
    /* wait for xfer to complete */
    if(wait)
    {
        if(abort_func == NULL)
        {
            while(!link_dma_noint_done(lbuf))
            {    
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
            }
        }
        else
        {            
            while((!link_dma_noint_done(lbuf)) && !(abort_func()))
            {    
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
                asm("NOP;");
            }
        }
    }
}


/**********************************************************/

/* End of file linkdma.c */

/**********************************************************/
