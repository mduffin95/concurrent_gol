/*
 * constants.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef CONSTANTS_H_
#define CONSTANTS_H_

//#define  IMHT 16                  //image height
//#define  IMWD 16                  //image width
#define  SLSZ 2000                 //slice array length
#define  GRIDSZ 10000              //grid array size
#define  WORKERS 6                //number of workers

#define PAUSE 1
#define UPLOAD 2

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

#endif /* CONSTANTS_H_ */
