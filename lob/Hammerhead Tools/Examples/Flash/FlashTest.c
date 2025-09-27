//*********************************************************
//
//  FLASH TEST
//  ------------
//  FlashTest.c : source file for flash file test
//
//	Notes:	
//			The test sequence is as follows:
//              - detect FLASH type from a database
//				- erase entire flash with chip erase call
//				- verify that the chip erase worked (make sure all bytes are 0xff)
//				- write a sequence to flash
//				- verify the writes worked
//				- erase entire flash with chip erase call
//				- verify that the chip erase worked (make sure all bytes are 0xff)
//
//  PROVIDED BY:
//  ------------
//  BittWare, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph:  603-226-0404
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
//  2.00  11/09/99  rlh	    Update test sequence and use new flash utilities, and for Hammerhead
//  2.10  10/18/00  rpc     Update test for HHPC104+
//  3.00  11/15/00  rpc     Update for generic (auto detect) use; added LED blinks for status
//
//*********************************************************

#include <21060.h>
#include <def21160.h>
#include "flash.h"

#define START_SECTOR 0

//*********************************************************

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

#ifndef FALSE
#define FALSE (0)
#define TRUE  (!FALSE)
#endif

//*********************************************************
// Global variables - for external visibility via symbol table.
// Use the new flash utilities and structures
_BW_FLASH *my_flash;
int errors;
int done;

//*********************************************************
//  
//  
//  
//*********************************************************
int main(void)
{
	int j, sector;
    int start_sector = START_SECTOR;

	// init processor for use
    init_HH_manual(0xc, 0x1ce1b86, 2, 0x10);

	// Set up flags 2 and 3 for output
	asm("bit set MODE2 0x60000;");

    done = FALSE;
	errors = 0;

    // Autodetect FLASH type, init variables and access, initialize flash pointer.
    if((my_flash = FlashInit(ADSP_21160)) == 0)
	{
	    exit(-1);
	}
 
	/* Turn off LEDs */
    asm("bit clr FLAGS 0x0000000c;");
          
	// Erase entire FLASH chip
	FlashChipErase( my_flash );
        
 	// Read from FLASH to verify that the erase worked (should be all 0xff)
  	FlashReadReset( my_flash );

    asm("bit set FLAGS 0x00000004;");
    for (sector = start_sector; sector < FlashNumSectors( my_flash ); sector++ )
    {
        for (j = 0; j < FlashSectorSize( my_flash ); j++ )
        {
            if (FlashReadByte( my_flash, (sector << 16) + j) != 0xff)
            {
            	errors++;
                asm("bit set FLAGS 0x0000000c;"); /* ERROR: Turn on LEDs */
                break;						
	       	}
       	}
		//Toggle LEDs with every sector
		asm("bit tgl FLAGS 0x0000000c;");
  	}

 	// Write a simple counter pattern to the flash
 	for (sector = start_sector; sector < FlashNumSectors( my_flash ); sector++ )
  	{
     	for (j = 0; j < FlashSectorSize( my_flash ); j++)
        {
           	FlashWriteByte( my_flash, (sector << 16) + j, j);
        }
		//Toggle LEDs with every sector
		asm("bit tgl FLAGS 0x0000000c;");
  	}

 	// Read from FLASH to verify that the writes worked
 	for (sector = start_sector; sector < FlashNumSectors( my_flash ); sector++ )
    {
      	for (j = 0; j < FlashSectorSize( my_flash ); j++)
       	{
         	if (FlashReadByte(my_flash, (sector << 16) + j) != (j & 0xff))
           	{
              	errors++;
                asm("bit set FLAGS 0x0000000c;"); /* ERROR: Turn on LEDs */
              	break;
            }
        }
		//Toggle LEDs with every sector
		asm("bit tgl FLAGS 0x0000000c;");
  	}

 	// Erase flash sector by sector
  	for (sector = start_sector; sector < FlashNumSectors( my_flash ); sector++ )
   	{
      	FlashSectorErase( my_flash, sector );
		//Toggle LEDs with every sector
		asm("bit tgl FLAGS 0x0000000c;");
   	}

  	// Read from FLASH to verify that the sector erases worked (should be all 0xff)
	// Note that once we find an error in a sector, we can skip to the next one.

   	FlashReadReset( my_flash );
       
	for (sector = start_sector; sector < FlashNumSectors( my_flash ); sector++ )
    {
    	for (j = 0; j < FlashSectorSize( my_flash ); j++ )
       	{
          	if (FlashReadByte( my_flash, (sector << 16) + j) != 0xff)
           	{
             	errors++;
                asm("bit set FLAGS 0x0000000c;"); /* ERROR: Turn on LEDs */
              	break;
           	}
       	}
		//Toggle LEDs with every sector
		asm("bit tgl FLAGS 0x0000000c;");
  	}

    asm("bit clr FLAGS 0x0000000c;");        /* Turn off LEDs */
    done = TRUE;
}

//*********************************************************
//  End of file FlashTest.c
//*********************************************************

