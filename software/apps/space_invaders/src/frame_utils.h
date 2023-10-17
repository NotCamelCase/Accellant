#pragma once

#include <cstdint>

#include "sprite.h"
#include "../../../kernel/vga_core.h"

struct Rect
{
    uint16_t x, y;
    uint16_t w, h;
};

// Clear frame buffer to black
void ClearScreen(DisplayPixel *pFramebuffer);

// Draw a sprite at (posX, posY) on frame buffer
void DrawSprite(DisplayPixel *pFramebuffer, Sprite *pSprite, uint32_t posX, uint32_t posY);

// Draw a rect at (posX, posY) of color on frame buffer
void DrawRect(DisplayPixel *pFramebuffer, DisplayPixel color, const Rect& rect);

// Check if rect 'a' collides with rect 'b'
bool RectCollidesWith(const Rect &a, const Rect &b);