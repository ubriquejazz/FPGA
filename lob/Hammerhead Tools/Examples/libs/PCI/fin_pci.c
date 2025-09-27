//*****************************************************************************
//                                                                             
//  fin_pci.c : Collection of SharcFin PCI bus access functions for SPCI
//              transfers to/from PCI memory and I/O space, block      
//              transfers (DMAs) over the PCI bus, and PCI interface init.     
//																			  
//  33 North Main Street                                                       
//  Concord, NH  03301                                                         
//  Tel: 603-226-0404                                                          
//  Fax: 603-226-6667                                                          
//  E-mail: support@bittware.com                                               
//                                                                             
//  Copyright 2001, BittWare, Inc.
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//	Ver		Author	Date	 	Changes                                       
//	---		------	----		-------			  					          
//	1.0		rpc		02/02/02	Creation                                      
//*****************************************************************************
#include <21160.h>
#include <def21160.h>
#include <stdio.h>
#include "fin_pci.h"
#include "fin.h"
#include "extint.h"

#ifndef SYSCON
#define SYSCON 0
#define SYSTAT 3
#endif

#if 0
#define FIN_DMA_LOC_ADDR_PTR   0x48
#define FIN_DMA_CTL_STAT_REG   0x49
#define CH0_CB_TO_PCI_START    0x45000000
#define CH1_CB_TO_PCI_START    0x47000000
#define CH0_PCI_TO_CB_START    0x41000000
#define CH1_PCI_TO_CB_START    0x43000000
#define FIN_DMA_DONE           0x01000000
#endif

//Globals
volatile int *fin_base = 0;
volatile int pci_error;
volatile int *fin_tx_buffer;
volatile int *fin_rx_buffer;
volatile int *fin_tx_fifo_stat;
volatile int *fin_rx_fifo_stat;
volatile int dummy;
static int epb_tbl[4] = {EPB0, EPB1, EPB2, EPB3};

// ----------------------  SPCI UTILITY FUNCTIONS  -------------------------

void SPCI_addr(int addr)
{
    // Load target PCI address
	SetFIN(SNGL_PCI_ADDR_REG_UPR, 0x00000000);
    SetFIN(SNGL_PCI_ADDR_REG_LWR, addr);
}

void SPCI_data_lwr32(int data)
{
    //Write lower 32 bits with data
    SetFIN(SNGL_PCI_DATA_REG_UPR, 0x00000000);
	SetFIN(SNGL_PCI_DATA_REG_LWR, data);
}

void SPCI_data_upr32(int data)
{
    //Write upper 32 bits with data
    SetFIN(SNGL_PCI_DATA_REG_UPR, data);
	SetFIN(SNGL_PCI_DATA_REG_LWR, 0x00000000);
}

void SPCI_command(int cmd)
{
	SetFIN(SPCI_COMMAND_REG, cmd);

	// Check status
	while(GetFIN(SPCI_COMMAND_REG) & SPCI_STATUS)
	{
	}

	pci_error = GetFIN(PCI_ERROR_REG);
	SetFIN(PCI_ERROR_REG, PCI_SPCI_MASK);
}

// get_processor_ID - Return the processor's ID
int get_processor_ID(void)
{
    return((GetIOP(SYSTAT) & 0xF00) >> 8);
}

// get_msize - Return the MSIZE field in SYSCON
int get_msize(void)
{
    return((GetIOP(SYSCON) & 0xF000) >> 12);
}

// get_MMS_addr - return the MMS address for
//                an internal address on this processor
int get_MMS_addr(int addr)
{
    return((addr) + 0x100000*get_processor_ID());
}

// get_SDRAM_top - Return the end address of SDRAM
//                 based on MSIZE
int get_SDRAM_top(void)
{
    int i;
	int temp;
	int nwords = 2;

	temp = get_msize() + 13;
	for(i = 1; i < temp; i++)
	{
	    nwords *= 2;
    }
    return(nwords);
}

// ------------------  SPCI MEMORY ACCESS FUNCTIONS  -------------------------

