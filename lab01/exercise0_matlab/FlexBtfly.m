function [dataout]= FlexBtfly (N, datain, W)

dataout= [];

for m=1:N/2
    dataout(m)= datain(m) + datain(N/2+m);
end;
for m=N/2+1:N
    dataout(m)= (datain(m-N/2) - datain(m))*W(m-N/2);
end;
