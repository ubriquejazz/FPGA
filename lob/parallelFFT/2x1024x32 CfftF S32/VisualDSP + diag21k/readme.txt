README.TXT for HAMMERHEAD LINK TRANSFERS
===========================================

Notes:
1.  The files FIN_PCI.doj and UTIL_LIB.DLB are needed for this example.  
These are a libraries of PCI transfer routines, and utilities provided by 
Bittware.  The location of these files is:
C:\HHTools\examples\libs 

2.  The PCI library source files 
are fin_pci.c and fin_pci.h, located in C:\HHTools\examples\libs\PCI. 

3.  The Utility library source files 
are utils.c and utils.h, located in C:\HHTools\examples\libs\UTILS. 

4.  Although the library files are local to the other source files for this example, 
it is recommended that when adding of this file to the project, point to a central 
location, as described in Note 1.  This way, one instance of each library can be 
pointed to by multiple projects, rather than duplicating the libraries once for each.

5.  Mastering Channel 1 has been known to be problematic when doing block reads
from PCI for SharcFIN revision 3.  This is a silicon problem, and cannot be 
corrected by a workaround.  

JUAN
====

* Si activamos el procesado, hemos de bajar la frecuencia de 16 a 2KHz para no perder una linea --> freq tipo FLOAT en vez de INT

* funciona con 16 lineas en vez de 4096

* Line_TRIG y Buffer_TRIG monitorizadas exteriormente: OUTPUT#1 y OUTPUT#2

* Se pierden primeros 6F pixels de la ultima linea

* Link Port a 40 MHz