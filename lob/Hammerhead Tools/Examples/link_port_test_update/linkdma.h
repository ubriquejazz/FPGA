/*****************************************************************************\
*                                                                             
*  linkdma.c : Header for link port transfer functions/utilities for Hammerhead                          
*                                                                                        
*  Copyright (2000) BittWare, Inc.                                       	  
*  33 North Main Street                                                       
*  Concord, NH  03301                                                         
*  Tel: 603-226-0404                                                          
*  Fax: 603-226-6667                                                          
*  E-mail: support@bittware.com                                               
*                                                                             
*	Ver		Author	Date	 	Changes                                       
*	---		------	----		-------			  					          
*                                                                             
\*****************************************************************************/

//Prototypes
void link_dma_xmt( int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) );
void link_dma_rcv( int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int wait, int (abort_func()) );
int link_dma_done( int lbuf );

void link_dma_noint_xmt(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()) );
void link_dma_noint_rcv(int *buf, int buflen, int link, int lbuf, int linkspeed, int link_width, int bit_width, int stride, int wait, int (abort_func()) );
int link_dma_noint_done( int lbuf );

/**********************************************************/
/* End of file linkdma.h */
/**********************************************************/


