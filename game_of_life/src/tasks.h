/*
 * tasks.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef TASKS_H_
#define TASKS_H_

#include "constants.h"

interface farmer {
    unsigned getSlice(unsigned id, uchar slice[]); //Why can we not specify first dimension?
    int doneIteration(unsigned id, uchar slice[]); //Returns 1 when we want to continue.
};

void sliceWorker(unsigned id, static const unsigned cols, client interface farmer i, streaming chanend top_c, streaming chanend bot_c);

void distributor(server interface farmer c[n], unsigned n, chanend c_in, chanend c_out, chanend fromAcc);



#endif /* TASKS_H_ */
