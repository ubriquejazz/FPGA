

#include "mutex_blk.h"

#define SHAREABLE (1 << 16)
#define NON_CACHED (0)
#define WB_WA_CACHE (1) /* write back, write allocate */
#define WT_CACHE (2) /* write thru */
#define WB_CACHE (3) /* write back */
#define INNER_SHIFT (2)
#define OUTER_SHIFT (12)
#define TEX_MSB (1 << 14)
#define AP_FAULT (0) /* no access, a fault */
#define AP_FULL (3 << 10) /* full access */
#define DOMAIN(x) (x << 5)
#define INNER_NON_CACHED (NON_CACHED << INNER_SHIFT)
#define INNER_WB_WA (WB_WA_CACHE<< INNER_SHIFT)
#define INNER_WT (WT_CACHE<< INNER_SHIFT)
#define INNER_WB (WB_CACHE<< INNER_SHIFT)
#define OUTER_NON_CACHED (TEX_MSB | (NON_CACHED << OUTER_SHIFT))
#define OUTER_WB_WA (TEX_MSB | (WB_WA_CACHE<< OUTER_SHIFT))
#define OUTER_WT (TEX_MSB | (WT_CACHE<< OUTER_SHIFT))
#define OUTER_WB (TEX_MSB | (WB_CACHE << OUTER_SHIFT))
#define SECTION(attributes) ((attributes) | 0x2)
#define SUPER_SECTION(attributes) ((attributes) | 0x4002)

// Las optimizaciones del compilador pueden hacer que optimice la localización de estas variables dentro del mapa de memoria. Para que en ambos procesadores estén en la misma región, se estable la mínima optimización (o0) en esta parte del programa en ambos cores.
#pragma GCC push_options
#pragma GCC optimize ("O0")

// Mutex en cada core que se aloja en la sección .mem_mutex del linker script con alineamiento d 32 bits.
volatile unsigned int ctrl_mutex __attribute__ ((section (".mem_mutex"))) __attribute__( ( aligned ( 32 ) ) ) = unlocked;

#define DATA_LEN 100
volatile unsigned int data[DATA_LEN] __attribute__ ((section (".mem_mutex"))) __attribute__( ( aligned ( 32 ) ) );
volatile unsigned int result[DATA_LEN] __attribute__ ((section (".mem_mutex"))) __attribute__( ( aligned ( 32 ) ) );

#pragma GCC pop_options



int main()
{
    init_platform();

    Xil_SetTlbAttributes(0x03000000, SECTION(SHAREABLE|NON_CACHED));

	// TO DO

    cleanup_platform();
    return 0;
}
