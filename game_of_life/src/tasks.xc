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
#include "io.h"
#include <stdio.h>
#include <string.h> //for memcpy
#include <xs1.h>

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

void distributor(server farmer_if c[n], unsigned n, client but_led_if gpio, chanend c_in, chanend c_out, chanend acc) {
    uchar grid [IMHT*IMWD];
    readGrid(grid, c_in);

    int size = IMWD;
    int remainder = size % n;
    int rows = (size - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(unsigned id, uchar slice[]) -> unsigned rows_return:
            printf("Process %u is retrieving data.\n", id);
            rows_return = (id==n-1) ? rows+remainder : rows;
            memcpy(slice, grid+rows*id*size, rows_return*size*sizeof(uchar));
            break;
        case c[int i].report(unsigned id, uchar slice[]):
            printf("Process %u is reporting. slice[0] = %d.\n", id, slice[0]);
            break;
        case gpio.event():
            printf("Button %u was pressed.\n", gpio.getButton());
            break;
        case acc :> int tilted:
            printf("Tilted = %d\n", tilted);
            break;
        }
    }
}
