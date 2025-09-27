/*****************************************************************************\
*                                                                             *
*  utils.h : Header file for DSP-side utility functions
*                                                                             *
*  PROVIDED BY:                                                               *
*  ------------                                                               *
*  BittWare, Inc.                                                             *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Ph: 603-226-0404                                                           *
*  Fax: 603-226-6667                                                          *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*  Copyright 2001, BittWare, Inc.
*
*  The user is hereby granted a non-exclusive license to use 
*  and or modify this software provided that it runs on BittWare 
*  hardware. Usage of this software on non-BittWare hardware 
*  without the express written permission of BittWare is strictly 
*  prohibited.
*
*    Version   Changes                                                        *
*    --------  -------------------------------------------------------        *
*     1.00      3/27/01 - [rpc] Creation
*
\*****************************************************************************/

#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

#ifndef SetFIN
#define SetFIN(addr, val)  (* (volatile int *) (fin_base_addr + (addr))) = (val)
#define GetFIN(addr)       (* (volatile int *) (fin_base_addr + (addr)))
#endif

#define FIN_VERSION_REG       0x08
#define FIN_SDRAM_CFG_OLD     0x48
#define FIN_SDRAM_CFG_V4PLUS  0x45
#define SDRAM_DENSITY_64MB    0x10
#define SDRAM_DENSITY_128MB   0x20
#define SDRAM_DENSITY_256MB   0x40

// Utilities Function Prototypes
int get_proc_ID(void);
int get_fin_version(void);
int *get_ms_base(int ext_bank_num);
void init_Hammerhead(void);
void init_HH_manual(int msize, int wait, int sdram_nrows, int sdram_bank_density);
void init_SDRAM(void);


