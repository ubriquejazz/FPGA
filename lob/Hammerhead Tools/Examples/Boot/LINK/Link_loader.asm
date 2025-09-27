//*******************************************************************************
//  link_loader.asm
//
//	LINK BOOT LOADER EXAMPLE - TRANSMITTER 
// (Primary (MASTER) processor boot loads the SLAVE)								
//*******************************************************************************
//	NOTE:								                          				
//	One thing needs to be changed each time you change the file           	
//	that you want to load:
//    #define FILE_SIZE  xxxx
//  This should be changed to match the number of lines in the .ldr file that 
//  you are transmitting over the link port.	
//																				
//*******************************************************************************/
//  Copyright 2001, BittWare, Inc.
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0   08/20/01  rpc     Coding for example
//
//*******************************************************************************/

#include "def21160.h"
#include <asm_sprt.h>

/* CHANGE FILE_SIZE = # of lines in the .ldr file that you include as a variable in this program */
#define	FILE_SIZE	6039                /* link boot file size			*/
#define CODE_SIZE	FILE_SIZE/3			/* calculates the code size 	*/
#define KERNEL_SIZE	256					/* loader kernel size			*/

.SEGMENT/dm     seg_dm16;
.ALIGN 2;
.VAR ldata[FILE_SIZE] = "blink.ldr"; // The size of ldata should match the file being sent
.ENDSEG;

.SEGMENT/pm     seg_pmco;
.global _lboot_tx;

_lboot_tx:
        save_reg;                   // save all Registers

        ustat1 = dm(SYSCON);		// Clear Buffer Hang Disable
		bit clr ustat1 BHD;			// for rev 0.0				
		dm(SYSCON) = ustat1;

		b0=ldata;					// set pointer to the beginning	
		m0=1;						// of the boot data 			
		l0=0;

		call lboot (db);			// call boot loader routine	
		r15=KERNEL_SIZE;			// send kernel only first	
		nop;

		lcntr=0xFFFF, do wait1 until lce; // waste some time
wait1:	nop;

		call lboot (db);			// call boot loader routine	
		r15=CODE_SIZE-KERNEL_SIZE;	// send the rest of code	
		nop;

        restore_reg;                // restore all Registers

exit;

/* --------------------------------------kernel link boot routine here-----------------------------------------------------------*/

lboot:	
		r0 = 0x3fff8;         // disable all but LBUF0
		r0 = r0 OR r4;        // OR in the desired link port
        dm(LAR) = r0;         // write the LAR; assign link to LBUF0

		r3 = 0x19;            // L0EN | L0TRAN | L0EXT
		dm(LCTL0) = r3;       // Write to LCTL0

		lcntr=r15, do link_boot until lce;
			buffer_full:	USTAT1=dm(LCOM); // Wait for room to be available in LBUF0	*/
					        bit tst USTAT1 0x00000001; 
		    		        if tf jump buffer_full;
			r0=dm(i0,m0);					 // read 16 lsbs of word	into r0							
			r0=LSHIFT r0 by 16;				 // shift it to the 16 msbs of r0						
			px1=r0;							 // load px1 with 16 lsbs in r0 (e.g. 0x1111xxxx)		
			r0=dm(i0,m0);					 // read middle 16 bits into r0 (e.g. 0x00002222)		
			r1=dm(i0,m0);					 // read 16 msbs into r1	(0x00003333)					
			r0=r0 OR LSHIFT r1 by 16;		 // shift msbs, combine w/ r0 (e.g. 0x33332222)			
			px2=r0;							 // load px2 with 32 msbs, (e.g. PX = 0x333322221111xxxx)
		link_boot: 	 dm(LBUF0) = px;         // write PX to LBUF0									
	rts;
	
.ENDSEG;        
