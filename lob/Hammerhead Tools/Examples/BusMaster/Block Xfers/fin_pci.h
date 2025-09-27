//**********************************************************
//  fin_pci.h : Support for PCI_LIB functions for the SharcFin
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
//    Ver.  Dates     Changes                                
//    ----  --------  ---------------------------------------
//    1.0   02/06/01  Create for PCI_LIB
//    1.1   06/13/01  Additions for FIN v4
//
//**********************************************************
#if !defined(FINPCI_H)
#define FINPCI_H

#ifndef FALSE
#define FALSE   0
#define TRUE    (!FALSE)
#endif

#ifndef NULL
#define NULL (void *)0
#endif

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

// Cluster bus transfer support
typedef struct
{
    unsigned long local_addr;  // 0x40000 - 0x5ffff, or 0x800000 to top of SDRAM
    unsigned long pci_addr;    // Any valid PCI memory adress
	int size;                  // max 2^16 64-bit words
	unsigned long dmac;        // the word to be built and used by R/W functions
	int channel;               // 0 or 1
	int direction;             // 0 = READ, 1 = WRITE
	int burst_size;            // 8, 16, 32, or 64
	int burst_control;         // 0 = enable, 1 = disable
	int interrupt_control;     // 0 = disable, 1 = enable
	int bus_lock_control;      // 0 = disable, 1 = enable
	int stride;                // 0 to 255
	int hh_slave_dmac;         // 0 = do not use; 10, 11, 12, or 13 can use only when stride = 0
	int dma_width;             // 0 = 64-bit, 1 forces 32-bit width
	int wait_control;          // 0 = do not wait for DMA complete, 1 = do wait
}CLST_BUS_XFER_T; // Cluster bus transfer type

// internal defines
#define CLST_BUS_XFER_DMA_START  0x01000000
#define CLST_BUS_XFER_DMA_CHAN1  0x02000000
#define CLST_BUS_XFER_WRITE      0x04000000
#define CLST_BUS_XFER_READ       ~CLST_BUS_XFER_WRITE 
#define CLST_BUS_XFER_INTR_ENA   0x08000000
#define CLST_BUS_XFER_BRST_DISA  0x10000000
#define CLST_BUS_XFER_BUS_LOCK   0x20000000
#define CLST_BUS_XFER_BRST_LEN0  0x40000000
#define CLST_BUS_XFER_BRST_LEN1  0x80000000
#define CLST_BUS_XFER_DMA_DONE   CLST_BUS_XFER_DMA_START
#define CLST_BUS_XFER_DMAR_ENA   0x00000001
#define CLST_BUS_XFER_DMAR_CH1   0x00000002
#define CLST_BUS_XFER_DMAR_WR    0x00000004

// API defines
#define FIN_DMA_READ             0
#define FIN_DMA_WRITE            1
#define FIN_DMA_CHAN0            0
#define FIN_DMA_CHAN1            1
#define FIN_DMA_BURST_ENABLE     0
#define FIN_DMA_BURST_DISABLE    1
#define FIN_DMA_INTRPT_DISABLE   0
#define FIN_DMA_INTRPT_ENABLE    1
#define FIN_DMA_BUSLOCK_DISABLE  0
#define FIN_DMA_BUSLOCK_ENABLE   1
#define FIN_DMA_NO_WAIT          0
#define FIN_DMA_WAIT             1
#define FIN_DMA_DMAR_DISABLE     0
#define FIN_DMA_DMAR_ENABLE      1
#define FIN_DMA_WIDTH_64         0
#define FIN_DMA_WIDTH_32         1
#define FIN_DMA_BURST_8          8
#define FIN_DMA_BURST_16         16
#define FIN_DMA_BURST_32         32
#define FIN_DMA_BURST_64         64
#define FIN_DMA_HH_SLAVE_NONE    0
#define FIN_DMA_HH_SLAVE_DMAC10  10
#define FIN_DMA_HH_SLAVE_DMAC11  11
#define FIN_DMA_HH_SLAVE_DMAC12  12
#define FIN_DMA_HH_SLAVE_DMAC13  13

//Globals
extern volatile int pci_error;
extern volatile int *fin_base;

