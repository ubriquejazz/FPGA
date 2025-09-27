%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% fftmain.m
%
% It analyses the quantization effects on s standard FFT.
%
% Last update: 25/01/2017
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
close all;
clc;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Program control variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CTRL_show_figs= true;
CTRL_mode_chk= true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Global parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fs = 62.5e6;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters for FFT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nfft= 512;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input generation
tones= [2e6 5e6 9e6 12e6];
amplitude= 0.5;
[t, finput]= genInput (amplitude, tones, Nfft, fs);


fidh= fopen ('DataIn.h', 'w+');
fprintf (fidh, 'sampleOutX_t DataIn[FFT_LENGTH]= {');
for n=1:length(finput)-1,
    fprintf (fidh, 'std::complex<float>(%f,%f), ', real(finput(n)), imag(finput(n)));
end;
fprintf (fidh, 'std::complex<float>(%f,%f)};\n\n', real(finput(end)), imag(finput(end)));
fclose (fidh);


if CTRL_show_figs==true
    figure;
    t=[0:length(finput)-1];
    t= t/500e3;
    plot(t, finput);
    xlabel('Samples');
    ylabel('Amplitude');
    title ('Input signal, floating-point');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Floating-point FFT computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f= [-Nfft/2:Nfft/2-1]*fs/Nfft;

foutputi= fft (finput(1:Nfft), Nfft);
foutput= abs (foutputi);
foutput= fftshift (foutput);
foutputi= fftshift (foutputi);

if CTRL_show_figs==true
    figure;
    subplot (2, 1, 1); plot (finput(1,1:Nfft));
    xlabel ('Time (s)');
    title ('First frame FFT, floating-point');
    subplot (2, 1, 2); stem (f,foutput);
    xlabel ('Frequency (Hz)');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flexible Floating-point FFT computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f= [-Nfft/2:Nfft/2-1]*fs/Nfft;

fxoutputi= FlexFFT (Nfft, finput(1:Nfft));

fidh= fopen ('DataOut_OK.h', 'w+');
fprintf (fidh, 'sampleOutX_t DataOut_OK[FFT_LENGTH]= {');
for n=1:length(fxoutputi)-1,
    fprintf (fidh, 'std::complex<float>(%f,%f), ', real(fxoutputi(n)), imag(fxoutputi(n)));
end;
fprintf (fidh, 'std::complex<float>(%f,%f)};\n\n', real(fxoutputi(end)), imag(fxoutputi(end)));
fclose (fidh);

fxoutput= abs (fxoutputi);
fxoutput= fftshift (fxoutput);
fxoutputi= fftshift (fxoutputi);

if CTRL_show_figs==true
    figure;
    subplot (2, 1, 1); plot (finput(1,1:Nfft));
    xlabel ('Time (s)');
    title ('First frame FFT, flexible floating-point');
    subplot (2, 1, 2); stem (f,fxoutput);
    xlabel ('Frequency (Hz)');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flexible Error analysis in FFT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
error= abs (foutput - fxoutput);

if CTRL_show_figs==true
    figure;
    stem (f, error);
    title ('Flexible - floating-point First frame FFT error');
end;

mx= max (max (max (error)));
s= sprintf ('\nMaximum absolute error in FFT quantization: %f.\n', mx);
disp (s);

