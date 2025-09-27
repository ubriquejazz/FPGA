README.TXT for the FLASH BOOT EXAMPLE
=========================================================================

This file describes how to boot a processor from FLASH.  This example 
loads blink.ldr, which gives evidence that the boot program is running 
by flashing LEDs.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    >>> FLASH booting will not work without proper jumpering! <<<
 See your board's manual to properly install jumpers for FLASH booting.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

To run the example, first install the jumper for FLASH booting P1 
according to the users manual.  Then type at a DOS prompt:

    C:> flashldr

When prompted, enter the complete path of the file blink.ldr (in this
directory), as:

    D:\MyDirectories\Bittware\Examples\Boot\FLASH\blink.ldr

Type at the DOS prompt:

    C:> diag21k -xreset.cmd

When the FLASH has been written and the board reset, the LEDs on P1
should be blinking, indicating P1 has booted and is running the blink 
program.


NOTES

1.  This example makes use of a Bittware host utility called 
    flashldr.exe, located in the \DSP21KSF\bin directory.

2.  To create a file xxxx.ldr from file xxxx.dxe for FLASH booting, do the 
    following:
    a. Go to Project Options, and the Project tab, change type to 
       Loader file.
    b. On the Load tab:
       - set radio button to Loader21k
       - for kernel file, replace the default ADI kernel with 160_prom.dxe
         included in this directory, as the ADI kernel does not work;
       - set Output file name (if desired -- default is xxxx.ldr);
       - set Boot type to PROM;
       - Hex start address 0x0;
       - set Format to ASCII.
    c. Click on OK, then do a Rebuild All on the project.  The additional
       step of creating the xxxx.ldr file is done at the end.

3.  If multiple processors are FLASH booting, the FLASH image must include
    code for all processors.  This is accomplished by checking the 
    Multiprocessor box in step b (of note 2), and adding the paths of the
    .DXEs to be loaded into each processor.

