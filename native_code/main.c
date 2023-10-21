#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "math_operations/math_operations.h"

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <number> <number>\n", argv[0]);
        return -1;
    }

    int a = atoi(argv[1]);
    int b = atoi(argv[2]);

    printf("%d * %d = %d\n", a, b, multiply(a, b));

    return 0;
}