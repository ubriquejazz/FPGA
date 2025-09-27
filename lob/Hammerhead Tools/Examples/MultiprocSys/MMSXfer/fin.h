//**********************************************************
//  fin.h : SharcFin definitions and macros
//
//  PROVIDED BY:
//  ------------
//  BittWare, Inc.
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
#if !defined(FIN_H)
#define FIN_H

// Macros
#define MS2_21065L        0x02000000
#define SetFIN(addr,val)  (*(volatile unsigned long *) (fin_base + (addr)))=(val)
#define GetFIN(addr)      (*(volatile unsigned long *) (fin_base + (addr)))

// Configuration addresses
#define LOCAL_BAR0_ADDR   0x00020010
#define LOCAL_BAR1_ADDR   0x00020014
#define LOCAL_BAR2_ADDR   0x00020018
#define LOCAL_BAR3_ADDR   0x0002001c
#define LOCAL_BAR4_ADDR   0x00020020
#define LOCAL_BAR5_ADDR   0x00020024
#define LOCAL_ROM_ADDR    0x00020030
#define LOCAL_MODE_ADDR   0x00020004
#define PMC_1_BAR0_ADDR   0x00080010
#define PMC_1_BAR1_ADDR   0x00080014
#define PMC_1_BAR2_ADDR   0x00080018
#define PMC_1_BAR3_ADDR   0x0008001c
#define PMC_1_BAR4_ADDR   0x00080020
#define PMC_1_BAR5_ADDR   0x00080024
#define PMC_1_ROM_ADDR    0x00080030
#define PMC_1_MODE_ADDR   0x00080004
#define PMC_2_BAR0_ADDR   0x00100010
#define PMC_2_BAR1_ADDR   0x00100014
#define PMC_2_BAR2_ADDR   0x00100018
#define PMC_2_BAR3_ADDR   0x0010001c
#define PMC_2_BAR4_ADDR   0x00100020
#define PMC_2_BAR5_ADDR   0x00100024
#define PMC_2_ROM_ADDR    0x00100030
#define PMC_2_MODE_ADDR   0x00100004
  
// FIN commands
#define XMT0              0x00010000  // Start/check/cancel the FIN to PCI 0 xfer
#define XMT1              0x00020000  // Start/check/cancel the FIN to PCI 1 xfer
#define RCV0              0x00040000  // Start/check/cancel the PCI to FIN 0 xfer
#define RCV1              0x00080000  // Start/check/cancel the PCI to FIN 1 xfer
#define FIFO_FLUSH_XMT0   0x00200000  // Flush transmit FIFO0
#define FIFO_FLUSH_XMT1   0x00400000  // flush transmit FIFO1
#define SPCI_STATUS       0x20000000  // Bit mask to check SPCI done
#define PCI_ERROR_MASK    0x0f3f0000  // Bit mask to check for PCI errors
#define FORCE_32_XFER0    0x00000005  // Force a 32-bit xmt/rcv on chan 0
#define FORCE_32_XFER1    0x0000000a  // Force a 32-bit xmt/rcv on chan 1
#define REBURST_ENA_RCV0  0x04000000  // Receive reburst enable for channel 0
#define REBURST_ENA_RCV1  0x08000000  // Receive reburst enable for channel 1

