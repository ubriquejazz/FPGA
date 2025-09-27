/*****************************************************************************\
*                                                                             *
*  utils.c : Source file for DSP-side utility functions
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
#include <def21160.h>
#include <21160.h>
#include "fin_i2c.h"
#include "utils.h"

// Globals
int error = 0;
int *fin_base_addr;

/**********************************************************/
//  Function: get_proc_ID
//  input:    none
//  output:   processor ID of the current HH
//
/**********************************************************/
int get_proc_ID(void)
{
	return((GetIOP(SYSTAT) & 0xf00) >> 8);
}

/**********************************************************/
//  Function: get_fin_version
//  input:    none
//  output:   SHARC FIN version currently on the HH board
//
/**********************************************************/
int get_fin_version(void)
{
    // Get base address of the SHARC FIN
	fin_base_addr = get_ms_base(2);

	return(GetFIN(FIN_VERSION_REG) & 0xff);
}

/**********************************************************/
//  Function: get_ms_base
//  input:    external_bank_number is 0-4.
//            0-3 selects mem regions 0-3, 4 selects unbanked mem
//  output:   pointer to the base address of the memory select
//
/**********************************************************/
int *get_ms_base(int ext_bank_num)
{
    int  msize;

    msize = (GetIOP(SYSCON) & 0xF000) >> 12;
    return((int *) (0x800000 + (ext_bank_num * (0x2000 << msize))));
}

/**********************************************************/
//  Function: init_SDRAM - called by init_Hammerhead().  Reads
//            SDRAM EEPROM via I2C for info needed to init the
//            SDRAM interface on the FIN.
//  input:    none
//  output:   none
//
/**********************************************************/
void init_SDRAM(void)
{
    I2C_INFO *i2c_infp;
	int sdram_cfg_reg;
	int num_rows;
	int bnk_density;
	int ctemp;
    unsigned char buff[8];

	// Get FIN version number; set SDRAM config register
    sdram_cfg_reg = ((get_fin_version()) < 4) ? FIN_SDRAM_CFG_OLD : FIN_SDRAM_CFG_V4PLUS;

	// Init the I2C interface
    i2c_infp = fin_i2c_init((unsigned char *)(fin_base_addr + I2C_CONTROL_REG));

    // Read the info from the SDRAM EEPROM
    if(fin_i2c_read(i2c_infp,       // I2C_INFO pointer from init
	                I2C_SPD_EEPROM, // device to read
					0x05,           // SDRAM rows offset
					buff,           // destination pointer
					1) == -1)       // number of bytes
	{
	    error = 1;
	}

	num_rows = buff[0];

    if(fin_i2c_read(i2c_infp,       // I2C_INFO pointer from init
	                I2C_SPD_EEPROM, // device to read
					0x1f,           // SDRAM bank density offset
					buff,           // destination pointer
					2) == -1)       // number of bytes
	{
	    error = 1;
	}

	bnk_density = buff[1] << 8 | buff[0];

	// Close the I2C interface
	fin_i2c_done(i2c_infp);

	// Configure SDRAM settings
	ctemp = GetFIN(sdram_cfg_reg) & 0xfc;
	if(num_rows != 0xff && num_rows != 0 && num_rows != 1)
	{
	    ctemp = (bnk_density & SDRAM_DENSITY_64MB)  ? ctemp |= 1 :
                (bnk_density & SDRAM_DENSITY_128MB) ? ctemp |= 2 :
                (bnk_density & SDRAM_DENSITY_256MB) ? ctemp |= 3 : ctemp;
	}
	SetFIN(sdram_cfg_reg, ctemp);
}
/**********************************************************/
//  Function: init_HH_manual - initilialize Hammerhead and SDRAM  
//            based on input parameters.  
//
//  inputs:   msize - value to write to SYSCON in the MSIZE field
//            wait  - value to write to WAIT register
//  output:   none
//
/**********************************************************/
void init_HH_manual(int msize, int wait, int sdram_nrows, int sdram_bank_density)
{
    int ctemp;
	int sdram_cfg_reg;

    // Get base address of the SHARC FIN
	fin_base_addr = get_ms_base(2);

	// Get FIN version number; set SDRAM config register
    sdram_cfg_reg = ((get_fin_version()) < 4) ? FIN_SDRAM_CFG_OLD : FIN_SDRAM_CFG_V4PLUS;

	// Configure SDRAM settings
	ctemp = GetFIN(sdram_cfg_reg) & 0xfc;
	if(sdram_nrows != 0xff && sdram_nrows != 0 && sdram_nrows != 1)
	{
	    ctemp = (sdram_bank_density & SDRAM_DENSITY_64MB)  ? ctemp |= 1 :
                (sdram_bank_density & SDRAM_DENSITY_128MB) ? ctemp |= 2 :
                (sdram_bank_density & SDRAM_DENSITY_256MB) ? ctemp |= 3 : ctemp;
	}
	SetFIN(sdram_cfg_reg, ctemp);

	// Set the SYSCON and WAIT according input parameters
	SetIOP(SYSCON, 0x10000 | msize << 12);  // set BHD and msize
	SetIOP(WAIT, wait);
}


/**********************************************************/
//  Function: init_Hammerhead - initilialize HH based on msize and wait
//            the values stored in FIN EEPROM.  SDRAM is set according 
//            to info in the SDRAM EEPROM.  Uses the I2C interface on
//            the SHARC FIN.
//  input:    none
//  output:   none
//
/**********************************************************/
void init_Hammerhead(void)
{
    I2C_INFO *i2c_infp;
    int msize;
    int wait;
    unsigned char buff[8];

    // Get base address of the SHARC FIN
	fin_base_addr = get_ms_base(2);

	// Init the I2C interface
    i2c_infp = fin_i2c_init((unsigned char *)(fin_base_addr + I2C_CONTROL_REG));

	// Read the msize and wait info from the FIN EEPROM
    if(fin_i2c_read(i2c_infp,       // I2C_INFO pointer from init
	                I2C_FIN_EEPROM, // device to read
					0x8c,           // wait/msize offset
					buff,           // destination pointer
					8) == -1)       // number of bytes
	{
	    error = 1;
	}

	// Pack bytes
	wait  = buff[3] << 24 | buff[2] << 16 | buff[1] << 8 | buff[0];
	msize = buff[7] << 24 | buff[6] << 16 | buff[5] << 8 | buff[4];

	// Close the I2C interface
	fin_i2c_done(i2c_infp);

	// initialize the SDRAM interface
    init_SDRAM();

	// Set the SYSCON and WAIT according to EEPROM values
	SetIOP(SYSCON, 0x10000 | msize << 12);  // BHD and msize
	SetIOP(WAIT, wait);
}
