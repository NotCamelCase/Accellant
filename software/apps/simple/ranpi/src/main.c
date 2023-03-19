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
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "../../../../kernel/uart_core.h"
#include "../../../../kernel/led_core.h"
#include "../../../../kernel/timer_core.h"

#define BAUD_RATE   9600

void sleep_ms(uint32_t valMs)
{
    uint32_t start = timer_get_time_ms();
    uint32_t now = 0;
    do
    {
        now = timer_get_time_ms();
    } while ((now - start) <= valMs);
}

void print_str(const char* val)
{
    const uint32_t len = strlen(val) + 1; // Include \0
    for (uint32_t i = 0; i < len; i++)
    {
        uart_write_byte(val[i]);
    }
}

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
    led_set_value(0x0);

    uart_init(BAUD_RATE);

    led_set_value(0x5);

    float ztot, yran, ymult, ymod, x, y, z, pi, prod;
    long int low, ixran, itot, j, iprod;

    sleep_ms(1000);

    print_str("Running RanPI...\n");

    uint32_t s = timer_get_cycle_count();

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

    // Print result value in hex
    print_str("Result: 0x");

    char floatStr[32] = {};
    itoa(*(int*)(&pi), &floatStr[0], 16);
    print_str(&floatStr[0]); // 3.004f = 0x40428f5c

    char intStr[10] = {};
    print_str("\nNumber of cycles: "); // 221975
    itoa((e - s), &intStr[0], 10);
    print_str(&intStr[0]);

    return 0;
}