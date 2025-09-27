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

//Globals
extern volatile int pci_error;
extern volatile int *fin_base;


//**********************************************************
// External Function Prototypes
extern void SharcFin_PCI_Init(void);
extern int SharcFin_SPCIWr64(unsigned int pciAddr, int data_hi, int data_lo);
extern int SharcFin_SPCIRd64(unsigned int pciAddr, int *data_hi, int *data_lo);
extern int SharcFin_SPCIWr32(unsigned int pciAddr, int data); 
extern int SharcFin_SPCIRd32(unsigned int pciAddr, int *data); 
extern int SharcFin_SPCIWr16(unsigned int pciAddr, int data);
extern int SharcFin_SPCIRd16(unsigned int pciAddr, int *data);
extern int SharcFin_SPCIWr8(unsigned int pciAddr, int data);
extern int SharcFin_SPCIRd8(unsigned int pciAddr, int *data);

extern int SharcFin_IO_SPCIWr64(unsigned int pciAddr, int data_hi, int data_lo);
extern int SharcFin_IO_SPCIRd64(unsigned int pciAddr, int *data_hi, int *data_lo);
extern int SharcFin_IO_SPCIWr32(unsigned int pciAddr, int data); 
extern int SharcFin_IO_SPCIRd32(unsigned int pciAddr, int *data); 
extern int SharcFin_IO_SPCIWr16(unsigned int pciAddr, int data);
extern int SharcFin_IO_SPCIRd16(unsigned int pciAddr, int *data);
extern int SharcFin_IO_SPCIWr8(unsigned int pciAddr, int data);
extern int SharcFin_IO_SPCIRd8(unsigned int pciAddr, int *data);

extern int SharcFin_PCI_CFG_Write(int addr, int data);
extern int SharcFin_PCI_CFG_Read(int addr, int *data);

extern int SharcFin_PCI_DMA_Write(int mchan, int dmac, int size, void *src, 
                                  void *dst, int force32, int wait, int *ticks);
extern int SharcFin_PCI_DMA_Read(int mchan, int dmac, int size, void *src, 
                                 void *dst, int force32, int wait, int *ticks);

#endif
//**********************************************************
// End of file fin_pci.h
//**********************************************************
