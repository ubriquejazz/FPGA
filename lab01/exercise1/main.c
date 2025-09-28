#include <stdio.h>
#include "funciones.h"
#include "DataIn.h"
#include "DataOK.h"

int main()
{
    xil_printf("Inicio del programa...\n\r");

    int errorCount = 0;
    for (int i = 0; i < FFT_LENGTH; i++) {
        if (a[i] != b[i]) {
            xil_printf("Error en posición %d: DataIn=%d, Esperado=%d\n\r",
                       i, a[i], b[i]);
            errorCount++;
        }
    }
    xil_printf("Total de errores: %d\n\r", errorCount);

    float sigma = 0.01;
    errorCount = 0;
	for (int i=0; i<FFT_LENGTH; i++) {
		if ( ( (b[i].real() - a[i].real()) > sigma) || ( (b[i].real() - a[i].real()) < -sigma) ) {
			errorCount++;
		}
		if ( ( (b[i].imag() - a[i].imag()) > sigma) || ( (b[i].imag() - a[i].imag()) < -sigma) ) {
			errorCount++;
		}
	}
    xil_printf("Con tolerancia del %f: %d\n\r", sigma, errorCount);

    return 0;
}