// SharcFin_SPCIWr64
//
// Write 64 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_SPCIWr64(unsigned int pciAddr, int data_hi, int data_lo)
{
	volatile int qWordAddr;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register then write the 
	// appropriate command to the SPCI command register.
	SetFIN(SNGL_PCI_DATA_REG_UPR, data_hi);
	SetFIN(SNGL_PCI_DATA_REG_LWR, data_lo);
	SPCI_command(SPCI64_WRITE);

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIRd64
//
// Read 64 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_SPCIRd64(unsigned int pciAddr, int *data_hi, int *data_lo)
{
	volatile int qWordAddr;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the appropriate command to the SPCI command register,
	// then read the data register.
	SPCI_command(SPCI64_READ);
	*data_hi = GetFIN(SNGL_PCI_DATA_REG_UPR);
	*data_lo = GetFIN(SNGL_PCI_DATA_REG_LWR);

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIWr32
//
// Write 32 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_SPCIWr32(unsigned int pciAddr, int data)
{
	volatile int qWordAddr;
	int wordSel;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	wordSel = (pciAddr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.

	switch (wordSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_WRITE_LO);
        break;

		case 1:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_WRITE_HI);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIRd32
//
// Read 32 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.
int SharcFin_SPCIRd32(unsigned int pciAddr, int *data)
{	
	volatile int qWordAddr;
	int wordSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	wordSel = (pciAddr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

  	// Write the SPCI command register
	switch (wordSel)
	{
		case 0:
		  SPCI_command(SPCI32_READ_LO);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR);
        break;

		case 1:
		  SPCI_command(SPCI32_READ_HI);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIWr16
//
// Write 16 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_SPCIWr16(unsigned int pciAddr, int data)
{ 
	volatile int qWordAddr;
	int wordSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	wordSel = (pciAddr & 0x00000006) >> 1;
	data &= 0xffff;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch(wordSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_WORD0_WR);
		break;

		case 1:
		  SPCI_data_lwr32(data << 16);
		  SPCI_command(SPCI32_WORD1_WR);
		break;

		case 2:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_WORD2_WR);
		break;

		case 3:
		  SPCI_data_upr32(data << 16);
		  SPCI_command(SPCI32_WORD3_WR);
		break;
	}

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIRd16
//
// Read 16 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.

int SharcFin_SPCIRd16(unsigned int pciAddr, int *data)
{
	volatile int qWordAddr;
	int wordSel;
	        		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	wordSel = (pciAddr & 0x00000006) >> 1;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the SPCI command register
	switch(wordSel)
	{
		case 0:
		  SPCI_command(SPCI32_WORD0_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) & 0xffff;
		break;

		case 1:
		  SPCI_command(SPCI32_WORD1_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) >> 16;
		break;

		case 2:
		  SPCI_command(SPCI32_WORD2_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) & 0xffff;
		break;

		case 3:
		  SPCI_command(SPCI32_WORD3_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) >> 16;
		break;
	}
	
	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIWr8
//
// Write 8 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_SPCIWr8(unsigned int pciAddr, int data)
{ 
	volatile int qWordAddr;
	int byteSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	byteSel = pciAddr & 0x00000007;
	data &= 0xff;  // write only 8 bits

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch(byteSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_BYTE0_WR);
		break;

		case 1:
		  SPCI_data_lwr32(data << 8);
		  SPCI_command(SPCI32_BYTE1_WR);
		break;

		case 2:
		  SPCI_data_lwr32(data << 16);
		  SPCI_command(SPCI32_BYTE2_WR);
		break;

		case 3:
		  SPCI_data_lwr32(data << 24);
		  SPCI_command(SPCI32_BYTE3_WR);
		break;

		case 4:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_BYTE4_WR);
		break;

		case 5:
		  SPCI_data_upr32(data << 8);
		  SPCI_command(SPCI32_BYTE5_WR);
		break;

		case 6:
		  SPCI_data_upr32(data << 16);
		  SPCI_command(SPCI32_BYTE6_WR);
		break;

		case 7:
		  SPCI_data_upr32(data << 24);
		  SPCI_command(SPCI32_BYTE7_WR);
		break;
	}

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_SPCIRd8
//
// Read 8 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.

int SharcFin_SPCIRd8(unsigned int pciAddr, int *data)
{
	volatile int qWordAddr;
	int byteSel;
	        		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffff8;
	byteSel = pciAddr & 0x00000007;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the SPCI command register
	switch(byteSel)
	{
		case 0:
		  SPCI_command(SPCI32_BYTE0_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) & 0xff;
		break;

		case 1:
		  SPCI_command(SPCI32_BYTE1_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 8) & 0xff;
		break;

		case 2:
		  SPCI_command(SPCI32_BYTE2_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 16) & 0xff;
		break;

		case 3:
		  SPCI_command(SPCI32_BYTE3_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 24) & 0xff;
		break;

		case 4:
		  SPCI_command(SPCI32_BYTE4_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) & 0xff;
		break;

		case 5:
		  SPCI_command(SPCI32_BYTE5_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 8) & 0xff;
		break;

		case 6:
		  SPCI_command(SPCI32_BYTE6_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 16) & 0xff;
		break;

		case 7:
		  SPCI_command(SPCI32_BYTE7_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 24) & 0xff;
		break;
	}
	
	return(pci_error & PCI_ERROR_MASK);
}

// --------------------  SPCI I/O ACCESS FUNCTIONS  -------------------------

// SharcFin_IO_SPCIWr32
//
// Write 32 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_IO_SPCIWr32(unsigned int pciAddr, int data)
{
	volatile int qWordAddr;
	int wordSel;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	wordSel = (pciAddr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch (wordSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_IO_WRITE_LO);
        break;

		case 1:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_IO_WRITE_HI);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_IO_SPCIRd32
//
// Read 32 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.
int SharcFin_IO_SPCIRd32(unsigned int pciAddr, int *data)
{
	volatile int qWordAddr;
	int wordSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	wordSel = (pciAddr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

  	// Write the SPCI command register
	switch (wordSel)
	{
		case 0:
		  SPCI_command(SPCI32_IO_READ_LO);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR);
        break;

		case 1:
		  SPCI_command(SPCI32_IO_READ_HI);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_IO_SPCIWr16
//
// Write 16 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_IO_SPCIWr16(unsigned int pciAddr, int data)
{ 
	volatile int qWordAddr;
	int wordSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	wordSel = (pciAddr & 0x00000006) >> 1;
	data &= 0xffff;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch(wordSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_IO_WORD0_WR);
		break;

		case 1:
		  SPCI_data_lwr32(data << 16);
		  SPCI_command(SPCI32_IO_WORD1_WR);
		break;

		case 2:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_IO_WORD2_WR);
		break;

		case 3:
		  SPCI_data_upr32(data << 16);
		  SPCI_command(SPCI32_IO_WORD3_WR);
		break;
	}

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_IO_SPCIRd16
//
// Read 16 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.

int SharcFin_IO_SPCIRd16(unsigned int pciAddr, int *data)
{
	volatile int qWordAddr;
	int wordSel;
	        		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	wordSel = (pciAddr & 0x00000006) >> 1;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the SPCI command register
	switch(wordSel)
	{
		case 0:
		  SPCI_command(SPCI32_IO_WORD0_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) & 0xffff;
		break;

		case 1:
		  SPCI_command(SPCI32_IO_WORD1_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) >> 16;
		break;

		case 2:
		  SPCI_command(SPCI32_IO_WORD2_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) & 0xffff;
		break;

		case 3:
		  SPCI_command(SPCI32_IO_WORD3_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) >> 16;
		break;
	}
	
	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_IO_SPCIWr8
//
// Write 8 bits with a SPCI transfer to the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or 0 if successful.
int SharcFin_IO_SPCIWr8(unsigned int pciAddr, int data)
{ 
	volatile int qWordAddr;
	int byteSel;
	
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	byteSel = pciAddr & 0x00000007;
	data &= 0xff;  // write only 8 bits

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch(byteSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI32_IO_BYTE0_WR);
		break;

		case 1:
		  SPCI_data_lwr32(data << 8);
		  SPCI_command(SPCI32_IO_BYTE1_WR);
		break;

		case 2:
		  SPCI_data_lwr32(data << 16);
		  SPCI_command(SPCI32_IO_BYTE2_WR);
		break;

		case 3:
		  SPCI_data_lwr32(data << 24);
		  SPCI_command(SPCI32_IO_BYTE3_WR);
		break;

		case 4:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI32_IO_BYTE4_WR);
		break;

		case 5:
		  SPCI_data_upr32(data << 8);
		  SPCI_command(SPCI32_IO_BYTE5_WR);
		break;

		case 6:
		  SPCI_data_upr32(data << 16);
		  SPCI_command(SPCI32_IO_BYTE6_WR);
		break;

		case 7:
		  SPCI_data_upr32(data << 24);
		  SPCI_command(SPCI32_IO_BYTE7_WR);
		break;
	}

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_IO_SPCIRd8
//
// Read 8 bits with a SPCI transfer from the address indicated by pciAddr.
// This function returns -1 if the PCI interface has not been initialized,
// or an error bit pattern if a PCI error occurred.  The requested data is 
// written to pointer data.

int SharcFin_IO_SPCIRd8(unsigned int pciAddr, int *data)
{
	volatile int qWordAddr;
	int byteSel;
	        		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = pciAddr & 0xfffffffb;
	byteSel = pciAddr & 0x00000007;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the SPCI command register
	switch(byteSel)
	{
		case 0:
		  SPCI_command(SPCI32_IO_BYTE0_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR) & 0xff;
		break;

		case 1:
		  SPCI_command(SPCI32_IO_BYTE1_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 8) & 0xff;
		break;

		case 2:
		  SPCI_command(SPCI32_IO_BYTE2_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 16) & 0xff;
		break;

		case 3:
		  SPCI_command(SPCI32_IO_BYTE3_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_LWR) >> 24) & 0xff;
		break;

		case 4:
		  SPCI_command(SPCI32_IO_BYTE4_RD);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR) & 0xff;
		break;

		case 5:
		  SPCI_command(SPCI32_IO_BYTE5_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 8) & 0xff;
		break;

		case 6:
		  SPCI_command(SPCI32_IO_BYTE6_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 16) & 0xff;
		break;

		case 7:
		  SPCI_command(SPCI32_IO_BYTE7_RD);
		  *data = (GetFIN(SNGL_PCI_DATA_REG_UPR) >> 24) & 0xff;
		break;
	}
	
	return(pci_error & PCI_ERROR_MASK);
}

// ------------------  SPCI CONFIGURATION ACCESS FUNCTIONS  ---------------------

// SharcFin_PCI_CFG_Write
//
// Write 32 bits with a SPCI transfer to the Base Address Register 
// indicated by addr.
// This function returns -1 if the PCI interface has not been initialized, 
// an error bit pattern if a PCI error occurred, or 0 if successful.
//
// WARNING: This function is meant for configuration of a stand-alone PCI
// bus.  If this function is called in a non-stand-alone system, such
// as in a PC host, the results are unpredictable, and the system may crash.
int SharcFin_PCI_CFG_Write(int addr, int data)
{
    volatile int qWordAddr;
	int wordSel;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = addr & 0xfffffff8;
	wordSel = (addr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

	// Write the data to the data register with the proper alignment
	// and then write the appropriate command to the SPCI command register.
	switch(wordSel)
	{
		case 0:
		  SPCI_data_lwr32(data);
		  SPCI_command(SPCI_WR_CONFIG_LO);
        break;

		case 1:
		  SPCI_data_upr32(data);
		  SPCI_command(SPCI_WR_CONFIG_HI);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}


// SharcFin_PCI_CFG_Read
//
// Read 32 bits with a SPCI transfer from the Base Address Register 
// indicated by addr.
// This function returns -1 if the PCI interface has not been initialized,
// an error bit pattern if a PCI error occurred, or the BAR if successful.
int SharcFin_PCI_CFG_Read(int addr, int *data)
{
    volatile int qWordAddr;
	int wordSel;
 		
	if(fin_base == 0)
	{
	    return(-1);
	}

	qWordAddr = addr & 0xfffffff8;
	wordSel = (addr & 0x00000004) >> 2;

    // Load the target PCI address
    SPCI_addr(qWordAddr);

  	// Write the SPCI command register
	switch(wordSel)
	{
		case 0:
		  SPCI_command(SPCI_RD_CONFIG_LO);
		  *data = GetFIN(SNGL_PCI_DATA_REG_LWR);
        break;

		case 1:
		  SPCI_command(SPCI_RD_CONFIG_HI);
		  *data = GetFIN(SNGL_PCI_DATA_REG_UPR);
        break;
    }

	return(pci_error & PCI_ERROR_MASK);
}

// ------------------  PCI INTERFACE INIT FUNCTION  -------------------------

// SharcFin_PCI_Init
//
// Initializes the pointer to the FIN

void SharcFin_PCI_Init(void)
{
#if defined (__ADSP21160__)
    int msize;

    // Initialize the pointer to the FIN (MS2), which differs with the MSIZE 
	// field in SYSCON in the case of the Hammerhead.
    msize = get_msize();
	if (msize < 9)	// Bank size = 2 ** (msize + 13) -> we want at least 2**22
	{
	    msize = 9;
		SetIOP(SYSCON, (GetIOP(SYSCON) | (msize << 12)));
	}
	fin_base = (int *) (0x800000 + (2 * (0x2000 << msize)));
#elif defined (__ADSP21065L__)
	fin_base = (int *) MS2_21065L;
#endif
}


// ------------------  PCI BLOCK MOVE FUNCTIONS  -------------------------

// SharcFin_PCI_DMA_Write
//
// This function uses bus master channel mchan (0 or 1) and DMAC dmac (10 to 13) 
// to write size bytes of data from pointer src to pointer dst.  
// Note that dst is a byte-oriented, 64-bit aligned PCI address, and src is internal
// memory space on the processor.  
// If wait flag is set to 1, the function will not return until the DMA is complete.
// If wait is set, AND the pointer ticks is non-NULL, ticks will contain the number 
// of system clocks that elapsed during the transfer.  
// If force32 flag is set to 1, the DMA will transfer in the lower 32 bits of the bus.
// Function returns the contents of the PCI error register on failure, or 0 on success.

int SharcFin_PCI_DMA_Write(int mchan, int dmac, int size, void *src, 
                           void *dst, int force32, int wait, int *ticks)
{
	int clocks;
	int timer;
	int done_flag;

	if(mchan == 0)
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT0);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT0); // flush FIFO
		done_flag = XMT0;

		if(force32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the FIN FIFO0 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR0, (int) dst);                      // PCI destination
		SetFIN(MAST_WR_XFR_CNT0, size);                        // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT0); // Start xfer
	}
	else
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT1);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT1); // flush FIFO
		done_flag = XMT1;

		if(force32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the FIN FIFO1 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR1, (int) dst);                      // PCI destination
		SetFIN(MAST_WR_XFR_CNT1, size);                        // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT1); // Start xfer
	}

	timer = (ticks != NULL) ? 1 : 0;

	// Transfer data from internal to external memory.
    clocks = intmem_to_extmem((int *)src,                 // Source buffer.
      	             (int *)fin_tx_buffer,                // Destination buffer.
       	             (size/4),                            // Buffer size (32-bit words)
					 0,                                   // External Increment (EM)
    	  		     dmac,                                // DMA Channel
					 DMAC_MASTER | DMAC_DEN | DMAC_TRANS, // flags for this transfer
			         wait,            	                  // Wait for DMA to complete?
                     timer);                              // Use the timer?

	if(ticks != NULL) *ticks = clocks;

	if(wait)
	{
		// Verify FIN to PCI xfer done
		while(GetFIN(DMA_START_DONE) & done_flag)
		{
		    asm("nop; nop; nop; nop; nop; nop; nop; nop;");
		    asm("nop; nop; nop; nop; nop; nop; nop; nop;");
		}
  	}

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}


