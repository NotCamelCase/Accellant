#pragma once

#include <iostream>
#include <vector>
#include <cassert>
#include <cstdint>
#include <chrono>
#include <cstring>

#include "../../../kernel/vga_core.h"

#define GLM_FORCE_INLINE
#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include "../../../deps/glm/vec3.hpp"
#include "../../../deps/glm/vec4.hpp"
#include "../../../deps/glm/mat4x4.hpp"
#include "../../../deps/glm/gtc/matrix_transform.hpp"