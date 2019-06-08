function PmOFDM = cag(RPM, Vp, R)

% Sinusoide
Pp = (Vp^2)/R;
Vrms = Vp / sqrt(2);
PmSin = Vrms^2;

% OFDM
Ofdm_Sin_dB = RPM - 3;      % Diferencia respecto al Sin
% Ofdm_Sin_dB = 10 * log10(PmSin/PmOFDM);
arg = Ofdm_Sin_dB/10;
Ofdm_Sin = 10^arg;
PmOFDM = PmSin / Ofdm_Sin;

% PmOFDM = cag(13, 1, 1);
% fi (PmOFDM,1,18,17);


