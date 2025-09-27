//*********************************************************
//
//  FLASH
//  ------------
//  flash.c : Generic FLASH utility source file for BittWare boards.
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
//
//  Ver.  Dates     Author  Changes                                
//  ----  --------  ------  -----------------------------
//  1.00  08/19/98  reddog  Initial Release (pulled many diverse board
//                          specific versions together).
//  1.10  11/11/98  reddog  Update for Spinner board.
//  2.00  08/08/99  jmbj    Updated with BW_FLASH structure
//  2.01  11/02/99  rlh	    Update for Hammerhead
//  2.02  05/30/00  rlh	    Update for 29LV160BT
//  2.03  10/18/00  rpc     Update for 29LV160DB (bottom boot sectors)
//  3.00  11/15/00  rpc     Add support for auto detect of FLASH type
//
//*********************************************************

#include <21160.h>
#include "flash.h"

// Usually, we would include the def file for the processor in use, i.e. def21060.h, def21160.h ...
// BUT, we want these utilities to work for all processor types, and the only def we need is
// SYSCON for getting msize, so we will hard code SYSCON as 0x00, which it is for 21060, 21061, 21062, 21065,
// and 21160.  
#define SYSCON	0x00

// The FLASH database array.  To add a FLASH type, first add the structure element in flash.h, 
// then add the element to this list
_BW_FLASH flash_dbase[] =
{
    POCKET_VIDEO_FLASH, 
	SPINNER_FLASH, 
	SF104p_FLASH800, 
	SF104p_FLASH160, 
	HAMMERHEAD_PCI_FLASH, 
	HAMMERHEAD_PC104_FLASH,
	POCKET_AUDIO_FLASH
};

//*********************************************************
// Auto detect FLASH type; initialize Flash memory access.
//*********************************************************
_BW_FLASH *FlashInit(int proc_type)
{
	int idx;
	int msize;
	int base;
	_BW_FLASH *flash_info;
	
	for(idx = 0; idx < NUM_FLASH_ENTRIES; idx++)
	{
	    flash_info = (_BW_FLASH *)&flash_dbase[idx];
		if(proc_type != flash_info->proc_type)
		{
		    continue;
		}

		// Get base addresses for each external memory bank
		if ( flash_info->proc_type == ADSP_21065 ) 
		{
			switch (flash_info->mem_select)
			{
			  case 0  :
			    flash_info->base_addr = (0x0020000);
			    break;
			
			  case 1  :
			    flash_info->base_addr = (0x1000000);
			    break;
			
			  default :
			  case 2  :
			    flash_info->base_addr = (0x2000000);
			    break;
			
			  case 3  :
			    flash_info->base_addr = (0x3000000);
			    break;
			}
		}
		else 
		{	
			// Set base to start of external space
			if (flash_info->proc_type == ADSP_21160)
			{
				base = 0x800000;
			}
			else
			{
				base = 0x400000;
			}
			
			// Add the required bank offset based on mem select and mem size
			msize = (GetIOP(SYSCON) & 0xF000) >> 12;
			base  = (base + (flash_info->mem_select * (0x2000 << msize)));
			flash_info->base_addr = base;
		}
		
		// Determine Flash type
		FlashReadReset(flash_info);
		if(FlashReadID(flash_info) == flash_info->id_val)
		{    
			FlashReadReset(flash_info);
			flash_info->status = FLASH_ID_OK;
			break;
		}
	}

	if(idx == NUM_FLASH_ENTRIES)
	{
	  flash_info = 0;
	}

	return(flash_info);
}

//*********************************************************
// Force Flash memory into normal READ mode.
//*********************************************************

int  FlashReadReset( _BW_FLASH *flash_info )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  switch( flash_info->cmd_reset )
  {
    case 1 :
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xf0;
      break;

    case 2 :
      * (volatile int *) (flashbase + BankOffset) = 0xf0;
      break;
    
    default:
      break;
  }
  return(SUCCESS);
}

//*********************************************************
// Wait for flash to complete task
//*********************************************************

