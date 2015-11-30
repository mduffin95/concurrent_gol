/*
 * global.h
 *
 *  Created on: 30 Nov 2015
 *      Author: matth
 */


#ifndef GLOBAL_H
#define GLOBAL_H

#include <platform.h>
#include <xs1.h>

#ifdef __XC__
# define EXTERNAL extern
#else
# include <xccompat.h>
typedef chanend chan;
# define streaming
# define in
# define out

# ifndef __cplusplus
#  define EXTERNAL
# else
#  define EXTERNAL extern "C"
# endif // __cplusplus
#endif // __XC__

#endif // GLOBAL_H
