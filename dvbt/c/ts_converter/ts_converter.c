#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>

FILE *fdatos_entrada;
FILE *fdatos_salida;
//FILE *fdatos_salida2;
//FILE *fdatos_salida3;
//FILE *fdatos_salida4;
int i, cont;
char byte;

int main(int argc, char *argv[])
{
	fdatos_entrada = fopen("00_Bandas_verticales_ByN.ts", "r");
	fdatos_salida = fopen("00_Bandas_verticales_ByN_formato_de_1bytexlinea.dat", "w");
	//fdatos_salida2 = fopen("00_Bandas_verticales_ByN_formato_de_1TSxlinea_bytes_separados_por_espacio.dat", "w");
	//fdatos_salida3 = fopen("00_ejemplo_formato_de_1bytexlinea.dat", "w");
	//fdatos_salida4 = fopen("00_ejemplo_formato_de_1TSxlinea_bytes_separados_por_espacio.dat", "w");
	cont = 1;
	while(!feof(fdatos_entrada)){
		for(i=0; i<188; i++){
			byte = fgetc(fdatos_entrada);
			fprintf(fdatos_salida, "%d ", byte);
			fprintf(fdatos_salida, "\n");
			//fprintf(fdatos_salida2, "%d ", byte);
			/*
			if(cont < 100){
				fprintf(fdatos_salida3, "%d ", byte);
				fprintf(fdatos_salida3, "\n");
				fprintf(fdatos_salida4, "%d ", byte);
			}*/
		}
		fprintf(fdatos_salida2, "\n");
		/*
		if(cont < 100)
			fprintf(fdatos_salida4, "\n");*/
		cont++;
		if(cont%200 == 0)
			printf(".");
	}
	fclose(fdatos_entrada);
	fclose(fdatos_salida);
	//fclose(fdatos_salida2);
	//fclose(fdatos_salida3);
	//fclose(fdatos_salida4);
	printf("\nFinalizado con éxito!\n");
	//scanf("%d", &cont);

	return EXIT_SUCCESS;
}
