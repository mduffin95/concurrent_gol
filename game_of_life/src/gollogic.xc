/*
 * gollogic.xc
 *
 *  Created on: 30 Nov 2015
 *      Author: matth
 */
#include "gollogic.h"
#include "types.h"
#include <stdio.h>

uchar calcGol(uchar *cell, unsigned size, unsigned row, unsigned col) {
    int left = (size+col-1)%size - col; //value to add to go left
    int right = (col+1)%size - col;
    uchar box[9] = {*(cell+left-size), *(cell-size), *(cell+right-size), *(cell+left), *cell, *(cell+right), *(cell+left+size), *(cell+size), *(cell+right+size)};
    uchar neighbours = *(cell+left-size) + *(cell-size) + *(cell+right-size) + *(cell+left) + *(cell+right) + *(cell+left+size) + *(cell+size) + *(cell+right+size);
//    printf("after neighbours\n");
    uchar live = *cell;
//    printf("inside calcgol\n");
    if (live) {
//        printf("Cell (%u, %u) has %u neighbours. [%u, %u, %u, %u, %u, %u, %u, %u, %u]\n", row, col, neighbours, box[0], box[1], box[2], box[3], box[4], box[5], box[6], box[7], box[8]);
        if (neighbours < 2 || neighbours > 3) {
            return 0; //Dies
        }
//        printf("Cell (%u, %u) lives  with %u neighbours.\n", row, col, neighbours);
        return 1; //Lives on, becuase there are 2 or 3 neighbours
    }
    else {
        if (neighbours == 3) {
            return 1; //Becomes live
        }
        return 0; //Stays dead
    }
}
