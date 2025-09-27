/*------------------- Preprocessor Statements ---------------------*/

#include <def21160.h>
#include <21160.h>

asm( "#include <def21160.h>" );

#include <signal.h>
//#include <sport.h>
#include <macros.h>
#include "linkdma.h"
#include "sharc_fin.h"

#define FLAG_SYNC 0

#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)

#ifndef FALSE
   #define FALSE 0
   #define TRUE (!FALSE)
#endif

#ifndef NULL
   #define NULL 0L
#endif

extern volatile int flag_reg;
extern int *ms2_ptr;

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int link_dma_done_status[6] = { FALSE, FALSE, FALSE, FALSE, FALSE, FALSE };
int link_dma_index_offset[6]  = { II4, II5, II6, II7, II8, II9 };
int link_dma_stride_offset[6] = { IM4, IM5, IM6, IM7, IM8, IM9 };
int link_dma_length_offset[6] = {  C4,  C5,  C6,  C7,  C8,  C9 };
int link_dma_stat_bit[6] = { 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020 };

void disable_channel(int lbuf)
{
	unsigned int	lctlx;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable channel */
    asm("NOP;");
    asm("BIT CLR MODE1 IRPTEN;");
    asm("NOP;");
    SetIOP(lctlx, GetIOP(lctlx) & ~(0x3f << ((10*lbuf)%30)));
    asm("NOP;");
    asm("BIT SET MODE1 IRPTEN;");
    asm("NOP;");
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void LP0I_handler ( int id )
{
    int lbuf = 0;

    link_dma_done_status[lbuf] = TRUE;

    // Disable interrupt
    interrupt( SIG_LP0I, SIG_IGN );

	disable_channel(lbuf);
}

void LP1I_handler ( int id )
{
    int lbuf = 1;

    link_dma_done_status[lbuf] = TRUE;
    // Disable interrupt
    interrupt( SIG_LP1I, SIG_IGN );

	disable_channel(lbuf);
}

void LP2I_handler ( int id )
{
    int lbuf = 2;

    link_dma_done_status[lbuf] = TRUE;

    // Disable interrupt
    interrupt( SIG_LP2I, SIG_IGN );

	disable_channel(lbuf);
}

void LP3I_handler ( int id )
{
    int lbuf = 3;

    link_dma_done_status[lbuf] = TRUE;

    // Disable interrupt
    interrupt( SIG_LP3I, SIG_IGN );

	disable_channel(lbuf);
}

void LP4I_handler ( int id )
{
    int lbuf = 4;

    link_dma_done_status[lbuf] = TRUE;

    // Disable interrupt
    interrupt( SIG_LP4I, SIG_IGN );

	disable_channel(lbuf);
}

void LP5I_handler ( int id )
{
    int lbuf = 5;

    link_dma_done_status[lbuf] = TRUE;

    // Disable interrupt
    interrupt( SIG_LP5I, SIG_IGN );

	disable_channel(lbuf);
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void set_dma_interrupt( int lbuf )
{
    switch( lbuf )
    {
      case 0:
        interrupt( SIG_LP0I, LP0I_handler );
        break;
      case 1:
        interrupt( SIG_LP1I, LP1I_handler );
        break;
      case 2:
        interrupt( SIG_LP2I, LP2I_handler );
        break;
      case 3:
        interrupt( SIG_LP3I, LP3I_handler );
        break;
      case 4:
        interrupt( SIG_LP4I, LP4I_handler );
        break;
      case 5:
        interrupt( SIG_LP5I, LP5I_handler );
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
void clear_dma_interrupt( int lbuf )
{
    switch( lbuf )
    {
      case 0:
        interrupt( SIG_LP0I, SIG_IGN );
        break;
      case 1:
        interrupt( SIG_LP1I, SIG_IGN );
        break;
      case 2:
        interrupt( SIG_LP2I,  SIG_IGN );
        break;
      case 3:
        interrupt( SIG_LP3I,  SIG_IGN );
        break;
      case 4:
        interrupt( SIG_LP4I,  SIG_IGN );
        break;
      case 5:
        interrupt( SIG_LP5I,  SIG_IGN );
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
int link_dma_done( int lbuf )
{
    return( link_dma_done_status[lbuf] );
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_xmt( int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) )
{
    int Temp;
	unsigned int	lctlx;
	unsigned int	speed_mask;
	unsigned int	ctlbits;

#if FLAG_SYNC
	int ext_flag_mask;

#ifdef MASTER
    ext_flag_mask = B_H1F1;
#else
    ext_flag_mask = B_H2F1;
#endif

    //Wait for signal from other uP, then tx
	do
	{
		flag_reg = *(ms2_ptr + HH_FLAGS);
	}while(flag_reg & ext_flag_mask); 
#endif

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable transmit channel and clear all settings */
    asm( "NOP;" );
    asm( "BIT CLR MODE1 IRPTEN;" );
    asm( "NOP;" );
  	SetIOP( lctlx, GetIOP(lctlx) & ~(0x3ff << ((10*lbuf)%30)));

    /* Update Link Assigment Register with new map */
	Temp = GetIOP(LAR);        
    Temp &= ~( 7 << (3 * lbuf) );
    Temp |= (link << (3 * lbuf));      /* Map link buffer to tx link port */
    SetIOP(LAR, Temp);
  
	/* Set the link port speed */
    speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask ) );  

   	/* Use 8 bit link port width unless specified for 4 bit */ 
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));

    asm( "NOP;" );
    asm( "BIT SET MODE1 IRPTEN;" );
    asm( "NOP;" );
   
    // Enable interrupt.
    set_dma_interrupt( lbuf );

    /* clear completion flag */
    link_dma_done_status[lbuf]=FALSE;

    /* set transmit parms */
    SetIOP( link_dma_index_offset[lbuf],  (int)buf ); /* Index  */
    SetIOP( link_dma_stride_offset[lbuf], 1        ); /* stride */
    SetIOP( link_dma_length_offset[lbuf], buflen   ); /* length (down-counter) */

	/* Enable channel */
    /* Set ctl for word size, Tx, no chain, DMA, and lbuf enable */

	ctlbits = (bit_width == 48) ? 0x1b : 0x0b;

	asm( "NOP;" );
	asm( "BIT CLR MODE1 IRPTEN;" );
	asm( "NOP;" );
	SetIOP( lctlx, GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30)) );
	asm( "NOP;" );
	asm( "BIT SET MODE1 IRPTEN;" );
	asm( "NOP;" );

    /* wait for xfer to complete */
    if(wait)
    {
 		while(GetIOP(link_dma_length_offset[lbuf]) > 0)
		    ;

		while(((GetIOP(LCOM) >> lbuf*2) & 3) > 0)
		    ;

   		/* disable channel */
	    disable_channel(lbuf);  
    }
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void link_dma_rcv( int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) )
{
    int Temp;
	unsigned int lctlx;
	unsigned int speed_mask;
	unsigned int ctlbits;

    lctlx = (lbuf < 3) ? LCTL0 : LCTL1;

    /* disable receive channel */
    asm( "NOP;" );
    asm( "BIT CLR MODE1 IRPTEN;" );
    asm( "NOP;" );
    SetIOP( lctlx, GetIOP(lctlx) & ~(0x3FF << ((10*lbuf) % 30)) );

    Temp = GetIOP(LAR);        /* Update Link Assigment Register with new map */
    Temp &= ~( 7 << (3 * lbuf) );
    Temp |= (link << (3 * lbuf));      /* Map link buffer to rx link port */
    SetIOP(LAR, Temp);         /* Update Link Assigment Register with new map */

	speed_mask = (linkspeed % 4) << ((5 + (10*lbuf)) % 30);
    SetIOP(lctlx, (GetIOP(lctlx) |  speed_mask ) ); 
 
	// Use 8 bit link port width unless specified for 4 bit
	if (link_width != 4)
		SetIOP(lctlx, (GetIOP(lctlx) | (0x1 << ((9 + (10*lbuf)) % 30))));

    asm( "NOP;" );
    asm( "BIT SET MODE1 IRPTEN;" );
    asm( "NOP;" );
   
    // Enable interrupt.
    set_dma_interrupt( lbuf );

    /* clear completion flag */
    link_dma_done_status[lbuf]=FALSE;

    /* set parms */
    SetIOP( link_dma_index_offset[lbuf],  (int)buf ); /* Index  */
    SetIOP( link_dma_stride_offset[lbuf], 1        ); /* stride */
    SetIOP( link_dma_length_offset[lbuf], buflen   ); /* length (down-counter) */

   /* Enable channel */
    /* Set ctl for word size, Rx, no chain, DMA, and lbuf enable */
    ctlbits = (bit_width == 48) ? 0x13 : 0x03;

	asm( "NOP;" );
	asm( "BIT CLR MODE1 IRPTEN;" );
	asm( "NOP;" );
	SetIOP( lctlx, GetIOP(lctlx) | (ctlbits << ((10*lbuf) % 30)) );
	asm( "NOP;" );
	asm( "BIT SET MODE1 IRPTEN;" );
	asm( "NOP;" );

#if FLAG_SYNC
	// Signal the other processor that RX has been started
    asm("bit set FLAGS FLG1;");
#endif

    /* wait for receive to complete */
    if( wait )
    {
		while(GetIOP(link_dma_length_offset[lbuf]) > 0)
		    ;	    

		while(((GetIOP(LCOM) >> lbuf*2) & 3) > 0)
		    ;

	    for (Temp=0; Temp<1000; Temp++)  
		    asm("nop;"); //Wait a bit

   		/* disable channel */
		disable_channel(lbuf);
    }

#if FLAG_SYNC
    // Clear FLAG1
    asm("bit clr FLAGS FLG1;");
#endif
}

/**********************************************************/

/* End of file linkdma.c */

/**********************************************************/
