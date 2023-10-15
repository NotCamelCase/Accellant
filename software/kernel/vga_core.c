#include "vga_core.h"

#include <stdlib.h>

#include "memory_map.h"

static volatile uint32_t *const vga_ptr = (volatile uint32_t *)MMIO_VGA_BASE_ADDRESS;

static DisplayData g_DisplayData = {};

static __attribute__((constructor)) void vga_init(void)
{
    // Allocate back buffers for display
    g_DisplayData.frontBuffer = aligned_alloc(64, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(DisplayPixel));
    g_DisplayData.midBuffer = aligned_alloc(64, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(DisplayPixel));
    g_DisplayData.backBuffer = aligned_alloc(64, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(DisplayPixel));
}

static __attribute__((destructor)) void vga_deinit(void)
{
    free(g_DisplayData.frontBuffer);
    free(g_DisplayData.midBuffer);
    free(g_DisplayData.backBuffer);
}

static void vga_swap_buffers(void)
{
    // Current front buffer becomes the back buffer
    // Current mid buffer becomes the front buffer
    // Current back buffer becomes the mid buffer

    DisplayPixel *pCurrBackBuf = g_DisplayData.backBuffer;
    DisplayPixel *pCurrMidBuf = g_DisplayData.midBuffer;
    DisplayPixel *pCurrFrontBuf = g_DisplayData.frontBuffer;

    g_DisplayData.frontBuffer = pCurrMidBuf;
    g_DisplayData.midBuffer = pCurrBackBuf;
    g_DisplayData.backBuffer = pCurrFrontBuf;
}

static void vga_flush_frame_buffer(DisplayPixel *pFramebuffer)
{
    // Set flush range to the active frame buffer before requesting a D$ flush
    vga_ptr[VGA_REG_SET_FLUSH_START_ADDR] = (uint32_t)pFramebuffer;
    vga_ptr[VGA_REG_SET_FLUSH_END_ADDR] = (uint32_t)pFramebuffer + (sizeof(DisplayPixel) * SCREEN_WIDTH * SCREEN_HEIGHT);

    // Flush D$ so that VGA scan-out will have fetched coherent data
    asm volatile("csrw pmpcfg0, x0");

    // Reset the flush range
    vga_ptr[VGA_REG_SET_FLUSH_START_ADDR] = 0x0;
    vga_ptr[VGA_REG_SET_FLUSH_END_ADDR] = UINT32_MAX;
}

void vga_program_fb_base_addr(DisplayPixel *currentFBBase)
{
    vga_ptr[VGA_REG_SET_FB_BASE_ADDR] = (uint32_t)currentFBBase;
}

void vga_present(void)
{
    // Prepare present buffers
    vga_swap_buffers();

    // Flush frame buffer contents in D$ to main memory
    vga_flush_frame_buffer(g_DisplayData.frontBuffer);

    // Re-program front buffer to be displayed
    vga_program_fb_base_addr(g_DisplayData.frontBuffer);
}

DisplayPixel *vga_get_back_buffer(void)
{
    return g_DisplayData.backBuffer;
}