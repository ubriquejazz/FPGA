/* FFT implementation on a single core

lab01/fft_1core/main.cc

Develop the main.cc file with the implementation of a FFT, associated to the 
vector tests previously generated, and validated with the golden patterns

- Integration and verification of the C model in Vivado for a single core solution
- Measure the performance of the implementation

 */
#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xtime_l.h"
#include "Flexfft.h"

#include "../data/DataIn.h"
#include "../data/DataOut_OK.h"

int main() {

    xil_printf("Inicio del programa...\n\r");

    XTime tStart, tEnd;
    int errorCount = 0;
    sampleOutX_t DataOut[FFT_LENGTH];

    XTime_GetTime(&tStart);
	FlexFFT(DataIn, DataOut);
    XTime_GetTime(&tEnd);

    double elapsed_sec = (double)(tEnd - tStart) / COUNTS_PER_SECOND;
    xil_printf("Tiempo empleado: %f segundos\n\r", elapsed_sec);    

	// Compare DataOut with DataOut_OK from ../data/DataOut_OK.h	
	int error=0;
	for (int i=0; i<FFT_LENGTH; i++) {
        if ( ( (DataOut[i].real() - DataOut_OK[i].real()) > 0.01) || ( (DataOut[i].real() - DataOut_OK[i].real()) < -0.01) ) {
            error++;
        }
        if ( (DataOut[i].imag() - DataOut_OK[i].imag()) > 0.01) || ( (DataOut[i].imag() - DataOut_OK[i].imag()) < -0.01) ) {
            error++;
        }
    }
    if (error==0) {
		xil_printf("FFT OK\n");
	} else {
		xil_printf("FFT ERROR: %d\n", error);
	}
    return 0;
}