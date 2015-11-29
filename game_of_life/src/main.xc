// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo)

#include <platform.h>
#include <i2c.h>
#include <stdio.h>
#include <gpio.h>

/*---My Includes---*/
#include "io.h"
#include "tasks.h"
#include "constants.h"

on tile[0] : port p_scl = XS1_PORT_1E;         //interface ports to accelerometer
on tile[0] : port p_sda = XS1_PORT_1F;
on tile[0] : in port explorer_buttons = XS1_PORT_4E; //port to access xCore-200 buttons
on tile[0] : out port explorer_leds = XS1_PORT_4F;   //port to access xCore-200 LEDs

int main(void) {

    interface i2c_master_if i2c[1];               //interface to accelerometer

    //char infname[] = "test.pgm";     //put your input image path here
    //char outfname[] = "testout.pgm"; //put your output image path here
    chan c_inIO, c_outIO, c_acc_dist;    //extend your channel definitions here

    farmer_if b[WORKERS];
    streaming chan c[WORKERS];
    data_if d[WORKERS];

    input_gpio_if i_explorer_buttons[2];
    output_gpio_if i_explorer_leds[4];
    but_led_if gpio;

    data_if writer;

    par {
        on tile[0] : input_gpio_with_events(i_explorer_buttons, 2, explorer_buttons, null);
        on tile[0] : output_gpio(i_explorer_leds, 4, explorer_leds, null);
        on tile[0] : i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing accelerometer data
        on tile[0] : accelerometer(i2c[0], c_acc_dist);        //client thread reading accelerometer data.
        on tile[0] : DataInStream("test.pgm", c_inIO);          //thread to read in a PGM image
        on tile[0] : DataOutStream("testout.pgm", writer);       //thread to write out a PGM image
        on tile[0] : gpioHandler(gpio, i_explorer_buttons[0], i_explorer_buttons[1],
                i_explorer_leds[0], i_explorer_leds[1],
                i_explorer_leds[2], i_explorer_leds[3]);
        on tile[0] : distributor(b, d, WORKERS, gpio, c_inIO, writer, c_acc_dist);//thread to coordinate work on image
        on tile[0] : par (int i=0; i<WORKERS/2 - 2; i++) {
            sliceWorker(IMWD, b[i], d[i], c[i], c[(i+1)%WORKERS]);
        }
        on tile[1]: par (int i=WORKERS/2 - 2; i<WORKERS; i++) {
            sliceWorker(IMWD, b[i], d[i], c[i], c[(i+1)%WORKERS]);
        }
    }
    return 0;
}
