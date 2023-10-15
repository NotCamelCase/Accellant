#pragma once

#include "sprite.h"
#include "frame_utils.h"

#define MAX_HERO_LASERS 4
#define HERO_LASER_POS_INVALID 0xffff

#define HERO_POS_Y 445

struct Aliens;
struct Ufo;
struct Blockers;

enum class PlayerInput : uint8_t
{
    MOVE_LEFT,
    MOVE_RIGHT,
    SHOOT,
    NONE
};

struct Hero
{
    Hero(Sprite *pSprite);
    ~Hero() {}

    struct
    {
        uint16_t posX = HERO_LASER_POS_INVALID;
        uint16_t posY;
    } m_Lasers[MAX_HERO_LASERS];

    uint8_t m_Lives;

    // Y pos is fixed
    uint16_t m_PosX;

    uint32_t m_Score = 0;

    Sprite *m_pSprite;

    void Render(DisplayPixel *pFramebuffer) const;
    bool Update(PlayerInput input);

    void CheckLaserAliensCollision(Aliens *pAliens);
    void CheckLaserUfoCollision(Ufo *pUfo);
    void CheckLaserBlockersCollisions(Blockers* pBlockers);
};