#include "vga_core.h"

#include <stdlib.h>

#include "memory_map.h"

static volatile uint32_t *const vga_ptr = (volatile uint32_t *)MMIO_VGA_BASE_ADDRESS;

static __attribute__((constructor)) void vga_init(void)
{
    // Allocate back buffers for display
    g_DisplayData.frontBuffer = calloc(SCREEN_WIDTH * SCREEN_HEIGHT, sizeof(DisplayPixel));
    g_DisplayData.backBuffer = calloc(SCREEN_WIDTH * SCREEN_HEIGHT, sizeof(DisplayPixel));
}

static __attribute__((destructor)) void vga_deinit(void)
{
    free(g_DisplayData.frontBuffer);
    free(g_DisplayData.backBuffer);
}

void vga_program_fb_base_addr(DisplayPixel *currentFBBase)
{
    vga_ptr[VGA_REG_SET_FB_BASE_ADDR] = (uint32_t)currentFBBase;
}

void vga_present(void)
{
    DisplayPixel *tb = g_DisplayData.backBuffer;

    g_DisplayData.backBuffer = g_DisplayData.frontBuffer;
    g_DisplayData.frontBuffer = tb;

    vga_program_fb_base_addr(g_DisplayData.frontBuffer);
}

DisplayPixel *vga_get_back_buffer(void)
{
    return g_DisplayData.backBuffer;
}