int  FlashPollData ( _BW_FLASH *flash_info, unsigned Offs, int ExitValue )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

 // For now, give up after a LONG wait
  int test_wait_loop = 0;

  while (((* (volatile int *) (flashbase + BankOffset + Offs) & BW_FLASH_DQ7) != ExitValue ))
  {
  	test_wait_loop++;
  }
  
  return(SUCCESS);
}

//*********************************************************
// Write a byte to FLASH
//
// input: Addr - a valid address in FLASH memory space (any bank)
//*********************************************************

int  FlashWriteByte ( _BW_FLASH *flash_info, unsigned Addr, int Data )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  switch( flash_info -> cmd_write )
  {
    case 1 :
      * (volatile int *) (flashbase + BankOffset + 0x5555) = 0xaa;
      * (volatile int *) (flashbase + BankOffset + 0x2aaa) = 0x55;
      * (volatile int *) (flashbase + BankOffset + 0x5555) = 0xa0;
      * (volatile int *) (flashbase + BankOffset + Addr )  = Data;
      FlashPollData( flash_info, Addr, Data & BW_FLASH_DQ7 );
      break;

    case 2 :
      * (volatile int *) (flashbase + BankOffset + 0xAAA)  = 0xaa;
      * (volatile int *) (flashbase + BankOffset + 0x555)  = 0x55;
      * (volatile int *) (flashbase + BankOffset + 0xAAA)  = 0xa0;
      * (volatile int *) (flashbase + BankOffset + Addr )  = Data;
      FlashPollData( flash_info, Addr, Data & BW_FLASH_DQ7 );
      break;

    case 3 :
      * (volatile int *) (flashbase + BankOffset + 0x555)  = 0xaa;
      * (volatile int *) (flashbase + BankOffset + 0x2AA)  = 0x55;
      * (volatile int *) (flashbase + BankOffset + 0x555)  = 0xa0;
      * (volatile int *) (flashbase + BankOffset + Addr )  = Data;
      FlashPollData( flash_info, Addr, Data & BW_FLASH_DQ7 );
      break;

    default:
      break;
  }
  return(SUCCESS);
}

//*********************************************************
// Read a byte from FLASH
//
// input: Addr - a valid address in FLASH memory space (any bank)
// output: the byte that was read from FLASH
//*********************************************************

int FlashReadByte ( _BW_FLASH *flash_info, unsigned Offs )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  return( * (volatile int *) (flashbase + BankOffset + Offs ) & 0x0ff );
}

//*********************************************************
// Read chip manufacturer and device codes from FLASH
//
// input: Bank - identifies which of four (0-3) FLASH memory banks to affect
// output: Manufacturer code in bits 15-8, Device code in bits 7-0
//*********************************************************

int FlashReadID(_BW_FLASH *flash_info)
{
  int ReturnVal  = 0;
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  switch( flash_info->cmd_read_id )
  {
    case 1 :
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0x90;

      ReturnVal = (( FlashReadByte( flash_info, 0 ) & 0xff) << 8) +
                  (  FlashReadByte( flash_info, 1 ) & 0xff);
      break;

    case 2 :
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x90;

      ReturnVal = (( FlashReadByte( flash_info, 0 ) & 0xff) << 8) +
                  (  FlashReadByte( flash_info, 2 ) & 0xff);
      break;
    
    case 3 :
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x90;

      ReturnVal = (( FlashReadByte( flash_info, 0 ) & 0xff) << 8) +
                  (  FlashReadByte( flash_info, 1 ) & 0xff);
      break;
    
    default:
      break;
  }
  return( ReturnVal );
}

//*********************************************************
// Erase entire FLASH chip (one bank)
//*********************************************************

int  FlashChipErase( _BW_FLASH *flash_info )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  switch( flash_info->cmd_chip_erase )
  {
    case 1 :
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0x10;
      FlashPollData( flash_info, 0, 0x80 );
      break;

    case 2 :
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x10;
      FlashPollData( flash_info, 0, 0x80 );
      break;

    case 3 :
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x10;
      FlashPollData( flash_info, 0, 0x80 );
      break;

    default:
      break;
  }
  return(SUCCESS);
}