// 64- and 32-bit MEMORY read/write commands, enabling 64-, 32-, 16-, and 8-bit accesses.
#define SPCI64_READ       0x26FF0000  // Start a 64-bit single PCI access read
#define SPCI64_WRITE      0x27FF0000  // Start a 64-bit single PCI access write
#define SPCI32_READ_LO    0x360F0000  // Start a LS 32-bit single PCI access read
#define SPCI32_WRITE_LO   0x370F0000  // Start a LS 32-bit single PCI access write
#define SPCI32_READ_HI    0x36F00000  // Start a MS 32-bit single PCI access read
#define SPCI32_WRITE_HI   0x37F00000  // Start a MS 32-bit single PCI access write
#define SPCI32_WORD0_RD   0x36030000  // Start a 32-bit SPCI read  byte lanes 0 & 1
#define SPCI32_WORD0_WR   0x37030000  // Start a 32-bit SPCI write byte lanes 0 & 1
#define SPCI32_WORD1_RD   0x360C0000  // Start a 32-bit SPCI read  byte lanes 2 & 3
#define SPCI32_WORD1_WR   0x370C0000  // Start a 32-bit SPCI write byte lanes 2 & 3
#define SPCI32_WORD2_RD   0x36300000  // Start a 32-bit SPCI read  byte lanes 4 & 5
#define SPCI32_WORD2_WR   0x37300000  // Start a 32-bit SPCI write byte lanes 4 & 5
#define SPCI32_WORD3_RD   0x36C00000  // Start a 32-bit SPCI read  byte lanes 6 & 7
#define SPCI32_WORD3_WR   0x37C00000  // Start a 32-bit SPCI write byte lanes 6 & 7
#define SPCI32_BYTE0_RD   0x36010000  // Start a 32-bit SPCI read  byte lane 0
#define SPCI32_BYTE0_WR   0x37010000  // Start a 32-bit SPCI write byte lane 0
#define SPCI32_BYTE1_RD   0x36020000  // Start a 32-bit SPCI read  byte lane 1
#define SPCI32_BYTE1_WR   0x37020000  // Start a 32-bit SPCI write byte lane 1
#define SPCI32_BYTE2_RD   0x36040000  // Start a 32-bit SPCI read  byte lane 2
#define SPCI32_BYTE2_WR   0x37040000  // Start a 32-bit SPCI write byte lane 2
#define SPCI32_BYTE3_RD   0x36080000  // Start a 32-bit SPCI read  byte lane 3
#define SPCI32_BYTE3_WR   0x37080000  // Start a 32-bit SPCI write byte lane 3
#define SPCI32_BYTE4_RD   0x36100000  // Start a 32-bit SPCI read  byte lane 4
#define SPCI32_BYTE4_WR   0x37100000  // Start a 32-bit SPCI write byte lane 4
#define SPCI32_BYTE5_RD   0x36200000  // Start a 32-bit SPCI read  byte lane 5
#define SPCI32_BYTE5_WR   0x37200000  // Start a 32-bit SPCI write byte lane 5
#define SPCI32_BYTE6_RD   0x36400000  // Start a 32-bit SPCI read  byte lane 6
#define SPCI32_BYTE6_WR   0x37400000  // Start a 32-bit SPCI write byte lane 6
#define SPCI32_BYTE7_RD   0x36800000  // Start a 32-bit SPCI read  byte lane 7
#define SPCI32_BYTE7_WR   0x37800000  // Start a 32-bit SPCI write byte lane 7

// 64- and 32-bit I/O read/write commands, enabling 32-, 16-, and 8-bit accesses.
#define SPCI32_IO_READ_LO    0x320F0000  // Start a LS 32-bit single PCI access read
#define SPCI32_IO_WRITE_LO   0x330F0000  // Start a LS 32-bit single PCI access write
#define SPCI32_IO_READ_HI    0x32F00000  // Start a MS 32-bit single PCI access read
#define SPCI32_IO_WRITE_HI   0x33F00000  // Start a MS 32-bit single PCI access write
#define SPCI32_IO_WORD0_RD   0x32030000  // Start a 32-bit SPCI read  byte lanes 0 & 1
#define SPCI32_IO_WORD0_WR   0x33030000  // Start a 32-bit SPCI write byte lanes 0 & 1
#define SPCI32_IO_WORD1_RD   0x320C0000  // Start a 32-bit SPCI read  byte lanes 2 & 3
#define SPCI32_IO_WORD1_WR   0x330C0000  // Start a 32-bit SPCI write byte lanes 2 & 3
#define SPCI32_IO_WORD2_RD   0x32300000  // Start a 32-bit SPCI read  byte lanes 4 & 5
#define SPCI32_IO_WORD2_WR   0x33300000  // Start a 32-bit SPCI write byte lanes 4 & 5
#define SPCI32_IO_WORD3_RD   0x32C00000  // Start a 32-bit SPCI read  byte lanes 6 & 7
#define SPCI32_IO_WORD3_WR   0x33C00000  // Start a 32-bit SPCI write byte lanes 6 & 7
#define SPCI32_IO_BYTE0_RD   0x32010000  // Start a 32-bit SPCI read  byte lane 0
#define SPCI32_IO_BYTE0_WR   0x33010000  // Start a 32-bit SPCI write byte lane 0
#define SPCI32_IO_BYTE1_RD   0x32020000  // Start a 32-bit SPCI read  byte lane 1
#define SPCI32_IO_BYTE1_WR   0x33020000  // Start a 32-bit SPCI write byte lane 1
#define SPCI32_IO_BYTE2_RD   0x32040000  // Start a 32-bit SPCI read  byte lane 2
#define SPCI32_IO_BYTE2_WR   0x33040000  // Start a 32-bit SPCI write byte lane 2
#define SPCI32_IO_BYTE3_RD   0x32080000  // Start a 32-bit SPCI read  byte lane 3
#define SPCI32_IO_BYTE3_WR   0x33080000  // Start a 32-bit SPCI write byte lane 3
#define SPCI32_IO_BYTE4_RD   0x32100000  // Start a 32-bit SPCI read  byte lane 4
#define SPCI32_IO_BYTE4_WR   0x33100000  // Start a 32-bit SPCI write byte lane 4
#define SPCI32_IO_BYTE5_RD   0x32200000  // Start a 32-bit SPCI read  byte lane 5
#define SPCI32_IO_BYTE5_WR   0x33200000  // Start a 32-bit SPCI write byte lane 5
#define SPCI32_IO_BYTE6_RD   0x32400000  // Start a 32-bit SPCI read  byte lane 6
#define SPCI32_IO_BYTE6_WR   0x33400000  // Start a 32-bit SPCI write byte lane 6
#define SPCI32_IO_BYTE7_RD   0x32800000  // Start a 32-bit SPCI read  byte lane 7
#define SPCI32_IO_BYTE7_WR   0x33800000  // Start a 32-bit SPCI write byte lane 7

