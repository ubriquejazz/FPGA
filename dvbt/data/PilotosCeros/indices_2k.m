clear all;
close all;

ceros = zeros(1, 2048);
ultimo_cero = 172;

pilotos = zeros(1, 2048);
primer_piloto = 172 + 1;

tps = zeros(1, 2048);
primer_tps = 172 + 1;

for i=1:172
    ceros(i) = 1;
end;
for i=173:1877
    ceros(i) = 0;
end;
for i=1878:2048
    ceros(i) = 1;
end;

tps(35) = 1;
tps(51) = 1;
tps(210) = 1;
tps(347) = 1;
tps(414) = 1;
tps(570) = 1;
tps(596) = 1;
tps(689) = 1;
tps(791) = 1;
tps(902) = 1;
tps(1074) = 1;
tps(1220) = 1;
tps(1263) = 1;
tps(1287) = 1;
tps(1470) = 1;
tps(1595) = 1;
tps(1688) = 1;

pilotos(1)=1;
pilotos(49)=1;
pilotos(55)=1;
pilotos(88)=1;
pilotos(142)=1;
pilotos(157)=1;
pilotos(193)=1;
pilotos(202)=1;
pilotos(256)=1;
pilotos(280)=1;
pilotos(283)=1;
pilotos(334)=1;
pilotos(433)=1;
pilotos(451)=1;
pilotos(484)=1;
pilotos(525)=1;
pilotos(532)=1;
pilotos(619)=1;
pilotos(637)=1;
pilotos(715)=1;
pilotos(760)=1;
pilotos(766)=1;
pilotos(781)=1;
pilotos(805)=1;
pilotos(874)=1;
pilotos(889)=1;
pilotos(919)=1;
pilotos(940)=1;
pilotos(943)=1;
pilotos(970)=1;
pilotos(985)=1;
pilotos(1051)=1;
pilotos(1102)=1;
pilotos(1108)=1;
pilotos(1111)=1;
pilotos(1138)=1;
pilotos(1141)=1;
pilotos(1147)=1;
pilotos(1207)=1;
pilotos(1270)=1;
pilotos(1324)=1;
pilotos(1378)=1;
pilotos(1492)=1;
pilotos(1684)=1;
pilotos(1705)=1;


aux = zeros (1, 2048);
aux( primer_piloto : (primer_piloto + 1704) ) = pilotos(1:1705);
aux_tps = zeros (1, 2048);
aux_tps( primer_tps : (primer_tps + 1704) ) = tps(1:1705);

figure; stem(ceros);
hold on; stem(aux, 'r');
hold on; stem(aux_tps, 'g');

fid1=fopen('RomCeros2k.dat','w');
fprintf(fid1,'%d, \n', ceros);
fclose(fid1);

fid1=fopen('RomPilotos2k.dat','w');
fprintf(fid1,'%d, \n', aux);
fclose(fid1);

fid1=fopen('RomTps2k.dat','w');
fprintf(fid1,'%d, \n', aux_tps);
fclose(fid1);

