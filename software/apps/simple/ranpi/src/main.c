/*--- pi.c       PROGRAM RANPI
 *
 *   Program to compute PI by probability.
 *   By Mark Riordan  24-DEC-1986;
 *   Original version apparently by Don Shull.
 *   To be used as a CPU benchmark.
 *
 *  Translated to C from FORTRAN 20 Nov 1993
 */
#include <stdint.h>
#include <stdlib.h>

#include "../../../../kernel/common.h"

void myadd(float* sum, float* addend)
{
    /*
    c   Simple adding subroutine thrown in to allow subroutine
    c   calls/returns to be factored in as part of the benchmark.
    */
    *sum = *sum + *addend;
}

// Computes a value of PI iteratively using soft-float
int main(void)
{
    // Brief delay to let putty catch up w/ the program
    timer_sleep(1000);

    printf("Running RanPI...\n");

    uint32_t s = timer_get_cycle_count();

    float ztot, yran, ymult, ymod, x, y, z, pi, prod;
    long int low, ixran, itot, j, iprod;

    ztot = 0.0;
    low = 1;
    ixran = 1907;
    yran = 5813.0;
    ymult = 1307.0;
    ymod = 5471.0;
    itot = 100;

    for (j = 1; j <= itot; j++)
    {
        /*
        c   X and Y are two uniform random numbers between 0 and 1.
        c   They are computed using two linear congruential generators.
        c   A mix of integer and real arithmetic is used to simulate a
        c   real program.  Magnitudes are kept small to prevent 32-bit
        c   integer overflow and to allow full precision even with a 23-bit
        c   mantissa.
        */
        iprod = 27611 * ixran;
        ixran = iprod - 74383 * (long int)(iprod / 74383);
        x = (float)ixran / 74383.0f;
        prod = ymult * yran;
        yran = (prod - ymod * (long int)(prod / ymod));
        y = yran / ymod;
        z = x * x + y * y;

        myadd(&ztot, &z);

        if (z <= 1.0)
        {
            low = low + 1;
        }
    }

    pi = 4.0f * (float)low / (float)itot;

    uint32_t e = timer_get_cycle_count();

    printf("Result: %f\n", pi); // 3.004f = 0x40428f5c
    printf("Number of cycles: %d\n", (int)(e - s)); // ~225000

    return 0;
}