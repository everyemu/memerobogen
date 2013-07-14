// -*- C++ -*-
// VisualBoyAdvance - Nintendo Gameboy/GameboyAdvance (TM) emulator.
// Copyright (C) 1999-2003 Forgotten
// Copyright (C) 2004 Forgotten and the VBA development team

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2, or(at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software Foundation,
// Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#ifndef GBA_CHEATS_H
#define GBA_CHEATS_H

typedef int BOOL;
#define TRUE	1
#define FALSE	0

struct CheatsData {
  int code;
  int size;
  int status;
  BOOL enabled;
  u32 address;
  u32 value;
  u32 oldValue;
  char codestring[20];
};

#ifdef __cplusplus
extern "C" {
#endif
int cheatsFind(const char *code);
void cheatsAdd(const char *,u32,u32,int,int);
void cheatsAddCheatCode(const char *code);
BOOL cheatsAddGSACode(const char *code);
BOOL cheatsAddCBACode(const char *code);
void cheatsDelete(int number, BOOL restore);
void cheatsDeleteAll(BOOL restore);
void cheatsEnable(int number);
void cheatsDisable(int number);
void cheatsWriteMemory(u32 *, u32, u32);
void cheatsWriteHalfWord(u16 *, u16, u16);
void cheatsWriteByte(u8 *, u8);
int cheatsCheckKeys(u32,u32);
#ifdef __cplusplus
}
#endif

extern int cheatsNumber;
extern struct CheatsData cheatsList[100];
#endif // GBA_CHEATS_H
