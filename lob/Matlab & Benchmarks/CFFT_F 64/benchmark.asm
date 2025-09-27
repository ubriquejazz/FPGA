/*****************************************************/
/*                                                   */
/*  int Clock_start = count_start()                  */
/*  int Clock_count = count_end(int Clock_start)     */
/*                                                   */
/*****************************************************/

#include "def21160.h"
#include "asm_sprt.h"

.section/pm seg_pmco;
.global _count_start;
.global _count_end;

_count_start: /* call this to start cycle count */
r1=mode1;
bit clr mode1 IRPTEN;
r0=emuclk;
mode1=r1;
exit;

_count_end: /* call this to end cycle count */ 
r2=mode1;
bit clr mode1 IRPTEN;
r0=emuclk;
r0=r0-r4;
r1=14;     /* fudge factor to compensate for overhead */
r0=r0-r1;  
mode1=r2;
exit;


