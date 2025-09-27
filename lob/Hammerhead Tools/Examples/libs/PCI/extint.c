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
#include <21160.h>
#include <signal.h>
#include "fin.h"
#include "fin_pci.h"
#include "extint.h"

//**********************************************************
// 
// 
// 
//**********************************************************
int extmem_to_intmem(int *extsrc, int *intdest, int num_to_copy, int incr, 
					 int dma_channel, int flags, int wait, int use_timer)
{    
    int chan_offset, DMATime;
	int dma_status_bit;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from external memory
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH     );       // Flush
    SetIOP( (II10+chan_offset      ),  (int)intdest    );
    SetIOP( (IM10+chan_offset      ),  1               );
    SetIOP( (C10+chan_offset       ),  num_to_copy     );
    SetIOP( (EI10+chan_offset      ),  (int)extsrc     );
    SetIOP( (EM10+chan_offset      ),  incr            );
    SetIOP( (EC10+chan_offset      ),  num_to_copy     );

	if(use_timer)
	{
		timer_off();
		timer_set(0x1FFFFF, 0x1FFFFF);
		DMATime = timer_on();
	}

    // start DMA
	SetIOP( (DMAC10+(dma_channel-10)),  flags);     // Enable, Read from extmem.

    // If we need to wait for completion.
    if(wait)
    {       
        // Wait until dma completed.
		dma_status_bit = 1L << dma_channel;
        while( GetIOP( DMASTAT ) & dma_status_bit )
		{
		}
    }
    
	if(use_timer)
	{
	    DMATime -= timer_off();
        return(DMATime);
	}
	else
	{
		return 0;
	}
}

//**********************************************************
// 
// 
// 
//**********************************************************
int intmem_to_extmem(int *intsrc, int *extdest, int num_to_copy, int incr, 
					 int dma_channel, int flags, int wait, int use_timer)
{    
    int chan_offset, DMATime = 0;
	int dma_status_bit;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from internal memory
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH     );       // Flush
    SetIOP( (II10+chan_offset      ),  (int)intsrc     );
    SetIOP( (IM10+chan_offset      ),  1               );
    SetIOP( (C10+chan_offset       ),  num_to_copy     );
    SetIOP( (EI10+chan_offset      ),  (int)extdest    );
    SetIOP( (EM10+chan_offset      ),  incr            );
    SetIOP( (EC10+chan_offset      ),  num_to_copy     );

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
        dma_status_bit = 1L << dma_channel;
        while( GetIOP( DMASTAT ) & dma_status_bit )
		{
		}
    }
    
	if(use_timer)
	{
		DMATime -= timer_off();
        return(DMATime);
	}
	else
	{
		return 0;
	}
}



//**********************************************************
// 
// 
// 
//**********************************************************
int intmem_to_epb(int *intsrc, int num_to_copy, int dma_channel, int flags, int wait)
{    
    int chan_offset;

    // Check for valid DMA channel.
    if( (dma_channel < 10) || (dma_channel > 13) )
        return( FALSE );
    chan_offset = (dma_channel - 10) << 3;
         
    // Prepare DMA from internal memory to EPB (via DMAC).
    SetIOP( (DMAC10+(dma_channel-10)),  DMAC_FLUSH);     // Flush
    SetIOP( (II10+chan_offset      ),  (int)intsrc);
    SetIOP( (IM10+chan_offset      ),  1          );
    SetIOP( (C10+chan_offset       ),  num_to_copy);
    SetIOP( (DMAC10+(dma_channel-10)), flags      );     // Enable, Write to extmem.

    // If we need to wait for completion.
    if(wait)
    {    
        int dma_status_bit = 1L << dma_channel;
        
        // Wait until dma completed.
        while( GetIOP( DMASTAT ) & dma_status_bit )
            ;

        // Disable DMA.
        SetIOP( (DMAC10+(dma_channel-10)), DMAC_FLUSH );
    }
    
    return(0);
}

//**********************************************************
// End of file extint.c
//**********************************************************
