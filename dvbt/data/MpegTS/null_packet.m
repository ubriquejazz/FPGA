clear all;

data(1)= 71;
data(2)= 1;
data(3)= -1;
data(4)= 16;

for i= 5:188
    data(i) = -1;
end;

fid1=fopen('null_packet.dat','w');
fprintf(fid1,'%0.2X,\n', data + (data<0)*2^8);
fclose(fid1);
