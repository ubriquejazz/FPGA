/*****************************************************************************\
*                                                                             *
*  ADSP21K INTERFACE LIBRARY                                                  *
*  -------------------------                                                  *
*  dspuart.h : Include file for functions to access the Natl Semiconductor    *
*              PC16552DV DUART (Dual UART).  This header is generic to all    *
*              processors that use the DUART, as long as the dspuart.c it     *
*              supports is modified for the desired processor.                *
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
*    Version   Changes                                                        *
*    --------  -------------------------------------------------------        *
*     1.00     11/20/97 [reddog] Initial coding.                              *
*     1.01     10/06/98  reddog  Adapted for Spinner.                         *
*     1.02     06/05/00  rpc     Added comments; cleanup                      *
*                                                                             *
\*****************************************************************************/

// Standard headers.

/**********************************************************/

// Specific headers.

/**********************************************************/

// Defines for the offsets to the UART registers.
#define UART_OFFSET     0x200000
#define UART2_OFFSET	0x0000
#define UART1_OFFSET	0x0008

#define RBR_ADDR	0x0000  
#define THR_ADDR	0x0000
#define DLL_ADDR	0x0000
#define DLM_ADDR	0x0001
#define IER_ADDR	0x0001
#define IIR_ADDR	0x0002
#define FCR_ADDR	0x0002
#define LCR_ADDR	0x0003
#define MCR_ADDR	0x0004
#define LSR_ADDR	0x0005
#define MSR_ADDR	0x0006
#define SCR_ADDR	0x0007

#define CTL0_ADDR   0x00010
#define CTL1_ADDR	0x00020

#define UART_RESET      0x0001

#define IRQ1_DSPA_SEL_BOTH   0x0000
#define IRQ1_DSPA_SEL_UART1  0x0001
#define IRQ1_DSPB_SEL_BOTH   0x0000
#define IRQ1_DSPB_SEL_UART2  0x0002

/**********************************************************/

#ifndef FALSE
#define FALSE   0
#define TRUE    (!FALSE)
#endif

#ifndef SetIOP
#define SetIOP(addr, val)  (* (int *) (addr)) = (val)
#define GetIOP(addr)       (* (int *) (addr))
#endif

/**********************************************************/

// Definitions.
typedef unsigned char UCHAR;

#define BUFSIZE 64
#define CTL_REG0   *(uart_ms_ptr + CTL0_ADDR)
#define CTL_REG1   *(uart_ms_ptr + CTL1_ADDR)

#define UART1_RBR  *(uart_ms_ptr + UART1_OFFSET + RBR_ADDR)
#define UART1_THR  *(uart_ms_ptr + UART1_OFFSET + THR_ADDR)
#define UART1_DLL  *(uart_ms_ptr + UART1_OFFSET + DLL_ADDR)
#define UART1_DLM  *(uart_ms_ptr + UART1_OFFSET + DLM_ADDR)
#define UART1_IER  *(uart_ms_ptr + UART1_OFFSET + IER_ADDR)
#define UART1_IIR  *(uart_ms_ptr + UART1_OFFSET + IIR_ADDR)
#define UART1_FCR  *(uart_ms_ptr + UART1_OFFSET + FCR_ADDR)
#define UART1_LCR  *(uart_ms_ptr + UART1_OFFSET + LCR_ADDR)
#define UART1_MCR  *(uart_ms_ptr + UART1_OFFSET + MCR_ADDR)
#define UART1_LSR  *(uart_ms_ptr + UART1_OFFSET + LSR_ADDR)
#define UART1_MSR  *(uart_ms_ptr + UART1_OFFSET + MSR_ADDR)
#define UART1_SCR  *(uart_ms_ptr + UART1_OFFSET + SCR_ADDR)

#define UART2_RBR  *(uart_ms_ptr + UART2_OFFSET + RBR_ADDR)
#define UART2_THR  *(uart_ms_ptr + UART2_OFFSET + THR_ADDR)
#define UART2_DLL  *(uart_ms_ptr + UART2_OFFSET + DLL_ADDR)
#define UART2_DLM  *(uart_ms_ptr + UART2_OFFSET + DLM_ADDR)
#define UART2_IER  *(uart_ms_ptr + UART2_OFFSET + IER_ADDR)
#define UART2_IIR  *(uart_ms_ptr + UART2_OFFSET + IIR_ADDR)
#define UART2_FCR  *(uart_ms_ptr + UART2_OFFSET + FCR_ADDR)
#define UART2_LCR  *(uart_ms_ptr + UART2_OFFSET + LCR_ADDR)
#define UART2_MCR  *(uart_ms_ptr + UART2_OFFSET + MCR_ADDR)
#define UART2_LSR  *(uart_ms_ptr + UART2_OFFSET + LSR_ADDR)
#define UART2_MSR  *(uart_ms_ptr + UART2_OFFSET + MSR_ADDR)
#define UART2_SCR  *(uart_ms_ptr + UART2_OFFSET + SCR_ADDR)

/**********************************************************/

// Function prototypes.

void reset_uarts( void );
void  init_uart1( void );
void  init_uart2( void );
int   get_byte1( int *data_ptr );
int   put_byte1( UCHAR data );
int   get_byte2( int *data_ptr );
int   put_byte2( UCHAR data );

int get_byte1_poll( int *data_ptr );
int get_byte2_poll( int *data_ptr );
int put_byte1_poll( UCHAR data );
int put_byte2_poll( UCHAR data );
void reset_uarts_poll( void );
void init_uart1_poll( void );
void init_uart2_poll( void );


/**********************************************************/

/* End of file dspuart.h */

/**********************************************************/
