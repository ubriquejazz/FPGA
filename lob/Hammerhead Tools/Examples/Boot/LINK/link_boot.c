//*********************************************************
//
//  Blink
//  -----
//  link_boot.c : Example demonstrating link booting a 
//      processor (the slave, or receiver) from another
//      (the master, or transmitter).
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
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0   08/20/01  rpc     Coding for example
//
//*********************************************************
#include <def21160.h>
#include <21160.h>

void lboot_tx(int link);

void main(void)
{

	// call assembly function to transmit program on the
    // indicated link port, and boot-load the receiver processor
    lboot_tx(2);
}
