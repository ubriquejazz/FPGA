//*********************************************************
//
//  Blink
//  -----
//  blink.c : Example demonstrating use of timers,
//            interrupts, flags, and the LEDs.
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
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//
//*********************************************************

#include <def21160.h>
#include <21160.h>

/**********************************************************/
/**********************************************************/
#define CLOCK_RATE  2000000

#ifndef SetIOP
#define SetIOP(addr,val)    (*(unsigned long *)(addr))=(val)
#define GetIOP(addr)		(*(unsigned long *)(addr))
#endif

int count;
int mpid;

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int get_idc( void )
{
    int idc;

    idc = GetIOP( SYSTAT );
    idc = (idc>>8) & 0x07;

    return( idc );
}


/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void main ( void )
{
    int cnt;

    /* Initialize data. */
    count=-1;
    mpid = get_idc();

    // Initialize flags for output.
	asm("BIT SET MODE2 0x00060000;");

// Use a delay and then toggle LEDs based in mpid so they
// all toggle at a different rate

	while(1)
	{
		count++;

		for (cnt = 0 ; cnt < 500000 ; cnt++);

		if (!(count % (mpid*2)))
			asm("BIT TGL FLAGS 0x00000004;");

		if (!(count % (mpid*2+1)))
			asm("BIT TGL FLAGS 0x00000008;");

 		SetIOP(MSGR0, count);
	}	
}

/**********************************************************/

/* End of file blink.c */

/**********************************************************/
