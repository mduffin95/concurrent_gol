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

void sliceWorker(client farmer_if dist_control, client data_if dist_data, streaming chanend top_c, streaming chanend bot_c) {
    uchar d1[SLSZ], d2[SLSZ];
    uchar *data_curr = d1;
    uchar *data_next = d2;
    unsigned rows, cols;
    {rows, cols} = dist_control.getSlice(data_curr);
    unsigned round = 1;
    uchar *slice = data_curr+cols;
    uchar paused = 0;
    uchar *top_arr = data_curr;
    uchar *bot_arr = data_curr+(rows+1)*cols; //Aliasing pointers
    unsigned live = 0;
    while(1) {
        select {
        case dist_control.resume():
            paused = 0;
            break;
        default:
            if (!paused) {
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


                switch (dist_control.report(round, live)) {
                case PAUSE:
                    paused = 1;
                    break;
                case UPLOAD:
                    unsigned r = rows;
                    unsigned c = cols;
                    dist_data.transferData(slice, r, c);
                    break;
                default:
                    break;
                }

                round++;
            }
            break;
        }
    }
}

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, client data_if reader, client data_if writer, chanend acc) {
    uchar grid [GRIDSZ];
    unsigned rows_g, cols_g; // "global" rows and columns values
    unsigned round_g = 1;
    gpio.setGreen(1);
    reader.transferData(grid, rows_g, cols_g); //This fills in height and width
    gpio.setGreen(0);
    int upload_count = 0; // How many workers have given slice back to grid.
    unsigned pause_round = 0; //The round number on which to pause.
    unsigned slices_round = 0; //The round number on which to retrieve slices.


    int remainder = rows_g % n;
    int rows_per_worker = (rows_g - remainder) / n;
    while(1) {
        [[ordered]]
        select {
        case gpio.event():
            uchar button = gpio.getButton();
            printf("Button %u was pressed.\n", button);
            if(button == 1) {
                slices_round = round_g + 1;
            }
            break;
        case acc :> int tilted:
            if (!tilted) {
                for(int i=0; i<n; i++) {
                    c[i].resume(); //Resume them all.
                }
                pause_round = 0;
            } else { //Tilted
                pause_round = round_g + 1;
            }
            break;
        //Initially send each slice to each worker.
        case c[int i].getSlice(uchar inData[]) -> {unsigned rows_return, unsigned cols_return}:
            printf("Process %u is retrieving data.\n", i);
            rows_return = (i==n-1) ? rows_per_worker+remainder : rows_per_worker;
            cols_return = cols_g;
            memcpy(inData+cols_g, grid+rows_per_worker*i*cols_g, rows_return*cols_g*sizeof(uchar)); //inData+cols_g to give room for top row.
            break;
        //Gather data from each worker. Send back code to tell them what to do.
        case c[int i].report(unsigned round, unsigned live) -> int return_code:

            if (round_g < round) round_g = round;
            if (pause_round == round) {
                return_code = PAUSE;
                printf("Process %u is reporting. Round = %u. Live = %u\n", i, round, live);
            }
            else if (slices_round == round) return_code = UPLOAD;
            else return_code = 0;
            break;
        //Get slices from workers and copy back to main grid array.
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
        }
    }
}
