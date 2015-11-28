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
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            c_in :> grid[y*IMWD+x]; //read the pixel value
        }
    }
}


void writeGrid(uchar grid[], chanend c_out) {
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            c_out <: grid[y*IMWD+x]; //read the pixel value
        }
    }
}
