
//Found this code at http://www.mathcs.emory.edu/~cheung/Courses/255/Syllabus/1-C-intro/bit-array.html which saved me some time.

void  SetBit( int A[ ], int k ) {
    A[k/32] |= 1 << (k%32);  // Set the bit at the k-th position in A[i]
}

void  ClearBit( int A[ ], int k ) {
    A[k/32] &= ~(1 << (k%32));
}

int TestBit( int A[ ], int k ) {
    return ( (A[k/32] & (1 << (k%32) )) != 0 );
}
