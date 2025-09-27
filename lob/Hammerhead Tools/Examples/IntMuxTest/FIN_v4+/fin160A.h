//*********************************************************
//
//  fin160A.h
//  ------------
//  fin160A.h : Definition file for SharcFIN 160A
//
//  PROVIDED BY:
//  ------------
//  BittWare Research Systems, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph: 603-226-0404
//  Fax: 603-226-6667
//  WWW: www.bittware.com
//  E-mail: support@bittware.com
//
//  Copyright (c) 2000
//
//  Ver.  Dates     Author  Changes                                
//  ----  --------  ------  -----------------------------
//  1.00  06/05/00  rlh	  	Initial creation
//
//*********************************************************

#define FIN_ADDR_OVERRIDE	0x40
#define FIN_STATUS			0x41
#define FIN_PBUS_CFG		0x42
#define	FIN_WATCHDOG_CFG	0x43
#define FIN_PMCA_CFG		0x44
#define FIN_PMCB_STATUS		0x45
#define FIN_I2C				0x46
#define FIN_PMC_I2C			0x47
#define FIN_SD_SIZE			0x48
#define FIN_SD_CFG			0x49
#define FIN_SD_WINDOW		0x4A

#define FIN_INT_CFG_H1I0	0x50
#define FIN_INT_CFG_H1I1	0x51
#define FIN_INT_CFG_H2I0	0x52
#define FIN_INT_CFG_H2I1	0x53
#define FIN_INT_CFG_H3I0	0x54
#define FIN_INT_CFG_H3I1	0x55
#define FIN_INT_CFG_H4I0	0x56
#define FIN_INT_CFG_H4I1	0x57
#define FIN_INT_CFG_PCINT	0x58

#define FIN_INT_CFG_PMCI0	0x5A
#define FIN_INT_CFG_PMCI1	0x5B

#define FIN_FLGS_STATUS		0x5E
#define FIN_IRQS_STATUS		0x5F




//*********************************************************
//  End of file flash.h  
//*********************************************************
