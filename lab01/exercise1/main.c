#include <stdio.h>

#include "xtime_l.h"
#include "xil_printf.h"
#include "funciones.h"

#include "DataIn.h"
#include "DataOK.h"

#define TEST_SAMPLES 1000

int measure()
{
    XTime tStart, tEnd;
    double time_avg;

    xil_printf("Medición de tiempo con XTime\n\r");

    // Guardar tiempo de inicio
    XTime_GetTime(&tStart);

    // Código a medir
    for (int i = 0; i < TEST_SAMPLES; i++) {
        // operación dummy
    }

    // Guardar tiempo de fin
    XTime_GetTime(&tEnd);

    // Calcular tiempo en segundos
    time_avg = (double)(tEnd - tStart) / COUNTS_PER_SECOND;
	xil_printf("Time average of execution: %.4f us.\n", time_avg / TEST_SAMPLES);

    return 0;
}

int main()
{
    xil_printf("Inicio del programa...\n\r");

    XTime tStart, tEnd;
    int errorCount = 0;

    XTime_GetTime(&tStart);

    // dummy operation

    XTime_GetTime(&tEnd);

    double elapsed_sec = (double)(tEnd - tStart) / COUNTS_PER_SECOND;
    xil_printf("Tiempo empleado: %f segundos\n\r", elapsed_sec);

    for (int i = 0; i < FFT_LENGTH; i++) {
        if (a[i] != b[i]) {
            // xil_printf("Error en %d: DataIn=%d, Esperado=%d\n\r", i, a[i], b[i]);
            errorCount++;
        }
    }
    xil_printf("Errores exactos: %d\n\r", errorCount);
    
    float sigma = 0.01;
    errorCount = cuenta(a, b, sigma);
    xil_printf("Con tolerancia del %f: %d\n\r", sigma, errorCount);

    return 0;
}
