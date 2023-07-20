#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "common.h"

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum
    {
        VGA_REG_SET_FB_BASE_ADDR = 0
    } VGA_REG;

    typedef struct
    {
        union
        {
            struct
            {
                // R8G8B8A8
                uint8_t r, g, b, a;
            };

            uint8_t data[4];
        };
    } DisplayPixel;

    typedef struct
    {
        // Linear R8G8B8A frame buffers
        DisplayPixel *frontBuffer; // Current frame buffer being displayed
        DisplayPixel *backBuffer;  // Next frame buffer to be displayed
    } DisplayData;

    static DisplayData g_DisplayData = {};

    void vga_program_fb_base_addr(DisplayPixel *currentFBBase);

    // Present current front buffer
    void vga_present(void);

    DisplayPixel *vga_get_back_buffer(void);

#if __cplusplus
}
#endif