//*****************************************************************************
//                                                                             
//  fin_pci.c : Collection of SharcFin PCI bus access functions for SPCI
//              transfers to/from PCI memory and I/O space, block      
//              transfers (DMAs) over the PCI bus, and PCI interface init.     
// Juancigno
//																			  
//*****************************************************************************
#include <21160.h>
#include <def21160.h>
#include <stdio.h>
#include "fin_pci.h"
#include "fin.h"
#include "extint0.h"

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
			                  (size/4),    		      // Buffer size
							  0,                      // External Increment (EM)
			                  dmac,                   // DMA Channel
							  DMAC_MASTER | DMAC_DEN, // flags for this transfer
			                  wait,            	      // Wait for DMA to complete?
                              timer);                 // Use the timer?
	
							  
	if(ticks != NULL) *ticks = clocks;

	return(GetFIN(PCI_ERROR_REG) & PCI_ERROR_MASK);
}


