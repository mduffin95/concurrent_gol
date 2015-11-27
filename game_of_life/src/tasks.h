/*
 * tasks.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef TASKS_H_
#define TASKS_H_

#include "types.h"
#include <gpio.h>

typedef interface farmer_if {
    unsigned getSlice(unsigned id, uchar slice[]); //Why can we not specify first dimension?

    [[clears_notification]]
    void report(unsigned id, uchar slice[]);

    [[notification]]
    slave void pause(void);

} farmer_if;

void sliceWorker(unsigned id, static const unsigned cols, client farmer_if i, streaming chanend top_c, streaming chanend bot_c);

void distributor(server farmer_if c[n], unsigned n, chanend c_in, chanend c_out, client input_gpio_if button_1, client input_gpio_if button_2,
        client output_gpio_if led_green, client output_gpio_if rgb_led_blue,
        client output_gpio_if rgb_led_green, client output_gpio_if rgb_led_red);


#endif /* TASKS_H_ */
