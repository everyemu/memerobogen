#ifndef GP2X_H
#define GP2X_H

extern const char* get_resource_path(char* file);
extern const char* get_documents_path(char* file);

void gp2x_init(void);
void gp2x_deinit(void);

/* video */
#define gp2x_screen videobuffer
#define gp2x_video_changemode(x) do{}while(0)
#define gp2x_video_changemode2(x) do{}while(0)
#define gp2x_video_setpalette(x1,x2) do{}while(0)
#define gp2x_video_RGB_setscaling(x1,x2,x3) do{}while(0)
#define gp2x_video_wait_vsync() do{}while(0)
#define gp2x_video_flush_cache() do{}while(0)
#define gp2x_memcpy_buffers(x1,x2,x3,x4) do{}while(0)
#define gp2x_memcpy_all_buffers(x1,x2,x3) do{}while(0)
#define gp2x_memset_all_buffers(x1,x2,x3) do{}while(0)
#define gp2x_pd_clone_buffer2() do{}while(0)

/* sound */
void gp2x_start_sound(int soundlen);
void gp2x_stop_sound();
void gp2x_sound_write(void *buff, int len);
void gp2x_sound_volume(u32 volume_up);
void gp2x_flipscreen(void);

/* joy */
unsigned long gpsp_gp2x_joystick_read(void);

extern void updateScreen();
extern unsigned long joystick_read(void);
extern int __emulation_saving;
extern int __emulation_run;
extern float __audioVolume;

enum  { GP2X_UP=0x1,       GP2X_LEFT=0x4,       GP2X_DOWN=0x10,  GP2X_RIGHT=0x40,
	GP2X_START=1<<8,   GP2X_SELECT=1<<9,    GP2X_L=1<<10,    GP2X_R=1<<11,
	GP2X_A=1<<12,      GP2X_B=1<<13,        GP2X_X=1<<14,    GP2X_Y=1<<15,
GP2X_VOL_UP=1<<23, GP2X_VOL_DOWN=1<<22, GP2X_PUSH=1<<27 };

#endif
