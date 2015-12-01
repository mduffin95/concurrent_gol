/*
 * tasks.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef TASKS_H_
#define TASKS_H_

#include "types.h"
#include "io.h"

typedef interface farmer_if {
    {unsigned, unsigned} getSlice(int slice[]); //This can go.

    [[clears_notification]]
    int report(unsigned round, unsigned live); //return value determines whether worker should pause or not.

    [[notification]]
    slave void resume(void);

} farmer_if;

void sliceWorker(client farmer_if dist_control, client data_if dist_data, streaming chanend top_c, streaming chanend bot_c);

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, chanend acc);

#endif /* TASKS_H_ */
