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

//Calculates what the next state of the given cell should be.
int calcGol(int grid[], int width, int height, int row, int col) {
    int neighbours = findNeighbours(grid, width, height, row, col);
    int live = Get2DCell(grid, width, height, row, col);
    if (live) {
        if (neighbours < 2 || neighbours > 3) {
            return 0; //Dies
        }
        return 1; //Lives on, becuase there are 2 or 3 neighbours
    }
    else {
        if (neighbours == 3) {
            return 1; //Becomes live
        }
        return 0; //Stays dead
    }
}

//Finds the number of neighbours surrounding the given cell.
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
