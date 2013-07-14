#include "../../../common.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#import "CoreSurface.h"
#import <AudioToolbox/AudioQueue.h>
#import "iphone.h"
//#import "JoyPad.h"

const int isStereo = 0;
#define AUDIO_BUFFERS 5
#define AUDIO_BUFFER_SIZE (16 << 7)

extern void app_MuteSound(void);
extern void sound_exit(void);
extern void memory_exit(void);
extern void gp2x_quit(void);

typedef struct AQCallbackStruct {
    AudioQueueRef queue;
    UInt32 frameCount;
    AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
    AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

AQCallbackStruct in;
int soundInit = 0;
float audioVolume = 1.0f;
unsigned long gp2x_pad_status = 0;
u16* videobuffer = NULL;
struct app_Preferences preferences;
unsigned short* screenbuffer = NULL;

extern void update_sound(void *userdata, u8 *stream, int length);
extern void updateScreen();

static void AQBufferCallback(
							 void *userdata,
							 AudioQueueRef outQ,
							 AudioQueueBufferRef outQB)
{
	unsigned char *coreAudioBuffer;
  
  AudioQueueSetParameter(outQ, kAudioQueueParam_Volume, audioVolume);
  
	coreAudioBuffer = (unsigned char*) outQB->mAudioData;
	outQB->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
	//fprintf(stderr, "sound_lastlen %d\n", sound_lastlen);
	update_sound(NULL, coreAudioBuffer, AUDIO_BUFFER_SIZE);
	AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}

int initSound()
{
  Float64 sampleRate = 44100.0;
  int i;
  UInt32 bufferBytes;

  soundInit = 0;

  in.mDataFormat.mSampleRate = sampleRate;
  in.mDataFormat.mFormatID = kAudioFormatLinearPCM;
  in.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  in.mDataFormat.mBytesPerPacket    =   4;
  in.mDataFormat.mFramesPerPacket   =   isStereo ? 1 : 2;
  in.mDataFormat.mBytesPerFrame     =   isStereo ? 4 : 2;
  in.mDataFormat.mChannelsPerFrame  =   isStereo ? 2 : 1;
  in.mDataFormat.mBitsPerChannel    =   16;


  UInt32 err;
  err = AudioQueueNewOutput(&in.mDataFormat,
              AQBufferCallback,
              NULL,
              CFRunLoopGetMain(),
              kCFRunLoopDefaultMode,
              0,
              &in.queue);

  bufferBytes = AUDIO_BUFFER_SIZE;

  for (i=0; i<AUDIO_BUFFERS; i++) 
  {
    err = AudioQueueAllocateBuffer(in.queue, bufferBytes, &in.mBuffers[i]);
    /* "Prime" by calling the callback once per buffer */
    //AQBufferCallback (&in, in.queue, in.mBuffers[i]);
    in.mBuffers[i]->mAudioDataByteSize = AUDIO_BUFFER_SIZE; //samples_per_frame * 2; //inData->mDataFormat.mBytesPerFrame; //(inData->frameCount * 4 < (sndOutLen) ? inData->frameCount * 4 : (sndOutLen));
    AudioQueueEnqueueBuffer(in.queue, in.mBuffers[i], 0, NULL);
  }
  
  AudioQueueSetParameter(in.queue, kAudioQueueParam_Volume, audioVolume);

  soundInit = 1;
  err = AudioQueueStart(in.queue, NULL);

  return 0;
}

int app_OpenSound()
{
  app_CloseSound();
  
 	if( soundInit == 0 )
	{
    return initSound();
  }
  
  return 0;
}

void app_CloseSound(void)
{
	if( soundInit == 1 )
	{
		AudioQueueDispose(in.queue, true);
		soundInit = 0;
	}
}

float app_GetAudioVolume(void)
{
  return audioVolume;
}

void app_MuteSound(void)
{
  audioVolume = 0.0f;
}

void app_DemuteSound(void)
{
  audioVolume = 1.0f;
}

void app_Begin(void)
{
  if(preferences.gameaudio)
  {
    audioVolume = 1.0f;
  }
  else
  {
    audioVolume = 0.0f;
  }
}

void app_End(void)
{
  if(update_backup_flag)
    update_backup_force();

  sound_exit();
  memory_exit();
  gp2x_quit();
  __emulation_run = 0;
  soundInit = 0;
}

unsigned long gpsp_gp2x_joystick_read(void)
{
/*
  char text_buffer[256];
  unsigned short KeyData = 0;
  unsigned long AnalogData = 0;
  
  if(Read_joypad(&KeyData, &AnalogData))
  {
    snprintf(text_buffer, 256, "Digital 0x%x Analog 0x%x \n", KeyData, AnalogData);
  
    print_string(text_buffer, 0xFFFF, 0x000, 0, 0);
  }
*/
	return gp2x_pad_status;
}

static int s_oldrate = 0, s_oldbits = 0, s_oldstereo = 0;

void gp2x_sound_sync(void)
{
	//	ioctl(sounddev, SOUND_PCM_SYNC, 0);
}

void gp2x_sound_volume(u32 volume_up)
{
}

/* common */
void gp2x_init(void)
{
	if(videobuffer != NULL)
	{
		free(videobuffer);
		videobuffer = NULL;
	}
	videobuffer = (u16*)malloc(240*160*2);
	
	//Init_joypad();
  
}

void gp2x_quit(void)
{
  //End_joypad();

	if(videobuffer != NULL)
	{
		free(videobuffer);
		videobuffer = NULL;
	}
  
  screenbuffer = NULL;
}

void gp2x_flipscreen(void)
{
  if(screenbuffer)
	{
	  memcpy(screenbuffer, videobuffer, 240*160*2);
	}
  updateScreen();
}

/* lprintf */
void lprintf(const char *fmt, ...)
{
	va_list vl;
	
	va_start(vl, fmt);
	vprintf(fmt, vl);
	va_end(vl);
}

