// runprime.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "fftw3.h"

#include <stdio.h>
#include <stdlib.h>
#include <windows.h> // for LARGE_INTEGER
#include <time.h>

#if !(defined WIN32) && !(defined ULONG)
#define ULONG unsigned long
#endif // ULONG
#ifndef LPULONG
#define LPULONG ULONG*
#endif // LPULONG

#define N 1024
#define ITERATIONS 1000000


LARGE_INTEGER start_time;
LARGE_INTEGER stop_time;

///////////////////////////////
// display_time() & time_snap()
// ----------------------------
void display_time(ULONG iterations, LARGE_INTEGER * start, LARGE_INTEGER * stop)
{
	LARGE_INTEGER Ctr1, Ctr2, Overhead;
	LARGE_INTEGER CountsPerSecond;
	double counts;
	double seconds;
	
	QueryPerformanceCounter(&Ctr1);
	QueryPerformanceCounter(&Ctr2);
	
	QueryPerformanceFrequency(&CountsPerSecond);

	//determine API overhead
	Overhead.QuadPart = Ctr2.QuadPart - Ctr1.QuadPart;  

	counts = (double)(stop->QuadPart - start->QuadPart - Overhead.QuadPart);
	seconds = (counts / (double)(CountsPerSecond.QuadPart));

	printf("%.0lf us", seconds);	// display
}
void time_snap(LARGE_INTEGER* li)
{
    QueryPerformanceCounter(li);
}

/////////////////////////////////////////////////////////////////////////////////////
int main(void)
{
	float pixelbuff[2*N];
    fftwf_complex *in, *out;
	fftwf_plan	p;

	int i, indx,  size, error;

// Array allocation
in  = (fftwf_complex*) malloc(sizeof(fftwf_complex) * N); 
out = (fftwf_complex*) malloc(sizeof(fftwf_complex) * N); 

// Plan = data that FFTW needs to compute the FFT
p = fftwf_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);

// Data Initialization
for (i = 0; i< 2*N; i++)
{
	pixelbuff[i] = 1.0;
}

// FFTW execution
time_snap(&start_time);
for (i = 0; i < ITERATIONS; i++)
{
	// Simulation of package of 2048 real numbers
	for (i = 0; i< N; i++)
		{
		in[i][0] = 1.0; 	in[i][1] = 1.0;
		}
	fftwf_execute(p);
}
time_snap(&stop_time);

printf("Computation Time: ");
display_time(ITERATIONS, &start_time, &stop_time);

// Print out the results.
printf("\nThe FFTW to be:\n");
system("pause");
for (indx = 0; indx < N; indx+=2)
	{
	printf("%f + i %f \n", out[indx][0], out[indx][1]);
	}
printf("DC component = %f + i %f \n", out[0][0], out[0][1]);
   
// De-allocation
fftwf_destroy_plan(p);
fftwf_free(in);
fftwf_free(out);

system("pause");

return 0;
}
