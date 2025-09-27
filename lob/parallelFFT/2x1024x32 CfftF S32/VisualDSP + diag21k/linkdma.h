/*****************************************************************************\
*                                                                             
*  linkdma.h : Support for link port transfer functions/utilities for Hammerhead                          
*                                                                                        
*  BittWare, Inc.                                       	  
*  33 North Main Street                                                       
*  Concord, NH  03301                                                         
*  Tel: 603-226-0404                                                          
*  Fax: 603-226-6667                                                          
*  E-mail: support@bittware.com                                               
*                                                                             
*  Copyright 2001, BittWare, Inc.
*
*  The user is hereby granted a non-exclusive license to use and or 
*  modify this software provided that it runs on BittWare hardware.  
*  Usage of this software on non-BittWare hardware without the express 
*  written permission of BittWare is strictly prohibited.
*
*	Ver		Author	Date	 	Changes                                       
*	---		------	----		-------			  					          
*                                                                             
\*****************************************************************************/

// Preprocessor Statements
#ifndef SetIOP
#define SetIOP(addr, val)  (* (volatile int *) addr) = (val)
#define GetIOP(addr)       (* (volatile int *) addr)
#endif

// Prototypes
void link_dma_xmt(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) );
void link_dma_rcv(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) );
int link_dma_done(int lbuf);

void link_dma_noint_xmt(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()) );
void link_dma_noint_rcv(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()) );
int link_dma_noint_done(int lbuf);

/**********************************************************/

/* End of file linkdma.h */

/**********************************************************/


