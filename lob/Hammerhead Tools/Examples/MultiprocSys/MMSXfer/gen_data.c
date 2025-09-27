//*********************************************************
//
//  gen_data.c 
//  --------------------------------------------
//  Program to generate test data for multiple processing example.
//  Data will be flagged ready using the MSGRx registers on the 
//  target board. 
//
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
//  Copyright (c) 2001
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//
//    Ver.  Dates     Author  Changes                                
//    ----  --------  ------  -----------------------------
//    1.0   04/16/01  rpc	  Create for Hammerhead
//
//*********************************************************
#include <def21160.h>
#include <21060.h>
#include <signal.h>
#include <macros.h>
#include "fin_pci.h"
#include "fin.h"

#define FILL_SDRAM           1                   // flag to artificially create data
#define PACKET_IN_SIZE       256                 // size of input data set
#define PROC_BOARD_BAR2      0xe6000000          // this PCI address "hard coded"
#define DM_IN_BUF_START      0x58000             // location of consumer input buff start
#define DM_IN_BUF_END        0x5c000             // location of consumer input buff end
#define DATA_IN_BUF_SIZE     (DM_IN_BUF_END-DM_IN_BUF_START) // size of consumer input buffer
#define NUM_PROCS            4                   // number of consumer processors in system
#define FILE_SDRAM_ADDR      0x800000            // addr of beginning of SDRAM
#define FILE_NWORDS          PACKET_IN_SIZE*256  // 256 packets of 256

int done = 0;
int offs = 0;                                    // holds the offset into source SDRAM
unsigned int *msgr0_addr;                        // contains addr of MSGR0 of consumer
int headp;                                       // consumer's 0-based head pointer (from MSGR0)
int tailp;                                       // consumer's 0-based tail pointer (from MSGR1)
int next_head;                                   // to calc next packet location
unsigned int *data_ptr;                          // used for pointing to consumers' MMS
int *in_data_start = (int *)DM_IN_BUF_START;     // pointer to beginning of internal (DM) memory buff
int *in_data;                                    // working pointer to internal memory
int *sdram_input_file = (int *)FILE_SDRAM_ADDR;  // pointer to SDRAM raw input

int get_tail(unsigned int *addr)
{
	SPCI_addr((int)addr);
	SPCI_command(SPCI32_READ_HI);
	return(GetFIN(SNGL_PCI_DATA_REG_UPR)); // MSGR1 is tail
}

int get_head(unsigned int *addr)
{
	SPCI_addr((int)addr);
	SPCI_command(SPCI32_READ_LO);
	return(GetFIN(SNGL_PCI_DATA_REG_LWR)); // MSGR0 is head
}

void set_head(unsigned int *addr, int val)
{
	SPCI_addr((int)addr);
	SetFIN(SNGL_PCI_DATA_REG_LWR, val);
	SPCI_command(SPCI32_WRITE_LO);
}
//*********************************************************
//
//
//
//*********************************************************
void main(void)
{
    int i;

    init_Hammerhead();
	
#if FILL_SDRAM
    // Code to prefill SDRAM with an incrementing pattern
	data_ptr = (unsigned int *) sdram_input_file;
	for(i = 0; i < FILE_NWORDS; i++)
	{
		*data_ptr++ = i;
	}
#endif

    SharcFin_PCI_Init();
	in_data = in_data_start;

	do
	{
		for(i = 1; i <= NUM_PROCS; i++)
		{
			// Transfer data from external to internal memory.
		    extmem_to_intmem((int *)(sdram_input_file + offs), // Source buffer
              	             (int *)in_data,                   // Destination buffer
		       	             PACKET_IN_SIZE,                   // Buffer size
							 1,                                // External Increment (EM)
            	  		     11,                               // DMA Channel
                 		     1);           	                   // Wait for DMA to complete?
	
            // don't wrap -- assume lots of SDRAM
	        offs += PACKET_IN_SIZE;

			// Point to appropriate processor MMS; this is a byte-oriented (PCI) address
			msgr0_addr = (unsigned int *)(PROC_BOARD_BAR2 + 4*(i*0x100000 + MSGR0));
			headp = get_head(msgr0_addr);

            // prepare for next data packet
			next_head = headp + PACKET_IN_SIZE;
			if(next_head >= DATA_IN_BUF_SIZE)
			{
			    next_head = 0;
			}

            // Wait for remote buffer not full
			while(next_head == (tailp = get_tail(msgr0_addr)))
			{
			}

			// Send a packet over PCI: first calc destination pointer
			data_ptr  = (unsigned int *)(PROC_BOARD_BAR2 + 4*(i*0x100000 + DM_IN_BUF_START + headp));

            SharcFin_PCI_DMA_Write(0,                // mchan
			                       9+i,              // use dmacs 10-13
								   PACKET_IN_SIZE*4, // size
								   (int *)in_data,   // *src
                                   (int *)data_ptr,  // *dst
								   0,                // force32
								   1,                // wait
								   NULL              // *ticks
								   );

			// Update remote head pointer
			set_head(msgr0_addr, next_head);

			// adjust the offset into the DM buffer
			in_data += PACKET_IN_SIZE;
			if((int)in_data == DM_IN_BUF_END)
			{
			    in_data = in_data_start;
			}
		}		      
	}while(offs < FILE_NWORDS);

	done = 1;
}

//*********************************************************
// End of file gen_data.c
//*********************************************************
