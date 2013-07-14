/*

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#ifndef GPSPHONE_IPHONE_H
#define GPSPHONE_IPHONE_H

#import <AudioToolbox/AudioQueue.h>
#import "../../../Frameworks/CoreSurface.h"

#define BIT_U			0x1
#define BIT_D			0x10
#define BIT_L 			0x4
#define BIT_R		 	0x40
#define BIT_SEL			(1<<9)
#define BIT_ST			(1<<8)
#define BIT_LPAD		(1<<10)
#define BIT_RPAD		(1<<11)
#define BIT_HARDA		(1<<12)
#define BIT_HARDB		(1<<13)
#define BIT_HARDX		(1<<14)
#define BIT_HARDY		(1<<15)
#define BIT_VOL_UP		(1<<23)
#define BIT_VOL_DOWN	(1<<22)
#define BIT_PUSH		(1<<27)

#define BIT_A			BIT_HARDB
#define BIT_B			BIT_HARDX

extern void updateScreen();

extern void gp2x_flipscreen();

typedef unsigned char byte;

struct app_Preferences
{
  int frameskip;
  byte debug;
  byte canDeleteROMs;
  byte autoSave;
  byte landscape;
  byte allowSuspend;
  bool smoothscaling;
  byte muted;
	byte volume;
	bool gameaudio;
	byte cheat1;
	byte cheat2;
	byte cheat3;
	byte cheat4;
	byte cheat5;
	byte cheat6;
	byte cheat7;
	byte cheat8;
  char skinfile[256];
};

void setDefaultPreferences();
int app_SavePreferences();
int app_LoadPreferences();

extern unsigned long gp2x_pad_status;

/* STUBs to emulator core */

void *app_Thread_Start(void *args);
void *app_Thread_Resume(void *args);
void app_Begin(void);
void app_End(void);
void app_Resume(void);
int app_LoadROM(const char *fileName);
void app_DeleteTempState(void);

void app_SetSvsFile(char* filename);

void app_MuteSound(void);
void app_DemuteSound(void);
float app_GetAudioVolume(void);
int app_OpenSound();
void app_CloseSound(void);
void app_StopSound();
void app_StartSound();
FILE* fopen_home(char* filename, char* fileop);

extern byte IS_DEBUG;
extern byte IS_CHANGING_ORIENTATION;
extern unsigned short  *screenbuffer;
extern int __screenOrientation;
extern struct app_Preferences preferences;

#ifndef GPSPHONE_DEBUG
#define LOGDEBUG(...) while(0){}
#else
void LOGDEBUG (const char *err, ...) ;
#endif

#endif
