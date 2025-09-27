/*****************************************************************************\
*                                                                             *
*  ADSP21K INTERFACE LIBRARY                                                  *
*  -------------------------                                                  *
*  dspuart.c : Functions to access UART from the SHARC DSP.                   *
*              This file works with 21065L and 21160                          *
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
*  Copyright (c) 2001
*
*  The user is hereby granted a non-exclusive license to use and or 
*  modify this software provided that it runs on BittWare hardware.  
*  Usage of this software on non-BittWare hardware without the express 
*  written permission of BittWare is strictly prohibited.
*
*    Version   Changes                                                        *
*    --------  -------------------------------------------------------        *
*     1.00     11/20/97 [reddog] Initial coding.                              *
*     1.01     08/18/98  reddog  Corrected xmit to check THRE, not CTS.       *
*     1.02     06/06/00  rpc     Modified for Hammerhead                      *
*                                                                             *
\*****************************************************************************/

// Standard headers.
#include <def21160.h>
#include <21160.h>
#include <signal.h>
#include <macros.h>
#include "dspuart.h"
#include "sharc_fin.h"
asm("#include <def21160.h>");
/**********************************************************/

// Global variables.

static int *ms2_ptr;
static int *ms3_ptr;

static int rcvbuf1[BUFSIZE];
static int xmtbuf1[BUFSIZE];
volatile int rcv_head1;
volatile int rcv_tail1;
volatile int xmt_head1;
volatile int xmt_tail1;
volatile int rcv_overflow_error1;
volatile int last_msr1;
volatile int last_iir1;
volatile int last_lsr1;
volatile int int_count1;

static int rcvbuf2[BUFSIZE];
static int xmtbuf2[BUFSIZE];
volatile int rcv_head2;
volatile int rcv_tail2;
volatile int xmt_head2;
volatile int xmt_tail2;
volatile int rcv_overflow_error2;
volatile int last_msr2;
volatile int last_iir2;
volatile int last_lsr2;
volatile int int_count2;

int get_mpid(void)
{
    return((GetIOP(SYSTAT) >> 8) & 0x07);
}

