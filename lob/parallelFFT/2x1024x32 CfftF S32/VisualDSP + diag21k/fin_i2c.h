/**
 * Copyright 2001, BittWare, Inc.
 * The user is hereby granted a non-exclusive license to use 
 * and or modify this software provided that it runs on BittWare 
 * hardware. Usage of this software on non-BittWare hardware 
 * without the express written permission of BittWare is strictly 
 * prohibited.
**/

/**
 * Library:	hildll
 *
 * File:	fin_i2c.h
 *
 * Desc:	i2c driver API, only fin_i2c_init is specific to SharcFIN.
 *
 *  Provided by
 *  -----------
 *	BittWare, Inc.
 *	33 N Main St
 *	Concord, NH 03301
 *	Ph:	(603) 226 0404
 *	Fax:	(603) 226 6667
 *	WWW:	http://www.bittware.com
 *	Email:	support@bittware.com
 *
 *	Version	Date		Changes
 *	-------	--------	----------------------------------------
 *	6.0		05/11/00	[dlh] update/initial coding for HIL 6.0
 *
 *      $Log: fin_i2c.h,v $
 *      Revision 1.2  2001/02/15 14:25:20  daveh
 *      fixed dsp21k_close_all bug
 *
 *      Revision 1.1  2001/01/11 16:22:15  jthomas
 *      Moved files from DSP21KSF to dsp21ksf
 *
 *      Revision 1.1  2001/01/10 21:47:47  jthomas
 *      Corrected filename cases for dsp21ksf
 *
 *      Revision 1.1  2000/12/19 16:30:13  daveh
 *      Entering windows code for first time
 *
 *      Revision 1.2  2000/07/18 18:37:16  jthomas
 *      Added non-empty files to the repository
 *
 *
**/

#ifndef FIN_I2C_H
#define FIN_I2C_H


#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char UCHAR;

//FIN eeprom and SDRAM Serial Presence Detect eeprom
#define I2C_FIN_EEPROM	 0x2
#define I2C_SPD_EEPROM	 0x0
#define I2C_CONTROL_REG  0x46
#define I2C_WRITE        0xA0
#define I2C_READ	     0xA1
#define US_TICKS         80    // number of clock ticks per microsecond
#define TIMEOUT          -1
#define SUCCESS          0
#define NULL             (void *)0

struct i2c_bits   // NOTE!  Bit fields are reversed in VisualDSP
{
    // VDSP version
	unsigned :27;     //31..5 ignore these
	unsigned eepwp:1; //4
	unsigned ddrv:1;  //3
	unsigned cdrv:1;  //2
    unsigned sda:1;   //1
	unsigned sck:1;   //0
};

struct i2c_info
{
	long i2c_timeout;
	union
	{
		volatile struct i2c_bits * i2c_bits;
		volatile unsigned char * eeprom_base_ptr;
	}i2c_ptr;
};

typedef struct i2c_info I2C_INFO;

I2C_INFO * fin_i2c_init(unsigned char * eeprom_base_ptr);
int fin_i2c_read(I2C_INFO * i2c_info, unsigned char device, unsigned char address, unsigned char * buffer, int num_bytes);
int fin_i2c_write(I2C_INFO * i2c_info, unsigned char device, unsigned char address, unsigned char * buffer, int num_bytes);
void fin_i2c_done(I2C_INFO * i2c_info);

#ifdef __cplusplus
};
#endif

#endif //#ifndef FIN_I2C_H
