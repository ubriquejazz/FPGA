//**********************************************************
//
//  DMA transfers between internal and external SHARC memory.
//  ---------------------------------------------------------
//  extint.c : Perform DMA memory transfers between internal and external memory.
//
//  PROVIDED BY:
//  ------------
//  BittWare Research Systems, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph: 603-226-0404
//  Fax: 603-226-6667
//  WWW: www.bittware.com
//  E-mail: support@bittware.com
//
//  Copyright 2001, BittWare, Inc.
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//    Ver.  Dates     Changes                                
//    ----  --------  ---------------------------------------
//		2.0	10/23/99	rlh		Modify for Hammerhead
//      2.1 06/01/00    rpc     Added increment parameter to extmem_to_intmem
//                              and intmem_to_extmem
//      2.2 03/04/01    rpc     Added use_timer flag to isolate timer
//
//**********************************************************

#include <def21160.h>
#include <21060.h>
#include <signal.h>

#include "extint0.h"

//**********************************************************

// Definitions.

#define DMAC_FLUSH      0x00004000      /* flush port buffer */
#define DMAC_SDO        0x00000005      /* slave, type data, output */

#define DMAC_MDI        0x00000401      /* master, type data, input */
#define DMAC_MDO        0x00000405      /* master, type data, output */

//#define DMAC_MDI        0x00040401      /* master, type data, input, 32 bit internal only */
//#define DMAC_MDO        0x00040405      /* master, type data, output 32 bit internal only */

//#define DMAC_MDI        0x00080401      /* master, type data, input, burst enabled */
//#define DMAC_MDO        0x00080405      /* master, type data, output, burst enabled  */

//#define DMAC_MDI        0x000c0401      /* master, type data, input, burst enabled , 32s only */
//#define DMAC_MDO        0x000c0405      /* master, type data, output, burst enabled, 32s only */

#define DMAC_MII        0x00000421      /* master, type instruction, input */
#define DMAC_MIO        0x00000425      /* master, type instruction, output */

//**********************************************************

// Global variables.

int dmac_ext_to_int = DMAC_MDI;
int dmac_int_to_ext = DMAC_MDO;

//**********************************************************
// 
// 
// 
//**********************************************************
int extmem_to_intmem(int *extsrc, int *intdest, int int_count, int ext_count, int incr, int dma_channel, 
                     int flags, int wait, int use_timer)
{    
    int chan_offset, DMATime;
	int dma_status_bit;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from external memory
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH );       // Flush
    SetIOP( (II10+chan_offset      ),  (int)intdest);
    SetIOP( (IM10+chan_offset      ),  1           );
    SetIOP( (C10+chan_offset       ),  int_count   );
    SetIOP( (EI10+chan_offset      ),  (int)extsrc );
    SetIOP( (EM10+chan_offset      ),  incr        );
    SetIOP( (EC10+chan_offset      ),  ext_count   );

	if(wait)
	{
        dma_status_bit = 1L << dma_channel;
	}

	if(use_timer)
	{
		timer_off();
		timer_set(0x1FFFFF, 0x1FFFFF);
		DMATime = timer_on();
	}

    // start DMA
	SetIOP( (DMAC10+(dma_channel-10)), flags);     // Enable, Read from extmem.

    // If we need to wait for completion.
    if(wait)
    {       
        // Wait until dma completed.
        while( GetIOP( DMASTAT ) & dma_status_bit )
		{
		}
		DMATime -= timer_off();

        // Disable DMA.
        SetIOP( (DMAC10+(dma_channel-10)), DMAC_FLUSH );
    }
    
	return (use_timer) ? DMATime : 0;
}

//**********************************************************
// 
// 
// 
//**********************************************************
int intmem_to_extmem(int *intsrc, int *extdest, int int_count, int ext_count, int incr, int dma_channel,
                     int flags, int wait, int use_timer)
{    
    int chan_offset, DMATime = 0;
	int dma_status_bit;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from internal memory
	SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH );       // Flush
    SetIOP( (II10+chan_offset      ),  (int)intsrc );
    SetIOP( (IM10+chan_offset      ),  1           );
    SetIOP( (C10+chan_offset       ),  int_count   );
    SetIOP( (EI10+chan_offset      ),  (int)extdest);
    SetIOP( (EM10+chan_offset      ),  incr        );
    SetIOP( (EC10+chan_offset      ),  ext_count   );

	if(wait)
	{
        dma_status_bit = 1L << dma_channel;
	}

	if(use_timer)
	{
		timer_off();
		timer_set(0x1FFFFF, 0x1FFFFF);
		DMATime = timer_on();
	}
    
	SetIOP( (DMAC10+(dma_channel-10)), flags);  // Enable, Write to extmem.

    // If we need to wait for completion.
    if(wait)
    {    
        // Wait until dma completed.
        while( GetIOP( DMASTAT ) & dma_status_bit )
		{
		}
		DMATime -= timer_off();
           
        // Disable DMA.
        SetIOP( (DMAC10+(dma_channel-10)), DMAC_FLUSH );
    }
    
	return (use_timer) ? DMATime : 0;
}


//**********************************************************
// 
// 
// 
//**********************************************************
int intmem_to_epb( int *intsrc, int num_to_copy, int dma_channel, int wait )
{    
    int chan_offset;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from internal memory to EPB (via DMAC).
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH      );       // Flush
    SetIOP( (II10+chan_offset      ),  (int)intsrc     );
    SetIOP( (IM10+chan_offset      ),  1               );
    SetIOP( (C10+chan_offset       ),  num_to_copy     );
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_SDO        );     // Enable, Write to extmem.

    // If we need to wait for completion.
    if( wait )
    {    
        int dma_status_bit = 1L << dma_channel;
        
        // Wait until dma completed.
        while( GetIOP( DMASTAT ) & dma_status_bit )
            ;

        // Disable DMA.
        SetIOP( (DMAC10+(dma_channel-10)), DMAC_FLUSH );
    }
    
    return( 0 );
}

//**********************************************************
 
// End of file extint.c
 
//**********************************************************
