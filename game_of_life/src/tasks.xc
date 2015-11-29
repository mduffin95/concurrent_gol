/*
 * tasks.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "tasks.h"
#include "utils.h"
#include "types.h"
#include "constants.h"
#include "io.h"
#include <stdio.h>
#include <string.h> //for memcpy
#include <xs1.h>

uchar calcGol(uchar *cell, unsigned size, unsigned row, unsigned col) {
    int left = (size+col-1)%size - col; //value to add to go left
    int right = (col+1)%size - col;
    uchar box[9] = {*(cell+left-size), *(cell-size), *(cell+right-size), *(cell+left), *cell, *(cell+right), *(cell+left+size), *(cell+size), *(cell+right+size)};
    uchar neighbours = *(cell+left-size) + *(cell-size) + *(cell+right-size) + *(cell+left) + *(cell+right) + *(cell+left+size) + *(cell+size) + *(cell+right+size);
//    printf("after neighbours\n");
    uchar live = *cell;
//    printf("inside calcgol\n");
    if (live) {
        printf("Cell (%u, %u) has %u neighbours. [%u, %u, %u, %u, %u, %u, %u, %u, %u]\n", row, col, neighbours, box[0], box[1], box[2], box[3], box[4], box[5], box[6], box[7], box[8]);
        if (neighbours < 2 || neighbours > 3) {
            return 0; //Dies
        }
        printf("Cell (%u, %u) lives  with %u neighbours.\n", row, col, neighbours);
        return 1; //Lives on, becuase there are 2 or 3 neighbours
    }
    else {
        if (neighbours == 3) {
            return 1; //Becomes live
        }
        return 0; //Stays dead
    }
}

void sliceWorker(static const unsigned cols, client farmer_if dist_control, client data_if dist_data, streaming chanend top_c, streaming chanend bot_c) {
    uchar d1[SLSZ], d2[SLSZ];
    uchar *data_curr = d1;
    uchar *data_next = d2;
    uchar *slice = data_curr+cols;
    unsigned rows = dist_control.getSlice(slice);
    unsigned round = 0;
    uchar paused = 0;
    uchar single = 0;
    uchar *top_arr = data_curr;
    uchar *bot_arr = data_curr+(rows+1)*cols; //Aliasing pointers
    unsigned live = 0;
    while(1) {
        select {
        case dist_control.playPause():
            if (paused) {
                dist_control.restart();
            } else {
                dist_control.report(round, live);
            }
            paused = ~paused;
            single = 0;
            break;
        case dist_data.requestTransfer():
            unsigned len = rows*cols;
            dist_data.transferData(slice, len);
            break;
        default:
            if (!paused && !single) {
                for(int i=0; i<IMWD; i++) {
                    top_c <: slice[i];
                    bot_c <: slice[(rows-1)*cols+i];
                    top_c :> top_arr[i];
                    bot_c :> bot_arr[i];
                }
                live = 0;
                for (int y=0; y<rows; y++) {
                    for (int x=0; x<cols; x++) {
                        data_next[cols+y*cols+x] = calcGol(slice+y*cols+x, cols, y, x);
                        if(data_next[cols+y*cols+x]) {
                            live++;
                        }
                    }
                }
                uchar *tmp = data_curr;
                data_curr = data_next;
                data_next = tmp;
                slice = data_curr+cols;
                top_arr = data_curr;
                bot_arr = data_curr+(rows+1)*cols;
                round++;
                single = 1;
            }
            break;
        }
    }
}

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, chanend c_in, chanend c_out, chanend acc) {
    uchar grid [IMHT*IMWD];
    readGrid(grid, c_in);

    int upload_count = 0; // How many workers have given slice back to grid.

    int size = IMWD;
    int remainder = size % n;
    int rows = (size - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(uchar slice[]) -> unsigned rows_return:
            printf("Process %u is retrieving data.\n", i);
            rows_return = (i==n-1) ? rows+remainder : rows;
            memcpy(slice, grid+rows*i*size, rows_return*size*sizeof(uchar));
            break;
        case c[int i].report(unsigned round, unsigned live):
            printf("Process %u is reporting. Round = %u. Live = %u\n", i, round, live);
            break;
        case d[int i].transferData(uchar slice[], unsigned &len):
            printf("Process %u is transferring. slice[0] = %u.\n", i, slice[0]);
            memcpy(grid+rows*i*size, slice, len*sizeof(uchar)); //Copy slice into grid.
            if (++upload_count == n) {
                writeGrid(grid, c_out); // Send grid off to DataOutStream
                upload_count = 0;
            }
            break;
        case c[int i].restart():
            printf("Process is restarting.\n");
            break;
        case gpio.event():
            uchar button = gpio.getButton();
            printf("Button %u was pressed.\n", button);
            if(button == 1) {
                for(int j=0; j<n; j++)
                    d[j].requestTransfer(); //Send notification to all workers.
            }
            break;
        case acc :> int tilted:
            printf("Tilted = %d\n", tilted);
            for(int j=0; j<n; j++) //Toggle pause/play state after a tilt.
                c[j].playPause();
            break;
        }
    }
}
