#pragma once

#include "common.h"

namespace partI
{
    // Frame buffer dimensions
    static const auto g_scWidth = 640u;
    static const auto g_scHeight = 480u;

// Transform a given vertex in NDC [-1,1] to raster-space [0, {w|h}]
#define TO_RASTER(v) glm::vec3((g_scWidth * (v.x + 1.0f) / 2), (g_scHeight * (v.y + 1.f) / 2), 1.0f)

    void HelloTriangle()
    {
#if 1 // 2DH (x, y, w) coordinates of our triangle's vertices, in counter-clockwise order
        glm::vec3 v0(-0.5, 0.5, 1.0);
        glm::vec3 v1(0.5, 0.5, 1.0);
        glm::vec3 v2(0.0, -0.5, 1.0);
#else // Or optionally go with this set of vertices to see how this triangle would be rasterized
        glm::vec3 v0(-0.5, -0.5, 1.0);
        glm::vec3 v1(-0.5, 0.5, 1.0);
        glm::vec3 v2(0.5, 0.5, 1.0);
#endif

        // Apply viewport transformation
        v0 = TO_RASTER(v0);
        v1 = TO_RASTER(v1);
        v2 = TO_RASTER(v2);

        // Per-vertex color values
        // Notice how each of these RGB colors corresponds to each vertex defined above
        glm::vec3 c0(1, 0, 0);
        glm::vec3 c1(0, 1, 0);
        glm::vec3 c2(0, 0, 1);

        // Base vertex matrix
        glm::mat3 M = // transpose(glm::mat3(v0, v1, v2));
            {
                // Notice that glm is itself column-major)
                {v0.x, v1.x, v2.x},
                {v0.y, v1.y, v2.y},
                {v0.z, v1.z, v2.z},
            };

        // Compute the inverse of vertex matrix to use it for setting up edge functions
        M = inverse(M);

        // Calculate edge functions based on the vertex matrix once
        glm::vec3 E0 = M * glm::vec3(1, 0, 0); // == M[0]
        glm::vec3 E1 = M * glm::vec3(0, 1, 0); // == M[1]
        glm::vec3 E2 = M * glm::vec3(0, 0, 1); // == M[2]

        auto fb = vga_get_back_buffer();
        vga_present();

        // Start rasterizing by looping over pixels to output a per-pixel color
        for (auto y = 0; y < g_scHeight; y++)
        {
            for (auto x = 0; x < g_scWidth; x++)
            {
                // Sample location at the center of each pixel
                glm::vec3 sample = {x + 0.5f, y + 0.5f, 1.0f};

                // Evaluate edge functions at every fragment
                float alpha = glm::dot(E0, sample);
                float beta = glm::dot(E1, sample);
                float gamma = glm::dot(E2, sample);

                // If sample is "inside" of all three half-spaces bounded by the three edges of our triangle, it's 'on' the triangle
                if ((alpha >= 0.0f) && (beta >= 0.0f) && (gamma >= 0.0f))
                {
                    glm::vec3 color;

#if 1 // Blend per-vertex colors defined above using the coefficients from edge functions
                    color = glm::vec3(c0 * alpha + c1 * beta + c2 * gamma);
#else // Or go with flat color if that's your thing
                    color = glm::vec3(1, 0, 0);
#endif

                    DisplayPixel px = {
                        static_cast<uint8_t>(255 * glm::clamp(color.r, 0.0f, 1.0f)),
                        static_cast<uint8_t>(255 * glm::clamp(color.g, 0.0f, 1.0f)),
                        static_cast<uint8_t>(255 * glm::clamp(color.b, 0.0f, 1.0f))};

                    fb[x + y * g_scWidth] = px;
                }
            }
        }
    }
}