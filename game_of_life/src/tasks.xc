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
#include "bitarray.h"
#include <stdio.h>
#include <string.h> //for memcpy
#include <xs1.h>

void sliceWorker(client farmer_if dist_control, client data_if dist_data, streaming chanend top_c, streaming chanend bot_c) {
    int d1[SLSZ], d2[SLSZ];
    int *data_curr = d1;
    int *data_next = d2;
    unsigned rows, cols;
    select { //Waits until the data is ready before retrieving slice.
        case dist_data.sliceReady():
            {rows, cols} = dist_data.getSlice(data_curr);
            break;
    }
    unsigned round = 1;
    int *slice = data_curr+IntWidth(cols);
    int paused = 0;
    int *top_arr = data_curr;
    int *bot_arr = data_curr+(rows+1)*IntWidth(cols); //Aliasing pointers
    unsigned live = 0;
    while(1) {
        select {
        case dist_control.resume():
            paused = 0;
            break;
        default:
            if (!paused) {
                for(int i=0; i<IntWidth(cols); i++) {
                    top_c <: slice[i];
                    bot_c <: slice[(rows-1)*IntWidth(cols)+i];
                    top_c :> top_arr[i];
                    bot_c :> bot_arr[i];
                }
                live = 0;
                for (int y=0; y<rows; y++) {
                    for (int x=0; x<cols; x++) {
                        Set2DCell(data_next+IntWidth(cols), cols, rows, y, x, calcGol(slice, cols, rows, y, x));
//                        data_next[cols+y*cols+x] = calcGol(slice+y*cols+x, cols, y, x);
                        if(Get2DCell(data_next, cols, rows, y, x)) {
                            live++;
                        }
                    }
                }
                int *tmp = data_curr;
                data_curr = data_next;
                data_next = tmp;
                slice = data_curr+IntWidth(cols);
                top_arr = data_curr;
                bot_arr = data_curr+(rows+1)*IntWidth(cols);

                switch (dist_control.report(round, live)) {
                case PAUSE:
                    paused = 1;
                    break;
                case UPLOAD:
                    dist_data.transferData(slice, rows, cols);
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

void distributor(server farmer_if c[n], server data_if d[n], unsigned n, client but_led_if gpio, chanend acc) {
    int grid [GRIDSZ] = {0};
    unsigned rows_g, cols_g; // "global" rows and columns values
    unsigned round_g = 1;

//    reader.transferData(grid, rows_g, cols_g); //This fills in height and width

    int upload_count = 0; // How many workers have given slice back to grid.
    int pause_count = 0;
    unsigned pause_round = 0; //The round number on which to pause.
    unsigned slices_round = 0; //The round number on which to retrieve slices.
    unsigned tot_live = 0;
//    int alt_round = 1;

    int remainder, rows_per_worker;
    while(1) {
//        if (alt_round%2==1){
//            gpio.toggleGreen2();
//        }
//        alt_round++;
        [[ordered]]
        select {
        case gpio.event():
            uchar button = gpio.getButton();
            printf("Button %u was pressed.\n", button);
            if(button == 1) {
                slices_round = round_g + 1;
                gpio.setBlue(1);
            } else {
                gpio.setGreen(1);
                {rows_g, cols_g} = DataIn("128x128.pgm", grid);
                gpio.setGreen(0);

                for (int i=0; i<n; i++) d[i].sliceReady();

                //Initialise these now we now rows and cols.
                remainder = rows_g % n;
                rows_per_worker = (rows_g - remainder) / n;
            }
            break;
        case acc :> int tilted:
            if (!tilted) {
                for(int i=0; i<n; i++) {
                    c[i].resume(); //Resume them all.
                    gpio.setRed(0);
                }
                pause_round = 0;
            } else { //Tilted
                pause_round = round_g + 1;
            }
            break;
        //Initially send each slice to each worker.
        case d[int i].getSlice(int inData[]) -> {unsigned rows_return, unsigned cols_return}:
            printf("Process %u is retrieving data.\n", i);
            rows_return = (i==n-1) ? rows_per_worker+remainder : rows_per_worker;
            cols_return = cols_g;
            int k = IntWidth(cols_g);
            memcpy(inData+k, grid+rows_per_worker*i*k, rows_return*k*sizeof(int)); //inData+cols_g to give room for top row.
            break;
        //Gather data from each worker. Send back code to tell them what to do.
        case c[int i].report(unsigned round, unsigned live) -> int return_code:
            if (round_g < round) {
                round_g = round;
                gpio.toggleGreen2();
            }
            if (pause_round == round) {
                printf("Process %u is reporting. Round = %u. Live = %u\n", i, round, live);
                return_code = PAUSE;
                tot_live += live;
                if (pause_count++ == 0) gpio.setRed(1);
                else if (pause_count == n) {
                    printf("Report: round = %u, live = %u\n", round_g, tot_live);
                    pause_count = 0;
                    tot_live = 0;
                }
            }
            else if (slices_round == round) return_code = UPLOAD;
            else return_code = 0;
            break;
        //Get slices from workers and copy back to main grid array. Output to file.
        case d[int i].transferData(int slice[], unsigned r, unsigned c):
            printf("Process %u is transferring.\n", i, slice[0]);
            int k = IntWidth(cols_g);
            memcpy(grid+rows_per_worker*i*k, slice, r*k*sizeof(int)); //Copy slice into grid.
            if (++upload_count == n) {
//                PrintArray(grid, cols_g, rows_g);
                unsigned rows_tmp = rows_g;
                unsigned cols_tmp = cols_g; //For security, as I am passing references.
                DataOut("testout.pgm", grid, rows_tmp, cols_tmp);
                gpio.setBlue(0);
                upload_count = 0;
            }
            break;
        }
    }
}
