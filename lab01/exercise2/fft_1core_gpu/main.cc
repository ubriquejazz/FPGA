/*
 * Empty C++ Application
 */
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"

#include <complex>
using namespace std;
typedef std::complex<float> sampleInX_t;
typedef std::complex<float> sampleOutX_t;

#define FFT_LENGTH 512

#include "DataIn.h"
#include "DataOut_OK.h"

// NEON libraries
#include "Ne10.h"

// Timer libraries
#include "xtime_l.h"

// Number of FFT points
#define NFFT FFT_LENGTH

// Number of iterations
#define TEST_SAMPLES	1000


int main()
{
	printf("*****************************************************\n");
	printf("***  Launching the FFT test program (%d) ***\n", NFFT);
	printf("******************************************************\n");


	// Size of FFT
	ne10_int32_t fftSize = NFFT;

	// Pointer of src_input FFT
	ne10_fft_cpx_float32_t *psrc_ddr; // = XPAR_DDR_MEM_BASEADDR; // Its posible to set memory baseaddress
	// Pointer of dst_output FFT
	ne10_fft_cpx_float32_t *pdst_ddr; // = XPAR_DDR_MEM_BASEADDR + 0x8000;
	// Configuration variable FFT
	ne10_fft_cfg_float32_t cfg;

	// Variables to generate input and read output
	uint32_t i;


	// Checking if NEON is avilable
	if (ne10_init() != NE10_OK)
	{
		xil_printf("\nFailed to initialise Ne10.\n");
		return 1;
	}

	// printf("***  Alloc memory to FFT test program  ***\n");
	// printf("***********************************************\n");
	// Configuration of pointers and coefficients of FFT.
	cfg = ne10_fft_alloc_c2c_float32_neon(fftSize);
	// Initialization of pointers src and dst
	psrc_ddr = (ne10_fft_cpx_float32_t *) (cfg->buffer + (sizeof (ne10_fft_cpx_float32_t) * (fftSize)));
	pdst_ddr = (ne10_fft_cpx_float32_t *) (psrc_ddr + (sizeof (ne10_fft_cpx_float32_t) * (fftSize)));

	// Check if we can remove this part
	if (cfg == NULL)
	{
		xil_printf("\nERROR! Alloc failed.\n");
		return -1;
	}


	// printf("***  Generating the input to FFT test program  ***\n");
	// printf("*******************************************************\n");
	for (i = 0; i < NFFT; i++)
	{
		psrc_ddr[i] = (ne10_fft_cpx_float32_t) ...................;
	}

	// printf("***  Launch %d iters of FFT test program  ***\n", TEST_SAMPLES);
	// printf("********************************************************\n");
	for (int m = 0; m < TEST_SAMPLES; m++)
	{
		......................................
	}

	// printf("***  Time of execution of FFT test program  ***\n");
	// printf("********************************************************\n");

	printf("Time average of execution: %.4f us.\n", time_avg / TEST_SAMPLES);



	// printf("***  Validation with the golden pattern  ***\n");
	// printf("********************************************************\n");
	....................................

	

	printf("***********************************************\n");
	printf("***  End of FFT test program  ***\n");
	printf("***********************************************\n");


	return 0;
}
