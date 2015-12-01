/*
 * gollogic.xc
 *
 *  Created on: 30 Nov 2015
 *      Author: matth
 */
#include "gollogic.h"
#include "types.h"
#include "bitarray.h"
#include <stdio.h>

int calcGol(int grid[], int width, int height, int row, int col) {
//    int left = (size+col-1)%size - col; //value to add to go left
//    int right = (col+1)%size - col;
    int neighbours = findNeighbours(grid, width, height, row, col);

            /*Get2DCell(grid, width, height, row-1, col-1) + Get2DCell(grid, width, height, row-1, col) + Get2DCell(grid, width, height, row-1, col+1)
            + Get2DCell(grid, width, height, row, col-1) + Get2DCell(grid, width, height, row, col+1) + Get2DCell(grid, width, height, row+1, col-1)
            + Get2DCell(grid, width, height, row+1, col) + Get2DCell(grid, width, height, row+1, col+1);*/
//    printf("after neighbours\n");
    int live = Get2DCell(grid, width, height, row, col);
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

int findNeighbours(int grid[], int width, int height, int row, int col) {
    int result = 0;
    for (int i=-1; i<2; i++) {
        for (int j=-1; j<2; j++) {
            result += Get2DCell(grid, width, height, row+i, (col+j+width)%width);
        }
    }
    result -= Get2DCell(grid, width, height, row, col);
    return result;
}
