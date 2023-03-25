#include <stdlib.h>
#include <ctype.h>

#include "../../../../kernel/common.h"

void swap(int* a, int* b)
{
    int t = *b;
    *b = *a;
    *a = t;
}

void sort_numbers(int* numbers, const int N)
{
    for (int i = 0; i < N; i++)
    {
        for (int j = i+1; j < N; j++)
        {
            if (numbers[i] > numbers[j])
            {
                swap(&numbers[j], &numbers[i]);
            }
        }
    }
}

int main(void)
{
    timer_sleep(1000);

    const int N = 10;
    int* numbers = (int*)malloc(N * sizeof(int));

    // Wait for user to input N numbers
    for (int n = 0; n < N; n++)
    {
        printf("Enter a new number: \n");

        int i = 0;
        bool eol = false;
        char digits[10] = {};

        // Receive up to 10 chars which comprise each possible 32-bit integer
        while ((i < 10) && (!eol))
        {
            uint8_t nc;
            while (!uart_rx_empty())
            {
                uart_read_byte(&nc);

                if (!isdigit(nc))
                {
                    eol = true;
                    break;
                }
                else
                {
                    digits[i++] = nc;
                }
            }
        }

        numbers[n] = atoi(&digits[0]);
    }

    // Sort the inputs
    sort_numbers(&numbers[0], N);

    printf("Inputs sorted: {");
    for (int n = 0; n < N-1; n++)
    {
        printf("%d, ", numbers[n]);
    }

    printf("%d}\n", numbers[N-1]);

    free(numbers);

    return 0;
}