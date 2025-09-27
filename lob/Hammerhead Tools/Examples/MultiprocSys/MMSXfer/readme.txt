README.TXT for HAMMERHEAD MMS TRANSFERS
=======================================

Notes:
1. In gen_data.c, the definition PROC_BOARD_BAR2 must be known and hard-coded
for this example to work.  This is the PCI BAR2 address of the consumer DSP
board, and can be found by:
  a. running the host utility BWCFG from a MSDOS window;
  b. determining the consumer board (device);
  c. displaying properties for the consumer to read the BAR2 address.

2.  The files FIN_PCI_HH.DLB and UTIL_LIB.DLB are needed for this example.  
These are a libraries of PCI transfer routines, and utilities provided by 
Bittware.  The location of these files is:
d:\<yourpath>\examples\libs - where d: is your hard drive designator, and 
<yourpath> is the directory path where you have installed your examples.

3.  The PCI library source files are fin_pci.c and fin_pci.h, located in d:\<yourpath>\examples\libs\PCI.  Refer to these files for details and usage 
information.

4.  The Utility library source files are utils.c and utils.h, located in d:\<yourpath>\examples\libs\UTILS.  Refer to these files for details and usage 
information.

5.  Although the library files are local to the other source files for this example, 
it is recommended that when adding of this file to the project, point to a central 
location, as described in Note 1.  This way, one instance of each library can be 
pointed to by multiple projects, rather than duplicating the libraries once for each.

6.  Mastering Channel 1 has been known to be problematic when doing block reads
from PCI for SharcFIN revision 3.  This is a silicon problem, and cannot be 
corrected by a workaround.  To determine your SharcFIN version, invoke diag21k 
and enter the command:

    DIAG21K[1]>rr 8

The output of this command will be hexadecimal 000f010x, where x is the SharcFIN 
version.

7.  If you have SharcFIN version 4 or above, you may use the Clusterbus DMA 
functions.  See file fin_pci.c located in d:\<yourpath>\examples\libs\PCI for 
details.