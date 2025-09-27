%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
% ParallelFFT.m
% Parallel Implementation of Float-Point FFTs 
% DSP based FDOCT (Juan GAGO)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

clear all;
close all;
N = 2048;
M = 32;
R = 64;

for f0 = 1:(N/2)
   
n = 0 : 1/N : 1-1/N;
x = cos(2*pi*f0*n);

X = fft(x);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Step 1&2: Arrange the input array in a R*M matrix
for row = 1 : R               
    A(row, 1:M) = x([1:M] + (row-1)*M);
end;

B = fft(A);         % Step 3: 1st FFT stage: 32 FFTs of 64 complex points

% Step 4: Change the phase of the elements
for m = 1 : R
    for k = 1 : M
        C(m,k) = B(m,k) * exp (- 2 * pi * i * (m-1) * (k-1) / N);
    end;
end;

D = fft (C');       % Step 5&6: 2nd FFT stage: 64 FFTs of 32 complex points
                    % Theses FFTs are optimizable thanks to real-signal properties

% Arrange the output M*R matrix in an N-array
for row = 1 : M            
    Y([1:R] + (row-1)* R) = D(row, R:-1:1);
end;
Z = circshift(Y,[0 -R]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1);clf;
title('Parallel FFT');
xlabel('freq samples');
ylabel('magnitude');
line(1:N, abs(X),'color','b','LineStyle','none', 'Marker','+');
line(1:N, abs(Z),'color','r','LineStyle','none', 'Marker','.');
drawnow;
end;