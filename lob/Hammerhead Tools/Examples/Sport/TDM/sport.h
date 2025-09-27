// Bittware copy of sport.h due to syntax error in Analog file
/*
 *  Copyright 2001, BittWare, Inc.
 *
 *  The user is hereby granted a non-exclusive license to use and or 
 *  modify this software provided that it runs on BittWare hardware.  
 *  Usage of this software on non-BittWare hardware without the express 
 *  written permission of BittWare is strictly prohibited.
 *
 */


/* sport.h - $Date: 10/09/97 6:28p $ */

/* Sport.h for the ADSP21060 */

#ifndef __SPORT_DEFINED
#define __SPORT_DEFINED

#define SPORT_DTYPE_RIGHT_JUSTIFY_ZERO_FILL 0
#define SPORT_DTYPE_RIGHT_JUSTIFY_SIGN_EXTEND 1
#define SPORT_DTYPE_MU_LAW_COMPANDING 2
#define SPORT_DTYPE_A_LAW_COMPANDING 3

struct __sport_transmit_control_register
{
    /* Status bits */
    unsigned int const volatile txs:2;  /* Read only TX Buffer status */
    unsigned int const volatile tuvf:1; /* Read only undeflow status  */
    unsigned int const volatile chnl:5; /* Read only current channel  */
    
    /* Multichannel */
    unsigned int mdf:4;       /* MC Frame delay                       */
    
    /* DMA Control */
    unsigned int schen:1;     /* Auto-chaining enable                 */
    unsigned int sden:1;      /* DMA Enable                           */
    
    /* Frame Sync Control */
    unsigned int lafs:1;      /* Late FS (alternate)                  */
    unsigned int ltfs:1;      /* Active low FS                        */
    unsigned int ditfs:1;     /* Data independent FS                  */
    unsigned int itfs:1;      /* Internal FS                          */
    unsigned int tfsr:1;      /* FS Required                          */
    
    /* Data control */
    unsigned int ckre:1;      /* Data and FS on clock rising edge     */
    unsigned int gclk:1;      /* Enable clock only during transmission*/
    unsigned int iclk:1;      /* Internal clock                       */
    unsigned int pack:1;      /* Unpack two words per transfer        */
    unsigned int slen:5;      /* Data word length minus one           */
    unsigned int sendn:1;     /* Data word endian 1 = LSB first       */
    unsigned int dtype:2;     /* Data type specifier                  */
    unsigned int spen:1;      /* Enable                               */
};

struct __sport_receive_control_register
{
    /* Status bits */
    unsigned int const volatile rxs:2;  /* Read only TX Buffer status */
    unsigned int const volatile ruvf:1; /* Read only undeflow status  */
    
    /* Multichannel */
    unsigned int nch:5;       /* MC Number of channels                */
    unsigned int mce:1;       /* MC Frame delay                       */
    
    /* Miscellaneous */
    unsigned int spl:1;       /* Loop back configure (test)           */
    unsigned int d2dma:1;     /* Enable 2-dimensional DMA array       */
    
    unsigned int const __reserved_1:1;  /* Reserved                   */
    
    /* DMA Control */
    unsigned int schen:1;     /* Auto-chaining enable                 */
    unsigned int sden:1;      /* DMA Enable                           */
    
    /* Frame Sync Control */
    unsigned int lafs:1;      /* Late FS (alternate)                  */
    unsigned int lrfs:1;      /* Active low FS                        */
    
    unsigned int const __reserved_2:1;  /* Reserved                   */
    
    unsigned int irfs:1;      /* Internal FS                          */
    unsigned int rfsr:1;      /* FS Required                          */
    
    /* Data control */
    unsigned int ckre:1;      /* Data and FS on clock rising edge     */
    unsigned int gclk:1;      /* Enable clock only during transmission*/
    unsigned int iclk:1;      /* Internal clock                       */
    unsigned int pack:1;      /* Unpack two words per transfer        */
    unsigned int slen:5;      /* Data word length minus one           */
    unsigned int sendn:1;     /* Data word endian 1 = LSB first       */
    unsigned int dtype:2;     /* Data type specifier                  */
    unsigned int spen:1;      /* Enable                               */
    
};
    
struct __transmit_divisor_register_structure
{
    unsigned int tfsdiv:16;  /* Transmit frame sync divisor           */
    unsigned int tckdiv:16;  /* Transmit clock divisor                */
};

struct __receive_divisor_register_structure
{
    unsigned int rfsdiv:16;  /* Transmit frame sync divisor           */
    unsigned int rckdiv:16;  /* Transmit clock divisor                */
};

struct __sport_structure
{
    struct __sport_transmit_control_register txc; /* Transmit control reg */
    struct __sport_receive_control_register rxc;  /* Receive control reg  */

    int volatile tx;              /* Transmit data buffer                 */
    int volatile rx;              /* Receive data buffer                  */

    struct __transmit_divisor_register_structure tdiv; /* Transmit divisor*/

    int const volatile tcnt;     /* Temporary register for divisor        */

    struct __receive_divisor_register_structure rdiv;  /* Receive divisor */

    int const volatile rcnt;     /* Temporary register for divisor        */

    int mtcs;        /* Multichannel channel transmit enable              */
    int mrcs;        /* Multichannel channel receive enable               */
    int mtccs;       /* Multichannel channel transmit companding enable   */
    int mrccs;       /* Multichannel channel receive companding enable    */
} ;

#define sport0_iop (*(volatile struct __sport_structure *)0x00e0)
#define sport1_iop (*(volatile struct __sport_structure *)0x00f0)

#define sport_setup(a,b) \
    do \
	if ((a == 0) || (a == 1)) { \
	    volatile pm int *__temp2 = (int *)(0x00e0 + a*0x10); \
	    struct __sport_structure * __temp1 = (&b); \
	    asm volatile ("\n\tR0=R0-R0, PM(%1,M14)=M5;" \
			  "\n\tR0=DM(%0,M6), PM(%1,M15)=R0;" \
			  "\n\tLCNTR=%2, DO (PC, 1) UNTIL LCE;" \
			  "\n\t\tR0=DM(%0,M6), PM(%1,M14)=R0;" \
			  "\n\tPM(%1,M14)=R0;\n" \
			  : "=w" (__temp1), "=y" ((pm *)__temp2) \
			  : "J" (sizeof(struct __sport_structure)-1), \
			    "0" (__temp1), "1" ((pm *)__temp2) \
			  : "R0"); \
	} \
    while (0)

#define sport_enable_transmit (a) \
    ((a) ? sport1_iop.tx.spen = 1 : sport0_iop.tx.spen = 1)
    
#define sport_enable_receive (a) \
    ((a) ? sport1_iop.rx.spen = 1 : sport0_iop.rx.spen = 1)

#define sport_disable_transmit (a) \
    ((a) ? sport1_iop.tx.spen = 0 : sport0_iop.tx.spen = 0)

#define sport_disable_receive (a) \
    ((a) ? sport1_iop.rx.spen = 0 : sport0_iop.rx.spen = 0)

#endif
