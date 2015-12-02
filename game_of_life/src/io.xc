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
            printf("Green LED\n");
            break;
        case dist.setRed(unsigned a):
            rgb_led_red.output(a);
            printf("Red LED\n");
            break;
        case dist.setBlue(unsigned a):
            rgb_led_blue.output(a);
            printf("Blue LED\n");
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
                state = 0; //Still flat, so go to flat state3
                dist <: 0;
            }
            else state = 2;
            break;
        }

    }
}

[[combinable]]
void DataInStream(char infname[], server data_if dist) { //There would be no point making this distributable. May as well have a normal function.
    int res;
    uchar line[SLSZ];
    printf("DataInStream: Start...\n");

    //Open PGM file
    unsigned rc[2]; //Only way I could work out how to get data back.
    res = _openinpgm(infname, rc);
    if (res) {
        printf("DataInStream: Error openening %s\n.", infname);
        return;
    }
    while(1) {
        select {
            case dist.transferData(uchar data[], unsigned &r, unsigned &c):
                r = rc[0];
                c = rc[1]; //Sends data through because of references.
                for(int y=0; y<r; y++) {
                    _readinline(line, c);
                    for(int x=0; x<c; x++) {
                        data[y*c+x] = (line[x]) ? 1 : 0;
                    }
                }
                _closeinpgm();
                printf("DataInStream:Done...\n");
                break;
        }
    }
}

[[distributable]]
void DataOutStream(char outfname[], server data_if dist) { //convert to use interface.


    while(1) {
        select {
            case dist.transferData(uchar data[], unsigned &rows, unsigned &cols):
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
                        line[x] = (data[y*cols+x]) ? 255 : 0;
                    }
                    _writeoutline(line, cols);
                }
                _closeoutpgm();
                printf("DataOutStream:Done...\n");
                break;
        }
    }
}
