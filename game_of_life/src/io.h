/*
 * io.h
 *
 *  Created on: 26 Nov 2015
 *      Author: matth
 */


#ifndef IO_H_
#define IO_H_

#include "i2c.h"

#define FXOS8700EQ_I2C_ADDR 0x1E  //register addresses for accelerometer
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6

void accelerometer(client interface i2c_master_if i2c, chanend toDist);

void DataInStream(char infname[], chanend c_out);

void DataOutStream(char outfname[], chanend c_in);

#endif /* IO_H_ */