// SharcFin_PCI_DMA_Read
//
// This function uses bus master channel mchan (0 or 1) and DMAC dmac (10 to 13) 
// to read size bytes of data from pointer src to pointer dst.  
// Note that src is a byte-oriented, 64-bit aligned PCI address, and dst is internal
// memory space on the processor.  
// If wait flag is set to 1, the function will not return until the DMA is complete.
// If wait is set, AND the pointer ticks is non-NULL, ticks will contain the number 
// of system clocks that elapsed during the transfer.  
// If force32 flag is set to 1, the DMA will transfer in the lower 32 bits of the bus.
// Function returns the contents of the PCI error register on failure, or 0 on success.

int SharcFin_PCI_DMA_Read(int mchan, int dmac, int size, void *src, 
                           void *dst, int force32, int wait, int *ticks)
{
	int clocks;
	int timer;

	timer = (ticks != NULL) ? 1 : 0;

	if(mchan == 0)
	{
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV0);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT0) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV0);

		if(force32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the FIN FIFO0 to PCI transfer DMA
SetFIN(RCV_FIFO_STATUS, GetFIN(RCV_FIFO_STATUS) | 0x3f);
		SetFIN(MAST_RD_ADDR0, (int) src);                      // PCI source
		SetFIN(MAST_RD_XFR_CNT0, size);                        // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV0); // Start xfer
		while(GetFIN(USR_ID_FIFO_STAT) & RCV0_EMPTY)           // wait for FIFO not empty
		    ;
	}
	else
	{
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV1);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT1) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }
	    SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV1);

		if(force32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the FIN FIFO1 to PCI transfer DMA
SetFIN(RCV_FIFO_STATUS, GetFIN(RCV_FIFO_STATUS) | 0x3f00);
		SetFIN(MAST_RD_ADDR1, (int) src);                      // PCI source
		SetFIN(MAST_RD_XFR_CNT1, size);                        // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV1); // Start xfer
		while(GetFIN(USR_ID_FIFO_STAT) & RCV1_EMPTY)           // wait for FIFO not empty
		    ;
	}

	clocks = extmem_to_intmem((int *)fin_rx_buffer,   // Source buffer.
			                  (int *)dst,    	      // Destination buffer.
			                  (size/4),    		      // Buffer size
							  0,                      // External Increment (EM)
			                  dmac,                   // DMA Channel
							  DMAC_MASTER | DMAC_DEN, // flags for this transfer
			                  wait,            	      // Wait for DMA to complete?
                              timer);                 // Use the timer?
	
							  
	if(ticks != NULL) *ticks = clocks;

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}

