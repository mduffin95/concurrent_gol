
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

int IntWidth( int bitWidth ) {
    int sz = sizeof(int)*8;
    return (sz-1+bitWidth)/sz;
}

int Get2DCell( int A[], int width, int height, int row, int col) {
    int sz = sizeof(int)*8;
    int arr_width = IntWidth(width);
    return ((A[row*arr_width + col/sz] & (1 << (col%sz))) != 0);
}

void Set2DCell( int A[], int width, int height, int row, int col, int val) {
    int sz = sizeof(int)*8;
    int arr_width = IntWidth(width);
    if (val)
        A[row*arr_width + col/sz] |= (1 << (col%sz));
    else
        A[row*arr_width + col/sz] &= ~(1 << (col%sz));
}

void PrintArray( int A[], int width, int height) {
    for(int i=0; i<height; i++) {
        for(int j=0; j<width; j++) {
            printf("%d", Get2DCell(A, width, height, i, j));
        }
        printf("\n");
    }
}
//Need to write some functions that allow you to access this array like a 2D array.

