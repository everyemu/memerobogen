/* gameplaySP
 *
 * Copyright (C) 2006 Exophase <exophase@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "../common.h"

//#define WITH_INTERPRETER 1

#ifdef WITH_INTERPRETER
u32 iwram_code_min = 0xFFFFFFFF;
u32 iwram_code_max = 0xFFFFFFFF;
u32 ewram_code_min = 0xFFFFFFFF;
u32 ewram_code_max = 0xFFFFFFFF;

// Default
u32 idle_loop_target_pc = 0xFFFFFFFF;
u32 translation_gate_target_pc[MAX_TRANSLATION_GATES];
u32 translation_gate_targets = 0;
u32 iwram_stack_optimize = 1;

void dump_translation_cache() {}
void flush_translation_cache_ram() { }
void _flush_translation_cache_ram() { }
void flush_translation_cache_rom() { }
void _flush_translation_cache_rom() { }
void flush_translation_cache_bios() { }
void _flush_translation_cache_bios() { }
#endif

// Temporary replacement of stub declarations for use with interpreter to make things easier
u8 *memory_map_read[8 * 1024];
u8 *memory_map_write[8 * 1024];

