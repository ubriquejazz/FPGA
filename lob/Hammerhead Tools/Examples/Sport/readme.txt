README.TXT

Notes concerning the SPORT tests for the Bittware HH-PCI board:
---------------------------------------------------------------

1. Processor to processor tests require a null_modem (twisted) cable connected to 
the appropriate connectors labeled HHxSP1 and HHySP1, where x and y are the 
processor numbers.  (Only SPORT1 routed to connectors)

2. Tests can be run using an In-Circuit Emulator, unless they are board-to-board tests.  
In this case, one or both of the executables are run under diag21k.  

3. The example SPORT tests have scripts that run under diag21k. 


Names/descriptions of the SPORT executable files:

SPORTLOOPBK.DXE       Loopback test; requires only one processor and no cable; test any SPORT.
SPORTTESTXMT.DXE      Master of the polled test; requires cable attached to slave.
SPORTTEST.DXE         Slave of the polled test; requires cable attached to master.
SPORTDMASINGLEGEN.DXE Master of non-chained DMA test; requires cable attached to slave.
SPORTDMASINGLE.DXE    Slave of non-chained DMA test; requires cable attached to master.
SPORTTDMGEN.DXE       Master of TDM test; requires no cable.
SPORTTDMRX.DXE        Slave of TDM test; requires no cable.


The sport tests (except for TDM) require each processor's SPORT jumper set as follows:
  
     1 o   o 2
     3 o   o 4
     5 o   o 6
     7 o---o 8    <-- sends frame sync from transmitter to receiver
     9 o   o 10
    11 o   o 12
    13 o   o 14


