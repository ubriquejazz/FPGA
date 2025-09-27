//*********************************************************
//
//  Blink
//  -----
//  blink.c : Example demonstrating use of timers,
//            interrupts, flags, and the LEDs.
//
//*********************************************************

#include <def21160.h>
#include <21160.h>
#include <filter.h>
#include <complex.h>

/**********************************************************/
/**********************************************************/
#define CLOCK_RATE  2000000

#ifndef SetIOP
#define SetIOP(addr,val)    (*(unsigned long *)(addr))=(val)
#define GetIOP(addr)		(*(unsigned long *)(addr))
#endif

#define FFT_SIZE			 64

#pragma align 64 
float dm input_r[FFT_SIZE]; 
#pragma align 64 
float pm input_i[FFT_SIZE]; 

float dm temp_r[FFT_SIZE]; 
float pm temp_i[FFT_SIZE]; 

float dm twid_r[FFT_SIZE/2]; 
float pm twid_i[FFT_SIZE/2]; 

int count=0;
int mpid;

int input_data[FFT_SIZE*2];	
int output_data[FFT_SIZE*2];	

int count_start();
int count_end(int);

volatile int time_temp, cycle_count; /* for benchmark routines */
/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
int get_idc( void )
{
    int idc;

    idc = GetIOP( SYSTAT );
    idc = (idc>>8) & 0x07;

    return( idc );
}


/**********************************************************/
/*                                                        */
/*                                                        */
/*                                                        */
/**********************************************************/
void main ( void )
{
    int cnt;
	int i, j;
	float pi = 3.141516;
	complex_float temp, exponent;
	
    /* Initialize data. */
    count=-1;
    mpid = get_idc();
	exponent.re = 0;
	exponent.im = 2 * pi * 45;
	
//////////////////////
// FFT 				//
//////////////////////

    // Initialize input  buffer for the FFT 
	for (i=0; i<FFT_SIZE*2; i += 2)
	{
		input_data[i] = 1;						input_data[i+1] = 0;
	}
	for (i=0, j=0; i<FFT_SIZE; i++, j +=2)
	{
		input_r[i] = (float)input_data[j];		input_i[i] = (float)input_data[j+1];
	}
	
	twidfftf(twid_r,twid_i,FFT_SIZE); 
	time_temp = count_start();					// Benchmark routine start 
	cfftf(input_r,input_i, temp_r, temp_i, twid_r, twid_i, FFT_SIZE);
	
	// Load out buffer for the FFT
	time_temp = count_start();					// Benchmark routine start 
	for (i=0, j=0; i<FFT_SIZE; i++, j +=2)
	{
		temp.re = input_r[i];	
		temp.im = input_i[i];
		exponent.im = i * exponent.im;
		temp = cmltf( temp, cexp(exponent));
		output_data[j]   = temp.re;
		output_data[j+1] = temp.im;
	}		
	cycle_count = count_end(time_temp); 		// Benchmark routine end   
	   
//////////////////////////////////////////////////////////////
// Use a delay and then toggle LEDs based in mpid so they	//
// all toggle at a different rate							//
//////////////////////////////////////////////////////////////
    // Initialize flags for output.
	asm("BIT SET MODE2 0x00060000;");

	while(1)
	{
		count++;
		for (cnt = 0 ; cnt < 500000 ; cnt++);

		if (!(count % (mpid*2)))
			asm("BIT TGL FLAGS 0x00000004;");

		if (!(count % (mpid*2+1)))
			asm("BIT TGL FLAGS 0x00000008;");

 		SetIOP(MSGR0, count);
	}	
}

/* End of file blink.c */
