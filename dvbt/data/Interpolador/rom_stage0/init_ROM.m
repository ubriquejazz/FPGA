% importar stage1_input_16x8192.dat
% stage1_input_16x8192

% lo pasamos a natural y 18 bits
input = (stage1_input_16x8192 + 2^15) * 2^2;

fid1=fopen('stage1_input_18x8192.coe','w');
fprintf(fid1,'%d,\n', input); 
fclose(fid1);