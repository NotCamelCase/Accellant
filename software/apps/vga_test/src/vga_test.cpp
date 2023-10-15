#include "../../../kernel/vga_core.h"

int main(int argc, char **ppArgv)
{
    uint8_t iter = 0;

    while (true)
    {
        auto fb = vga_get_back_buffer();

        for (uint32_t y = 0; y < SCREEN_HEIGHT; y++)
        {
            for (uint32_t x = 0; x < SCREEN_WIDTH; x++)
            {
                fb[x + y * SCREEN_WIDTH] = { iter, iter, iter, 0xff };
            }
        }

        ++iter;

        vga_present();
    }

    return 0;
}