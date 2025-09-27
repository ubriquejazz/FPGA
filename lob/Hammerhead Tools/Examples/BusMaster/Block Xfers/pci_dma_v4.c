//*********************************************************
//
//  pci_dma_v4.c : Program to test PCI_LIB functions for
//  DMAs over PCI.  This program assumes the Hammerhead board
//  uses SharcFIN version 4 and above.
//
//  PROVIDED BY:
//  ------------
//  BittWare Research Systems, Inc.
//  33 North Main Street
//  Concord, NH  03301
//  Ph: 603-226-0404
//  Fax: 603-226-6667
//  WWW: www.bittware.com
//  E-mail: support@bittware.com
//
//  Copyright 2001, BittWare, Inc.
//
//  The user is hereby granted a non-exclusive license to use and or 
//  modify this software provided that it runs on BittWare hardware.  
//  Usage of this software on non-BittWare hardware without the express 
//  written permission of BittWare is strictly prohibited.
//
//*********************************************************
#include <def21160.h>
#include <signal.h>
#include "fin_pci.h"
#include <21160.h>

#define BUF_SIZE   0x2000
#define NUM_LOOPS  0x100

#define CLOCKSPD    (float) 80000000.0	// HH Clock Rate


CLST_BUS_XFER_T tx;
CLST_BUS_XFER_T rx;
int tx_setup_stat;
int rx_setup_stat;
int tx_stat;
int rx_stat;
int loop;
int pci_addr = 0;
int src_array[BUF_SIZE];
int dst_array[BUF_SIZE];
int xfer_errors[NUM_LOOPS];
int done;
volatile int rx_intr_count = 0;
volatile int rx_flag = 0;

int tx_start_time;
int tx_stop_time;
int tx_accum_time = 0;

int rx_start_time;
int rx_stop_time;
int rx_accum_time = 0;

int ave_tx_time = 0;
int ave_rx_time = 0;
volatile float ReadLoopRate;
volatile float WriteLoopRate;
int total_errors = 0;
int *sdram_start_addr = (int*)0x800000;




/**********************************************/
void fin_rx_dma_complete(int sig)
{
    Fin_PCI_CB_DMA_Clear_Interrupt();
	rx_intr_count++;
	rx_flag = 1;
}


////////////////////////////////////////////////////////////////////////////////
//               main
////////////////////////////////////////////////////////////////////////////////
void main(void)
{
    int i;

    SetIOP(SYSCON, 0x1c000);
	SetIOP(WAIT, 0x1ce1b86);

	// Init the PCI interface
	SharcFin_PCI_Init();
	done = 0;

    interrupt(SIG_IRQ0, fin_rx_dma_complete);

	// Plain DMA test
    tx.channel = FIN_DMA_CHAN0;
	tx.direction = FIN_DMA_WRITE;
	tx.burst_size = FIN_DMA_BURST_32;
	tx.burst_control = FIN_DMA_BURST_ENABLE;
	tx.interrupt_control = FIN_DMA_INTRPT_DISABLE;
	tx.bus_lock_control = FIN_DMA_BUSLOCK_ENABLE;
	tx.wait_control = FIN_DMA_WAIT;
	tx.stride = 1;
	tx.hh_slave_dmac = FIN_DMA_HH_SLAVE_NONE;
    tx_setup_stat = Fin_PCI_CB_DMA_Setup_Xfer(&tx);

    rx.channel = FIN_DMA_CHAN0;
	rx.direction = FIN_DMA_READ;
	rx.burst_size = FIN_DMA_BURST_32;
	rx.burst_control = FIN_DMA_BURST_ENABLE;
	rx.interrupt_control = FIN_DMA_INTRPT_ENABLE; // enable interrupt
	rx.bus_lock_control = FIN_DMA_BUSLOCK_ENABLE;
	rx.wait_control = FIN_DMA_NO_WAIT;
	rx.stride = 1;
	rx.hh_slave_dmac = FIN_DMA_HH_SLAVE_NONE;
    rx_setup_stat = Fin_PCI_CB_DMA_Setup_Xfer(&rx);

	// If pci_addr has not been set by the host, exit
	if(pci_addr == 0)
	{
	    return;
	}

	for(loop = 0; loop < NUM_LOOPS; loop++)
	{
	    // Init the outgoing data
#if 1
		for(i = 0; i < BUF_SIZE; i++)
		{
		    src_array[i] = i + i*loop;
		}
#else

		for(i = 0; i < BUF_SIZE; i++)
		{
		    src_array[i] = i + i*loop;
		    *sdram_start_addr++ = i + i*loop;
		}
#endif

		timer_set(0xFFFFFFFF, 0xFFFFFFFF);
		tx_start_time = timer_on();
//		tx_stop_time = timer_off();

		// Re-initialize SDRAM Base
		sdram_start_addr = (int*)0x800000;

	    // Start the xfers
#if 1
        tx_stat = Fin_PCI_CB_DMA_Write(src_array, (int *)pci_addr, BUF_SIZE, &tx);
#else
        tx_stat = Fin_PCI_CB_DMA_Write(sdram_start_addr, (int *)pci_addr, BUF_SIZE, &tx);
#endif
		
		tx_stop_time = timer_off();

		tx_accum_time += (0xFFFFFFFF - tx_stop_time);

		timer_set(0xFFFFFFFF, 0xFFFFFFFF);
		rx_start_time = timer_on();

        rx_stat = Fin_PCI_CB_DMA_Read (dst_array, (int *)pci_addr, BUF_SIZE, &rx);

		// Wait until RX done
		while(rx_flag == 0)
		{
		}

		rx_stop_time = timer_off();
		rx_accum_time += (0xFFFFFFFF - rx_stop_time);

		// Reset flag
		rx_flag = 0;

		// Re-initialize SDRAM Base
		sdram_start_addr = (int*)0x800000;

		// Check data
		for(i = 0; i < BUF_SIZE; i++)
		{
#if 1
		    if(dst_array[i] != src_array[i])
			{
			    xfer_errors[loop]++;
				total_errors++;
			}
#else

		    if(dst_array[i] != *sdram_start_addr++)
			{
			    xfer_errors[loop]++;
				total_errors++;
			}
#endif
		}

		// Re-initialize SDRAM Base
		sdram_start_addr = (int*)0x800000;


	}

	ave_tx_time = tx_accum_time / NUM_LOOPS;
	ave_rx_time = rx_accum_time / NUM_LOOPS;


	ReadLoopRate = ((float)BUF_SIZE/(float)ave_rx_time) * CLOCKSPD * 4.0;
	WriteLoopRate = ((float)BUF_SIZE/(float)ave_tx_time) * CLOCKSPD * 4.0;


	done = 1;
}


