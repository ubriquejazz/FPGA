/********************************************************************************/
/*
/* template.cpp : Real Time Template
/*
/********************************************************************************/

#include "stdafx.h"
#include "const21k.h"	// for DEV_RESET_ON_LOAD
#include "dsp21k.h"
#include <time.h>		// for sleep
#include <string.h>		// for memcpy and string routines
#include <stdio.h>
#include <stdlib.h>		// for system
#include <conio.h>		// for kbhit

#define INIT_SDRAM      1						// set flag to init SDRAM with incrementing pattern
#define N 				1024		
#define FFT_SIZE		64					    // 1024 = 32 x 32
#define LINE_SIZE       1024*2                  // line data = 1024 8-byte pixels (complex_float pixels)
#define FRAME_SIZE      32						// lines per frame for this test
#define TOTAL_PIXELS    LINE_SIZE*FRAME_SIZE	// total number of pixels (32-bits words)
#define NUM_FRAMES		4						// 4 frames
#define FREQ			300				 		// Hz frame rate

/********************/
/* Global Variables */
/********************/

PDSP21K	processor1, processor2, processor3, processor4;

U32	dsp_addr1 = 0x800000;			
U32	dsp_addr2 = 0x1000000;			

long Frame_Size =	FRAME_SIZE;
long Total_Pixels = TOTAL_PIXELS;
long Num_Frames =	NUM_FRAMES;
long Line_Freq =	FREQ;

int  device_num = 0;		// device number defaults to 0
int  errors = 0;

/********************************************************************************/
void sleep(unsigned int mseconds)
{
    clock_t goal = mseconds + clock();
    while (goal > clock());
}

/********************************************************************************/
/* Open processors on device 0 and load SDRAM and MMS of P3
/********************************************************************************/
long BittWareOpen(long Total_Pixels)
{
	int i, value;					// auxiliar 
	U32 zeros[0x4000];				// MMS P3
	int error1, error2, error3, error4;

	for(i = 0; i < 0x4000; i++)
	{
		zeros[i] = 0;
	}

	if ((processor1 = dsp21k_open_by_id(device_num, 1)) == NULL)
    {
        return 11;
    }
	else
	{
    
		// Reset the board and configure all processors on the board
	    dsp21k_reset_bd( processor1 );
		sleep (100);

		// processors need to be configured after a board reset for host access
		dsp21k_cfg_proc( processor1 );

		// processors need to be configured after a board reset for host access
		processor2 = dsp21k_open_by_id(device_num, 2);
		dsp21k_cfg_proc(processor2);

		// processors need to be configured after a board reset for host access
		processor4 = dsp21k_open_by_id(device_num, 4);
		dsp21k_cfg_proc(processor4);

		// processors need to be configured after a board reset for host access
		processor3 = dsp21k_open_by_id(device_num, 3);
		dsp21k_cfg_proc(processor3);

		// dsp21k_load_exe will first reset and configure the processor
		// before downloading if the DEV_RESET_ON_LOAD setting is set
		dsp21k_rd_bd_setting(processor1, DEV_RESET_ON_LOAD, &value);
		if(value == 0)
		{
			value = 1;
			dsp21k_wr_bd_setting(processor1, DEV_RESET_ON_LOAD, value);
		}

		// Clearing internal mem buffer on PROC3 (INTERMEDIAL)
		dsp21k_dl_32s( processor3, 0x58000, 0x4000, zeros );
	
		// Download the dsp programs
		error1 = dsp21k_load_exe(processor1, "hh1_generator.dxe");
		error2 = dsp21k_load_exe(processor2, "hh2_consumer.dxe");
		error3 = dsp21k_load_exe(processor3, "hh3_consumer.dxe");	
		error4 = dsp21k_load_exe(processor4, "hh4_consumer.dxe");	
		
		return error1 + error2 + error3 + error4;
	}
}

/********************************************************************************/
void BittWareClose(long error)
{

    // Reset the board.
    dsp21k_reset_bd( processor1 );
	sleep (100);
					
	// Close the processors.
	dsp21k_close(processor2);	
	dsp21k_close(processor4);
	dsp21k_close(processor3);
	dsp21k_close(processor1);

}

