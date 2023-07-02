/* Apple2Arduino firmware */
/* by Daniel L. Marks */

/*
   Copyright (c) 2022 Daniel Marks

  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#pragma once

#include "ff.h"
#include "config.h"

extern "C" {
#ifdef USE_MEM_CHECK
  void check_memory(int id);
#endif
}

#ifdef DEBUG_BYTES
extern uint8_t DEBUG_counter;
extern uint8_t DEBUG_data[DEBUG_BYTES];
#endif

#ifdef USE_MEM_CHECK
  #define CHECK_MEM(id) check_memory(id)
#else
  #define CHECK_MEM(id) {}
#endif

