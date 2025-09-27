/*****************************************************************************\
*                                                                             *
*  fin_i2c.c : Source file to encapsulate i2c protocol -- 
*              EEPROM-specific i2c driver
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
*    Version   Changes                                                        *
*    --------  -------------------------------------------------------        *
*     1.00      8/25/99 - [dlh] Initial coding. (Adapted from                 *
*                         http://d1.ifmo.ru/library/i2c/i2cpseud.htm)         *
*
*  $Log: fin_i2c.c,v $
*  Revision 1.2  2001/02/15 14:25:20  daveh
*  fixed dsp21k_close_all bug
*
*  Revision 1.1  2001/01/11 16:22:15  jthomas
*  Moved files from DSP21KSF to dsp21ksf
*
*  Revision 1.1  2001/01/10 21:47:47  jthomas
*  Corrected filename cases for dsp21ksf
*
*  Revision 1.1  2000/12/19 16:30:12  daveh
*  Entering windows code for first time
*
*  Revision 1.3  2000/08/25 16:46:49  daveh
*  [dlh]  HIL re-integration with linux port, bug fixes and updates
*
*  Revision 1.2  2000/07/18 18:37:16  jthomas
*  Added non-empty files to the repository
*
*     2.00      3/27/01 - [rpc] Host version ported for DSP use;
*     Uses timer interrupt for embedded delays required by I2C
*
\*****************************************************************************/
/**
 * Copyright 2001, BittWare, Inc.
 * The user is hereby granted a non-exclusive license to use 
 * and or modify this software provided that it runs on BittWare 
 * hardware. Usage of this software on non-BittWare hardware 
 * without the express written permission of BittWare is strictly 
 * prohibited.
**/

/**********************************************************/
// Local definitions
#include <signal.h>
#include <21160.h>
#include "fin_i2c.h"


// globals
volatile int timer_expired;
volatile int intr_cnt = 0;

// Local functions
unsigned char i2c_GET_BIT(int n, unsigned char data);
void i2c_SET_BIT(int n, unsigned char * data, unsigned char bit);
void i2c_microsec_delay(long delay_time);

void timer_isr(int sig)
{
    intr_cnt++;
    timer_expired = 1;
}

void fin_i2c_done(I2C_INFO * i2c_info)
{
	//enable write-protect
	i2c_info->i2c_ptr.i2c_bits->eepwp = 0;
	free(i2c_info);
	i2c_info = NULL;
}

I2C_INFO * fin_i2c_init(unsigned char * eeprom_base_ptr)
{
	I2C_INFO *i2c_info;

	i2c_info = (I2C_INFO *)malloc(sizeof(I2C_INFO));
	
	if(!i2c_info)
		return NULL;

	i2c_info->i2c_ptr.eeprom_base_ptr = eeprom_base_ptr;
	
	//disable write-protect
	i2c_info->i2c_ptr.i2c_bits->eepwp = 1;
	
	return i2c_info;
}


/**********************************************************/
/* i2c_set_SCK( PDSP21K processor, int SCK )			  */
/*	 - sets SCK high or low depending on value of SCK     */
/**********************************************************/
void i2c_set_SCK(I2C_INFO * i2c_info, unsigned char sck )
{
	i2c_microsec_delay(6);
	i2c_info->i2c_ptr.i2c_bits->sck = sck;
}

/**********************************************************/
/* i2c_set_SDA( PDSP21K processor, int SDA )			  */
/*	 - sets SDA high or low depending on value of SDA     */
/**********************************************************/
void i2c_set_SDA(I2C_INFO * i2c_info, unsigned char sda )
{
	i2c_microsec_delay(6);
	i2c_info->i2c_ptr.i2c_bits->sda = sda;

}

/**********************************************************/
/* i2c_get_SCK( PDSP21K processor )						  */
/*	 - returns SCK										  */
/**********************************************************/
unsigned char i2c_get_SCK(I2C_INFO * i2c_info)
{
	i2c_microsec_delay(6);
	return (UCHAR)i2c_info->i2c_ptr.i2c_bits->sck;
}

