//*********************************************************
//
//  FLASH
//  ------------
//  flash.h : Generic FLASH utility header file for BittWare boards.
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
//  Ver.  Dates     Author  Changes                                
//  ----  --------  ------  -----------------------------
//  1.00  08/19/98  reddog  Initial Release (pulled many diverse board
//                          specific versions together).
//  2.00  08/08/99  jmbj    Reorganized with BW_FLASH structure.
//  2.01  11/02/99  rlh	    Add support for 21160 processor
//  2.02  05/08/00  gdl	    Add support for Shortfin 21065l processor
//  2.03  10/18/00  rpc     Update for 29LV160DB (bottom boot sectors)
//  3.00  11/15/00  rpc     Add support for auto-detecting FLASH type
//
//*********************************************************

#ifndef BW_FLASH_HDR
#define BW_FLASH_HDR

typedef struct 
{
  unsigned int  flash_type;      /* Component type                   */
  unsigned int  id_val;          /* Manufacturer/device ID           */
           int  status;          /* Reset, initialized, etc.         */
  unsigned int  proc_type;       /* 21065, 21060, etc.               */
  unsigned int  base_addr;       /* First location (set in init)     */

  unsigned int  mem_select;      /* SHARC memory select region       */
  unsigned int  num_banks;       /* Number of devices                */
  unsigned int  bank_size;       /* Bytes allocated to bank          */
  unsigned int  active_bank;     /* Selected bank                    */
  unsigned int  num_sectors;     /* Number of sectors (boot sec=1)   */
  unsigned int  sector_size;     /* Primary sector size              */
  unsigned int  boot_sector;     /* Location of boot sector          */
  unsigned int  num_boot_secs;   /* Number of sectors in boot sector */
  unsigned int  device_size;     /* Number of bytes in device        */

  unsigned int  cmd_reset;       /* Put device into read mode        */
  unsigned int  cmd_write;       /* Write a byte sequence            */
  unsigned int  cmd_read_id;     /* Read device ID sequence          */
  unsigned int  cmd_chip_erase;  /* Chip erase sequence              */
  unsigned int  cmd_sec_erase;   /* Sector erase sequence            */
  unsigned int  cmd_poll;        /* Method of polling                */

} _BW_FLASH;

// Flash Types
#define BW_FL_AM29LV800BT  1
#define BW_FL_AM29LV160BT  2
#define BW_FL_AM29F016     3
#define BW_FL_AM29F800     4
#define BW_FL_AM29LV001BT  5
#define BW_FL_AM29LV160DB  6

// Flash IDs
#define BW_FL_AM29LV800BT_ID  (0x1DA)
#define BW_FL_AM29LV160BT_ID  (0x1C4)
#define BW_FL_AM29F016_ID     (0x1AD)
#define BW_FL_AM29F800_ID     (0x1D6)
#define BW_FL_AM29LV001BT_ID  (0x1ED)
#define BW_FL_AM29LV160DB_ID  (0x149)

// Processor Types
#define ADSP_21065         (1)
#define ADSP_21060         (2)
#define ADSP_21061         (3)
#define ADSP_21062         (4)
#define ADSP_21160         (5)

// Status Codes
#define FLASH_NO_STAT      (0)
#define FLASH_ID_OK        (1)
#define FLASH_ERROR        (-1)

#define BW_FLASH_DQ7       (0x80)      // Used in polling function

#ifndef SetIOP
#define SetIOP(addr, val)  (* (int *) addr) = (val)
#define GetIOP(addr)       (* (int *) addr)
#endif

#ifndef FALSE
#define FALSE (0)
#define TRUE  (!FALSE)
#endif

#ifndef SUCCESS
#define SUCCESS (0)
#define FAILURE (-1)
#endif

/*********** STRUCTURE ENTRIES FOR FLASH DATABASE *****************/
#define NUM_FLASH_ENTRIES  7  // When adding a new FLASH TYPE, bump this

