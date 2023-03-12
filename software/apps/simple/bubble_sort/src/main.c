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
    led_set_value(0x0);

    uart_init(BAUD_RATE);

    led_set_value(0x5);

    sleep_ms(1000);

    const int N = 10;
    int numbers[N];

    // Wait for user to input N numbers
    for (int n = 0; n < N; n++)
    {
        print_str("Enter a new number: \n");

        int i = 0;
        bool eol = false;
        char digits[10] = {};

        // Receive up to 10 chars which comprise each possible 32-bit integer
        while ((i < 10) && (!eol))
        {
            uint8_t nc;
            while (uart_read_byte(&nc) == STATUS_SUCCESS)
            {
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

    char tempStr[10] = {};

    print_str("Inputs sorted: ");
    print_str("{ ");
    for (int n = 0; n < N; n++)
    {
        itoa(numbers[n], &tempStr[0], 10);

        print_str(&tempStr[0]);

        if (n != N-1)
            print_str(", ");
    }
    print_str(" }\n");

    return 0;
}