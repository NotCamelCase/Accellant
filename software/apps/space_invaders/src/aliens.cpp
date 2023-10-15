#include "aliens.h"

#include <cstring>
#include <cmath>

#include "hero.h"
#include "blockers.h"

#define ALIENS_GRID_START_X 25
#define ALIENS_GRID_START_Y 25

#define ALIENS_SPACING_X 50
#define ALIENS_SPACING_Y 50

#define ALIENS_MOVE_SIDE_AMOUNT 5
#define ALIENS_MOVE_DOWN_AMOUNT 10

#define ALIENS_GRID_MAX_X (SCREEN_WIDTH - ALIENS_GRID_START_X - 40)
#define ALIENS_GRID_MIN_X ALIENS_GRID_START_X

#define LASER_WIDTH 3
#define LASER_HEIGHT 12
#define ALIEN_LASER_SPEED_Y 4

Aliens::Aliens(Sprite *pSprites)
{
    // Start with one row of red alien, followed by two rows of yellow
    // and another row of green aliens
    m_Sprites[0] = &pSprites[SPRITE_TYPE_RED];
    m_Sprites[1] = &pSprites[SPRITE_TYPE_YELLOW];
    m_Sprites[2] = &pSprites[SPRITE_TYPE_YELLOW];
    m_Sprites[3] = &pSprites[SPRITE_TYPE_GREEN];

    memset(m_Properties, true, sizeof(bool) * ALIEN_GRID_NUM_X * ALIEN_GRID_NUM_Y);

    // Place aliens on initial grid
    uint16_t posY = ALIENS_GRID_START_Y;

    for (size_t j = 0; j < ALIEN_GRID_NUM_Y; j++)
    {
        uint16_t posX = ALIENS_GRID_START_X;

        for (size_t i = 0; i < ALIEN_GRID_NUM_X; i++)
        {
            m_Positions[i][j] = {posX, posY};

            posX += ALIENS_SPACING_X;
        }

        posY += ALIENS_SPACING_Y;
    }
}

void Aliens::Render(DisplayPixel *pFramebuffer) const
{
    for (uint32_t j = 0; j < ALIEN_GRID_NUM_Y; j++)
    {
        // Every row contains the same type of alien
        auto pSprite = m_Sprites[j];

        for (uint32_t i = 0; i < ALIEN_GRID_NUM_X; i++)
        {
            if (m_Properties[i][j].alive)
            {
                DrawSprite(
                    pFramebuffer,
                    pSprite,
                    m_Positions[i][j].posX,
                    m_Positions[i][j].posY);
            }
        }
    }

    constexpr DisplayPixel laserColor = {
        0xff,
        0x0,
        0x0,
        0x0};

    for (const auto &laser : m_Lasers)
    {
        if (laser.posX != ALIEN_LASER_POS_INVALID)
            DrawRect(pFramebuffer, laserColor, laser.posX, laser.posY, LASER_WIDTH, LASER_HEIGHT);
    }
}

bool Aliens::Update()
{
    // Laser trajectory
    for (auto &laser : m_Lasers)
    {
        if (laser.posY < SCREEN_HEIGHT)
        {
            // Moves downward
            laser.posY += ALIEN_LASER_SPEED_Y;
        }
        else if (laser.posX != ALIEN_LASER_POS_INVALID)
        {
            laser.posX = ALIEN_LASER_POS_INVALID;
        }
    }

    if (m_ChangeDir)
    {
        bool aliensOob = false;

        // Push every row ALIENS_GRID_DOWN_AMOUNT pixels down
        for (uint32_t j = 0; j < ALIEN_GRID_NUM_Y; j++)
        {
            for (uint32_t i = 0; i < ALIEN_GRID_NUM_X; i++)
            {
                m_Positions[i][j].posY += ALIENS_MOVE_DOWN_AMOUNT;
                aliensOob |= (m_Positions[i][j].posY >= (SCREEN_HEIGHT - 75));
            }
        }

        // Change the dir
        m_Direction = !m_Direction;
        m_ChangeDir = false;

        return aliensOob;
    }
    else
    {
        bool changeDir = false;
        bool aliensAlive = false;

        for (uint32_t j = 0; j < ALIEN_GRID_NUM_Y; j++)
        {
            for (uint32_t i = 0; i < ALIEN_GRID_NUM_X; i++)
            {
                // This branch is mispredicted once every N frames, right after a change of direction has taken place.
                // So, assuming no BTB entry aliasing happens w/ all the other stuff that happens every frame in between,
                // the branch penalty is rather negligible.
                if (m_Direction) // L -> R
                {
                    m_Positions[i][j].posX += ALIENS_MOVE_SIDE_AMOUNT;
                    changeDir |= (m_Properties[i][j].alive && (m_Positions[i][j].posX >= ALIENS_GRID_MAX_X));
                }
                else // R -> L
                {
                    m_Positions[i][j].posX -= ALIENS_MOVE_SIDE_AMOUNT;
                    changeDir |= (m_Properties[i][j].alive && (m_Positions[i][j].posX <= ALIENS_GRID_MIN_X));
                }

                aliensAlive |= m_Properties[i][j].alive;
            }
        }

        m_ChangeDir = changeDir;

        // Aliens can randomly shoot at the player
        const auto randX = rand() % ALIEN_GRID_NUM_X;
        const auto randY = rand() % ALIEN_GRID_NUM_Y;

        if (m_Properties[randX][randY].alive)
        {
            // Check if there is any re-usable laser
            for (auto &laser : m_Lasers)
            {
                if (laser.posX == ALIEN_LASER_POS_INVALID)
                {
                    laser.posX = m_Positions[randX][randY].posX;
                    laser.posY = m_Positions[randX][randY].posY;

                    break;
                }
            }
        }

        return !aliensAlive;
    }
}

void Aliens::CheckAlienLaserHeroCollisions(Hero *pHero)
{
    const auto heroRect = Rect{
        pHero->m_PosX,
        HERO_POS_Y,
        pHero->m_pSprite->m_Width,
        pHero->m_pSprite->m_Height};

    for (auto &laser : m_Lasers)
    {
        const auto laserRect = Rect{
            laser.posX,
            laser.posY,
            LASER_WIDTH,
            LASER_HEIGHT};

        if (laser.posX != ALIEN_LASER_POS_INVALID)
        {
            if (RectCollidesWith(laserRect, heroRect))
            {
                laser.posX = ALIEN_LASER_POS_INVALID;
                --pHero->m_Lives;
            }
        }
    }
}

void Aliens::CheckAlienLaserBlockersCollisions(Blockers *pBlockers)
{
    for (auto &laser : m_Lasers)
    {
        const auto laserRect = Rect{
            laser.posX,
            laser.posY,
            LASER_WIDTH,
            LASER_HEIGHT};

        if (laser.posX != ALIEN_LASER_POS_INVALID)
        {
            if (pBlockers->CheckLaserBlockersCollisions(laserRect))
            {
                laser.posX = ALIEN_LASER_POS_INVALID;
            }
        }
    }
}