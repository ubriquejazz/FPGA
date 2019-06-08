function Hd = interpolador7x(Fs, N)

Fc   = 4.3;      % Cutoff Frequency
flag = 'scale';  % Sampling Flag
Beta = 0.5;      % Window Parameter

% Create the window vector for the design algorithm.
win = kaiser(N+1, Beta);

% Calculate the cefficients using the FIR1 function.
b  = fir1(N, Fc/(Fs/2), 'low', win, flag);
Hd = dfilt.dffir(b);

intf = 7;                     % Interpolation Factor
num  = get(Hd, 'Numerator');  % Get the numerator from the current filter.

Hd  = mfilt.firinterp(intf, num);

% Hd = interpolador7x(64, 48);
% fid1=fopen('filter_64M.dat','w');
% fprintf(fid1,'%1.4f, \n', num);
% fclose(fid1);

% Hd = interpolador7x(112, 48);
% fid1=fopen('filter_112M.dat','w');
% fprintf(fid1,'%1.4f, \n', num);
% fclose(fid1);

