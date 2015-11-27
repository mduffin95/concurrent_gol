/*
 * acc.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "io.h"
#include <stdio.h>
#include "constants.h"
#include "types.h"
#include "pgmIO.h"


/////////////////////////////////////////////////////////////////////////////////////////
//
// Initialise and  read accelerometer, send first tilt event to channel
//
/////////////////////////////////////////////////////////////////////////////////////////
void accelerometer(client interface i2c_master_if i2c, chanend toDist) {
    i2c_regop_res_t result;
    char status_data = 0;
    int tilted = 0;

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

    //Probe the accelerometer x-axis forever
    while (1) {

        //check until new accelerometer data is available
        do {
            status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
        }while (!status_data & 0x08);

        //get new x-axis tilt value
        int x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);

        //send signal to distributor after first tilt
        if (!tilted) {
            if (x>30) {
                tilted = 1 - tilted;
                toDist <: 1;
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from PGM file from path infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out) {
    int res;
    uchar line[IMWD];
    printf("DataInStream: Start...\n");

    //Open PGM file
    res = _openinpgm(infname, IMWD, IMHT);
    if (res) {
        printf("DataInStream: Error openening %s\n.", infname);
        return;
    }

    //Read image line-by-line and send byte by byte to channel c_out
    for (int y = 0; y < IMHT; y++) {
        _readinline(line, IMWD);
        for (int x = 0; x < IMWD; x++) {
            c_out <: line[ x ];
            printf("-%4.1d ", line[x]); //show image values
        }
        printf("\n");
    }

     //Close PGM image file
    _closeinpgm();
    printf("DataInStream:Done...\n");
    return;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to PGM image file
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataOutStream(char outfname[], chanend c_in) {
    int res;
    uchar line[ IMWD ];

    //Open PGM file
    printf( "DataOutStream:Start...\n" );
    res = _openoutpgm( outfname, IMWD, IMHT );
    if( res ) {
        printf( "DataOutStream:Error opening %s\n.", outfname );
        return;
    }

    //Compile each line of the image and write the image line-by-line
    for( int y = 0; y < IMHT; y++ ) {
        for( int x = 0; x < IMWD; x++ ) {
            c_in :> line[ x ];
        }
        _writeoutline( line, IMWD );
    }

    //Close the PGM image
    _closeoutpgm();
    printf( "DataOutStream:Done...\n" );
    return;
}