//*********************************************************
//
//
//
//*********************************************************
int  FlashSectorErase( _BW_FLASH *flash_info, int Sector )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;
  int i;
  int SectorAddr;
  
  switch( flash_info->cmd_sec_erase )
  {
    case 1 :
      SectorAddr = (Sector & 0x1f) << 16;

      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0x5555 + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x2aaa + BankOffset) = 0x55;
      * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

      FlashPollData( flash_info, SectorAddr, 0x80 );
      break;

    case 2 :
	  // Allow for up to 32 sectors (needed on 29LV160BT)

      SectorAddr = (Sector & 0x1f) << 16;

      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

      FlashPollData( flash_info, SectorAddr, 0x80 );

      // If sector Boot Sector, deal with subsectors by adding offsets from where we are
      if( Sector == flash_info->boot_sector )
      {    
	  	  // Add in size of 1st boot sector
	  	  SectorAddr += 0x8000;	 //32k
          for( i=1 ; i<flash_info->num_boot_secs; i++ )
          {    

              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x80;
              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
              * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

              FlashPollData( flash_info, SectorAddr, 0x80 );

			  // Add offset to get to next boot sector
			  SectorAddr += 0x2000; //8k
          }
      }
      break;

    case 3 :
      // If sector Boot Sector, deal with subsectors.
      if( Sector == flash_info->boot_sector )
      {    
          for( i=0 ; i<flash_info->num_boot_secs; i++ )
          {    
              SectorAddr = 0x0001C000 + (i * 0x1000);

              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x80;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
              * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

              FlashPollData( flash_info, SectorAddr, 0x80 );
          }
      }
      else {
        SectorAddr = (Sector & 0x0f) << 14;

        * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
        * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
        * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x80;
        * (volatile int *) (flashbase + 0x555 + BankOffset) = 0xaa;
        * (volatile int *) (flashbase + 0x2AA + BankOffset) = 0x55;
        * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

        FlashPollData( flash_info, SectorAddr, 0x80 );
      }
      break;

    case 4 :
	  // Allow for the 32 sectors needed on 29LV160DB (bottom boot sectors)

      SectorAddr = (Sector & 0x1f) << 16;

      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x80;
      * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
      * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
      * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

      FlashPollData( flash_info, SectorAddr, 0x80 );

      // If sector Boot Sector, deal with subsectors by adding offsets from where we are
      if( Sector == flash_info->boot_sector )
      {    
	  	  SectorAddr += 0x4000;	 // Add 16k to point to 2nd boot sector
          for( i=1 ; i<flash_info->num_boot_secs; i++ )
          {    
              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0x80;
              * (volatile int *) (flashbase + 0xAAA + BankOffset) = 0xaa;
              * (volatile int *) (flashbase + 0x555 + BankOffset) = 0x55;
              * (volatile int *) (flashbase + BankOffset + SectorAddr) = 0x30;

              FlashPollData( flash_info, SectorAddr, 0x80 );

			  SectorAddr += 0x2000; // Add 8k to point to 3rd and 4th boot sectors
          }
      }
      break;

      default:
      break;
  }
  return(SUCCESS);
}

//*********************************************************
// Temporarily suspend a sector erase operation.
//*********************************************************

int  FlashSectorEraseSuspend( _BW_FLASH *flash_info )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  * (volatile int *) (flashbase + BankOffset) = 0xb0;
  return(SUCCESS);
}

//*********************************************************
// Resume a sector erase operation that has been suspended.
//*********************************************************

int  FlashSectorEraseResume( _BW_FLASH *flash_info )
{
  int flashbase  = flash_info->base_addr;
  int BankOffset = flash_info->active_bank * flash_info->bank_size;

  * (volatile int *) (flashbase + BankOffset) = 0x30;
  return(SUCCESS);
}

int FlashNumSectors( _BW_FLASH *flash_info )
{
    return( flash_info->num_sectors );
}

int FlashSectorSize( _BW_FLASH *flash_info )
{
    return( flash_info->sector_size );
}

int FlashNumBanks( _BW_FLASH *flash_info )
{
    return( flash_info->num_banks );
}

int FlashType( _BW_FLASH *flash_info )
{
    return( flash_info->flash_type );
}

//*********************************************************
//  End of file flash.c
//*********************************************************
