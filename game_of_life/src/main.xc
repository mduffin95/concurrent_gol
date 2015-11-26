// COMS20001 - Cellular Automaton Farm - Initial Code Skeleton
// (using the XMOS i2c accelerometer demo)

#include <platform.h>
#include <xs1.h>
#include <stdio.h>

/*---My Includes---*/
#include "io.h"
#include "tasks.h"
#include "constants.h"

on tile[0]: port p_scl = XS1_PORT_1E;         //interface ports to accelerometer
on tile[0]: port p_sda = XS1_PORT_1F;

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
    on tile[0]: DataOutStream("testout.pgm", c_outIO);       //thread to write out a PGM image
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