//PCI Error masks
#define PCI_ERROR_MASK  0x0f3f0000   // Masks off all bits except PCI errors
#define PCI_SPCI_MASK   0x0f000000   // Mask used to clear SPCI errors
#define PCI_ERROR_PED   0x08000000   // Parity error flag detected
#define PCI_ERROR_MRT   0x04000000   // Maximum retry timeout flag
#define PCI_ERROR_MA    0x02000000   // Master abort has occurred
#define PCI_ERROR_RTA   0x01000000   // Received target abort
#define PCI_ERROR_SPCI  0x00200000   // Error during Single PCI access
#define PCI_ERROR_CHN   0x00100000   // Error during chained mode access
#define PCI_ERROR_RCV1  0x00080000   // Error during Receive DMA chan 1
#define PCI_ERROR_RCV0  0x00040000   // Error during Receive DMA chan 0
#define PCI_ERROR_XMT1  0x00020000   // Error during Transmit DMA chan 0
#define PCI_ERROR_XMT0  0x00010000   // Error during Transmit DMA chan 1

//******************************************************************************
// Utility function prototypes
void SPCI_addr(int addr);
void SPCI_data_lwr32(int data);
void SPCI_data_upr32(int data);
void SPCI_command(int cmd);
int get_msize(void);
int get_processor_ID(void);
int get_MMS_addr(int addr);
int get_SDRAM_top(void);

// External Function Prototypes
// init routine
extern void SharcFin_PCI_Init(void);

// SPCI to/from memory
extern int SharcFin_SPCIWr64(unsigned int pciAddr, int data_hi, int data_lo);
extern int SharcFin_SPCIRd64(unsigned int pciAddr, int *data_hi, int *data_lo);
extern int SharcFin_SPCIWr32(unsigned int pciAddr, int data); 
extern int SharcFin_SPCIRd32(unsigned int pciAddr, int *data); 
extern int SharcFin_SPCIWr16(unsigned int pciAddr, int data);
extern int SharcFin_SPCIRd16(unsigned int pciAddr, int *data);
extern int SharcFin_SPCIWr8(unsigned int pciAddr, int data);
extern int SharcFin_SPCIRd8(unsigned int pciAddr, int *data);

// SPCI to/from I/O space
extern int SharcFin_IO_SPCIWr64(unsigned int pciAddr, int data_hi, int data_lo);
extern int SharcFin_IO_SPCIRd64(unsigned int pciAddr, int *data_hi, int *data_lo);
extern int SharcFin_IO_SPCIWr32(unsigned int pciAddr, int data); 
extern int SharcFin_IO_SPCIRd32(unsigned int pciAddr, int *data); 
extern int SharcFin_IO_SPCIWr16(unsigned int pciAddr, int data);
extern int SharcFin_IO_SPCIRd16(unsigned int pciAddr, int *data);
extern int SharcFin_IO_SPCIWr8(unsigned int pciAddr, int data);
extern int SharcFin_IO_SPCIRd8(unsigned int pciAddr, int *data);

// PCI config routines
extern int SharcFin_PCI_CFG_Write(int addr, int data);
extern int SharcFin_PCI_CFG_Read(int addr, int *data);

// internal <--> PCI DMA
extern int SharcFin_PCI_DMA_Write(int mchan, int dmac, int size, void *src, 
                           void *dst, int force32, int wait, int *ticks);
extern int SharcFin_PCI_DMA_Read(int mchan, int dmac, int size, void *src, 
                           void *dst, int force32, int wait, int *ticks);

// cluster bus <--> PCI DMA (Fin version 4 and higher)
extern int Fin_PCI_CB_DMA_Setup_Xfer(CLST_BUS_XFER_T *xfer);
extern int Fin_PCI_CB_DMA_Write(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *tx);
extern int Fin_PCI_CB_DMA_Read(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *rx);
extern int Fin_PCI_CB_HH_DMA_Write(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *tx);
extern int Fin_PCI_CB_HH_DMA_Read(void *local_addr, void *pci_addr, int count, CLST_BUS_XFER_T *rx);
void Fin_PCI_CB_DMA_Clear_Interrupt(void);
#endif
//**********************************************************
// End of file fin_pci.h
//**********************************************************
