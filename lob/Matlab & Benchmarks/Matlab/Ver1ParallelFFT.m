%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
% ParallelFFT.m
% Parallel Implementation of Float-Point FFTs 
% DSP based FDOCT (Juan GAGO)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

clear all;
close all;
N = 256;
M = sqrt(N);

for f0 = 1:128
    
n = 0 : 1/N : 1-1/N;
x = cos(2*pi*f0*n);
X0 = fft(x);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Step 1&2: Arrange the input array in a M*M matrix
for row = 1 : M               
    A(row, 1:M) = x([1:M] + (row-1)*M);
end;

B = fft(A);         % Step 3: 1st FFT stage: M FFTs of M points

% Step 4: Change the phase of the elements
for m = 1 : M
    for k = 1 : M
        C(m,k) = B(m,k) * exp (- 2 * pi * i * (m-1) * (k-1) / N);
    end;
end;

D = fft (C');       % Step 5&6: 2nd FFT stage: M FFTs of M points

% Arrange the output M*M matrix in an N-array
for row = 1 : M               
    X1([1:M] + (row-1)*M) = D(row, 1:M);
end;


% for row = 1 : M/4
%     X11 = D(row, 1:M);
% end;
% 
% for row = M/2 :(-1): M/4 + 1
%     X12 = D(row, M:(-1):1);
% end;
% 
% for row = M/2 + 1 : 3*M/4
%     X13 = D(row, 1:M);
% end;
% 
% for row = M :(-1): 3*M/4 + 1 
%     X14 = D(row, M :(-1): 1);
% end;
% 
% X1 = [X11 X12 X13 X14];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1);clf;
title('Parallel FFT');
xlabel('freq samples');
ylabel('magnitude');
line(1:N, abs(X0),'color','b','LineStyle','none', 'Marker','+');
line(1:N, abs(X1),'color','r','LineStyle','none', 'Marker','.');
drawnow;
end;