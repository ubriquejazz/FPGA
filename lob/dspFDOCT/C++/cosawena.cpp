// cosawena.cpp : Defines the entry point for the console application.
//

#include "stdafx.h" 
#include "dsp21k.h"
#include "./complejo/complejo.h"

// Device number to open
#define DEVICE_NUMBER 0

int main(int argc, char* argv[])
{
	PDSP21K processor;
	unsigned int primesbuf[20];
	unsigned int *p;
	int indx, error;

	// se crean dos complejos con el constructor general
	complejo c1(1.0, 1.0);
	complejo c2(2.0, 2.0);

	// se crea un complejo con el constructor por defecto
	complejo c3;

	// se da valor a la parte real e imaginaria de c3
	c3.SetReal(5.0);
	c3.SetImag(2.0);
	
	// se crea un complejo con el valor por defecto (0.0) del 2º argumento
	complejo c4(4.0);
	
	// se crea un complejo a partir del resultado de una expresión
	// se utiliza el constructor de copia
	complejo suma = c1 + c2;
	
	// se crean tres complejos con el constructor por defecto
	complejo resta, producto, cociente;
	
	// se asignan valores con los operadores sobrecargados
	resta = c1 - c2;
	producto = c1 * c2;
	cociente = c1 / c2;
	
	// se imprimen los números complejos con el operador << sobrecargado
	cout << c1 << ", " << c2 << ", " << c3 << ", " << c4 << endl;
	cout << "Primer complejo: " << c1 << endl;
	cout << "Segundo complejo: " << c2 << endl;
	cout << "Suma: " << suma << endl;
	cout << "Resta: " << resta << endl;
	cout << "Producto: " << producto << endl;
	cout << "Cociente: " << cociente << endl;

	// se comparan complejos con los operadores == y != sobrecargados
	if (c1==c2) 
		cout << "Los complejos son iguales." << endl;
	else 
		cout << "Los complejos no son iguales." << endl;

	if (c1!=c2)
		cout << "Los complejos son diferentes." << endl;
	else
		{
		cout << "Los complejos no son diferentes." << endl;
		cout << "Ya he terminado." << endl;
		}

	return 0;
}