/**********************************************************/
/* i2c_get_SDA( PDSP21K processor )						  */
/*	 - returns SDA										  */
/**********************************************************/
unsigned char i2c_get_SDA(I2C_INFO * i2c_info)
{
	i2c_microsec_delay(6);	
	return (UCHAR)i2c_info->i2c_ptr.i2c_bits->sda;
}

/**********************************************************/
/* i2c_microsec_delay(long delay_time)                    */
/*   - delays for delay_time microseconds                 */
/**********************************************************/
void i2c_microsec_delay(long delay_time)
{
    long ticks;

	timer_off();
	timer_expired = 0;
	ticks = delay_time * US_TICKS;
	timer_set(ticks, ticks);
	interrupt(SIG_TMZ0, timer_isr);
	timer_on();
	while(timer_expired == 0)
	    ;
	timer_off();
	interrupt(SIG_TMZ0, SIG_IGN);	
}


/**********************************************************/
/* i2c_start                                              */
/*   - sends the start sequence for the i2c protocol      */
/*                                                        */
/**********************************************************/
void i2c_start(I2C_INFO * i2c_info)
{
	//start condition:  high to low transition of SDA when SCK is high
	i2c_set_SDA(i2c_info, 1);
	i2c_set_SCK(i2c_info, 1);
	i2c_set_SDA(i2c_info, 0);
	i2c_set_SCK(i2c_info, 0);
	i2c_set_SDA(i2c_info, 1);
}

/**********************************************************/
/* i2c_stop                                               */
/*   - sends the stop sequence for the i2c protocol       */
/*                                                        */
/**********************************************************/
void i2c_stop(I2C_INFO * i2c_info)
{
	//stop condition:  low to high transition of SDA when SCK is high
	i2c_set_SDA(i2c_info, 0);
	i2c_set_SCK(i2c_info, 1);
	i2c_set_SDA(i2c_info, 1);
	i2c_set_SCK(i2c_info, 0);

}

/**********************************************************/
/* i2c_put_byte                                           */
/*   - puts a byte on the data line and clocks the clock  */
/*     line                                               */
/**********************************************************/
void i2c_put_byte(I2C_INFO * i2c_info, char data)
{
	int n;

	i2c_set_SDA(i2c_info, 1);

	for( n = 7; n >= 0; n--)
	{
		i2c_set_SDA(i2c_info, i2c_GET_BIT(n, data));
		i2c_set_SCK(i2c_info, 1);
		i2c_set_SCK(i2c_info, 0);
	}
	i2c_set_SDA(i2c_info, 1);
}

/**********************************************************/
/* i2c_get_byte                                           */
/*   - clocks the clock line and reads bits off the data  */
/*     line                                               */
/**********************************************************/
char i2c_get_byte(I2C_INFO * i2c_info)
{
	int n;
	UCHAR data = 0;

	for( n = 7; n >= 0; n-- )
	{
		i2c_set_SDA(i2c_info, 1);
		i2c_set_SCK(i2c_info, 1);
		i2c_SET_BIT(n, &data, i2c_get_SDA(i2c_info));
		i2c_set_SCK(i2c_info, 0);
	}
	i2c_set_SDA(i2c_info, 1);
	return data;
}

/**********************************************************/
/* i2c_ack                                                */
/*   - sends the acknowledge sequence for the i2c         */
/*     protocol                                           */
/**********************************************************/
void i2c_ack(I2C_INFO * i2c_info)
{

	i2c_set_SDA(i2c_info, 0);
	i2c_set_SCK(i2c_info, 1);
	i2c_set_SCK(i2c_info, 0);
	i2c_set_SDA(i2c_info, 1);
}