/**********************************************************/
//
//  input: external_bank_number is 0-4.
//         0-3 select memory regions 0-3, 4 selects unbanked memory.
//  
/**********************************************************/
int *get_ms_base(int msnum)
{
    int msize;

	msize = (GetIOP(SYSCON) & 0xF000) >> 12;
	return((int *) 0x800000 + (msnum * (0x2000 << msize)));
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Get a 8-bit byte.
int get_byte1_poll( int *data_ptr )
{
    // If rcvr empty.
    if( !(UART1_LSR & 0x01) )
        return FALSE;

    // Get data from receive buffer.
    *data_ptr = UART1_RBR;

    // Return TRUE since data is valid.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Get a 8-bit byte.
int get_byte2_poll( int *data_ptr )
{
    // If rcvr empty.
    if( !(UART2_LSR & 0x01) )
        return FALSE;

    // Get data from receive buffer.
    *data_ptr = UART2_RBR;

    // Return TRUE since data is valid.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Put an 8-bit byte.
int put_byte1_poll( UCHAR data )
{
    // If xmtr not empty.
    if( !(UART1_LSR & 0x40) )
        return FALSE;

    // Put the data.
    UART1_THR = data;

    // Return TRUE since data was put in buffer.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Put an 8-bit byte.
int put_byte2_poll( UCHAR data )
{
    // If xmtr not empty.
    if( !(UART2_LSR & 0x40) )
        return FALSE;

    // Put the data.
    UART2_THR = data;

    // Return TRUE since data was put in buffer.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void init_uart1_poll( void )
{
    volatile int data;
    
    // Set desired baud, 8-bit, no parity, and 1 stop-bit.
    // UART speed divisors.
    //  For baud:       2400    4800    9600    19200   38400   57600   115200
    //  Divisor:        480     240     120     60      30      20      10
    //  Divisor(LSB):   224     240     120     60      30      20      10
    //  Divisor(MSB):   1       0       0       0       0       0       0
    
    // Set Divisor Latch bit in Line Control Reg.
    UART1_LCR = 0x83;
    // Set Divisor Latch LS byte for desired baud (default 115200).
    UART1_DLL = 10;
    // Set Divisor Latch MS byte for desired baud (default 115200).
    UART1_DLM = 0;
    // Clear Divisor Latch bit in Line Control Reg.
    UART1_LCR = 0x03;

    // Disable Fifos.
    UART1_FCR = 0x00;
    
    // Clear RTS in MCR.
    UART1_MCR = 00;

    // Clear the receiver.
    // Get line status register.
    last_lsr1 = UART1_LSR;
    
    // Loop while bit 0 is set indicating data ready.
    while( last_lsr1 & 0x01 )
    {
        // Read received data.
        data = UART1_RBR;
        // Get line status register.
        last_lsr1 = UART1_LSR;
    }        

    // Read Modem Status Register.
    last_msr1 = UART1_MSR;

    // Set RTS in MCR.
    UART1_MCR = 0x02;

    return;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void init_uart2_poll( void )
{
    volatile int data;
    
    // Set Divisor Latch bit in Line Control Reg.
    UART2_LCR = 0x83;
    // Set Divisor Latch LS byte for desired baud (default 115200).
    UART2_DLL = 10;
    // Set Divisor Latch MS byte for desired baud (default 115200).
    UART2_DLM = 0;
    // Clear Divisor Latch bit in Line Control Reg.
    UART2_LCR = 0x03;

    // Disable Fifos.
    UART2_FCR = 0x00;
    
    // Clear RTS in MCR.
    UART2_MCR = 00;

    // Clear the receiver.
    // Get line status register.
    last_lsr2 = UART2_LSR;
    
    // Loop while bit 0 is set indicating data ready.
    while( last_lsr2 & 0x01 )
    {
        // Read received data.
        data = UART2_RBR;
        // Get line status register.
        last_lsr2 = UART2_LSR;
    }        

    // Read Modem Status Register.
    last_msr2 = UART2_MSR;

    // Set RTS in MCR.
    UART2_MCR = 0x02;

    return;
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Get a 8-bit byte.
int get_byte1( int *data_ptr )
{
    // Check if we have received data into the receive buffer.
    if( rcv_head1 == rcv_tail1 )
    {    
        // Return FALSE since no data.
        return FALSE;
    }

    // Get data from receive buffer.
    *data_ptr = rcvbuf1[rcv_tail1];

    // Update tail pointer.
    rcv_tail1++;
    rcv_tail1 %= BUFSIZE;

    // Return TRUE since data is valid.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Get a 8-bit byte.
int get_byte2( int *data_ptr )
{
    // Check if we have received data into the receive buffer.
    if( rcv_head2 == rcv_tail2 )
    {    
        // Return FALSE since no data.
        return FALSE;
    }

    // Get data from receive buffer.
    *data_ptr = rcvbuf2[rcv_tail2];

    // Update tail pointer.
    rcv_tail2++;
    rcv_tail2 %= BUFSIZE;

    // Return TRUE since data is valid.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Put an 8-bit byte.
int put_byte1( UCHAR data )
{
    // Check if room in transmit buffer. 
    if( ((xmt_head1+1)%BUFSIZE) == xmt_tail1 )
    {
        // If not, return FALSE, indicating data was not buffered.    
        return FALSE;
    }

    // Transmit buffer has room, so put the data in.
    xmtbuf1[xmt_head1] = data;

    // Update head pointer.
    xmt_head1++;
    xmt_head1 %= BUFSIZE;

    // Check if we can send data, indicated by THRE set (bit 5 of LSR).
    last_lsr1 = UART1_LSR;
    if( last_lsr1 & 0x20 )
    {    
        // If THRE set, send data.
        UART1_THR = xmtbuf1[xmt_tail1];

        // Update tail pointer.
        xmt_tail1++;
        xmt_tail1 %= BUFSIZE;
    }        

    // Return TRUE since data was put in buffer.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Put an 8-bit byte.
int put_byte2( UCHAR data )
{
    // Check if room in transmit buffer. 
    if( ((xmt_head2+1)%BUFSIZE) == xmt_tail2 )
    {
        // If not, return FALSE, indicating data was not buffered.    
        return FALSE;
    }

    // Transmit buffer has room, so put the data in.
    xmtbuf2[xmt_head2] = data;

    // Update head pointer.
    xmt_head2++;
    xmt_head2 %= BUFSIZE;

    // Check if we can send data, indicated by THRE set (bit 5 of LSR).
    last_lsr2 = UART2_LSR;
    if( last_lsr2 & 0x20 )
    {    
        // If THRE set, send data.
        UART2_THR = xmtbuf2[xmt_tail2];

        // Update tail pointer.
        xmt_tail2++;
        xmt_tail2 %= BUFSIZE;
    }        

    // Return TRUE since data was put in buffer.
    return TRUE;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Uart-1 interrupt received.
void irq0_handler( int sig_num )
{
    int data;

    int_count1++;

    // Read interrupt identification register.
    last_iir1 = UART1_IIR;

    // Switch based on which interrupt is pending.
    switch( last_iir1 & 0x07 )
    {
        case 0:
            // Modem status interrupt. (IIR = 0)
            // Read modem status register.
            last_msr1 = UART1_MSR;
            // Check bit 5 (CTS).
            if( !(last_msr1 & 0x10) )
            {    
                // If clear, can't send more.
                break;
            }
            // If CTS is set, deliberately fall throught to try to send.
        case 2: 
            // Transmitter empty interrupt. (IIR=2)
            // Check if we can send data, indicated by THRE set (bit 5 of LSR).
            last_lsr1 = UART1_LSR;
            if( last_lsr1 & 0x20 )
            {    
                // Check if data to send.
                if( xmt_head1 != xmt_tail1 )
                {
                    // Send it.
                    UART1_THR = xmtbuf1[xmt_tail1];

                    // Update tail pointer.
                    xmt_tail1++;
                    xmt_tail1 %= BUFSIZE;
                }    
            }        
            break;
        case 6:
            // Receiver line status interrupt. (IIR=6)
        case 4:
            // Data available interrupt. (IIR=0xc or 4)
            // Read line status register.
            last_lsr1 = UART1_LSR;
            // Check bit 0 - Data Ready.
            if( last_lsr1 & 0x01 )
            {
                // Data available - so get byte.
                data = UART1_RBR;
                
                // Check if room in buffer. 
                if( ((rcv_head1+1)%BUFSIZE) == rcv_tail1 )
                {
                    // If not, set receive overflow, throw away data, and done.
                    rcv_overflow_error1 = TRUE;
                    break;
                }
                
                // Put it in receive buffer.
                rcvbuf1[rcv_head1] = data;
                
                // Update head pointer.
                rcv_head1 ++;
                rcv_head1 %= BUFSIZE;
            }        
            break;
        case 1:
        case 3:
        case 5:
        case 7:
        default:
            // No interrupt pending (bit 0 set), done.
            break;
    }
            
    return;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
// Uart-2 interrupt received.
void irq1_handler( int sig_num )
{
    int data;

    int_count2++;

    // Read interrupt identification register.
    last_iir2 = UART2_IIR;

    // Switch based on which interrupt is pending.
    switch( last_iir2 & 0x07 )
    {
        case 0:
            // Modem status interrupt. (IIR = 0)
            // Read modem status register.
            last_msr2 = UART2_MSR;
            // Check bit 5 (CTS).
            if( !(last_msr2 & 0x10) )
            {    
                // If clear, can't send more.
                break;
            }
            // If CTS is set, deliberately fall throught to try to send.
        case 2: 
            // Transmitter empty interrupt. (IIR=2)
            // Check if we can send data, indicated by THRE set (bit 5 of LSR).
            last_lsr2 = UART2_LSR;
            if( last_lsr2 & 0x20 )
            {    
                // Check if data to send.
                if( xmt_head2 != xmt_tail2 )
                {
                    // Send it.
                    UART2_THR = xmtbuf2[xmt_tail2];

                    // Update tail pointer.
                    xmt_tail2++;
                    xmt_tail2 %= BUFSIZE;
                }    
            }        
            break;
        case 6:
            // Receiver line status interrupt. (IIR=6)
        case 4:
            // Data available interrupt. (IIR=0xc or 4)
            // Read line status register.
            last_lsr2 = UART2_LSR;
            // Check bit 0 - Data Ready.
            if( last_lsr2 & 0x01 )
            {
                // Data available - so get byte.
                data = UART2_RBR;
                
                // Check if room in buffer. 
                if( ((rcv_head2+1)%BUFSIZE) == rcv_tail2 )
                {
                    // If not, set receive overflow, throw away data, and done.
                    rcv_overflow_error2 = TRUE;
                    break;
                }
                
                // Put it in receive buffer.
                rcvbuf2[rcv_head2] = data;
                
                // Update head pointer.
                rcv_head2 ++;
                rcv_head2 %= BUFSIZE;
            }        
            break;
        case 1:
        case 3:
        case 5:
        case 7:
        default:
            // No interrupt pending (bit 0 set), done.
            break;
    }
            
    return;
}        

/**********************************************************/
/*                                                        */
/*  Init UART 1 for use with interrupts                   */
/*                                                        */
/**********************************************************/
void init_uart1( void )
{
    volatile int data;
	int mpid;
	int offs;
    
    // Initialize global data.
    rcv_overflow_error1 = FALSE;
    rcv_head1  = 0;
    rcv_tail1  = 0;
    xmt_head1  = 0;
    xmt_tail1  = 0;
    int_count1 = 0;

    mpid = get_mpid();
    ms2_ptr = get_ms_base(2);

	// Enable UART1 to interrupt the correct HH
	offs = (HH1_IRQ0 + ((mpid-1)*2));
	*(ms2_ptr + offs) = B_UART0;

    // Set IRQ0 to be level sensitive.
    asm("BIT CLR MODE2 IRQ0E;");
    
    // Set desired baud, 8-bit, no parity, and 1 stop-bit.
    // UART speed divisors.
    //  For baud:       2400    4800    9600    19200   38400   57600   115200
    //  Divisor:        480     240     120     60      30      20      10
    //  Divisor(LSB):   224     240     120     60      30      20      10
    //  Divisor(MSB):   1       0       0       0       0       0       0
    
    // Set Divisor Latch bit in Line Control Reg.
    UART1_LCR = 0x83;
    // Set Divisor Latch LS byte for desired baud (default 115200).
    UART1_DLL = 10;
    // Set Divisor Latch MS byte for desired baud (default 115200).
    UART1_DLM = 0;
    // Clear Divisor Latch bit in Line Control Reg.
    UART1_LCR = 0x03;

    // Enable Fifos and set rcvr trigger to 8 bytes.
    UART1_FCR = 0x81;
    
    // Clear RTS in MCR.
    UART1_MCR = 00;

    // Clear the receiver.
    // Get line status register.
    last_lsr1 = UART1_LSR;
    
    // Loop while bit 0 is set indicating data ready.
    while( last_lsr1 & 0x01 )
    {
        // Read received data.
        data = UART1_RBR;
        // Get line status register.
        last_lsr1 = UART1_LSR;
    }        

    // Read Modem Status Register.
    last_msr1 = UART1_MSR;

    // Clear interrupt identification register.
    last_iir1 = UART1_IIR;

    // Set up interrupt handler for Uarts.
    interrupts(SIG_IRQ0, irq0_handler);

    // Enable all UART interrupts.
    UART1_IER = 0x0f;
        
    // Set RTS in MCR.
    UART1_MCR = 0x02;

    return;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void reset_uarts( void )
{    
    // Set the MS3 pointer.
    ms3_ptr = get_ms_base(3);

    // Reset and Run Uart.
    CTL_REG0 = CTL_REG0 & ~UART_RESET;  // Clear reset and run bits. 
    CTL_REG0 = CTL_REG0 |  UART_RESET;    // Set the reset bit.
    CTL_REG0 = CTL_REG0 & ~UART_RESET;  // Clear the reset bit. 

    return;
}

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void init_uart2( void )
{
    volatile int data;
	int mpid;
	int offs;

    // Initialize global data.
    rcv_overflow_error2 = FALSE;
    rcv_head2  = 0;
    rcv_tail2  = 0;
    xmt_head2  = 0;
    xmt_tail2  = 0;
    int_count2 = 0;

    mpid = get_mpid();
    ms2_ptr = get_ms_base(2);

	// Enable UART2 to interrupt the correct HH
	offs = (HH1_IRQ0 + ((mpid-1)*2));
	*(ms2_ptr + offs) = B_UART1;

    // Set IRQ0 to be level sensitive.
    asm("BIT CLR MODE2 IRQ0E;");
    
    // Set desired baud, 8-bit, no parity, and 1 stop-bit.
    // UART speed divisors.
    //  For baud:       2400    4800    9600    19200   38400   57600   115200
    //  Divisor:        480     240     120     60      30      20      10
    //  Divisor(LSB):   224     240     120     60      30      20      10
    //  Divisor(MSB):   1       0       0       0       0       0       0
    
    // Set Divisor Latch bit in Line Control Reg.
    UART2_LCR = 0x83;
    // Set Divisor Latch LS byte for desired baud (default 115200).
    UART2_DLL = 10;
    // Set Divisor Latch MS byte for desired baud (default 115200).
    UART2_DLM = 0;
    // Clear Divisor Latch bit in Line Control Reg.
    UART2_LCR = 0x03;

    // Enable Fifos and set rcvr trigger to 8 bytes.
    UART2_FCR = 0x81;
    
    // Clear RTS in MCR.
    UART2_MCR = 00;

    // Clear the receiver.
    // Get line status register.
    last_lsr2 = UART2_LSR;
    
    // Loop while bit 0 is set indicating data ready.
    while( last_lsr2 & 0x01 )
    {
        // Read received data.
        data = UART2_RBR;
        // Get line status register.
        last_lsr2 = UART2_LSR;
    }        

    // Read Modem Status Register.
    last_msr2 = UART2_MSR;

    // Clear interrupt identification register.
    last_iir2 = UART2_IIR;

    // Set up interrupt handler for Uarts.
    interrupts( SIG_IRQ0, irq1_handler );

    // Enable all UART interrupts.
    UART2_IER = 0x0f;
        
    // Set RTS in MCR.
    UART2_MCR = 0x02;

    return;
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int overflow_occurred1( void )
{
    int result;
                    
    result = rcv_overflow_error1;
    rcv_overflow_error1 = FALSE;

    return( result );
}        

/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int overflow_occurred2( void )
{
    int result;
                    
    result = rcv_overflow_error2;
    rcv_overflow_error2 = FALSE;

    return( result );
}        

/**********************************************************/
/* End of file dspuart.c */
/**********************************************************/
