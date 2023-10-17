#include "blockers.h"

#define BLOCKERS_START_POS_X 120
#define BLOCKERS_START_POS_Y 400

#define BLOCK_WIDTH 8
#define BLOCK_HEIGHT 8

/*
       [][][]
    [] [][][] []
    []        []
*/
const Blockers::BlockerOffset s_Blocker[] = {
            {1, 0}, {2, 0}, {3, 0},
    {0, 1}, {1, 1}, {2, 1}, {3, 1}, {4, 1},
    {0, 2},                         {4, 2},
};

void Blockers::Render(DisplayPixel *pFramebuffer) const
{
    constexpr DisplayPixel blockColor = {
        0xff,
        0xff,
        0x0,
        0x0};

    constexpr auto numBlocks = ARRAY_SIZE(s_Blocker);

    for (auto i = 1; i <= NUM_BLOCKERS; i++)
    {
        for (auto b = 0; b < ARRAY_SIZE(s_Blocker); b++)
        {
            const auto block = s_Blocker[b];

            if (!m_Flags[i - 1][b].destroyed)
            {
                uint16_t blockPosX = BLOCKERS_START_POS_X * i + (block.offsetX * BLOCK_WIDTH);
                uint16_t blockPosY = BLOCKERS_START_POS_Y + (block.offsetY * BLOCK_HEIGHT);

                const Rect rect = {blockPosX, blockPosY, BLOCK_WIDTH, BLOCK_HEIGHT};

                DrawRect(pFramebuffer, blockColor, rect);
            }
        }
    }
}

bool Blockers::CheckLaserBlockersCollisions(const Rect &laserRect)
{
    // TODO: Compute static bounding boxes of each blocker group to cull them first

    for (auto n = 1; n <= NUM_BLOCKERS; n++)
    {
        for (auto b = 0; b < ARRAY_SIZE(s_Blocker); b++)
        {
            if (!m_Flags[n - 1][b].destroyed)
            {
                const auto blocker = s_Blocker[b];
                const Rect blockRect = {
                    (uint16_t)(BLOCKERS_START_POS_X * n + (blocker.offsetX * BLOCK_WIDTH)),
                    (uint16_t)(BLOCKERS_START_POS_Y + (blocker.offsetY * BLOCK_HEIGHT)),
                    BLOCK_WIDTH,
                    BLOCK_HEIGHT};

                if (RectCollidesWith(laserRect, blockRect))
                {
                    m_Flags[n - 1][b].destroyed = true;

                    return true;
                }
            }
        }
    }

    return false;
}