// Fin_PCI_CB_DMA_Setup_Xfer (For SHARC FIN Rev 4 and above)
//
// This function is used to prepare for a PCI block transfer based on the DMA engine
// in the SHARC FIN.  It sets parameters for the transfer in a structure of type 
// CLST_BUS_XFER_T (defined in fin_pci.h) by sending it's pointer.  The structure
// elements are:
//
//   int channel;               // 0 or 1 (FIN PCI master channel)
//   int direction;             // 0 = READ, 1 = WRITE
//   int burst_size;            // 8, 16, 32, or 64
//   int burst_control;         // 0 = enable, 1 = disable
//   int interrupt_control;     // 0 = disable, 1 = enable; see note 1
//   int bus_lock_control;      // 0 = disable, 1 = enable
//   int stride;                // 0 to 255; see note 2
//   int hh_slave_dmac;         // 0 = do not use slave DMA; 10-13 = DMAC10 - DMAC13
//   int dma_width;             // 0 = 64-bit, 1 forces 32-bit width
//	 int wait_control;          // 0 = do not wait for DMA complete, 1 = do wait
//
// The file fin_pci.h has API defines to fill the above struct, as:
//   #define FIN_DMA_READ             0
//   #define FIN_DMA_WRITE            1
//   #define FIN_DMA_CHAN0            0
//   #define FIN_DMA_CHAN1            1
//   #define FIN_DMA_BURST_ENABLE     0
//   #define FIN_DMA_BURST_DISABLE    1
//   #define FIN_DMA_INTRPT_DISABLE   0
//   #define FIN_DMA_INTRPT_ENABLE    1
//   #define FIN_DMA_BUSLOCK_DISABLE  0
//   #define FIN_DMA_BUSLOCK_ENABLE   1
//   #define FIN_DMA_NO_WAIT          0
//   #define FIN_DMA_WAIT             1
//   #define FIN_DMA_DMAR_DISABLE     0
//   #define FIN_DMA_DMAR_ENABLE      1
//   #define FIN_DMA_WIDTH_64         0
//   #define FIN_DMA_WIDTH_32         1
//   #define FIN_DMA_BURST_8          8
//   #define FIN_DMA_BURST_16         16
//   #define FIN_DMA_BURST_32         32
//   #define FIN_DMA_BURST_64         64
//   #define FIN_DMA_HH_SLAVE_NONE    0
//   #define FIN_DMA_HH_SLAVE_DMAC10  10
//   #define FIN_DMA_HH_SLAVE_DMAC11  11
//   #define FIN_DMA_HH_SLAVE_DMAC12  12
//   #define FIN_DMA_HH_SLAVE_DMAC13  13
//
// This function is used to prepare for a call to one of the DMA transfer functions:
//    Fin_PCI_CB_DMA_Write
//    Fin_PCI_CB_DMA_Read
//    Fin_PCI_CB_HH_DMA_Write
//    Fin_PCI_CB_HH_DMA_Read
//
// Fin_PCI_CB_DMA_Setup_Xfer returns -1 if a parameter is out of range; 0 on success.
//
// NOTE 1 - INTERRUPTS:
// If two or more subsequent calls to this function are used to set up some transfers,
// (before transfers are started) and if the end-of-transfer interrupt is to be enabled 
// on one of the transfers, the LAST call to Fin_PCI_CB_DMA_Setup_Xfer must enable the 
// interrupt.
// NOTE 2 - STRIDE:
// The stride element of the CLST_BUS_XFER_T structure has two meanings, depending upon
// the transfer function used.  When using Fin_PCI_CB_DMA_Write or Fin_PCI_CB_DMA_Read,
// stride is handled by the FIN DMA engine, and implies 64-bit striding.  When using 
// Fin_PCI_CB_HH_DMA_Write or Fin_PCI_CB_HH_DMA_Read, stride is handled by the HH DMAC, 
// and implies 32-bit striding.

