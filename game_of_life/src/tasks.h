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
    unsigned getSlice(uchar slice[]); //This can go.

    [[clears_notification]]
    void report(unsigned round, unsigned live);

//    [[clears_notification]]
//    void upload(unsigned id, uchar slice[]);

    [[clears_notification]]
    void restart(void);

    [[notification]]
    slave void playPause(void);

//    [[notification]]
//    slave void print(void);

} farmer_if;

void sliceWorker(static const unsigned cols, client farmer_if dist_control, client data_if dist_data, streaming chanend top_c, streaming chanend bot_c);

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, chanend c_in, chanend c_out, chanend acc);

#endif /* TASKS_H_ */
