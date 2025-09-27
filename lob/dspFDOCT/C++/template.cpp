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
#define LINE_SIZE       1024					// line data = 1024 4-byte pixels (2048 2-bytes pixels)
#define FRAME_SIZE      32						// lines per frame for this test
#define TOTAL_PIXELS    LINE_SIZE*FRAME_SIZE	// total number of pixels (32-bits words)
#define NUM_FRAMES		4						// 4 frames
#define MAX_FREQ		1250			 		// Hz
#define SLAVES			2

/********************/
/* Global Variables */
/********************/

PDSP21K	processor1, processor2, processor3, processor4;

U32	dsp_addr = 0x800000;						

long Frame_Size =	FRAME_SIZE;
long Total_Pixels = TOTAL_PIXELS;
long Num_Frames =	NUM_FRAMES;
long Line_Freq =	MAX_FREQ;

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
	int error1, error2, error4;

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
		error4 = dsp21k_load_exe(processor4, "hh4_consumer.dxe");	
		
		return error1 + error2 + error4;
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
	dsp21k_close(processor1);

}

/********************************************************************************/
/*
/*
/********************************************************************************/
void main(int argc, char* argv[])
{
	int i,j,k;
	U32 image[TOTAL_PIXELS];				// data input (120KB < 64MB)
	S32 fft1[TOTAL_PIXELS/SLAVES];			// data output (40KB < 64MB)
	S32 fft2[TOTAL_PIXELS/SLAVES];			// data output (40KB < 64MB)
	U32 *pin, *pout1, *pout2;				// pointers
	U32 statistic[FRAME_SIZE/SLAVES];
	float average=0;

    // Open processors on device 0
	printf("Opening processors on device %d ...", device_num);
	errors = BittWareOpen(Total_Pixels);

if (!errors)
{
	// Download paramaters before running
//	printf("\nFrame Size (Lines < 32): "); scanf("%d", &Frame_Size);
	printf("\nTwo Lines Frequency: "); scanf("%d", &Line_Freq);
	if (Line_Freq > MAX_FREQ) 
		{	
			Line_Freq = MAX_FREQ;
			printf("Frequency not allowed. Two Lines Frequency: %d Hz ", MAX_FREQ);
		}
	printf("\nNumber of Frames: "); scanf("%d", &Num_Frames);
	Total_Pixels = Frame_Size * LINE_SIZE;

#if INIT_SDRAM
	for (i=0; i<Total_Pixels; i++)
	{
		image[i] = 0x10001;
	}
#endif

	printf("\n\n%d frames of %d pair of lines ", Num_Frames, Frame_Size);
	printf("\nlines of %d pixels to be processed @ %d Hz", LINE_SIZE, Line_Freq * 4);

 	dsp21k_dl_int(processor1, dsp21k_get_addr(processor1, "_Line_Freq"),  Line_Freq);
	dsp21k_dl_int(processor1, dsp21k_get_addr(processor1, "_Frame_Size"), Frame_Size);
	dsp21k_dl_int(processor2, dsp21k_get_addr(processor2, "_Frame_Size"), Frame_Size);
	dsp21k_dl_int(processor4, dsp21k_get_addr(processor4, "_Frame_Size"), Frame_Size);	

	// Start processor running.
	printf("\n\nPress a key to start processing...\n");
	getch();
	dsp21k_start(processor2);
   	sleep (100);
	dsp21k_start(processor4);
	sleep (100);
   	dsp21k_start(processor1);
	sleep (1000);

	printf("Processing frame... ");

/////////////////////////////////////////////////////////////////////////////////////
// Main Loop
/////////////////////////////////////////////////////////////////////////////////////   
	for (i = 0; i < Num_Frames; i++ )
	{
		pin= (U32 *)&image[0];
		pout1 = (U32 *)&fft1[0];
		pout2 = (U32 *)&fft2[0];		

		// Download the image to SDRAM from the file (INPUT)
		dsp21k_dl_32s( processor1, dsp_addr, Total_Pixels, pin );

		// Start running
		dsp21k_dl_int (processor1, dsp21k_get_addr(processor1, "_input"), 1);

		// Wait for FFT completing... 
	    sleep(100);
		while ( !dsp21k_ul_int( processor1, dsp21k_get_addr(processor1, "_output") ) );
		dsp21k_dl_int (processor1, dsp21k_get_addr(processor1, "_output"), 0);

		// Read result from Local RAM (OUTPUT)
		dsp21k_ul_32s( processor2, 
					   dsp21k_get_addr(processor2, "_rcvd_data"), Total_Pixels/SLAVES, pout1 );
		dsp21k_ul_32s( processor4, 
					   dsp21k_get_addr(processor4, "_rcvd_data"), Total_Pixels/SLAVES, pout2 );
			
		printf ("%d ", i);
	}
	 

///////////////////////////////////////////////////////////////////////////////////// 
	// Stop running
	dsp21k_dl_int (processor1, dsp21k_get_addr(processor1, "_done"), 1);
	
	// Read results
	k =	dsp21k_ul_int( processor1, dsp21k_get_addr(processor1, "_frame_cnt") );
	dsp21k_ul_32s( processor2, dsp21k_get_addr(processor2, "_stat"), Frame_Size/SLAVES-1, statistic );

	printf("\n\n%d frames processed by DSP-board \n", k);
	printf("pixel values of the last one: \n\n");

	// Close the processors.
	BittWareClose(errors);

	// Print out the results.
	for (k=0; k<Frame_Size/SLAVES; k++)
	{
		printf("\nLine %d: ", k+1);
		system("pause");
		for (i=0; i<2; i++)
		{
			for (j=0; j< (LINE_SIZE/2); j++)
			{
				printf("%d ",fft1[ (k*LINE_SIZE ) + i*(LINE_SIZE/2) + j]);
			}
			printf("\n");
		}
	}
	for (k=0; k<Frame_Size/SLAVES; k++)
	{
		printf("\nLine %d: ", k+1);
		system("pause");
		for (i=0; i<2; i++)
		{
			for (j=0; j< (LINE_SIZE/2); j++)
			{
				printf("%d ",fft2[ (k*LINE_SIZE ) + i*(LINE_SIZE/2) + j]);
			}
			printf("\n");
		}
	}
	for (i=0,k=1; i<Frame_Size/SLAVES-1; i++)
	{
		if (statistic[i])
		{
			printf ("\n%d Line : %d  cycles \n", i, statistic[i] );
			average += statistic[i];
			k++;
		}
	}
	printf ("\nProcessing Time per Two Lines : %f us \n", average / k * 0.0125 );
	printf ("\nMaximum Two Lines Frequency   : %f KHz \n\n", k / average * 80000);
	system("pause");


}
else
{
	printf("Number of errors = %d \n", errors);
}
	
}