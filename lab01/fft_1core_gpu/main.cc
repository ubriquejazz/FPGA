/* Accelerating the 512-points FFT by using the Neon GPU

List of functions from the Ne10 library to be used:
- ne10_init()
- ne10_fft_alloc_c2c_float32_neon()

Initialization of pointers src and dst
- psrc_ddr = (ne10_fft_cpx_float32_t *) (cfg->buffer + (sizeof(ne10_fft_cpx_float32_t) * (fftSize)))
- pdst_ddr = (ne10_fft_cpx_float32_t *) (psrc_ddr + (sizeof(ne10_fft_cpx_float32_t) * (fftSize)));

Initialization of the src buffer
- psrc_ddr[i] = (ne10_fft_cpx_float32_t) (complex_data);

 */
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xtime_l.h"

#include <complex>
using namespace std;
typedef std::complex<float> sampleInX_t;
typedef std::complex<float> sampleOutX_t;

#define FFT_LENGTH 512

#include "../data/DataIn.h"
#include "../data/DataOut_OK.h"

// NEON libraries
#include "../Ne10-standalone-lib-arm32/inc/NE10.h"

// Number of FFT points and iterations
#define NFFT 			FFT_LENGTH
#define TEST_SAMPLES	1000

int main()
{
	XTime tStart, tEnd;

	xil_printf("*** Launching the FFT test program (%d) ***\n", NFFT);

	// Size of FFT
	ne10_int32_t fftSize = NFFT;
	// Pointer of src_input FFT
	ne10_fft_cpx_float32_t *psrc_ddr; // = XPAR_DDR_MEM_BASEADDR; // Its posible to set memory baseaddress
	// Pointer of dst_output FFT
	ne10_fft_cpx_float32_t *pdst_ddr; // = XPAR_DDR_MEM_BASEADDR + 0x8000;
	// Configuration variable FFT
	ne10_fft_cfg_float32_t cfg;

	// Checking if NEON is avilable
	if (ne10_init() != NE10_OK)
		return 1;
	
	// Configuration of pointers and coefficients of FFT.
	cfg = ne10_fft_alloc_c2c_float32_neon(fftSize);

	// Initialization of pointers src and dst
	psrc_ddr = (ne10_fft_cpx_float32_t *) (cfg->buffer + (sizeof (ne10_fft_cpx_float32_t) * (fftSize)));
	pdst_ddr = (ne10_fft_cpx_float32_t *) (psrc_ddr + (sizeof (ne10_fft_cpx_float32_t) * (fftSize)));

	// Check if we can remove this part
	if (cfg == NULL)
		return -1;

	// Generating the input to FFT test program  
	for (int i = 0; i < NFFT; i++)
		psrc_ddr[i] = (ne10_fft_cpx_float32_t)(DataIn[i]);

	xil_printf("***  Launch %d iters of FFT test program  ***\n", TEST_SAMPLES);
    XTime_GetTime(&tStart);

	for (int m = 0; m < TEST_SAMPLES; m++) {
		// for an IFFT, the last parameter should be '1'
		ne10_fft_c2c_1d_float32(pdst_ddr, psrc_ddr, cfg, 0);
	}
    
	XTime_GetTime(&tEnd);
	double time_avg = (double)(tEnd - tStart) / COUNTS_PER_SECOND;
	xil_printf("Time average of execution: %.4f us.\n", time_avg / TEST_SAMPLES);

	xil_printf("***  Validation with the golden pattern  ***\n");	
	int error=0;
	for (int i=0; i<FFT_LENGTH; i++) {
        if ( ( (pdst_ddr[i].real() - DataOut_OK[i].real()) > 0.01) || ( (pdst_ddr[i].real() - DataOut_OK[i].real()) < -0.01) ) {
            error++;
        }
        if ( (pdst_ddr[i].imag() - DataOut_OK[i].imag()) > 0.01) || ( (pdst_ddr[i].imag() - DataOut_OK[i].imag()) < -0.01) ) {
            error++;
        }
    }
    if (error==0) {
		xil_printf("FFT OK\n");
	} else {
		xil_printf("FFT ERROR: %d\n", error);
	}

	// Free the allocated configuration structure
    ne10_fft_destroy_c2c_float32(cfg);

	return 0;
}
