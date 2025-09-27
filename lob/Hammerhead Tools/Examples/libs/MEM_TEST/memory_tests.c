/*****************************************************************************\
*                                                                             *
*  memory_tests.c : Source for standard memory test utilities.                *
*																			  *
*                                                                             *
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

#include "memory_tests.h"



/****************************************************************************************/
/*	incrementing_pattern_test															*/
/*		Writes an incrementing counter pattern to the given memory locations			*/
/*		starting with an initial count of pattern_start_value, incrementing by			*/
/*		increment each time, and then does a verify.									*/
/*																						*/
/*		Inputs:																			*/
/*			start_address			memory address to begin at							*/
/*			length					length of block to test								*/
/*			pattern_start_value		initial value for counter							*/
/*			increment				value to add to counter each time					*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*		Notes:																			*/
/****************************************************************************************/

int	incrementing_pattern_test (int *start_address, int length, int pattern_start_value, int increment)
{
	int *sdramtmp;
	int error_count;
	int count;
	int pattern;

	error_count = 0;

// Fill sdram with an incrementing pattern, beginning with the given start value for the pattern

	sdramtmp = start_address;
	pattern = pattern_start_value;
	for(count = 0 ; count < length ; count++) 
	{
		*sdramtmp++ =  pattern;
		pattern += increment;
	}

//	Verify it 

    sdramtmp = start_address;
	pattern = pattern_start_value;
	for(count = 0 ; count < length ; count++) 
	{
		if (*sdramtmp++ !=  pattern)
		{
			error_count++;
		}
		pattern += increment;
	}

	return (error_count);

}


/****************************************************************************************/
/*	static_pattern_test																	*/
/*		Writes a static pattern to the given memory locations and does a verify			*/
/*																						*/
/*		Inputs:																			*/
/*			start_address			memory address to begin at							*/
/*			length					length of block to test								*/
/*			pattern					the value to write									*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*		Notes:																			*/
/****************************************************************************************/

int	static_pattern_test (int *start_address, int length, int pattern)
{
	int *sdramtmp;
	int error_count;
	int count;

	error_count = 0;

// Fill sdram with the static pattern

	sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		*sdramtmp++ =  pattern;
	}

//	Verify it 

    sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		if (*sdramtmp++ !=  pattern)
		{
			error_count++;
		}
	}

	return (error_count);

}


/****************************************************************************************/
/*	alternating_pattern_test															*/
/*		Writes the two given static patterns to the given memory locations				*/
/*		in an alternating fashion and does a verify.									*/
/*																						*/
/*		Inputs:																			*/
/*			start_address			memory address to begin at							*/
/*			length					length of block to test (must be even)				*/
/*			pattern_one				first pattern										*/
/*			patterm_two				second pattern										*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*		Notes:																			*/
/*			The length must be even, i.e. divisible by two, since the test writes		*/
/*			two words at a time.  If it is not, it will write one less word than		*/
/*			specified.																	*/
/****************************************************************************************/

int	alternating_pattern_test (int *start_address, int length, int pattern_one, int pattern_two)
{
	int *sdramtmp;
	int error_count;
	int count;
	int	num_writes;

	error_count = 0;
	num_writes = length / 2;

// Fill sdram with the static patterns

	sdramtmp = start_address;
	for(count = 0 ; count < num_writes; count++) 
	{
		*sdramtmp++ =  pattern_one;
		*sdramtmp++ =  pattern_two;
	}

//	Verify it 

    sdramtmp = start_address;
	for(count = 0 ; count < num_writes; count++) 
	{
		if (*sdramtmp++ !=  pattern_one)
			error_count++;
		if (*sdramtmp++ !=  pattern_two)
			error_count++;
	}

	return (error_count);

}



/****************************************************************************************/
/*	walking_zero_test																	*/
/*		Performs a walking zero test on the given bits of the given memory location		*/
/*		This test is to show that all of the specified bits can be cleared				*/
/*		independent of adjacent bits													*/
/*																						*/
/*		Inputs:																			*/
/*			location				memory location to test								*/
/*			first_bit				first bit location to test 							*/
/*			last_bit				last bit location to test							*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*			or -1 if first_bit is greater than last_bit									*/
/*		Notes:																			*/
/*			This test will test all bits from first_bit to last_bit inclusive.			*/
/*			The test ignores all bits except those under test.							*/
/*			It is assumed that first_bit is less than last_bit							*/
/****************************************************************************************/

int	walking_zero_test (int *location, int first_bit, int last_bit)
{
	int error_count;
	int	bits_under_test_mask;
	int bit;
	int read_bits;

	error_count = 0;

// If the first bit is more than the last bit, get out of here

	if (first_bit > last_bit)
		return(-1);

// Create a mask to isolate the bits under test

	bits_under_test_mask = 0;
	for (bit = first_bit; bit <= last_bit; bit++)
		bits_under_test_mask |= (0x1 << bit);

// Write a zero through the specified bits with ones in all other bits under test
// Write any other bits in the location with whatever is currently in them

	for(bit = first_bit ; bit <= last_bit ; bit++) 
	{

	// Read the location, set all the bits under test, and then clear the current bit with an XOR

		*location = (*location | bits_under_test_mask) ^ (0x1 << bit);

  	// Read back the location, mask out all but the bits under test, and check that only the current bit is clear

		read_bits = *location & bits_under_test_mask;
		if (read_bits != (bits_under_test_mask ^ (0x1 << bit)))
			error_count++;
	}

	return (error_count);

}


