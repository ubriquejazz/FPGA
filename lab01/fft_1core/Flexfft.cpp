#include "Flexfft.h"
#include "../data/W_coef.h"
#include "../data/DataIn.h"
#include "../data/DataOut_OK.h"

void FlexFFT(sampleOutX_t datain[FFT_LENGTH], sampleOutX_t dataout[FFT_LENGTH])
{
	int n=0;
	int m=0;
	int p=0;
	sampleCoefX_t W_i[FFT_NFFT_MAX][FFT_LENGTH];
	sampleOutX_t data_int[FFT_NFFT_MAX+1][FFT_LENGTH];

	for (m=0; m<FFT_LENGTH; m++)
	{
		data_int[0][m]= datain[m];
	}

	for (m = 0; m < FFT_NFFT_MAX; m++) // m=1:Nstage
	{
		p= 0;
		for (n=0; n<FFT_LENGTH/2; n+= (1 << m))
		{
			W_i[m][p]= std::complex<float>(W[n].real(),W[n].imag());
			p++;
		}

		for (n = 0; n < (1 <<  m); n++) // n = 1:(2 ^ (m - 1))
		{
			FlexBtfly (FFT_LENGTH/(1 << m), &data_int[m][n*FFT_LENGTH/(1 << m)], &data_int[m+1][n*FFT_LENGTH/(1 << m)], W_i[m]);
		}
	}

	for (n=0; n<FFT_LENGTH; n++)
		dataout[n]= data_int[FFT_NFFT_MAX][inv_array[n]];
}

// Butterfly operation
void FlexBtfly(int N, sampleOutX_t* datain, sampleOutX_t* dataout, const sampleCoefX_t* W_i)
{
	int m;
	sampleSumX_t data_sum[FFT_LENGTH];
	sampleProdX_t data_prod[FFT_LENGTH];

	for (m = 0; m < N/2; m++) // for m = 1 : N/2
	{
		data_sum[m] = (sampleSumX_t) (datain[m] + datain[N/2 + m]);
		dataout[m] = (sampleOutX_t) data_sum[m];
	}

	for (m = N/2; m < N; m++) // for m = (N/2 + 1) : N
	{
		data_sum[m] = (sampleSumX_t) (datain[m - N/2] - datain[m]);
		data_prod[m] = (sampleProdX_t) (data_sum[m] * ((sampleSumX_t) W_i[m - N/2]));
		dataout[m] = (sampleOutX_t) data_prod[m];
	}
}

int main() {

	// DataIn from ../data/DataIn.h
	sampleOutX_t b[FFT_LENGTH];
	FlexFFT(DataIn, b);

	// Compare DataOut with DataOut_OK from ../data/DataOut_OK.h	
	int error=0;
	for (int i=0; i<FFT_LENGTH; i++) {
		if ( ( (b[i].real() - DataOut_OK[i].real()) > 0.01) || ( (b[i].real() - DataOut_OK[i].real()) < -0.01) ) {
			error++;
		}
		if ( ( (b[i].imag() - DataOut_OK[i].imag()) > 0.01) || ( (b[i].imag() - DataOut_OK[i].imag()) < -0.01) ) {
			error++;
		}
	}
	if (error==0) {
		printf("FFT OK\n");
	} else {
		printf("FFT ERROR: %d\n", error);
	}

	printf("***********************************************\n");
	printf("***  End of FFT test program  ***\n");
	printf("***********************************************\n");


	return 0;
}