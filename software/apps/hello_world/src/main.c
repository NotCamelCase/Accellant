#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "../../../kernel/uart_core.h"
#include "../../../kernel/led_core.h"

#define BAUD_RATE   9600

int main(void)
{
    led_set_value(0x0);

    uart_init(BAUD_RATE);

    const char* helloWorld = "Hello, World!\n";
    const uint32_t len = strlen(helloWorld) + 1; // Include \0

    led_set_value(0x5);

    // Print out Hello, World! in a loop
    while (true)
    {
        for (uint32_t i = 0; i < len; i++)
        {
            uart_write_byte(helloWorld[i]);
        }
    }

    return 0;
}