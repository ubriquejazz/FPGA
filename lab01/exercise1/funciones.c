#include "funciones.h"

int cuenta(sampleOutX_t* a, sampleOutX_t* b, float sigma) {
    int errorCount = 0;
	for (int i=0; i<FFT_LENGTH; i++) {
		if ( ( (b[i].real() - a[i].real()) > sigma) || ( (b[i].real() - a[i].real()) < -sigma) ) {
			errorCount++;
		}
		if ( ( (b[i].imag() - a[i].imag()) > sigma) || ( (b[i].imag() - a[i].imag()) < -sigma) ) {
			errorCount++;
		}
	}
    return errorCount;
}