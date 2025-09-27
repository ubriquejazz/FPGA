%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%
% DSP based FDOCT (Juan GAGO)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

clear all;
close all;
N = 1024;
% f0 = 40;

for f0 = 16:128
    
n = 0: 1/N : 1-1/N;
x = cos(2*pi*f0*n);
tic, 
    for k = 1:1000
        X = fft(x);
    end;
f0 
seconds = toc / 1000


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
M = 32;

for m = 1 : M               % Arrange in a 32x32 matrix
    k = [1:M] + (m-1)*M;
    A(m,1:32) = x(k);
end;

B = fft(A);         % 1st FFT stage: 32 FFTs of 32 points

for m = 1 : M
    for n = 1 : M
        C(m,n) = B(m,n) * exp (- 2 * pi * i * (m-1) * (n-1) / N);
    end;
end;

Y = fft (C');       % 2nd FFT stage: 32 FFTs of 32 points

for m = 1 : M
    offset = (m-1) * M;
    for n = 1 : M
        y(n + offset) = Y(m,n) ;
    end;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
figure(1),clf
line(1:N, abs(X),'color','b','LineStyle','none', 'Marker','.');
line(1:N, abs(y),'color','r','LineStyle','none', 'Marker','.');
%line(k(1:2:end), abs(y(1:2:end)), 'color','r','LineStyle','none','Marker','.')
%line(k(2:2:end), abs(y(2:2:end)), 'color','g','LineStyle','none','Marker','.')
title('FFT paralleling');
xlabel('freq samples');
ylabel('magnitude');
drawnow;
pause(0.1);
end;