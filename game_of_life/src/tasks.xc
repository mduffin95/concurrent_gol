/*
 * tasks.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "tasks.h"
#include "utils.h"
#include <stdio.h>
#include <string.h> //for memcpy

void sliceWorker(unsigned id, static const unsigned cols, client interface farmer i, streaming chanend top_c, streaming chanend bot_c) {
    uchar data[SLSZ];
    uchar *slice = data+cols;
    unsigned rows = i.getSlice(id, slice);
    uchar *top_arr = data;
    uchar *bot_arr = data+(rows+1)*cols; //Aliasing pointers
    while(1) {
        for(int i=0; i<IMWD; i++) {
            top_c <: slice[i];
            bot_c <: slice[(rows-1)*cols+i];
            top_c :> top_arr[i];
            bot_c :> bot_arr[i];
        }
        i.doneIteration(id, slice);
    }
    printf("%d, is done\n", id);
}

void distributor(server interface farmer c[n], unsigned n, chanend c_in, chanend c_out, chanend fromAcc) {
    uchar grid [IMHT*IMWD];
    readGrid(grid, c_in, c_out, fromAcc);

    int size = IMWD;
    int remainder = size % n;
    int rows = (size - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(unsigned id, uchar slice[]) -> unsigned rows_return:
            printf("Process %u is retrieving data\n", id);
            rows_return = (id==n-1) ? rows+remainder : rows;
            memcpy(slice, grid+rows*id*size, rows_return*size*sizeof(uchar));
            break;
        case c[int i].doneIteration(unsigned id, uchar slice[]) -> int continue_return:
            printf("Process %u has finished an iteration. slice[0] = %d\n", id, slice[0]);
            continue_return = 1;
            break;
        }
    }
}