int Fin_PCI_CB_DMA_Setup_Xfer(CLST_BUS_XFER_T *xfr)
{
    unsigned long dmac_word = 0;
	unsigned long temp;
	unsigned long fifo_stat;
	int int_mux_reg;

	// Parameter checking
	if(
		(xfr->channel != 0 && xfr->channel != 1) ||
		(xfr->direction != 0 && xfr->direction != 1) ||
		(xfr->burst_size != 8 && xfr->burst_size != 16 && xfr->burst_size != 32 && xfr->burst_size != 64) ||
		(xfr->interrupt_control != 0 && xfr->interrupt_control != 1)  ||
		(xfr->burst_control != 0 && xfr->burst_control != 1)  ||
		(xfr->bus_lock_control != 0 && xfr->bus_lock_control != 1)  ||
		(xfr->dma_width != 0 && xfr->dma_width != 1)  ||
		(xfr->wait_control != 0 && xfr->wait_control != 1)  ||
		(xfr->stride < 0 || xfr->stride > 255)  ||
		(xfr->hh_slave_dmac != 0 && xfr->hh_slave_dmac != 10 && xfr->hh_slave_dmac != 11 && 
		    xfr->hh_slave_dmac != 12 && xfr->hh_slave_dmac != 13) ||
		(xfr->stride != 0 && xfr->hh_slave_dmac != 0)
    )
	{
	    xfr->dmac = 0;
	    return(-1);
	}

    // build dmac_word and save to struct
	if(xfr->channel == FIN_DMA_CHAN1)                   dmac_word =  CLST_BUS_XFER_DMA_CHAN1;
	if(xfr->direction == FIN_DMA_WRITE)                 dmac_word |= CLST_BUS_XFER_WRITE;
	if(xfr->interrupt_control == FIN_DMA_INTRPT_ENABLE) dmac_word |= CLST_BUS_XFER_INTR_ENA;
	if(xfr->burst_control == FIN_DMA_BURST_DISABLE)     dmac_word |= CLST_BUS_XFER_BRST_DISA;
	if(xfr->bus_lock_control == FIN_DMA_BUSLOCK_ENABLE) dmac_word |= CLST_BUS_XFER_BUS_LOCK;

	switch(xfr->burst_size)
	{
	  case FIN_DMA_BURST_16:
	    dmac_word |= CLST_BUS_XFER_BRST_LEN0;
	  break;

	  case FIN_DMA_BURST_32:
	    dmac_word |= CLST_BUS_XFER_BRST_LEN1;
	  break;

	  case FIN_DMA_BURST_64:
	    dmac_word |= CLST_BUS_XFER_BRST_LEN0;
	    dmac_word |= CLST_BUS_XFER_BRST_LEN1;
	  break;
	}

	dmac_word |= (xfr->stride << 16);

	dmac_word |= CLST_BUS_XFER_DMA_START;

	xfr->dmac = dmac_word;

    // set up the FIFO status register
	temp = xfr->burst_size - 1;
    if(xfr->direction == FIN_DMA_WRITE)
	{
	    fifo_stat = GetFIN(XMT_FIFO_STATUS);
		fifo_stat &= (xfr->channel == FIN_DMA_CHAN1) ? ~(0xff << 24) : ~(0xff << 16);
	    temp <<= (xfr->channel == FIN_DMA_CHAN1) ? 24 : 16;
	    SetFIN(XMT_FIFO_STATUS, fifo_stat | temp);
	}
	else  //Read
	{
	    fifo_stat = GetFIN(RCV_FIFO_STATUS);
		fifo_stat &= (xfr->channel == FIN_DMA_CHAN1) ? ~(0xff << 8) : ~0xff;
	    temp <<= (xfr->channel == FIN_DMA_CHAN1) ? 8 : 0;
	    SetFIN(RCV_FIFO_STATUS, fifo_stat | temp);
	}

	// set or clear int mux bit
	int_mux_reg = FIN_HH1_IRQ0 + 2*(get_processor_ID() - 1);
	if(xfr->interrupt_control == FIN_DMA_INTRPT_ENABLE)
	{
	    SetFIN(int_mux_reg, (GetFIN(int_mux_reg) | B_CL_BUS_DMA_MSK));
	}
	else
	{
	    SetFIN(int_mux_reg, (GetFIN(int_mux_reg) & ~B_CL_BUS_DMA_MSK));
	}

	return(0);
}

