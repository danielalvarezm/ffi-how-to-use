#include <stdio.h>
#include "math_operations.h"

int main(void) {
    /* Fixed small inputs keep this C smoke example free of parsing/overflow. */
    const int a = 10;
    const int b = 2;

    printf("%d * %d = %d\n", a, b, multiply(a, b));
    printf("%d + %d = %d\n", a, b, add(a, b));

    return 0;
}
