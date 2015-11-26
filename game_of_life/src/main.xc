// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>

/*---My Includes---*/
#include "utils.h"
#include "io.h"
#include "constants.h"
#include <string.h> //for memcpy


on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to accelerometer
on tile[0]: port p_sda = XS1_PORT_1F;

interface farmer {
    unsigned getSlice(unsigned id, uchar slice[]); //Why can we not specify first dimension?
    int doneIteration(unsigned id, uchar slice[]); //Returns 1 when we want to continue.
};

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

void distributor(server interface farmer c[n], unsigned n, chanend c_in, chanend c_out, chanend fromAcc)
{
    uchar grid [IMHT*IMWD];

    //Starting up and wait for tilting of the xCore-200 Explorer
    printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );
    printf( "Waiting for Board Tilt...\n" );
    fromAcc :> int value;

    //Read in and do something with your image values..
    //This just inverts every pixel, but you should
    //change the image according to the "Game of Life"
    printf( "Processing...\n" );
    for( int y = 0; y < IMHT; y++ ) {   //go through all lines
        for( int x = 0; x < IMWD; x++ ) { //go through each pixel per line
            c_in :> grid[y*IMWD+x]; //read the pixel value
            c_out <: (uchar)( grid[y*IMWD+x] ^ 0xFF ); //send some modified pixel out
        }
    }
    printf( "\nOne processing round completed...\n" );
    int size = IMWD;
    int remainder = size % n;
    int rows = (size - remainder) / n;
    while(1) {
        select {
        case c[int i].getSlice(unsigned id, uchar slice[]) -> unsigned return_val:
            printf("Process %u is retrieving data\n", id);
            return_val = (id==n-1) ? rows+remainder : rows;
            memcpy(slice, grid+rows*id*size, return_val*size*sizeof(uchar));
            break;
        case c[int i].doneIteration(unsigned id, uchar slice[]) -> int return_val:
            printf("Process %u has finished an iteration. slice[0] = %d\n", id, slice[0]);
            return_val = 1;
            break;
        }
    }

}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Orchestrate concurrent system and start up all threads
//
/////////////////////////////////////////////////////////////////////////////////////////
int main(void) {

  i2c_master_if i2c[1];               //interface to accelerometer

  //char infname[] = "test.pgm";     //put your input image path here
  //char outfname[] = "testout.pgm"; //put your output image path here
  chan c_inIO, c_outIO, c_control;    //extend your channel definitions here

  interface farmer b[WORKERS];
  streaming chan c[WORKERS];

  par {
    on tile[0]: i2c_master(i2c, 1, p_scl, p_sda, 10);   //server thread providing accelerometer data
    on tile[0]: accelerometer(i2c[0],c_control);        //client thread reading accelerometer data
    on tile[0]: DataInStream("test.pgm", c_inIO);          //thread to read in a PGM image
    on tile[1]: DataOutStream("testout.pgm", c_outIO);       //thread to write out a PGM image
    on tile[1]: distributor(b, WORKERS, c_inIO, c_outIO, c_control);//thread to coordinate work on image
    on tile[0]: par (int i=0; i<WORKERS/2; i++) {
        sliceWorker(i, IMWD, b[i], c[i], c[(i+1)%WORKERS]);
    }
    on tile[1]: par (int i=WORKERS/2; i<WORKERS; i++) {
        sliceWorker(i, IMWD, b[i], c[i], c[(i+1)%WORKERS]);
    }
  }

  return 0;
}
