#pragma once

#include <cstdint>

typedef enum
{
    SPRITE_TYPE_HERO,
    SPRITE_TYPE_RED,
    SPRITE_TYPE_GREEN,
    SPRITE_TYPE_YELLOW,
    SPRITE_TYPE_UFO,
    SPRITE_TYPE_COUNT
} sprite_type_e;

struct Sprite
{
    // Image data
    uint8_t *m_pImage;

    // Image size
    uint16_t m_Width, m_Height;
};