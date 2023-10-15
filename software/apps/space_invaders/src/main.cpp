#include <iostream>

#include "../../../kernel/timer_core.h"
#include "../../../kernel/uart_core.h"

#include "assets.h"

#include "hero.h"
#include "aliens.h"
#include "ufo.h"
#include "blockers.h"

#define INPUT_MOVE_LEFT 'a'
#define INPUT_MOVE_RIGHT 'd'
#define INPUT_SHOOT ' '

Sprite g_Sprites[SPRITE_TYPE_COUNT] = {};

// Use randomized inputs to win or sample UART to receive input
PlayerInput ReceiveInput();

int main(int argc, char **ppArgv)
{
    // Initialize sprites w/ static images
    if (!InitAssets(g_Sprites))
    {
        printf("InitAssets() failed\n");
        return -1;
    }

    // TODO: Faster rand() impl

    while (true)
    {
        Hero hero(&g_Sprites[SPRITE_TYPE_HERO]);
        Aliens aliens(g_Sprites);
        Ufo ufo(&g_Sprites[SPRITE_TYPE_UFO]);
        Blockers blockers;

        bool gameOver = false;

        // Game loop
        while (!gameOver)
        {
            auto frameStart = timer_get_time_ms();

            auto fb = vga_get_back_buffer();

            ClearScreen(fb);

            ufo.Render(fb);
            aliens.Render(fb);
            blockers.Render(fb);
            hero.Render(fb);

            hero.CheckLaserAliensCollision(&aliens);
            hero.CheckLaserUfoCollision(&ufo);
            hero.CheckLaserBlockersCollisions(&blockers);

            aliens.CheckAlienLaserHeroCollisions(&hero);
            aliens.CheckAlienLaserBlockersCollisions(&blockers);

            gameOver |= hero.Update(ReceiveInput());
            gameOver |= aliens.Update();
            ufo.Update();

            vga_present();

            auto frameEnd = timer_get_time_ms();

            printf("Frame time: %d ms\n", (frameEnd - frameStart));
        }
    }

    return 0;
}

PlayerInput ReceiveInput()
{
    auto ret = PlayerInput::NONE;

    // Try to retrieve last input character via UART
    constexpr auto MAX_TRIES = 16;
    for (size_t i = 0; i < MAX_TRIES; i++)
    {
        if (!uart_rx_empty())
        {
            switch (uart_read_byte())
            {
            case INPUT_MOVE_LEFT:
                ret = PlayerInput::MOVE_LEFT;
                break;

            case INPUT_MOVE_RIGHT:
                ret = PlayerInput::MOVE_RIGHT;
                break;

            case INPUT_SHOOT:
                ret = PlayerInput::SHOOT;
                break;

            default:
                break;
            }

            return ret;
        }
    }

    return ret;
}