/**********************************************************/
/* i2c_ack                                                */
/*   - sends the acknowledge sequence for the i2c         */
/*     protocol                                           */
/**********************************************************/
void i2c_nack(I2C_INFO * i2c_info)
{

	i2c_set_SDA(i2c_info, 1);
	i2c_set_SCK(i2c_info, 1);
	i2c_set_SCK(i2c_info, 0);
}

/**********************************************************/
/* i2c_receive_ack                                        */
/*   - clocks the clock line and waits for an ack from    */
/*     eeprom.                                            */
/*   - if no ack is received, i2c_timeout is set to TRUE  */
/**********************************************************/
void i2c_receive_ack(I2C_INFO * i2c_info)
{
	int x = 0;

	i2c_set_SDA(i2c_info, 1);
	i2c_set_SCK(i2c_info, 1);

	//eeprom pulls line low as acknowledge
	while(i2c_get_SDA(i2c_info) == 1)
	{
		x++;
		if(x == 99999)
		{//TIMEOUT
			//should never get here
			i2c_info->i2c_timeout = 1;
			return;
		}
	};

	i2c_set_SCK(i2c_info, 0);
	i2c_set_SDA(i2c_info, 1);
}

/**********************************************************/
/* i2c_read(address, buffer, num_bytes)                   */
/*   - issues a random read at address into buffer,       */
/*     num_bytes in length                                */
/**********************************************************/
int fin_i2c_read(I2C_INFO * i2c_info, unsigned char device, unsigned char address, unsigned char * buffer, int num_bytes)
{
	int x;

	i2c_microsec_delay(80);
	i2c_info->i2c_timeout = 0;
	i2c_start(i2c_info);
	i2c_put_byte(i2c_info, (unsigned char)(device | I2C_WRITE));
	i2c_receive_ack(i2c_info);
	if(i2c_info->i2c_timeout)
		return TIMEOUT;
	i2c_put_byte(i2c_info, address);
	i2c_receive_ack(i2c_info);
	if(i2c_info->i2c_timeout)
		return TIMEOUT;
	i2c_start(i2c_info);
	i2c_put_byte(i2c_info, (unsigned char)(device | I2C_READ));
	i2c_receive_ack(i2c_info);
	if(i2c_info->i2c_timeout)
		return TIMEOUT;
	for( x = 0; x < num_bytes; x++)
	{
		if(x > 0)
			i2c_ack(i2c_info);
		buffer[x] = i2c_get_byte(i2c_info);
	}
	i2c_nack(i2c_info);
	i2c_stop(i2c_info);
	return SUCCESS;
}

                   
/**********************************************************/
/* i2c_write(address, buffer, num_bytes)                  */
/*   - issues a random write at address from buffer,      */
/*     num_bytes in length NOTE-num_bytes cannot be more  */
/*     than 16!											  */
/**********************************************************/
int fin_i2c_write(I2C_INFO * i2c_info, unsigned char device, unsigned char address, unsigned char * buffer, int num_bytes)
{
	int x;
	i2c_info->i2c_timeout = 0;
	i2c_start(i2c_info);
	i2c_put_byte(i2c_info, (unsigned char)(device | I2C_WRITE));
	i2c_receive_ack(i2c_info);
	if(i2c_info->i2c_timeout)
	{
		return TIMEOUT;
	}
	i2c_put_byte(i2c_info, address);
	i2c_receive_ack(i2c_info);
	if(i2c_info->i2c_timeout)
	{
		return TIMEOUT;
	}
	for( x = 0; x < num_bytes; x++)
	{
		i2c_put_byte(i2c_info, buffer[x]);
		i2c_receive_ack(i2c_info);
		if(i2c_info->i2c_timeout)
		{
			return TIMEOUT;
		}
	}
	i2c_stop(i2c_info);
	return SUCCESS;
}

unsigned char i2c_GET_BIT(int n, unsigned char data)
{
	return (UCHAR)((data >> n) & 0x1);
}

void i2c_SET_BIT(int n, unsigned char * data, unsigned char bit)
{
	*data |= (unsigned char)(bit << n);
}