// CONFIG read and write commands
#define SPCI_WR_CONFIG_LO    0x3b0f0000
#define SPCI_RD_CONFIG_LO    0x3a0f0000
#define SPCI_WR_CONFIG_HI    0x3bf00000
#define SPCI_RD_CONFIG_HI    0x3af00000


//FIN Ctrl Register offsets (byte boundary divided by 4 for 32-bit boundary)
#define MAST_WR_ADDR0         0x00/4
#define MAST_WR_XFR_CNT0      0x08/4
#define MAST_WR_CNT_STAT0     0x0C/4
#define MAST_WR_ADDR1         0x10/4
#define MAST_WR_XFR_CNT1      0x18/4
#define MAST_WR_CNT_STAT1     0x1C/4
#define SPCI_COMMAND_REG      0x24/4
#define MAST_RD_ADDR0         0x48/4
#define MAST_RD_XFR_CNT0      0x50/4
#define MAST_RD_CNT_STAT0     0x54/4
#define MAST_RD_ADDR1         0x58/4
#define MAST_RD_XFR_CNT1      0x60/4
#define MAST_RD_CNT_STAT1     0x64/4
#define RCV_FIFO_STATUS       0x68/4
#define RCV_FIFO_STATUS       0x68/4
#define XMT_FIFO_STATUS       0x6C/4
#define USR_INCOMING_MAIL_3_0 0x70/4
#define USR_INCOMING_MAIL_7_4 0x74/4
#define USR_OUTGOING_MAIL_3_0 0x78/4
#define USR_OUTGOING_MAIL_7_4 0x7C/4
#define USER_MBOX_FULL_EMPTY  0x80/4
#define USER_MBOX_INTR_MASK1  0x88/4
#define USER_MBOX_INTR_MASK2  0x8C/4
#define DMA_START_DONE        0x90/4
#define PCI_ERROR_REG         0x94/4
#define SNGL_PCI_ADDR_REG_LWR 0x98/4
#define SNGL_PCI_ADDR_REG_UPR 0x9C/4
#define SNGL_PCI_DATA_REG_LWR 0xA0/4
#define SNGL_PCI_DATA_REG_UPR 0xA4/4
#define RCV_FIFO0             0xB0/4
#define RCV_FIFO0_UPR         0xB4/4
#define RCV_FIFO1             0xB8/4
#define RCV_FIFO1_UPR         0xBC/4
#define XMT_FIFO0             0xC0/4
#define XMT_FIFO0_UPR         0xC4/4
#define XMT_FIFO1             0xC8/4
#define XMT_FIFO1_UPR         0xCC/4
#define DMA_CONTROL1          0xD0/4
#define DMA_CONTROL2          0xD4/4
#define USR_MBOX_STATUS       DMA_START_DONE
#endif
//**********************************************************
// End of file fin.h
//**********************************************************
