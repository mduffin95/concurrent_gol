/*
 * gollogic.h
 *
 *  Created on: 30 Nov 2015
 *      Author: matth
 */


#ifndef GOLLOGIC_H_
#define GOLLOGIC_H_

#include "types.h"

int calcGol(int grid[], int width, int height, int row, int col);

int findNeighbours(int grid[], int width, int height, int row, int col);

#endif /* GOLLOGIC_H_ */
