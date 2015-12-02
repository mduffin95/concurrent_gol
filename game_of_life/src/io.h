/*
 * io.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef IO_H_
#define IO_H_

#include "types.h"
#include <gpio.h>
#include <i2c.h>

typedef interface but_led_if {

    void toggleGreen2();
    void setGreen(unsigned a);
    void setRed(unsigned a);
    void setBlue(unsigned a);

    [[clears_notification]]
    uchar getButton();

    [[notification]]
    slave void event(void);
} but_led_if;

typedef interface data_if {
    [[clears_notification]]
    {unsigned, unsigned} getSlice(int slice[]);

    [[clears_notification]]
    void transferData(int data[], unsigned rows, unsigned cols);

    [[notification]]
    slave void sliceReady(void);
} data_if;

void gpioHandler(server but_led_if dist, client input_gpio_if button_0, client input_gpio_if button_1,
        client output_gpio_if led_green, client output_gpio_if rgb_led_blue,
        client output_gpio_if rgb_led_green, client output_gpio_if rgb_led_red);

void accelerometer(client interface i2c_master_if i2c, chanend toDist);

{unsigned, unsigned} DataIn(char infname[], int data[]);

void DataOut(char outfname[], int data[], int rows, int cols);

#endif /* IO_H_ */
