#pragma once

#define ALIEN_GRID_NUM_X 8
#define ALIEN_GRID_NUM_Y 4

#define MAX_ALIENS_LASERS 3
#define ALIEN_LASER_POS_INVALID 0xffff

#include "sprite.h"
#include "frame_utils.h"

struct Hero;
struct Blockers;

// Grid of aliens
struct Aliens
{
    Aliens(Sprite *pSprites);
    ~Aliens() {}

    bool m_Direction = true; // True: L->R | False: R->L
    bool m_ChangeDir = false;

    struct
    {
        uint16_t posX = ALIEN_LASER_POS_INVALID;
        uint16_t posY;
    } m_Lasers[MAX_ALIENS_LASERS];

    Sprite *m_Sprites[ALIEN_GRID_NUM_Y];

    struct
    {
        bool alive;
    } m_Properties[ALIEN_GRID_NUM_X][ALIEN_GRID_NUM_Y];

    struct
    {
        uint16_t posX;
        uint16_t posY;
    } m_Positions[ALIEN_GRID_NUM_X][ALIEN_GRID_NUM_Y];

    void Render(DisplayPixel *pFramebuffer) const;
    bool Update();
    void CheckAlienLaserHeroCollisions(Hero *pHero);
    void CheckAlienLaserBlockersCollisions(Blockers* pBlockers);
};