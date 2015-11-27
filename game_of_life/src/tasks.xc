/*
 * tasks.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "tasks.h"
#include "utils.h"
#include "types.h"
#include "constants.h"
#include <stdio.h>
#include <string.h> //for memcpy
#include <xs1.h>
#include <gpio.h>

void sliceWorker(unsigned id, static const unsigned cols, client farmer_if i, streaming chanend top_c, streaming chanend bot_c) {
    uchar data[SLSZ];
    uchar *slice = data+cols;
    unsigned rows = i.getSlice(id, slice);
    uchar *top_arr = data;
    uchar *bot_arr = data+(rows+1)*cols; //Aliasing pointers
    while(1) {
        select {
            case i.pause():
                i.report(id, slice);
                break;
            default:
                for(int i=0; i<IMWD; i++) {
                    top_c <: slice[i];
                    bot_c <: slice[(rows-1)*cols+i];
                    top_c :> top_arr[i];
                    bot_c :> bot_arr[i];
                }
                break;
        }
    }
}

void distributor(server farmer_if c[n], unsigned n, chanend c_in, chanend c_out, client input_gpio_if button_1, client input_gpio_if button_2,
        client output_gpio_if led_green, client output_gpio_if rgb_led_blue,
        client output_gpio_if rgb_led_green, client output_gpio_if rgb_led_red) {
    uchar grid [IMHT*IMWD];
    readGrid(grid, c_in);

    // LED state
    unsigned int green_led_state = 0;
    unsigned int rgb_led_state = 0;

    // Initial button event state, active low
    button_1.event_when_pins_eq(0);
    button_2.event_when_pins_eq(0);

    int size = IMWD;
    int remainder = size % n;
    int rows = (size - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(unsigned id, uchar slice[]) -> unsigned rows_return:
            printf("Process %u is retrieving data\n", id);
            rows_return = (id==n-1) ? rows+remainder : rows;
            memcpy(slice, grid+rows*id*size, rows_return*size*sizeof(uchar));
            break;
        case c[int i].report(unsigned id, uchar slice[]):
            printf("Process %u is reporting. slice[0] = %d\n", id, slice[0]);
            break;
        case button_1.event():
            if (button_1.input() == 0) {
                green_led_state = ~green_led_state;
                led_green.output(green_led_state);
                // Set button event state to active high for debounce
                for(int i=0; i<n; i++)
                    c[i].pause();
                button_1.event_when_pins_eq(1);
            } else {
                // Debounce button
                delay_milliseconds(50);
                button_1.event_when_pins_eq(0);
            }
            break;
        case button_2.event():
            if (button_2.input() == 0) {
                rgb_led_red.output(0);
                rgb_led_green.output(0);
                rgb_led_blue.output(0);
                rgb_led_state++;
                rgb_led_state %= 4;
                switch (rgb_led_state) {
                case 1:
                    rgb_led_red.output(1);
                    break;
                case 2:
                    rgb_led_green.output(1);
                    break;
                case 3:
                    rgb_led_blue.output(1);
                    break;
                }
                // Set button event state to active high for debounce
                button_2.event_when_pins_eq(1);
            } else {
                // Debounce button
                delay_milliseconds(50);
                button_2.event_when_pins_eq(0);
            }
            break;
        }
    }
}