// Fin_PCI_CB_DMA_Write (For SHARC FIN Rev 4 and above)
//
// This function uses calling arguments which include parameters in the CLST_BUS_XFER_T 
// structure tx to DMA a block of count 32-bit words from the memory on the cluster bus 
// to PCI space.  
// Note that local_addr (source) can point to either HH internal or to SDRAM memory, 
// and both local_addr and pci_addr are 64-bit aligned addresses.  
// Function returns the contents of the PCI error register on failure, or 0 on success.
// PCI error bits are defined in fin_pci.h.
int Fin_PCI_CB_DMA_Write(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *tx)
{
	int done_flag;
	int loc_addr;

    loc_addr = (local_addr < (int *) 0x800000) ? get_MMS_addr((int)local_addr) : (int)local_addr;

	if(tx->channel == 0)
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT0);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT0); // flush FIFO
		done_flag = XMT0;

		if(tx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the FIN FIFO0 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR0, (int) pci_addr);                 // PCI destination
		SetFIN(MAST_WR_XFR_CNT0, count*4);                     // Buffer size in bytes
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT0); // Start xfer
	}
	else  // Channel 1
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT1);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT1); // flush FIFO
		done_flag = XMT1;

		if(tx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the FIN FIFO1 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR1, (int) pci_addr);                 // PCI destination
		SetFIN(MAST_WR_XFR_CNT1, count*4);                     // Buffer size in bytes
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT1); // Start xfer
	}

	// Transfer data from cluster bus to FIN FIFO
	SetFIN(FIN_DMA_LOC_ADDR_PTR, loc_addr);   // local source address
	tx->dmac &= ~0x0000ffff;                  // clear count field
	tx->dmac |= (count >> 1);                 // count in 64-bit words
	SetFIN(FIN_DMA_CTL_STAT_REG, tx->dmac);   // kick off DMA

	if(tx->wait_control == FIN_DMA_NO_WAIT)
	    return(0);

	while(GetFIN(DMA_START_DONE) & done_flag)
	{
	    asm("nop; nop; nop; nop; nop;");
	}

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}