// PVP with 1MB (Single AM29LV800BT at MS2)
#define POCKET_VIDEO_FLASH \
  {BW_FL_AM29LV800BT, BW_FL_AM29LV800BT_ID, 0, ADSP_21065, 0, \
  2, 1, 0x100000, 0, 16, 0x10000, 16, 4, 0x100000, \
  2, 2, 2, 2, 2, 1} 

// Spinner with 1MB (Single AM29LV800BT at MS1)
#define SPINNER_FLASH \
  {BW_FL_AM29LV800BT, BW_FL_AM29LV800BT_ID, 0, ADSP_21065, 0, \
  1, 1, 0x100000, 0, 16, 0x10000, 15, 4, 0x100000, \
  2, 2, 2, 2, 2, 1}

// Shortfin with 1MB (Single AM29LV800BT at MS1)
#define SF104p_FLASH800 \
  {BW_FL_AM29LV800BT, BW_FL_AM29LV800BT_ID, 0, ADSP_21065, 0, \
  1, 1, 0x100000, 0, 16, 0x10000, 15, 4, 0x100000, \
  2, 2, 2, 2, 2, 1}

// Shortfin with 2MB (Single AM29LV160BT at MS1)
#define SF104p_FLASH160 \
  {BW_FL_AM29LV160BT, BW_FL_AM29LV160BT_ID, 0, ADSP_21065, 0, \
  1, 1, 0x200000, 0, 32, 0x10000, 31, 4, 0x200000, \
  2, 2, 2, 2, 2, 1}

  // Hammerhead PCI with 2MB (Single AM29LV160BT at MS1)
#define HAMMERHEAD_PCI_FLASH \
  {BW_FL_AM29LV160BT, BW_FL_AM29LV160BT_ID, 0, ADSP_21160, 0, \
  1, 1, 0x200000, 0, 32, 0x10000, 31, 4, 0x200000, \
  2, 2, 2, 2, 2, 1} 

// Hammerhead PC104+ with 2MB (Single AM29LV160DB at MS1)
#define HAMMERHEAD_PC104_FLASH \
  {BW_FL_AM29LV160DB, BW_FL_AM29LV160DB_ID, 0, ADSP_21160, 0, \
  1, 1, 0x200000, 0, 32, 0x10000, 0, 4, 0x200000,  \
  2, 2, 2, 2, 4, 1} //4

// PocketAudio 128kB (Single AM29LV001BT at MS2)
#define POCKET_AUDIO_FLASH \
  {BW_FL_AM29LV001BT, BW_FL_AM29LV001BT_ID, 0, ADSP_21065, 0, \
  2, 1, 0x020000, 0,  8, 0x04000,  7, 3, 0x020000, \
  2, 3, 3, 3, 3, 1} 

// GPC (Quad AM29F016 at )
// Goblin
// STQ4
// STP4
// BTCP
// BII
// BTEX/WTPMC (Sgl AM29F016 at MS3)

/*********** FLASH FUNCTION PROTOTYPES *****************/
_BW_FLASH *FlashInit (int proc_type);
int  FlashReadReset  ( _BW_FLASH *flash_info );
int  FlashPollData   ( _BW_FLASH *flash_info, unsigned Offs, int ExitValue );
int  FlashWriteByte  ( _BW_FLASH *flash_info, unsigned Addr, int Data );
int  FlashReadByte   ( _BW_FLASH *flash_info, unsigned Addr );
int  FlashChipErase  ( _BW_FLASH *flash_info );
int  FlashSectorErase( _BW_FLASH *flash_info, int Sector );
int  FlashReadID     ( _BW_FLASH *flash_info );
int  FlashNumSectors ( _BW_FLASH *flash_info );
int  FlashSectorSize ( _BW_FLASH *flash_info );
int  FlashNumBanks   ( _BW_FLASH *flash_info );
int  FlashType       ( _BW_FLASH *flash_info );
int  FlashSectorEraseSuspend( _BW_FLASH *flash_info );
int  FlashSectorEraseResume ( _BW_FLASH *flash_info );

#endif

//*********************************************************
//  End of file flash.h  
//*********************************************************
