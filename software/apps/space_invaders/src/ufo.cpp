#include "ufo.h"

#include <cmath>

#define UFO_START_X (SCREEN_WIDTH - 50)

#define UFO_MOVE_SPEED 4
#define UFO_MIN_POS_X 25

Ufo::Ufo(Sprite *pSprite) : m_pSprite(pSprite)
{
}

void Ufo::Render(DisplayPixel *pFramebuffer) const
{
    if (m_IsVisible)
    {
        DrawSprite(pFramebuffer, m_pSprite, m_PosX, UFO_START_Y);
    }
}

void Ufo::Update()
{
    if (m_IsVisible)
    {
        // The UFO moves horizontally right-to-left until it gets out of screen
        // or gets shot by the player
        if (m_PosX <= UFO_MIN_POS_X)
            m_IsVisible = false;
        else
            m_PosX -= UFO_MOVE_SPEED;
    }
    else
    {
        // Have the UFO randomly appear
        const auto rn = rand() & (0x1000 - 1);
        bool spawnUfo = (rn >= 250) && (rn < 270);

        if (spawnUfo)
        {
            m_IsVisible = true;
            m_PosX = UFO_START_X;
        }
    }
}