// Fin_PCI_CB_DMA_Read (For SHARC FIN Rev 4 and above)
//
// This function uses calling arguments which include parameters in the CLST_BUS_XFER_T 
// structure rx to DMA a block of count 32-bit words from PCI space to the memory on the 
// cluster bus.
// Note that local_addr (destination) can point to either HH internal or to SDRAM memory, 
// and both local_addr and pci_addr are 64-bit aligned addresses.  
// Function returns the contents of the PCI error register on failure, or 0 on success.
// PCI error bits are defined in fin_pci.h.
int Fin_PCI_CB_DMA_Read(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *rx)
{
	int loc_addr;

    loc_addr = (local_addr < (int *) 0x800000) ? get_MMS_addr((int)local_addr) : (int)local_addr;

	if(rx->channel == 0)
    {
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV0);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT0) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }

		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV0);

		if(rx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the PCI to FIN FIFO0 transfer DMA
		SetFIN(MAST_RD_ADDR0, (int) pci_addr);                 // PCI source
		SetFIN(MAST_RD_XFR_CNT0, count*4);                     // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV0); // Start xfer
    }
	else  // Channel 1
	{
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV1);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT1) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }

		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV1);

		if(rx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the PCI to FIN FIFO1 transfer DMA
		SetFIN(MAST_RD_ADDR1, (int) pci_addr);                 // PCI source
		SetFIN(MAST_RD_XFR_CNT1, count*4);                     // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV1); // Start xfer
	}

	// Transfer data from FIN FIFO to cluster bus
	SetFIN(FIN_DMA_LOC_ADDR_PTR, loc_addr);    // local destination
	rx->dmac &= ~0x0000ffff;                   // clear count field
	rx->dmac |= (count >> 1);                  // count in 64-bit words
	SetFIN(FIN_DMA_CTL_STAT_REG, rx->dmac);    // kick off DMA

	if(rx->wait_control == FIN_DMA_NO_WAIT)
	    return(0);

	while(GetFIN(FIN_DMA_CTL_STAT_REG) & CLST_BUS_XFER_DMA_DONE)
	{
	    asm("nop; nop; nop; nop; nop;");
	}

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}

// Fin_PCI_CB_HH_DMA_Write (For SHARC FIN Rev 4 and above)
//
// This function uses calling arguments which include parameters in the CLST_BUS_XFER_T 
// structure tx, to DMA a block of count 32-bit words from internal memory to PCI space.  
// It differs from Fin_PCI_CB_DMA_Write in that it uses one of the Hammerhead's external 
// port DMA channels, specified in tx structure element hh_slave_dmac, to increase the 
// transfer performance.  Element hh_slave_dmac must be set to 10, 11, 12 or 13.  The 
// disadvantage of this function is that it ties up a HH resource, the DMAC channel.
// Parameter local_addr (source) must point to HH internal memory, and both local_addr 
// and pci_addr are 64-bit aligned addresses.  
// Function returns -1 if tx structure element hh_slave_dmac = 0; the contents of the 
// PCI error register on failure, or 0 on success.
// PCI error bits are defined in fin_pci.h.
int Fin_PCI_CB_HH_DMA_Write(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *tx)
{
	int done_flag;
	int epb_addr;

	if(!(tx->hh_slave_dmac)) // if no DMAC resource
	{
	    return(-1);
	}

	epb_addr = get_MMS_addr(epb_tbl[tx->hh_slave_dmac - 10]);

	if(tx->channel == 0)
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT0);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT0); // flush FIFO
		done_flag = XMT0;

		if(tx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the FIN FIFO0 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR0, (int) pci_addr);                 // PCI destination
		SetFIN(MAST_WR_XFR_CNT0, count*4);                     // Buffer size in bytes
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT0); // Start xfer
	}
	else  // Channel 1
	{
	    fin_tx_buffer = (int *)(fin_base + XMT_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | XMT1);            // stop a FIN DMA if in progress
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | FIFO_FLUSH_XMT1); // flush FIFO
		done_flag = XMT1;

		if(tx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the FIN FIFO1 to PCI transfer DMA
		SetFIN(MAST_WR_ADDR1, (int) pci_addr);                 // PCI destination
		SetFIN(MAST_WR_XFR_CNT1, count*4);                     // Buffer size in bytes
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | XMT1); // Start xfer
	}

	// Start the slave DMA
	intmem_to_epb(local_addr, count, tx->hh_slave_dmac, DMAC_DEN | DMAC_TRANS | DMAC_BURST, 0);

	// Transfer data from cluster bus to FIN FIFO
	SetFIN(FIN_DMA_LOC_ADDR_PTR, epb_addr);   // local source address
	tx->dmac &= ~0x0000ffff;                  // clear count field
	tx->dmac |= (count >> 1);                 // count in 64-bit words
	SetFIN(FIN_DMA_CTL_STAT_REG, tx->dmac);   // kick off DMA

	if(tx->wait_control == FIN_DMA_NO_WAIT)
	    return(0);

	while(GetFIN(DMA_START_DONE) & done_flag)
	{
	    asm("nop; nop; nop; nop; nop;");
	}

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}

