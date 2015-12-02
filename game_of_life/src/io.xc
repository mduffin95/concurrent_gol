/*
 * acc.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "io.h"
#include <stdio.h>
#include <gpio.h>
#include <i2c.h>
#include <xs1.h> //For delay_milliseconds
#include "constants.h"
#include "types.h"
#include "pgmIO.h"
#include "bitarray.h"
#include <timer.h>

void gpioHandler(server but_led_if dist, client input_gpio_if button_0, client input_gpio_if button_1,
        client output_gpio_if led_green, client output_gpio_if rgb_led_blue,
        client output_gpio_if rgb_led_green, client output_gpio_if rgb_led_red) {

    // LED state
    unsigned green_led_state = 0;
    //unsigned rgb_led_state = 0;

    // Initial button event state, active low
    button_0.event_when_pins_eq(0);
    button_1.event_when_pins_eq(0);

    //Store last pressed button. 0 and 1.
    uchar last_pressed = 0;

    while (1) {
        select {
        case button_0.event():
            if (button_0.input() == 0) {
                last_pressed = 0;
                // Set button event state to active high for debounce
                button_0.event_when_pins_eq(1);
            } else {
                // Debounce button
                delay_milliseconds(50);
                button_0.event_when_pins_eq(0);
                dist.event();
            }
            break;
        case button_1.event():
            if (button_1.input() == 0) {
                last_pressed = 1;
                // Set button event state to active high for debounce
                button_1.event_when_pins_eq(1);
            } else {
                // Debounce button
                delay_milliseconds(50);
                button_1.event_when_pins_eq(0);
                dist.event();
            }
            break;
        case dist.toggleGreen2():
            green_led_state = ~green_led_state;
            led_green.output(green_led_state);
            break;
        case dist.setGreen(unsigned a):
            rgb_led_green.output(a);
            break;
        case dist.setRed(unsigned a):
            rgb_led_red.output(a);
            break;
        case dist.setBlue(unsigned a):
            rgb_led_blue.output(a);
            break;
        case dist.getButton() -> uchar p:
            p = last_pressed;
            break;
        }
    }
}

void accelerometer(client interface i2c_master_if i2c, chanend dist) {
    i2c_regop_res_t result;
    char status_data = 0;
    int state = 0;

    // Configure FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
    if (result != I2C_REGOP_SUCCESS) {
        printf("I2C write reg failed\n");
    }
    // Enable FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
    if (result != I2C_REGOP_SUCCESS) {
        printf("I2C write reg failed\n");
    }

    while (1) {
        // Wait for data ready from FXOS8700EQ
        do {
            status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
        } while (!status_data & 0x08);


        int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

        switch (state) {
        case 0: //Flat
            if(x>30 || x<-30) {
                state = 1;
                delay_milliseconds(50);
            }
            break;
        case 1:
            if(x>30 || x<-30) {
                state = 2; //Still tilted, so go to tilted state
                dist <: 1;
            }
            else state = 0;
            break;
        case 2: //Tilted
            if(x<=30 && x>=-30) {
                state = 3;
                delay_milliseconds(50);
            }
            break;
        case 3:
            if(x<=30 && x>=-30) {
                state = 0; //Still flat, so go to flat state
                dist <: 0;
            }
            else state = 2;
            break;
        }

    }
}

{unsigned, unsigned} DataIn(char infname[], int data[]) { //There would be no point making this distributable. May as well have a normal function.
    timer t;
    unsigned start_time, end_time;
    t :> start_time;
    int res;
    uchar line[SLSZ];
    printf("DataInStream: Start...\n");

    //Open PGM file
    unsigned hw[2]; //Only way I could work out how to get data back.
    res = _openinpgm(infname, hw);
    if (res) {
        printf("DataInStream: Error openening %s\n.", infname);
        return {0, 0};
    }
    unsigned height = hw[0];
    unsigned width = hw[1]; //Sends data through because of references.
    for(int y=0; y<height; y++) {
        _readinline(line, width);
        for(int x=0; x<width; x++) {
//            if (line[x]) { //This method doesn't seem to make any significant difference to time.
//                Set2DCell(data, width, height, y, x, 1);
//            }
            Set2DCell(data, width, height, y, x, (line[x]) ? 1 : 0); //This method allows for restart.
//            data[y*c+x] =
        }
    }
//    PrintArray(data, width, height);
    _closeinpgm();
    t :> end_time;
    printf("DataInStream:Done...\n");
    printf ("Number of timer ticks elapsed : % u\n" , end_time - start_time );
    return {width, height};
}

void DataOut(char outfname[], int data[], int rows, int cols) {
    int res;
    uchar line[SLSZ];
    //Open PGM file
    printf("DataOutStream:Start...\n");
    res = _openoutpgm(outfname, cols, rows);
    printf("DataOutStream opened file\n");
    if (res) {
        printf("DataOutStream:Error opening %s\n.", outfname);
        return;
    }

    for(int y=0; y<rows; y++) {
        for(int x=0; x<cols; x++) {
//                        line[x] = (data[y*cols+x]) ? 255 : 0;
            line[x] = Get2DCell(data, cols, rows, y, x) ? 255 : 0;
        }
        _writeoutline(line, cols);
    }
    _closeoutpgm();
    printf("DataOutStream:Done...\n");
}
