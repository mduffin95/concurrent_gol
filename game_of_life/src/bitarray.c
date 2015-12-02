
#include <stdio.h>

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
