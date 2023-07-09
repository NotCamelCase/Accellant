#include "../../../kernel/vga_core.h"

int main(int argc, char **ppArgv)
{
    while (true)
    {
        auto fb = vga_get_back_buffer();

        for (uint32_t y = 0; y < SCREEN_HEIGHT; y++)
        {
            for (uint32_t x = 0; x < SCREEN_WIDTH; x++)
            {
                fb[x + y * SCREEN_WIDTH] = { 0xff, 0xff, 0xff, 0xff };
            }
        }

        vga_swap_buffers();
        vga_present();
    }

    return 0;
}