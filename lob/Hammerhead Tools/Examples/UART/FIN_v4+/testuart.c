/*****************************************************************************\
*                                                                             *
*  ADSP21K INTERFACE LIBRARY                                                  *
*  -------------------------                                                  *
*  testuart.c : Example using functions to access UART from the SHARC DSP.    *
*                                                                             *
*  PROVIDED BY:                                                               *
*  ------------                                                               *
*  BittWare Research Systems, Inc.                                            *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Ph: 603-226-0404                                                           *
*  Fax: 603-226-6667                                                          *
*  Web: www.bittware.com                                                      *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*    Ver.   Changes                                                           *
*    -----  -------------------------------------------------------           *
*     1.00  11/20/97 [reddog] Initial coding.                                 *
*     1.01  08/18/98  reddog  Minor updates.                                  *
*     1.02  08/18/98  rpc     Version to test the HH-PCI uarts                *
*                                                                             *
\*****************************************************************************/

// Standard headers.
#include <def21160.h>
#include <21160.h>
#include <stdio.h>
#include <signal.h>
#include <macros.h>

/**********************************************************/

// Specific headers.
#include "dspuart.h"

/**********************************************************/

// Global variables.
int rcv_data;
int use_interrupts = 1;
int use_uart       = 2;
int mpid = 0;

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void init_uart( int uart_number, int use_interrupts )
{       
    if( uart_number == 2 )
    {    
        if( use_interrupts )
            init_uart2();
        else
            init_uart2_poll();
    }
    else
    {    
        if( use_interrupts )
            init_uart1();
        else
            init_uart1_poll();
    }

    return;
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void put_string( char * string, int uart_number, int use_interrupts )
{   
    int i;

    if( uart_number == 2 )
    {     
        if( use_interrupts )
        {    
            for( i=0 ; string[i] != '\0' ; i++ )
                // Loop while data not put into buffer.
                while( !put_byte2( string[i] ) ) ;
        }
        else
        {
            for( i=0 ; string[i] != '\0' ; i++ )
                // Loop while data not sent.
                while( !put_byte2_poll( string[i] ) ) ;
        }
    }
    else
    {     
        if( use_interrupts )
        {    
            for( i=0 ; string[i] != '\0' ; i++ )
			{
                // Loop while data not put into buffer.
                while( !put_byte1( string[i] ) ) ;
			}
        }
        else
        {
            for( i=0 ; string[i] != '\0' ; i++ )
                // Loop while data not sent.
                while( !put_byte1_poll( string[i] ) ) ;
        }
    }
        
    return;
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void main( void )
{
    char tempstr[40];
    char crlf[]  = "\r\n";
    char text[]  = "Hello World\r\nVersion 3.2\r\n";
    char text2[] = "The UART interface is interrupt driven.\r\n";
    char text3[] = "The UART interface is polled.\r\n";
    char text6[] = "Using UART #1.\r\n";
    char text7[] = "Using UART #2.\r\n";
    int j;

    
#ifdef USE_HARDWARE_EMULATOR
/* Modify to reflect hardware that is being used */
/* These values are for a HH PCI board with 64 MB SDRAM */
/* To find values for other boards/SDRAM, go into diag21k and type:
	br
	pc
	ir 0 4 */
    SetIOP(SYSCON, 0x1b000);  	
	SetIOP(WAIT, 0x1ce1b86);
#endif        

    // Initialize the Uart.
    reset_uarts();

    init_uart(use_uart, use_interrupts);

    // Clear screen - put some crlfs.
    for( j=0 ; j<5 ; j++ )
        put_string( crlf, use_uart, use_interrupts );
        
    put_string( text, use_uart, use_interrupts );
    
    if( use_interrupts )
        put_string( text2, use_uart, use_interrupts );
    else
        put_string( text3, use_uart, use_interrupts );
    
    mpid = get_mpid();
	sprintf(tempstr, "Running on MPID #%d.%s", mpid, crlf);
	put_string(tempstr, use_uart, use_interrupts);

#if 0
    if( mpid == 2 )
        put_string( text5, use_uart, use_interrupts );
    else
        put_string( text4, use_uart, use_interrupts );
#endif

    if( use_uart == 2 )
        put_string( text7, use_uart, use_interrupts );
    else
        put_string( text6, use_uart, use_interrupts );

    if( use_uart == 2 )
    {
        // Prepare to receive data.
        while( TRUE ) 
        {    
            if( use_interrupts )
            {    
                // Echo input to output.
                while( get_byte2( &rcv_data ) )
                    while( !put_byte2( rcv_data ) ) ;
            }
            else
            {
                // Echo input to output.
                while( get_byte2_poll( &rcv_data ) )
                    while( !put_byte2_poll( rcv_data ) ) ;
            }        
        }
    }
    else
    {            
        // Prepare to receive data.
        while( TRUE ) 
        {    
            if( use_interrupts )
            {    
                // Echo input to output.
                while( get_byte1( &rcv_data ) )
                    while( !put_byte1( rcv_data ) ) ;
            }
            else
            {
                // Echo input to output.
                while( get_byte1_poll( &rcv_data ) )
                    while( !put_byte1_poll( rcv_data ) ) ;
            }        
        }
    }
}        

/**********************************************************/

/* End of file testuart.c */

/**********************************************************/

