/*
 * io.h
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */


#ifndef IO_H_
#define IO_H_

#include "i2c.h"

void accelerometer(client interface i2c_master_if i2c, chanend toDist);

void DataInStream(char infname[], chanend c_out);

void DataOutStream(char outfname[], chanend c_in);

#endif /* IO_H_ */
