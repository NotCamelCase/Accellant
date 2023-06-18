#include <iostream>
#include <cstring>
#include <cmath>

#include "../../../kernel/vga_core.h"

using namespace std;

int main(int argc, char **ppArgv)
{
    auto fb = vga_get_back_buffer();

    for (uint32_t y = 0; y < SCREEN_HEIGHT; y++)
    {
        for (uint32_t x = 0; x < SCREEN_WIDTH; x++)
        {
            fb[x + y * SCREEN_WIDTH] = { 0xff, 0, 0 };
        }
    }

    vga_swap_buffers();

    while (true)
    {
        vga_present();
    }

    return 0;
}