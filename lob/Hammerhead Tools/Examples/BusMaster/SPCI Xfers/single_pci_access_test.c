//*********************************************************
//
//  single_pci_access_test.c : Program to test single location access
//               between HH internal memory and PCI bus mapped memory.
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
//    1.0   03/05/01  rpc	  Create based on dma_speed_test.c
//
//*********************************************************

#include <def21160.h>
#include <21060.h>
#include "fin_pci.h"

//*********************************************************
// Definitions

#define BUFFER_SIZE     	2 		    // Size of tx and rx internal buffers
#define CLOCKSPD    (float) 40000000.0	// External Clock Rate

//*********************************************************
// Macros 

#define MSize                 ((GetIOP(SYSCON) & 0xF000) >> 12)
#define HHCalcFinAddr(offset) (int *) (0x800000 + (2 * (0x2000 << MSize))+((offset) >> 2))
#define SetInt(addr,val)      (*(unsigned long *) (HHCalcFinAddr(INT_CTRL_REG)+((addr) >> 2)))=(val)
#define GetInt(addr)          (*(unsigned long *) (HHCalcFinAddr(INT_CTRL_REG)+((addr) >> 2)))
#define SetQL(addr,val)       (*(unsigned long *) (HHCalcFinAddr(QL_CTRL_REG)+((addr) >> 2)))=(val)
#define GetQL(addr)           (*(unsigned long *) (HHCalcFinAddr(QL_CTRL_REG)+((addr) >> 2)))

//*********************************************************
// Global variables 

int internal_buffer[BUFFER_SIZE];	// Internal buffer - used for both tx and rx
int	number_of_loops = 0x10000;		// Default number of loops
int current_loop;
volatile int done;
volatile int errors;				// Errors found in data at end of test
int *fin_tx_buffer;                 // Address of TX FIFO on the FIN
int *fin_rx_buffer;                 // Address of RX FIFO on the FIN
float ReadRate;                     // Averaged rate for DMA in
float WriteRate;                    // Averaged rate for DMA out
volatile float ReadLoopRate;
volatile float WriteLoopRate;
int ReadTransferTime;
int WriteTransferTime;

long pci_addr;                      // Starting PCI address for read/write

//*********************************************************
//
//
//
//*********************************************************
int main(int argc, char **argv)
{
    int msize;

    // Set any required wait states, memory bank size, sdram control, etc.
    msize = (GetIOP(SYSCON) & 0xF000) >> 12;
	if (msize < 9)								// Bank size = 2 ** (msize + 13) -> we want at least 2**22
	{
		SetIOP(SYSCON,(GetIOP(SYSCON) | (0x9 << 12)));
	}
    SetIOP(WAIT, 0x01CE1B86);
       
    // Initialization.
    done = FALSE;
	errors = 0;
	ReadRate = 0.0;
	WriteRate = 0.0;
	
	// Preset the buffer with a simple counter pattern
    internal_buffer[0] = 0x33333333;
    internal_buffer[1] = 0xcccccccc;
	

	// Run the prescribed number of loops, where each loop DMAs the block from internal 
	// to external and then back to internal again

	for (current_loop = 0; current_loop < number_of_loops; current_loop++)
	{
	    // WRITE
	    // Load the target PCI address
		SetQL(SNGL_PCI_ADDR_REG_UPR, 0x00000000);
		SetQL(SNGL_PCI_ADDR_REG_LWR, (int)pci_addr);

		// Write the data to the data register
		SetQL(SNGL_PCI_DATA_REG_UPR, internal_buffer[0]);
		SetQL(SNGL_PCI_DATA_REG_LWR, internal_buffer[1]);

		// Write the SPCI command register
		SetQL(SPCI_COMMAND_REG, SPCI_64_WRITE);

		// Check status
		while(GetQL(SPCI_COMMAND_REG) & SPCI_STATUS)
		{
		}

        // READ
	    // Load the target PCI address -- is this step redundant?  Yes.
		// SetQL(SNGL_PCI_ADDR_REG_UPR, 0x00000000);
		// SetQL(SNGL_PCI_ADDR_REG_LWR, (int)pci_addr);

 		// Write the SPCI command register
		SetQL(SPCI_COMMAND_REG, SPCI_64_READ);

		// Check status
		while(GetQL(SPCI_COMMAND_REG) & SPCI_STATUS)
		{
		}

		// Read back the data
		internal_buffer[0] = GetQL(SNGL_PCI_DATA_REG_UPR);
		internal_buffer[1] = GetQL(SNGL_PCI_DATA_REG_LWR);

		// Check data
		if(internal_buffer[0] != 0x33333333 || internal_buffer[1] != 0xcccccccc)
		{
		    errors++;
		}
    }
	

    // Done, so return;
    done = TRUE;

    return(0);
}

//*********************************************************

// End of file single_pci_access_test.c

//*********************************************************
