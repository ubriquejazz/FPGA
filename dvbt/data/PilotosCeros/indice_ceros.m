fid1=fopen('RomCeros2k.dat','w');
input = zero(1:2048);
for i=1:1556
    input(i) =0;
end;
for i=1557:2048
    input(i) =1;
end;
fprintf(fid1,'%d, \n', input);
fclose(fid1);
%%
fid2=fopen('RomCeros8k.dat','w');
input = zero(1:8192);
for i=1:6224
    input(i) = 0;
end;

for i=6225:8192
    input(i) =1;
end;

fprintf(fid2,'%d, \n', input);
fclose(fid2);


