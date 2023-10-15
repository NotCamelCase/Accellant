#include "hero.h"

#include <cmath>

#include "aliens.h"
#include "ufo.h"
#include "blockers.h"

#define LASER_X_OFFSET 25
#define LASER_POS_Y (HERO_POS_Y - 15)
#define LASER_MIN_Y 25

#define NUM_LIVES_INIT 3

#define PLAYER_MOVE_SPEED 1
#define HERO_LASER_SPEED_Y 4

#define LASER_WIDTH 3
#define LASER_HEIGHT 12

#define ALIEN_HIT_SCORE 5
#define UFO_HIT_SCORE 100

Hero::Hero(Sprite *pSprite) : m_PosX(rand() % (SCREEN_WIDTH - 50)),
                              m_Lives(NUM_LIVES_INIT),
                              m_pSprite(pSprite)
{
}

void Hero::Render(DisplayPixel *pFramebuffer) const
{
    // Draw the hero sprite at bottom of screen at fixed Y pos
    DrawSprite(pFramebuffer, m_pSprite, m_PosX, HERO_POS_Y);

    constexpr DisplayPixel laserColor = {
        0x0,
        0xff,
        0x0,
        0x0};

    // Draw active lasers
    for (const auto &laser : m_Lasers)
    {
        if (laser.posX != HERO_LASER_POS_INVALID)
            DrawRect(pFramebuffer, laserColor, laser.posX, laser.posY, LASER_WIDTH, LASER_HEIGHT);
    }
}

bool Hero::Update(PlayerInput input)
{
    // Laser trajectory
    for (auto &laser : m_Lasers)
    {
        if (laser.posY > LASER_MIN_Y)
        {
            laser.posY -= HERO_LASER_SPEED_Y;
        }
        else if (laser.posX != HERO_LASER_POS_INVALID)
        {
            laser.posX = HERO_LASER_POS_INVALID;
        }
    }

    // Process input
    if (input == PlayerInput::MOVE_LEFT)
    {
        m_PosX -= PLAYER_MOVE_SPEED;
    }
    else if (input == PlayerInput::MOVE_RIGHT)
    {
        m_PosX += PLAYER_MOVE_SPEED;
    }
    else if (input == PlayerInput::SHOOT)
    {
        // Find the first inactive laser
        for (auto &laser : m_Lasers)
        {
            if (laser.posX == HERO_LASER_POS_INVALID)
            {
                laser.posX = m_PosX + LASER_X_OFFSET;
                laser.posY = LASER_POS_Y;

                break;
            }
        }
    }

    // Return True if the player has lost
    return m_Lives == 0;
}

void Hero::CheckLaserAliensCollision(Aliens *pAliens)
{
    for (auto &laser : m_Lasers)
    {
        const auto laserRect = Rect{
            laser.posX,
            laser.posY,
            LASER_WIDTH,
            LASER_HEIGHT};

        if (laser.posX != HERO_LASER_POS_INVALID)
        {
            for (auto j = 0; j < ALIEN_GRID_NUM_Y; j++)
            {
                Sprite *pAlienSprite = pAliens->m_Sprites[j];

                for (auto i = 0; i < ALIEN_GRID_NUM_X; i++)
                {
                    const auto &alienPos = pAliens->m_Positions[i][j];

                    if (pAliens->m_Properties[i][j].alive)
                    {
                        const auto alienRect = Rect{
                            pAliens->m_Positions[i][j].posX,
                            pAliens->m_Positions[i][j].posY,
                            pAlienSprite->m_Width,
                            pAlienSprite->m_Height};

                        if (RectCollidesWith(laserRect, alienRect))
                        {
                            laser.posX = HERO_LASER_POS_INVALID;

                            pAliens->m_Properties[i][j].alive = false;

                            // Shut down an alien \o/
                            m_Score += ALIEN_HIT_SCORE;
                        }
                    }
                }
            }
        }
    }
}

void Hero::CheckLaserUfoCollision(Ufo *pUfo)
{
    for (auto &laser : m_Lasers)
    {
        const auto laserRect = Rect{
            laser.posX,
            laser.posY,
            LASER_WIDTH,
            LASER_HEIGHT};

        if (laser.posX != HERO_LASER_POS_INVALID)
        {
            const auto ufoRect = Rect{
                pUfo->m_PosX,
                UFO_START_Y,
                pUfo->m_pSprite->m_Width,
                pUfo->m_pSprite->m_Height};

            if (RectCollidesWith(laserRect, ufoRect))
            {
                laser.posX = HERO_LASER_POS_INVALID;

                pUfo->m_IsVisible = false;

                // Shut down the Ufo
                m_Score += UFO_HIT_SCORE;
            }
        }
    }
}

void Hero::CheckLaserBlockersCollisions(Blockers *pBlockers)
{
    for (auto &laser : m_Lasers)
    {
        const auto laserRect = Rect{
            laser.posX,
            laser.posY,
            LASER_WIDTH,
            LASER_HEIGHT};

        if (laser.posX != HERO_LASER_POS_INVALID)
        {
            if (pBlockers->CheckLaserBlockersCollisions(laserRect))
            {
                laser.posX = HERO_LASER_POS_INVALID;
            }
        }
    }
}