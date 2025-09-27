//*********************************************************
//
//  pci_dma.c : Program to test PCI_LIB functions for
//  DMAs over PCI.
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
//    1.0   02/07/01   rpc     Create
//    1.1   01/15/02   rpc     Added TEST_MCH0/1 defs to test mastering chans
//
//*********************************************************
#include "fin_pci.h"

#define TEST_MCH0   1
#define TEST_MCH1   1
#define BUF_SIZE    128

int src_data[BUF_SIZE];
int dst_dma0[BUF_SIZE]; // destination for chan0 DMA
int dst_dma1[BUF_SIZE]; // destination for chan1 DMA
int pci_addr;     // remote physical PCI address
int errors_dma0;  // error count for chan0 DMA
int errors_dma1;  // error count for chan1 DMA
int write_ticks0; // 80MHZ ticks elapsed during chan0 write
int read_ticks0;  // 80MHZ ticks elapsed during chan0 read
int write_ticks1; // 80MHZ ticks elapsed during chan1 write
int read_ticks1;  // 80MHZ ticks elapsed during chan1 read
int done = 0;     // done flag

void main(void)
{
    int i;

	// Init the source data
    for(i = 0; i < BUF_SIZE; i++)
	{
	    src_data[i] = ~i;
	}

	// Init the PCI interface
	SharcFin_PCI_Init();

    // HH uses DMACs 10-13
#if TEST_MCH0
	// DMA TEST Master Channel 0 ////////////////////////////////////////////////////////
    errors_dma0 = 0;
	SharcFin_PCI_DMA_Write(0,               // use master chan 0
	                       10,              // use DMAC 10
						   BUF_SIZE*4,      // xfer byte count
						   src_data,        // xfer source
						   (int *)pci_addr, // xfer destination
						   0,               // do not force 32-bit xfers
						   1,               // do wait for completion
						   &write_ticks0);  // get ticks elapsed
	
	SharcFin_PCI_DMA_Read(0,                // use master chan 0
	                      11,               // use DMAC 11
						  BUF_SIZE*4,       // xfer byte count
						  (int *)pci_addr,  // xfer source
						  dst_dma0,         // xfer destination
						  0,                // do not force 32-bit xfers
						  1,                // do wait for completion
						  &read_ticks0);    // get ticks elapsed

    for(i = 0; i < BUF_SIZE; i++)
	{
	    if(dst_dma0[i] != src_data[i])
		{
		    errors_dma0++;
		}
	}
#endif

#if TEST_MCH1
	// DMA TEST Master Channel 1 ////////////////////////////////////////////////////////
    errors_dma1 = 0;
	SharcFin_PCI_DMA_Write(1,               // use master chan 1
	                       10,              // use DMAC 10
						   BUF_SIZE*4,      // xfer byte count
						   src_data,        // xfer source
						   (int *)pci_addr, // xfer destination
						   0,               // do not force 32-bit xfers
						   1,               // do wait for completion
						   &write_ticks1);  // get ticks elapsed
	
	SharcFin_PCI_DMA_Read(1,                // use master chan 1
	                      11,               // use DMAC 11
						  BUF_SIZE*4,       // xfer byte count
						  (int *)pci_addr,  // xfer source
						  dst_dma1,         // xfer destination
						  0,                // do not force 32-bit xfers
						  1,                // do wait for completion
						  &read_ticks1);    // get ticks elapsed

    for(i = 0; i < BUF_SIZE; i++)
	{
	    if(dst_dma1[i] != src_data[i])
		{
		    errors_dma1++;
		}
	}
#endif

	done = 1;
}

//
// End of file pci_dma.c
//

