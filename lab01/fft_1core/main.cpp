#include "Flexfft.h"
#include "../data/DataIn.h"
#include "../data/DataOut_OK.h"
#include <stdio.h>

int main() {

    sampleOutX_t DataOut[FFT_LENGTH];
	FlexFFT(DataIn, DataOut);

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