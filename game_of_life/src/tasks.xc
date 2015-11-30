/*
 * tasks.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: Matt Duffin
 */

#include "tasks.h"
#include "types.h"
#include "constants.h"
#include "io.h"
#include "gollogic.h"
#include <stdio.h>
#include <string.h> //for memcpy
#include <xs1.h>

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
            unsigned r = rows;
            unsigned c = cols;
            dist_data.transferData(slice, r, c);
            break;
        default:
            if (!paused && !single) {
                for(int i=0; i<cols; i++) {
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

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, client data_if reader, client data_if writer, chanend acc) {
    uchar grid [GRIDSZ];
    unsigned rows_g, cols_g; // "global" rows and columns values
//    readGrid(grid, c_in);
    reader.transferData(grid, rows_g, cols_g); //This fills in height and width
    printf("Rows: %u, Cols: %u\n", rows_g, cols_g);

    int upload_count = 0; // How many workers have given slice back to grid.


    int remainder = rows_g % n;
    int rows_per_worker = (rows_g - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(uchar slice[]) -> unsigned rows_return:
            printf("Process %u is retrieving data.\n", i);
            rows_return = (i==n-1) ? rows_per_worker+remainder : rows_per_worker;
            memcpy(slice, grid+rows_per_worker*i*cols_g, rows_return*cols_g*sizeof(uchar));
            break;
        case c[int i].report(unsigned round, unsigned live):
            printf("Process %u is reporting. Round = %u. Live = %u\n", i, round, live);
            break;
        case d[int i].transferData(uchar slice[], unsigned &r, unsigned &c):
            printf("Process %u is transferring.\n", i, slice[0]);
            memcpy(grid+rows_per_worker*i*cols_g, slice, r*c*sizeof(uchar)); //Copy slice into grid.
            if (++upload_count == n) {
                for (int y = 0; y < rows_g; y++) {
                    for (int x = 0; x < cols_g; x++) {
                        printf("-%4.1d ", grid[y*cols_g+x]); //show image values
                    }
                    printf("\n");
                }
                unsigned rows_tmp = rows_g;
                unsigned cols_tmp = cols_g; //For security, as I am passing references.
                writer.transferData(grid, rows_tmp, cols_tmp);
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
