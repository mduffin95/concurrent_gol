
//Found this code at http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/1-C-intro/bit-array.html which saved me some time.

//void  SetBit( int A[ ], int k ) {
//    A[k/32] |= 1 << (k%32);  // Set the bit at the k-th position in A[i]
//}
//
//void  ClearBit( int A[ ], int k ) {
//    A[k/32] &= ~(1 << (k%32));
//}
//
//int TestBit( int A[ ], int k ) {
//    return ( (A[k/32] & (1 << (k%32) )) != 0 );
//}
//
//int BitsToInts( int numBits ) {
//    return (sizeof(int)-1+numBits)/sizeof(int);
//}

int Get2DCell( int A[], int width, int row, int col) {
    int sz = sizeof(int)*8;
    int arr_width = (sz-1+width)/sz;
    return ((A[row*arr_width + col/sz] & (1 << (col%sz))) != 0);
}


//Need to write some functions that allow you to access this array like a 2D array.