/********************************************************************************/
/*
/*
/********************************************************************************/
void main(int argc, char* argv[])
{
	int i,j,k;
	S32 image[TOTAL_PIXELS];				// data input  (128KB < 64MB)
	S32 fft[TOTAL_PIXELS];					// data output (128KB < 64MB)
	U32 *pin, *pout;						// pointers
	U32 statistic[64];
	U32 line_time[32];
	float average = 0;

#if INIT_SDRAM
	for (k=0; k<FRAME_SIZE; k++)
	{
		for (i=0; i<LINE_SIZE; i+=2)
		{
			image[ (k*LINE_SIZE ) + i]   = 1;
			image[ (k*LINE_SIZE ) + i+1] = 0;
		}
	}
#endif
	pin= (U32 *)&image[0];
	pout = (U32 *)&fft[0];

    // Open processors on device 0
	printf("Opening processors on device %d ...", device_num);
	errors = BittWareOpen(Total_Pixels);

if (!errors)
{
	// Download paramaters before running
	printf("\n\nLine Frequency (Hz): "); scanf("%d", &Line_Freq);
//	printf("Frame Size (Lines < 32): "); scanf("%d", &Frame_Size);
//	printf("Number of Frames: "); scanf("%d", &Num_Frames);
	Total_Pixels = Frame_Size * LINE_SIZE;

	printf("\n\n%d frames of %d lines ", Num_Frames, Frame_Size);
	printf("\nlines of %d pixels to be processed @ %d Hz", N, Line_Freq);
	
	dsp21k_dl_int(processor1, dsp21k_get_addr(processor1, "_Num_Frames"), Num_Frames);
 	dsp21k_dl_int(processor1, dsp21k_get_addr(processor1, "_Line_Freq"),  Line_Freq);
	dsp21k_dl_int(processor1, dsp21k_get_addr(processor1, "_Frame_Size"), Frame_Size);

	dsp21k_dl_int(processor2, dsp21k_get_addr(processor2, "_Frame_Size"), Frame_Size);
	dsp21k_dl_int(processor3, dsp21k_get_addr(processor3, "_Frame_Size"), Frame_Size);
	dsp21k_dl_int(processor4, dsp21k_get_addr(processor4, "_Frame_Size"), Frame_Size);	

	// Start processor running.
	printf("\n\nPress a key to start processing...\n");
	getch();
	dsp21k_start(processor3);
	sleep (100);
   	dsp21k_start(processor4);
	sleep (100);
	dsp21k_start(processor2);
	sleep (100);
   	dsp21k_start(processor1);
	sleep (1000);


	printf("Processing frame... ");

/////////////////////////////////////////////////////////////////////////////////////
// Main Loop
///////////////////////////////////////////////////////////////////////////////////// 
	for (i = 0; i < Num_Frames; i++ )
	{
		// Download the image to SDRAM from the file (INPUT)
		dsp21k_dl_32s( processor1, dsp_addr2, Total_Pixels, pin );
		dsp21k_dl_int( processor1, dsp21k_get_addr(processor1, "_input"), 1);
    
		// Wait for FFT completing... 
	    sleep(100);
		while ( !dsp21k_ul_int( processor1, dsp21k_get_addr(processor1, "_output") ) );
		dsp21k_dl_int (processor1, dsp21k_get_addr(processor1, "_output"), 0);

		// Read result from SDRAM (OUTPUT)
		dsp21k_ul_32s( processor1, dsp_addr2, Total_Pixels, pout );
			
//		printf ("%d ", i);
	}
	 

///////////////////////////////////////////////////////////////////////////////////// 
	
	// Stop running
	dsp21k_dl_int (processor1, dsp21k_get_addr(processor1, "_done"), 1);
	dsp21k_dl_int (processor2, dsp21k_get_addr(processor2, "_done"), 1);
	dsp21k_dl_int (processor3, dsp21k_get_addr(processor3, "_done"), 1);
	dsp21k_dl_int (processor4, dsp21k_get_addr(processor4, "_done"), 1);

	// Read results
	k =	dsp21k_ul_int( processor1, dsp21k_get_addr(processor1, "_frame_cnt") );
	printf("\n\n%d frames processed by DSP-board \n", k);
	printf("pixel values of the last one: \n\n");
	dsp21k_ul_32s( processor1, dsp21k_get_addr(processor1, "_stat"), 64, statistic );

	// Close the processors.
	BittWareClose(errors);

	// Print out the results.
	for (k=0; k<Frame_Size; k++)
	{
		printf("\nLine %d: ", k+1);
		system("pause");
		for (i=0; i<4; i++)
		{
			for (j=0; j< (LINE_SIZE/4); j++)
			{
				printf("%d ",fft[ (k*LINE_SIZE ) + i*(LINE_SIZE/4) + j]);
			}
			printf("\n");
		}
	}

	for (i=0, j=0; i<32; i++, j += 2)
	{
		if ( (statistic[j] == 0) || (statistic[j+1] == 0) )
				line_time[i] = 0;
		else
				line_time[i] = statistic[j] - statistic[j+1];
	}

	for (i=0,k=1; i<32; i++)
	{
		if (line_time[i])
			printf ("\n%d Line : %d  cycles \n", k++, line_time[i] );
	}

	for (i=0,k=1; i<32; i++)
	{
		average += line_time[i];
		if (line_time[i])
			k++;
	}
	printf ("\nProcessing Time per Line : %f us \n", average/ k * 0.0125 );
}
else
{
	printf("Number of errors = %d \n", errors);
}
	
}