/****************************************************************************************/
/*	walking_one_test																	*/
/*		Performs a walking one test on the given bits of the given memory location		*/
/*		This test is to show that all of the specified bits can be set					*/
/*		independent of adjacent bits													*/
/*																						*/
/*		Inputs:																			*/
/*			location				memory location to test								*/
/*			first_bit				first bit location to test 							*/
/*			last_bit				last bit location to test							*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*			or -1 if first_bit is greater than last_bit									*/
/*		Notes:																			*/
/*			This test will test all bits from first_bit to last_bit inclusive.			*/
/*			The test ignores all bits except those under test.							*/
/*			It is assumed that first_bit is less than last_bit							*/
/****************************************************************************************/

int	walking_one_test (int *location, int first_bit, int last_bit)
{
	int error_count;
	int	bits_under_test_mask;
	int bit;
	int read_bits;

	error_count = 0;

// If the first bit is more than the last bit, get out of here

	if (first_bit > last_bit)
		return(-1);

// Create a mask to isolate the bits under test

	bits_under_test_mask = 0;
	for (bit = first_bit; bit <= last_bit; bit++)
		bits_under_test_mask |= (0x1 << bit);

// Write a zero through the specified bits with ones in all other bits under test
// Write any other bits in the location with whatever is currently in them

	for(bit = first_bit ; bit <= last_bit ; bit++) 
	{

	// Read the location, clear all the bits under test, and then set the current bit

		*location = (*location & (!bits_under_test_mask)) | (0x1 << bit);

  	// Read back the location, mask out all but the bits under test, and check that only the current bit is set

		read_bits = *location & bits_under_test_mask;
		if (read_bits != (0x1 << bit))
			error_count++;
	}

	return (error_count);

}

/****************************************************************************************/
/*	walking_address_test																*/
/*		Performs a walking one test on the specified address lines.						*/
/*																						*/
/*		Inputs:																			*/
/*			base_address			base address										*/
/*			first_line				first address line to test 							*/
/*			last_line				last address line to test							*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*			or -1 if first_bit is greater than last_bit									*/
/*		Notes:																			*/
/*			This test will walk a one through the specified address lines,				*/
/*			adding this to the specified base address.  The test will write a counter   */
/*			out to the memory locations and then verify it.								*/
/****************************************************************************************/

int	walking_address_test (int *base_address, int first_line, int last_line)
{
	int error_count;
	int counter;
	int line;
	int *address;

	error_count = 0;

// If the first line is more than the last line, get out of here

	if (first_line > last_line)
		return(-1);

// Cycle a one through the specified address lines with zeros in all other lines, 
// add this to the base address and write an incrementing counter to the location.
// Note that it is critical that we do all the writes before any verifies as 
// we are trying to make sure that the writes do not go on top of each other

	counter = 0;
	for(line = first_line ; line <= last_line ; line++) 
	{
		address = base_address + (0x1 << line);
		*address = counter++;
 	}

// Now verify them

	counter = 0;
	for(line = first_line ; line <= last_line ; line++) 
	{

	// Set the current line, add this to the base, and write the counter

		address = base_address + (0x1 << line);
		if (*address != counter++)
			error_count++;

 	}

	return (error_count);

}

/****************************************************************************************/
/*	data_address_test																	*/
/*		Writes the address of the memory location  to the given memory locations 		*/
/*		and does a verify																*/
/*																						*/
/*		Inputs:																			*/
/*			start_address			memory address to begin at							*/
/*			length					length of block to test								*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*		Notes:																			*/
/****************************************************************************************/

int	data_address_test (int *start_address, int length)
{
	int *sdramtmp;
	int error_count;
	int count;

	error_count = 0;

// Fill sdram with the static pattern

	sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		*sdramtmp =  (int) sdramtmp;
		sdramtmp++;
	}

//	Verify it 

    sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		if (*sdramtmp !=  (int) sdramtmp)
		{
			error_count++;
		}
		sdramtmp++;
	}

	return (error_count);

}

/****************************************************************************************/
/*	data_address_complement_test														*/
/*		Writes the complement of the address of the memory location  to the given  		*/
/*		memory locations and does a verify												*/
/*																						*/
/*		Inputs:																			*/
/*			start_address			memory address to begin at							*/
/*			length					length of block to test								*/
/*		Outputs:																		*/
/*			number of errors encountered in test										*/
/*		Notes:																			*/
/****************************************************************************************/

int	data_address_complement_test (int *start_address, int length)
{
	int *sdramtmp;
	int error_count;
	int count;

	error_count = 0;

// Fill sdram with the static pattern

	sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		*sdramtmp =  ~((int) sdramtmp);
		sdramtmp++;
	}

//	Verify it 

    sdramtmp = start_address;
	for(count = 0 ; count < length ; count++) 
	{
		if (*sdramtmp !=  (~(int) sdramtmp))
		{
			error_count++;
		}
		sdramtmp++;
	}

	return (error_count);

}



