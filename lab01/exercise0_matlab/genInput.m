function [t, signal]= geninput (type, fTones, nSamples, fs)

% Check of a correct call
if nargin~=4,
    error ('Wrong number of arguments');
end;

% Determination of amplitudes
if type== 'random',
    amplitude= rand (size (fTones));
else,
    amplitude= type*ones (size (fTones));
end;

% Generation of partial signals
t= [0:1/fs:(nSamples-1)*(1/fs)];
signal= zeros (size (t));
for i=1: length (fTones),
    signal= signal + amplitude(i)*sin (2*pi*fTones(i)*t);
end;

% Unsigned input signal
mx= max (signal);
mn= min (signal);
for i=1:length (signal),
    signal(i)= 0.999999*(signal(i) - mn)/(mx - mn);
end;

% Plotting of the generated signal
figure;
plot (t, signal);
title('Generated input signal');
xlabel('Time (s)');
ylabel('Amplitude');

% Representation of the frequency input signal
figure;
specgram (signal, 2048, fs);
colorbar;
title ('Input signal spectrogram');
