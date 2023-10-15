#pragma once

#include "sprite.h"
#include "frame_utils.h"

#define UFO_START_Y 10

struct Ufo
{
    Ufo(Sprite *pSprite);

    bool m_IsVisible = false;

    uint16_t m_PosX;

    Sprite *m_pSprite;

    void Render(DisplayPixel *pFramebuffer) const;
    void Update();
};