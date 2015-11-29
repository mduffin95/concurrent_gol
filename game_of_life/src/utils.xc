/*
 * utils.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */
#include "utils.h"
#include "constants.h"
#include <stdio.h>

void readGrid(uchar grid[], chanend c_in) {
    uchar cell;
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            c_in :> cell; //read the pixel value
            if(cell) grid[y*IMWD+x] = 1;
            else grid[y*IMWD+x] = 0;
        }
    }
}


void writeGrid(uchar grid[], chanend c_out) {
    uchar cell;
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            cell = grid[y*IMWD+x];
            printf("Writing row: %d, col: %d = %u\n", y, x, cell);
            if(cell) c_out <: 255;
            else c_out <: 0;
        }
    }
}
