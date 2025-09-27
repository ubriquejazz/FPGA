/*****************************************************************************\
*                                                                             *
*  memory_tests.h : Header for standard memory test utilities.                *
*                                                                             *
*  Copyright (1999,2000) BittWare, Inc.                                       *
*  33 North Main Street                                                       *
*  Concord, NH  03301                                                         *
*  Tel: 603-226-0404                                                          *
*  Fax: 603-226-6667                                                          *
*  E-mail: support@bittware.com                                               *
*                                                                             *
*  Copyright 2001, BittWare, Inc.
*
*  The user is hereby granted a non-exclusive license to use and or 
*  modify this software provided that it runs on BittWare hardware.  
*  Usage of this software on non-BittWare hardware without the express 
*  written permission of BittWare is strictly prohibited.
*
*	Ver		Author	Date	 	Changes                                       *
*	---		------	----		-------			  					          *
*	1.0		rlh		11/11/99	Initial creation						  	  *
*                                                                             *
\*****************************************************************************/


int	incrementing_pattern_test (int *start_address, int length, int pattern_start_value, int increment);

int	static_pattern_test (int *start_address, int length, int pattern);

int alternating_pattern_test (int *start_address, int length, int pattern_one, int pattern_two);

int walking_zero_test (int *location, int first_bit, int last_bit);

int	walking_one_test (int *location, int first_bit, int last_bit);

int	walking_address_test (int *base_address, int first_line, int last_line);

int	data_address_test (int *start_address, int length);

int	data_address_complement_test (int *start_address, int length);

