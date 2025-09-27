/*
 * mutex_blk.h
 *
 *  Created on: 16/12/2016
 *      Author: alvaro
 */
///////////////////////////////////////////////////////////////////////////////
/*
 * Este fichero implementa dos funciones en ensamblador que aprovecha la infra-
 * estructura del ARM para implementar un semáforo (mutex). Una función sirve
 * para el cierre del semáforo (lock_mutex) y la otra para la apertura
 * (unlock_mutex).
 */
///////////////////////////////////////////////////////////////////////////////

#ifndef MUTEX_BLK_H_
#define MUTEX_BLK_H_

///////////////////////////////////////////////////////////////////////////////
// Mutex control
///////////////////////////////////////////////////////////////////////////////

#define locked   1
#define unlocked 0

extern void lock_mutex(void* mutex);
extern void unlock_mutex(void* mutex);


#endif /* MUTEX_BLK_H_ */
