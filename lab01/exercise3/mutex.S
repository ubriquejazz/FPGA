///////////////////////////////////////////////////////////////////////////////
/*
 * Este fichero implementa dos funciones en ensamblador que aprovecha la infra-
 * estructura del ARM para implementar un semáforo (mutex). Una función sirve
 * para el cierre del semáforo (lock_mutex) y la otra para la apertura
 * (unlock_mutex).
 */
///////////////////////////////////////////////////////////////////////////////

.macro WAIT_FOR_UPDATE
WFE
.endm

.macro SIGNAL_UPDATE
DSB
SEV
.endm

.equ locked, 1
.equ unlocked, 0
.equ yield, 1

.section .text
.align 2
.global lock_mutex
.type lock_mutex, %function

lock_mutex:

	LDR     r1, =locked
1:  LDREX   r2, [r0]
	CMP     r2, r1        // Test if mutex is locked or unlocked
	BEQ     2f			  // If locked - wait for it to be released, from 2
	STREXNE r2, r1, [r0]  // Not locked, attempt to lock it
	CMPNE   r2, #1        // Check if Store-Exclusive failed
	BEQ     1b           // Failed - retry from
	// Lock acquired
	DMB                   // Required before accessing protected resource
	BX      lr
2: // Take appropriate action while waiting for mutex to become unlocked
	// WAIT_FOR_UPDATE
    B       1b            @ Retry from 1

.size  lock_mutex, .-lock_mutex

.align  2
.global unlock_mutex
.type  unlock_mutex, %function

unlock_mutex:
  	LDR     r1, =unlocked               // required before releasing protected resource
  	DMB
  	STR r1, [r0]      // unlock mutex
	// SIGNAL_UPDATE
	DSB
  	BX  lr            // return
.size  unlock_mutex, .-unlock_mutex
