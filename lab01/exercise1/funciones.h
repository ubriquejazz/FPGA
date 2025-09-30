#ifndef FUNC_H
#define FUNC_H

#include <complex>
using namespace std;

#define PI	3.14159
#define FFT_LENGTH 8

typedef std::complex<float> sampleInX_t;
typedef std::complex<float> sampleCoefX_t;
typedef std::complex<float> sampleProdX_t;
typedef std::complex<float> sampleSumX_t;
typedef std::complex<float> sampleOutX_t;

int cuenta(sampleOutX_t* a, sampleOutX_t* b, float sigma);

#endif