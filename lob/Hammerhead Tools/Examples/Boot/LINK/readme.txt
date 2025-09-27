README.TXT for the HAMMERHEAD LINK BOOT EXAMPLE
=========================================================================

This file describes how to use the example code to link boot a Hammerhead 
(ADSP21160) processor on a Bittware DSP board.  In this example, the code
runs on a MASTER, or transmit processor, and it is the SLAVE, or receiver
that gets booted.  This example transmits blink.ldr, which is received by
the SLAVE and started, thus giving evidence that the boot program is 
running by flashing LEDs.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     >>> LINK booting will not work without proper jumpering! <<<
 See your board's manual to properly install jumpers for link booting.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

FILES
The following files are used in the example:

lboot.ldf        Linker description file that sets up 16-bit memory space
                 used by the example.

link_boot.c      A simple program with main which calls the function:
                     void lboot_tx(int link);
                 where link is the port used to transmit.  Note that this 
                 port must be physically connected to link port 4 of the 
                 receiver.

link_loader.asm  The assembly code for function lboot_tx. This file has a 
                 definition and a declaration as:

                     #define	FILE_SIZE	6039 
                     ldata[FILE_SIZE] = "blink.ldr";

                 The file blink.ldr may be replaced by any xxxx.ldr
                 application file built as described in note 3.  Also, the
                 definition of FILE_SIZE must be modified to reflect the 
                 number of lines in the new .ldr file.


NOTES
1.  The transmitter uses only link buffer 0 (LBUF0), regardless of the 
    link port used.  All other link buffers are disabled.

2.  The transmitting link port must be physically connected, either by a 
    cable or by PCB traces, to link 4 of the receiver.  Link 4 is the only
    port compatible with link booting.

3.  To create a file xxxx.ldr from file xxxx.dxe, do the following:
    a. Go to Project Options, and the Project tab, change type to 
       Loader file.
    b. On the Load tab, set Boot type to Link, and Format to ASCII.
    c. Click on OK, then do a Rebuild All on the project.  The additional
       step of creating the xxxx.ldr file is done at the end.
