#pragma once

#include <cstdint>

#include "frame_utils.h"

#define NUM_BLOCKERS 4
#define MAX_NUM_BLOCKS 16

struct Blockers
{
    struct BlockerOffset
    {
        // Block offset from pre-determined positions
        uint16_t offsetX;
        uint16_t offsetY;
    };

    struct
    {
        bool destroyed;
    } m_Flags[NUM_BLOCKERS][MAX_NUM_BLOCKS] = {};

    struct
    {
        // Fixed starting positions of each blocker
        uint16_t posX;
        uint16_t posY;
    } m_Positions[NUM_BLOCKERS];

    void Render(DisplayPixel *pFramebuffer) const;
    bool CheckLaserBlockersCollisions(const Rect& laserRect);
};