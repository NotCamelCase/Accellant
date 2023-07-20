/**  mandel.c   by Eric R. Weeks   written 9-28-96
 **  weeks@dept.physics.upenn.edu
 **  http://dept.physics.upenn.edu/~weeks/
 **
 **  This program is public domain, but this header must be left intact
 **  and unchanged.
 **
 **  to compile:  cc -o mand mandel.c
 **
 **/

#include <cstring>

#include "../../../kernel/vga_core.h"

int main(int argc, char **ppArgv)
{
    double x, xx, y, cx, cy;
    int iteration, hx, hy;
    int itermax = 100;
    int hxres = 640;
    int hyres = 480;

    auto fb = vga_get_back_buffer();

    vga_present();

    for (hy = 1; hy <= hyres; hy++)
    {
        for (hx = 1; hx <= hxres; hx++)
        {
            cx = (((float)hx) / ((float)hxres) - 0.5) * 3.0 - 0.7;
            cy = (((float)hy) / ((float)hyres) - 0.5) * 3.0;
            x = 0.0;
            y = 0.0;

            bool done = false;

            for (iteration = 1; (iteration < itermax) && (!done); iteration++)
            {
                xx = x * x - y * y + cx;
                y = 2.0 * x * y + cy;
                x = xx;

                if (x * x + y * y > 100.0)
                    done = true;
            }

            if (!done)
                fb[hx - 1 + (hy - 1) * hxres] = { 0xff, 0xff, 0xff, 0xff };
            else
                fb[hx - 1 + (hy - 1) * hxres] = {};
        }
    }

    return 0;
}