/*
 * utils.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */
#include "utils.h"
#include "constants.h"
#include <stdio.h>

void readGrid(uchar grid[], chanend c_in, chanend c_out, chanend fromAcc) {
    //Starting up and wait for tilting of the xCore-200 Explorer
    printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );
    printf( "Waiting for Board Tilt...\n" );
    fromAcc :> int value;

    //Read in and do something with your image values..
    //This just inverts every pixel, but you should
    //change the image according to the "Game of Life"
    printf( "Processing...\n" );
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            c_in :> grid[y*IMWD+x]; //read the pixel value
            c_out <: (uchar)( grid[y*IMWD+x] ^ 0xFF ); //send some modified pixel out
        }
    }
    printf( "\nOne processing round completed...\n" );
}
