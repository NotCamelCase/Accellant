#include "frame_utils.h"

#include <cstring>

void ClearScreen(DisplayPixel *pFramebuffer)
{
    memset(pFramebuffer, 0x0, sizeof(DisplayPixel) * SCREEN_WIDTH * SCREEN_HEIGHT);
}

void DrawSprite(DisplayPixel *pFrameBuffer, Sprite *pSprite, uint32_t posX, uint32_t posY)
{
    auto pFramePtr = &pFrameBuffer[posX + posY * SCREEN_WIDTH];
    auto pBlitPtr = pSprite->m_pImage;

    const uint32_t blitStride = 3 * pSprite->m_Width;

    for (uint32_t y = 0; y < pSprite->m_Height; y++)
    {
        for (uint32_t x = 0; x < pSprite->m_Width; x++)
        {
            pFramePtr[x] = {
                pBlitPtr[3 * x + 0],
                pBlitPtr[3 * x + 1],
                pBlitPtr[3 * x + 2],
                // alpha unused
            };
        }

        pFramePtr += SCREEN_WIDTH;
        pBlitPtr += blitStride;
    }
}

void DrawRect(DisplayPixel *pFramebuffer, DisplayPixel color, const Rect& rect)
{
    auto pFramePtr = &pFramebuffer[rect.x + rect.y * SCREEN_WIDTH];

    for (uint32_t y = 0; y < rect.h; y++)
    {
        for (uint32_t x = 0; x < rect.w; x++)
        {
            pFramePtr[x] = color;
        }

        pFramePtr += SCREEN_WIDTH;
    }
}

bool RectCollidesWith(const Rect &a, const Rect &b)
{
    bool x1Align = (a.x <= b.x) && ((a.x + a.w) >= b.x);
    bool x2Align = (b.x <= a.x) && ((b.x + b.w) >= a.x);
    bool y1Align = (a.y >= b.y) && (a.y <= (b.y + b.h));
    bool y2Align = (b.y >= a.y) && (b.y <= (a.y + a.h));

    return (x1Align || x2Align) && (y1Align || y2Align);
}