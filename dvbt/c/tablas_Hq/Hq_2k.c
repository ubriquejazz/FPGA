
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include "math.h"

#define MUESTRAS 	1512
#define MODO		2048
#define COLUMNAS	10

// ficheros de salida
FILE *fichero_Hq_impares;
FILE *fichero_Hq_pares;

int i, n, aux, filas, cols;
char auxiliar;
int * tabla_pares;
int * tabla_hq;

int exclusive_OR(int, int);
void permutacion_2k(void);

int main(int argc, char* argv[])
{
	//tabla_pares = (int *) malloc(MUESTRAS * sizeof(int));
	//tabla_hq = (int *) malloc(MUESTRAS * sizeof(int));

	tabla_pares 	= (int *) calloc(MUESTRAS, sizeof(int));
	tabla_hq 	= (int *) calloc(MUESTRAS, sizeof(int));

	permutacion_2k();

	fichero_Hq_impares = fopen("Hq_2k_impares.dat","w");
	fichero_Hq_pares   = fopen("Hq_2k_pares.dat","w");

	/****************************************************************************/
	// GENERAMOS LAS TABLAS PARA LAS MEMORIAS DE LA FPGA:
	/****************************************************************************/
	for(filas=0; filas<MUESTRAS; filas++){
		* (tabla_pares + *(tabla_hq + filas)) = filas;
		printf("Iteracion %d\n", filas);
	}

	for(filas=0; filas<MUESTRAS; filas++){
		fprintf(fichero_Hq_impares, "%d,\n", *(tabla_hq + filas));
		fprintf(fichero_Hq_pares,   "%d,\n", *(tabla_pares + filas));
		if(filas%200 == 0)
			printf("Escritos %d\n", filas);
	}

	free(tabla_pares);
	free(tabla_hq);

	fclose(fichero_Hq_impares);		
	fclose(fichero_Hq_pares);	

	printf("Even symbol 2k mode. File successfully written!\n");
	return 1;
}

// La siguiente función tiene que completar la tabla de correspondencias entre
// los índices de entrada y salida del symbol interleaver.
void permutacion_2k(void)
{
	int vector_R_prima[MODO][COLUMNAS];
	int vector_R[MODO][COLUMNAS];
	int fila, col, q, Hq, j, sumatorio;
	
	// Generamos el vector Ri':
	for(col=0; col<COLUMNAS; col++){
		vector_R_prima[0][col] = 0;
		vector_R_prima[1][col] = 0;
		vector_R_prima[2][col] = 0;
	}
	vector_R_prima[2][0] = 1;
	for(fila=3; fila<MODO; fila++)
	{
		for(col=0; col<(COLUMNAS-1); col++)
			vector_R_prima[fila][col] = vector_R_prima[fila-1][col+1];

		vector_R_prima[fila][COLUMNAS-1] = 
			exclusive_OR(	vector_R_prima[fila-1][0], 
					vector_R_prima[fila-1][3]);
	}
	
	// Generamos el vector Ri a partir del anterior:
	for(fila=0; fila<MODO; fila++){
		vector_R[fila][0]  = vector_R_prima[fila][9];
		vector_R[fila][7]  = vector_R_prima[fila][8];
		vector_R[fila][5]  = vector_R_prima[fila][7];
		vector_R[fila][1]  = vector_R_prima[fila][6];
		vector_R[fila][8]  = vector_R_prima[fila][5];
		vector_R[fila][2]  = vector_R_prima[fila][4];
		vector_R[fila][6]  = vector_R_prima[fila][3];
		vector_R[fila][9]  = vector_R_prima[fila][2];
		vector_R[fila][3]  = vector_R_prima[fila][1];
		vector_R[fila][4]  = vector_R_prima[fila][0];
	}

	// Rellenamos la tabla de correspondencias:
	q = 0;
	for(fila=0; fila<MODO; fila++){
		sumatorio = 0;
		for(j=0; j<COLUMNAS; j++){
			aux = vector_R[fila][j];
			sumatorio += vector_R[fila][j]*(int)pow(2, j);
		}
		Hq = (fila%2) * (MODO/2) + sumatorio;

		* (tabla_hq + q) = Hq;
		if(Hq < MUESTRAS)
			q++;
	}


}

int exclusive_OR(int a, int b)
{
	if( a!=b )
		return 1;
	else
		return 0;
}
