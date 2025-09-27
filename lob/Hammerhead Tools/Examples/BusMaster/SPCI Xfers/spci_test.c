//*********************************************************
//
//  spci_test.c : Program to test SPCI access functions for
//  64- 32-, 16-, and 8-bit SPCI transfers and DMAs over PCI.
//  This test uses the PCI_LIB library.
//
//  PROVIDED BY:
//  ------------
//  BittWare Research Systems, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph: 603-226-0404
//  Fax: 603-226-6667
//  Web: www.bittware.com
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
//    1.0   02/07/01   rpc     Create
//
//*********************************************************
#include "fin_pci.h"

int src_data8[] =  {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 
                    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff};
int src_data16[] = {0x0000, 0x1111, 0x2222, 0x3333, 0x4444, 0x5555, 0x6666, 0x7777, 
                    0x8888, 0x9999, 0xaaaa, 0xbbbb, 0xcccc, 0xdddd, 0xeeee, 0xffff};
int src_data32[] = {0x00000000, 0x11111111, 0x22222222, 0x33333333, 
                    0x44444444, 0x55555555, 0x66666666, 0x77777777, 
                    0x88888888, 0x99999999, 0xaaaaaaaa, 0xbbbbbbbb, 
				    0xcccccccc, 0xdddddddd, 0xeeeeeeee, 0xffffffff,
                    0x0f0f0f0f, 0x1e1e1e1e, 0x2d2d2d2d, 0x3c3c3c3c, 
                    0x4b4b4b4b, 0x5a5a5a5a, 0x69696969, 0x78787878, 
                    0x87878787, 0x96969696, 0xa5a5a5a5, 0xb4b4b4b4, 
				    0xc3c3c3c3, 0xd2d2d2d2, 0xe1e1e1e1, 0xf0f0f0f0};

int dst_data64[32]; // destination for 64-bit xfer
int dst_data32[16]; // destination for 32-bit xfer
int dst_data16[16]; // destination for 16-bit xfer
int dst_data8[16];  // destination for 8-bit xfer
int errors64;       // error count for 64-bit test
int errors32;       // error count for 32-bit test
int errors16;       // error count for 16-bit test
int errors8;        // error count for 8-bit test
int pci_addr;       // remote physical PCI address
int addr;           // temp address variable
int done = 0;       // done flag

void main(void)
{
    int i;
	int j;

	// Init the PCI interface
	SharcFin_PCI_Init();

	// 64 BIT TEST /////////////////////////////////////////////////////////
    addr = pci_addr;
	errors64 = 0;
    for(i = 0; i < 16; i++, addr +=8)
	{
	    if(SharcFin_SPCIWr64(addr, src_data32[i], src_data32[i]) != 0)
		{
		    errors64++;
		}
	}

    addr = pci_addr;
    for(i = 0, j = 0; i < 32; i += 2, j++, addr +=8)
	{
	    if((SharcFin_SPCIRd64(addr, &dst_data64[i], &dst_data64[i+1]) != 0) || 
		   (dst_data64[i] != src_data32[j]) || (dst_data64[i+1] != src_data32[j]))
		{
		    errors64++;
		}
	}

	// 32 BIT TEST /////////////////////////////////////////////////////////
    addr = pci_addr;
	errors32 = 0;
    for(i = 0; i < 16; i++, addr += 4)
	{
	    if(SharcFin_SPCIWr32(addr, src_data32[i]) != 0)
		{
		    errors32++;
		}
	}

    addr = pci_addr;
    for(i = 0; i < 16; i++, addr += 4)
	{
	    if((SharcFin_SPCIRd32(addr, &dst_data32[i]) != 0) || (dst_data32[i] != src_data32[i]))
		{
		    errors32++;
		}
	}

	// 16 BIT TEST /////////////////////////////////////////////////////////
    addr = pci_addr;
	errors16 = 0;
    for(i = 0; i < 16; i++, addr += 2)
	{
	    if(SharcFin_SPCIWr16(addr, src_data16[i]) != 0)
		{
		    errors16++;
		}
	}

    addr = pci_addr;
    for(i = 0; i < 16; i++, addr += 2)
	{
	    if((SharcFin_SPCIRd16(addr, &dst_data16[i]) != 0) || (dst_data16[i] != src_data16[i]))
		{
		    errors16++;
		}
	}

	// 8 BIT TEST //////////////////////////////////////////////////////////
    addr = pci_addr;
	errors8 = 0;
    for(i = 0; i < 16; i++, addr++)
	{
	    if(SharcFin_SPCIWr8(addr, src_data8[i]) != 0)
		{
		    errors8++;
		}
	}

    addr = pci_addr;
    for(i = 0; i < 16; i++, addr++)
	{
	    if((SharcFin_SPCIRd8(addr, &dst_data8[i]) != 0) || (dst_data8[i] != src_data8[i]))
		{
		    errors8++;
		}
	}

	done = 1;
}


