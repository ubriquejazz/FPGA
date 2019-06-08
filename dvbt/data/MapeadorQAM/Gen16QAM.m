% Reading the values from Figure 9a
dvbt_qam = [    +3 + 3i% ++
                +3 + 1i
                +1 + 3i
                +1 + 1i
            +3 - 3i % +-
            +3 - 1i
            +1 - 3i
            +1 - 1i
                -3 + 3i % -+
                -3 + 1i
                -1 + 3i
                -1 + 1i
            -3 - 3i % --
            -3 - 1i
            -1 - 3i
            -1 - 1i];
        
% Normalization factor from Section 4.4
M = 16;                         % 
v = log2(M);                    % Constalletion Size 
arg = 2/3 * (M - 1);            % 
scale = 4/3 * sqrt(arg);        % Scaling factor 

dvbt_qam = dvbt_qam/scale;
for i=1:M
    qam_re(i)  = real(dvbt_qam(i)); 
    qam_im(i)  = imag(dvbt_qam(i));
end;

%% A/D Conversion  1.0.15  fi (dvbt_qam,1,16,15);
dac_bit= 16;             
lsb = 1 / 2^(dac_bit-1); 
for i=1:M
    adc_real(i)  = floor(( qam_re(i) + lsb/2 )/lsb );
    adc_imag(i)  = floor(( qam_im(i) + lsb/2 )/lsb );
end;
adc_real = adc_real + (adc_real<0)*2^dac_bit;
adc_imag = adc_imag + (adc_imag<0)*2^dac_bit;

%% D/A Conversion  1.0.15          
dac_real = ( adc_real - (adc_real>2^15)*2^dac_bit ) * lsb;
dac_imag = ( adc_imag - (adc_imag>2^15)*2^dac_bit ) * lsb;


%% File Store
fid1=fopen('qam16_re.dat','w');
fid2=fopen('qam16_im.dat','w');
fprintf(fid1,'%0.4X,\n', adc_real);
fprintf(fid2,'%0.4X,\n', adc_imag);
fclose(fid1);
fclose(fid2);