// Fin_PCI_CB_HH_DMA_Read (For SHARC FIN Rev 4 and above)
//
// This function uses calling arguments which include parameters in the CLST_BUS_XFER_T 
// structure rx, to DMA a block of count 32-bit words from PCI space to internal memory.  
// It differs from Fin_PCI_CB_DMA_Read in that it uses one of the Hammerhead's external 
// port DMA channels, specified in rx structure element hh_slave_dmac, to increase the 
// transfer performance.  Element hh_slave_dmac must be set to 10, 11, 12 or 13.  The 
// disadvantage of this function is that it ties up a HH resource, the DMAC channel.
// Parameter local_addr (destination) must point to HH internal memory, and both 
// local_addr and pci_addr are 64-bit aligned addresses.  
// Function returns -1 if tx structure element hh_slave_dmac = 0; the contents of the 
// PCI error register on failure, or 0 on success.
// PCI error bits are defined in fin_pci.h.
int Fin_PCI_CB_HH_DMA_Read(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *rx)
{
	int epb_addr;

	if(!(rx->hh_slave_dmac)) // if no DMAC resource
	{
	    return(-1);
	}

	epb_addr = get_MMS_addr(epb_tbl[rx->hh_slave_dmac - 10]);

	if(rx->channel == 0)
    {
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO0);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV0);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT0) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }

		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV0);

		if(rx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER0);
	    }

	    // Start the PCI to FIN FIFO0 transfer DMA
		SetFIN(MAST_RD_ADDR0, (int) pci_addr);                 // PCI source
		SetFIN(MAST_RD_XFR_CNT0, count*4);                     // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV0); // Start xfer
    }
	else  // Channel 1
	{
	    fin_rx_buffer = (int *)(fin_base + RCV_FIFO1);
		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | RCV1);  // stop a FIN DMA if one is in progress
		while(GetFIN(MAST_RD_CNT_STAT1) > 0)
		{
		    dummy = *fin_rx_buffer;
	    }

		SetFIN(DMA_CONTROL1, GetFIN(DMA_CONTROL1) | REBURST_ENA_RCV1);

		if(rx->dma_width == FIN_DMA_WIDTH_32)
		{
		    SetFIN(DMA_CONTROL2, GetFIN(DMA_CONTROL2) | FORCE_32_XFER1);
	    }

	    // Start the PCI to FIN FIFO1 transfer DMA
		SetFIN(MAST_RD_ADDR1, (int) pci_addr);                 // PCI source
		SetFIN(MAST_RD_XFR_CNT1, count*4);                     // Buffer size (bytes)
		SetFIN(DMA_START_DONE, GetFIN(DMA_START_DONE) | RCV1); // Start xfer
	}

	intmem_to_epb(local_addr, count, rx->hh_slave_dmac, DMAC_DEN | DMAC_BURST, 0);

	// Transfer data from FIN FIFO to cluster bus
	SetFIN(FIN_DMA_LOC_ADDR_PTR, epb_addr);    // local destination
	rx->dmac &= ~0x0000ffff;                   // clear count field
	rx->dmac |= (count >> 1);                  // count in 64-bit words
	SetFIN(FIN_DMA_CTL_STAT_REG, rx->dmac);    // kick off DMA

	if(rx->wait_control == FIN_DMA_NO_WAIT)
	    return(0);

	while(GetFIN(FIN_DMA_CTL_STAT_REG) & CLST_BUS_XFER_DMA_DONE)
	{
	    asm("nop; nop; nop; nop; nop;");
	}

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}

// Fin_PCI_CB_DMA_Clear_Interrupt (For SHARC FIN Rev 4 and above)
//
//  Call this function to clear the interrupt condition when using 
//  the Cluster Bus SHARCFIN DMA 
void Fin_PCI_CB_DMA_Clear_Interrupt(void)
{
    SetFIN(FIN_DMA_CTL_STAT_REG, 0);
}
