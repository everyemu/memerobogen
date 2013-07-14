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

#include "common.h"
#include <pthread.h>
#include "helpers.h"
#include "iphone.h"

//#define WITH_INTERPRETER 1

void gp2x_quit();
 
char save_filename[512];
int __cheatmenu_run = 0;
int __emulation_run = 0;
int __emulation_paused = 0;

timer_type timer[4];

//debug_state current_debug_state = COUNTDOWN_BREAKPOINT;
//debug_state current_debug_state = PC_BREAKPOINT;
u32 breakpoint_value = 0x7c5000;
debug_state current_debug_state = RUN;
//debug_state current_debug_state = STEP_RUN;

//u32 breakpoint_value = 0;

frameskip_type current_frameskip_type = auto_frameskip;
u32 random_skip = 0;

static u32 fps = 60;
static u32 frames_drawn = 60;
int __saved = 0;
int __autosave = 0;
u32 frameskip_value = 6;
u32 gp2x_frameskip_value = 6;

u64 frame_count_initial_timestamp = 0;
u64 last_frame_interval_timestamp;
u64 last_frame_value_timestamp;
u32 gp2x_fps_debug = 0;
u32 global_cycles_per_instruction = 1;
u32 real_frame_count = 0;
u32 virtual_frame_count = 0;
u32 num_skipped_frames = 0;
u32 interval_skipped_frames;
u32 frames;
u32 skipped_frames = 0;
const u32 frame_interval = 60;

u32 skip_next_frame = 0;

u32 frameskip_counter = 0;

u32 cpu_ticks = 0;
u32 frame_ticks = 0;

u32 execute_cycles = 960;
s32 video_count = 960;
u32 ticks;

u32 arm_frame = 0;
u32 thumb_frame = 0;
u32 last_frame = 0;

u32 cycle_memory_access = 0;
u32 cycle_pc_relative_access = 0;
u32 cycle_sp_relative_access = 0;
u32 cycle_block_memory_access = 0;
u32 cycle_block_memory_sp_access = 0;
u32 cycle_block_memory_words = 0;
u32 cycle_dma16_words = 0;
u32 cycle_dma32_words = 0;
u32 flush_ram_count = 0;
u32 gbc_update_count = 0;
u32 oam_update_count = 0;

u32 synchronize_flag = 1;

u32 update_backup_flag = 1;
u32 clock_speed = 333;


#define check_count(count_var)                                                \
  if(count_var < execute_cycles)                                              \
    execute_cycles = count_var;                                               \

#define check_timer(timer_number)                                             \
  if(timer[timer_number].status == TIMER_PRESCALE)                            \
    check_count(timer[timer_number].count);                                   \

#define update_timer(timer_number)                                            \
  if(timer[timer_number].status != TIMER_INACTIVE)                            \
  {                                                                           \
    if(timer[timer_number].status != TIMER_CASCADE)                           \
    {                                                                         \
      timer[timer_number].count -= execute_cycles;                            \
      io_registers[REG_TM##timer_number##D] =                                 \
       -(timer[timer_number].count >> timer[timer_number].prescale);          \
    }                                                                         \
                                                                              \
    if(timer[timer_number].count <= 0)                                        \
    {                                                                         \
      if(timer[timer_number].irq == TIMER_TRIGGER_IRQ)                        \
        irq_raised |= IRQ_TIMER##timer_number;                                \
                                                                              \
      if((timer_number != 3) &&                                               \
       (timer[timer_number + 1].status == TIMER_CASCADE))                     \
      {                                                                       \
        timer[timer_number + 1].count--;                                      \
        io_registers[REG_TM0D + (timer_number + 1) * 2] =                     \
         -(timer[timer_number + 1].count);                                    \
      }                                                                       \
                                                                              \
      if(timer_number < 2)                                                    \
      {                                                                       \
        if(timer[timer_number].direct_sound_channels & 0x01)                  \
          sound_timer(timer[timer_number].frequency_step, 0);                 \
                                                                              \
        if(timer[timer_number].direct_sound_channels & 0x02)                  \
          sound_timer(timer[timer_number].frequency_step, 1);                 \
      }                                                                       \
                                                                              \
      timer[timer_number].count +=                                            \
       (timer[timer_number].reload << timer[timer_number].prescale);          \
    }                                                                         \
  }                                                                           \

u8 *file_ext[] = { ".gba", ".bin", ".zip", NULL };

#ifdef ARM_ARCH
void ChangeWorkingDirectory(char *exe)
{
#ifndef _WIN32_WCE
  char main_path[512];
  char *s;
  
  snprintf(main_path, 512, "%s", exe);
  s = strrchr(main_path, '/');
  if (s != NULL) {
    *s = '\0';
    chdir(main_path);
    *s = '/';
  }
#endif
}
#endif

void init_main()
{
  u32 i;

  skip_next_frame = 0;

  for(i = 0; i < 4; i++)
  {
    dma[i].start_type = DMA_INACTIVE;
    dma[i].direct_sound_channel = DMA_NO_DIRECT_SOUND;
    timer[i].status = TIMER_INACTIVE;
    timer[i].reload = 0x10000;
    timer[i].stop_cpu_ticks = 0;
  }

  timer[0].direct_sound_channels = TIMER_DS_CHANNEL_BOTH;
  timer[1].direct_sound_channels = TIMER_DS_CHANNEL_NONE;

  cpu_ticks = 0;
  frame_ticks = 0;

  execute_cycles = 960;
  video_count = 960;
}


#ifdef GP2X_BUILD
int iphone_main(char* load_filename)
#else
int main(int argc, char *argv[])
#endif
{
  u32 i;
  u32 vcount = 0;
  u32 ticks;
  u32 dispstat;
#ifndef GP2X_BUILD
  u8 load_filename[512];
#endif
  u8 bios_filename[512];

  cheatsNumber = 0;
    
#ifdef GP2X_BUILD
  gp2x_frameskip_value = 6;
  frame_count_initial_timestamp = 0;
  last_frame_interval_timestamp = 0;
  last_frame_value_timestamp = 0;
  real_frame_count = 0;
  virtual_frame_count = 0;
  num_skipped_frames = 0;
  interval_skipped_frames = 0;
  frames = 0;
  skipped_frames = 0;
  fps = 60;
  frames_drawn = 60;

  save_filename[0] = 0;
  __saved = 0;
  gp2x_init();
#endif
/*
#ifdef GP2X_BUILD
  if(gp2x_load_mmuhack() == -1)
    delay_us(2500000);
#endif
*/
#ifdef PSP_BUILD
  sceKernelRegisterSubIntrHandler(PSP_VBLANK_INT, 0,
   vblank_interrupt_handler, NULL);
  sceKernelEnableSubIntr(PSP_VBLANK_INT, 0);
#else
//  freopen("CON", "wb", stdout);
#endif

  extern char *cpu_mode_names[];

  init_gamepak_buffer();

	ChangeWorkingDirectory(get_documents_path("gpSPhone"));
  gamepak_filename[0] = 0;

#ifdef PSP_BUILD
  delay_us(2500000);
#endif

  init_main();
  init_sound();

  init_input();

/*
#ifdef GP2X_BUILD
  // Overclocking GP2X and MMU patch goes here
  gp2x_overclock();
#endif
*/
#ifdef GP2X_BUILD	

	if(load_bios(get_resource_path("gba_bios.bin")) == -1 && load_bios(get_documents_path("gba_bios.bin")) == -1 &&
     load_bios(get_resource_path("gba_bios.zip")) == -1 && load_bios(get_documents_path("gba_bios.zip")) == -1)
	{
		gui_action_type gui_action = CURSOR_NONE;
		print_string("gpSPhone needs a Gameboy Advance BIOS.", 0xFFFF, 0x000, 0, 0);
		print_string("On the main ROM select screen, choose", 0xFFFF, 0x000, 0, 10);
		print_string("the upper right icon to find ROMs.", 0xFFFF, 0x000, 0, 20);
		print_string("Download a legally obtained BIOS.", 0xFFFF, 0x000, 0, 30);
		print_string("The filename should be gba_bios.bin", 0xFFFF, 0x000, 0, 40);
		print_string("or gba_bios.zip and is case-sensitive.", 0xFFFF, 0x000, 0, 50);
		
		gp2x_flipscreen();
		
		while(gui_action == CURSOR_NONE)
		{
			gui_action = get_gui_input();
			delay_us(15000);
		}
		
		quit();
	}
	if(bios_rom[0] != 0x18)
	{
		gui_action_type gui_action = CURSOR_NONE;
		print_string("You have an incorrect BIOS image.", 0xFFFF, 0x000, 0, 0);
		print_string("While many games will work fine, some will not.", 0xFFFF, 0x000, 0, 10);
		print_string("The correct BIOS has an md5 sum of:", 0xFFFF, 0x000, 0, 20);
		print_string("a860e8c0b6d573d191e4ec7db1b1e4f6", 0xFFFF, 0x000, 0, 30);
		
		gp2x_flipscreen();
		
		while(gui_action == CURSOR_NONE)
		{
			gui_action = get_gui_input();
			delay_us(15000);
		}

		quit();
	}	

#else
  if(load_bios("gba_bios.bin") == -1)
  {
    gui_action_type gui_action = CURSOR_NONE;

    debug_screen_start();
    debug_screen_printl("Sorry, but gpSP requires a Gameboy Advance BIOS   ");
    debug_screen_printl("image to run correctly. Make sure to get an       ");
    debug_screen_printl("authentic one, it'll be exactly 16384 bytes large ");
    debug_screen_printl("and should have the following md5sum value:       ");
    debug_screen_printl("                                                  ");
    debug_screen_printl("a860e8c0b6d573d191e4ec7db1b1e4f6                  ");
    debug_screen_printl("                                                  ");
    debug_screen_printl("When you do get it name it gba_bios.bin and put it");
    debug_screen_printl("in the same directory as gpSP.                    ");
    debug_screen_printl("                                                  ");
    debug_screen_printl("Press any button to exit.                         ");

    debug_screen_update();

    while(gui_action == CURSOR_NONE)
    {
      gui_action = get_gui_input();
      delay_us(15000);
    }

    debug_screen_end();

    quit();
  }
	if(bios_rom[0] != 0x18)
	{
		gui_action_type gui_action = CURSOR_NONE;
		
		debug_screen_start();
		debug_screen_printl("You have an incorrect BIOS image.                 ");
		debug_screen_printl("While many games will work fine, some will not. It");
		debug_screen_printl("is strongly recommended that you obtain the       ");
		debug_screen_printl("correct BIOS file. Do NOT report any bugs if you  ");
		debug_screen_printl("are seeing this message.                          ");
		debug_screen_printl("                                                  ");
		debug_screen_printl("Press any button to resume, at your own risk.     ");
		
		debug_screen_update();
		
		while(gui_action == CURSOR_NONE)
		{
			gui_action = get_gui_input();
			delay_us(15000);
		}
		
		debug_screen_end();
		quit();
	}
	
#endif

#ifndef GP2X_BUILD
  if(argc > 1)
  {
    if(load_gamepak(argv[1]) == -1)
    {
#ifdef PC_BUILD
      printf("Failed to load gamepak %s, exiting.\n", load_filename);
#endif
      exit(-1);
    }

    set_gba_resolution(screen_scale);
    video_resolution_small();

	reset_gba();
	reg[CHANGED_PC_STATUS] = 1;
  }
  else
#endif
  {
#ifdef GP2X_BUILD
  
  if( (!strcasecmp(load_filename + (strlen(load_filename)-4), ".svs")) )
  {
    u32 pos;
    sprintf(save_filename, "%s", load_filename);
    pos = strlen(load_filename)-18;
    load_filename[pos] = '\0';  
    __saved = 1;
    /*
    if( strcasecmp(load_filename + (strlen(load_filename)-4), ".gba") &&
       strcasecmp(load_filename + (strlen(load_filename)-4), ".zip") )
    {
      sprintf(load_filename, "%s", save_filename);
      pos = strlen(load_filename)-4;
      load_filename[pos] = '\0';
      sprintf(load_filename, "%s.gba", load_filename);
    }
    */
  }
    
  if(load_gamepak(load_filename) == -1)
  {
	  gp2x_quit();
	  pthread_exit(NULL);
  }
  
  reset_gba();
  reg[CHANGED_PC_STATUS] = 1;
#else
    if(load_file(file_ext, load_filename) == -1)
    {
      menu(copy_screen());
    }
    else
    {
      if(load_gamepak(load_filename) == -1)
      {
#ifdef PC_BUILD
        printf("Failed to load gamepak %s, exiting.\n", load_filename);
#endif
        exit(-1);
      }

      set_gba_resolution(screen_scale);
      video_resolution_small();

       reset_gba();
       reg[CHANGED_PC_STATUS] = 1;
    }
#endif
  }
/*
	cheats[0].cheat_active = preferences.cheat1;
	cheats[1].cheat_active = preferences.cheat2;
	cheats[2].cheat_active = preferences.cheat3;
	cheats[3].cheat_active = preferences.cheat4;
	cheats[4].cheat_active = preferences.cheat5;
	cheats[5].cheat_active = preferences.cheat6;
	cheats[6].cheat_active = preferences.cheat7;
	cheats[7].cheat_active = preferences.cheat8;
*/	
  last_frame = 0;
  get_ticks_us(&frame_count_initial_timestamp);
  get_ticks_us(&last_frame_interval_timestamp);
#ifndef WITH_INTERPRETER
  execute_arm_translate(execute_cycles);
#else
  execute_arm(execute_cycles);
#endif
  return 0;
}

void print_memory_stats(u32 *counter, u32 *region_stats, char *stats_str)
{
  u32 other_region_counter = region_stats[0x1] + region_stats[0xE] +
   region_stats[0xF];
  u32 rom_region_counter = region_stats[0x8] + region_stats[0x9] +
   region_stats[0xA] + region_stats[0xB] + region_stats[0xC] +
   region_stats[0xD];
  u32 _counter = *counter;

  printf("memory access stats: %s (out of %d)\n", stats_str, _counter);
  printf("bios: %f%%\tiwram: %f%%\tewram: %f%%\tvram: %f\n",
   region_stats[0x0] * 100.0 / _counter, region_stats[0x3] * 100.0 /
   _counter,
   region_stats[0x2] * 100.0 / _counter, region_stats[0x6] * 100.0 /
   _counter);

  printf("oam: %f%%\tpalette: %f%%\trom: %f%%\tother: %f%%\n",
   region_stats[0x7] * 100.0 / _counter, region_stats[0x5] * 100.0 /
   _counter,
   rom_region_counter * 100.0 / _counter, other_region_counter * 100.0 /
   _counter);

  *counter = 0;
  memset(region_stats, 0, sizeof(u32) * 16);
}

u32 event_cycles = 0;
const u32 event_cycles_trigger = 60 * 5;
u32 no_alpha = 0;

void trigger_ext_event()
{
}

u32 update_gba()
{
  irq_type irq_raised = IRQ_NONE;
  int current_synchronize_flag;

  if (__saved == 1) 
  {
    current_synchronize_flag = synchronize_flag;
    synchronize_flag = 0;
  }

  do
  {
    cpu_ticks += execute_cycles;

    reg[CHANGED_PC_STATUS] = 0;



    if(gbc_sound_update)
    {
      gbc_update_count++;
      update_gbc_sound(cpu_ticks);
      gbc_sound_update = 0;
    }

    update_timer(0);
    update_timer(1);
    update_timer(2);
    update_timer(3);

    video_count -= execute_cycles;

    if(video_count <= 0)
    {
      u32 vcount = io_registers[REG_VCOUNT];
      u32 dispstat = io_registers[REG_DISPSTAT];

      if((dispstat & 0x02) == 0)
      {
        // Transition from hrefresh to hblank
        video_count += (272);
        dispstat |= 0x02;

        if((dispstat & 0x01) == 0)
        {
          u32 i;
          if(oam_update)
            oam_update_count++;

          if(no_alpha)
            io_registers[REG_BLDCNT] = 0;
          update_scanline();

          // If in visible area also fire HDMA
          for(i = 0; i < 4; i++)
          {
            if(dma[i].start_type == DMA_START_HBLANK)
              dma_transfer(dma + i);
          }
        }

        if(dispstat & 0x10)
          irq_raised |= IRQ_HBLANK;
      }
      else
      {
        // Transition from hblank to next line
        video_count += 960;
        dispstat &= ~0x02;

        vcount++;

        if(vcount == 160)
        {
          // Transition from vrefresh to vblank
          u32 i;

          dispstat |= 0x01;
          if(dispstat & 0x8)
          {
            irq_raised |= IRQ_VBLANK;
          }

          affine_reference_x[0] =
           (s32)(address32(io_registers, 0x28) << 4) >> 4;
          affine_reference_y[0] =
           (s32)(address32(io_registers, 0x2C) << 4) >> 4;
          affine_reference_x[1] =
           (s32)(address32(io_registers, 0x38) << 4) >> 4;
          affine_reference_y[1] =
           (s32)(address32(io_registers, 0x3C) << 4) >> 4;

          for(i = 0; i < 4; i++)
          {
            if(dma[i].start_type == DMA_START_VBLANK)
              dma_transfer(dma + i);
          }
        }
        else

        if(vcount == 228)
        {
          // Transition from vblank to next screen
          dispstat &= ~0x01;

    			/*if( __cheatmenu_run )
    			{
    				menu(NULL);
    				__cheatmenu_run = 0;
    			}*/
          /*
          frame_ticks++;
    			if(__autosave && frame_ticks >= 18000 )
    			{
    				char filename[260];
    				unsigned short *current_screen;
    				sprintf(filename, "%s-last-autosave.svs", gamepak_filename);
			
    				print_string("autosaving", 0xFFFF, 0x000, 0, 10);
    				gp2x_flipscreen();
			
    				current_screen = copy_screen();
    				save_state(filename, current_screen);
    				free(current_screen);
			
    				frame_ticks = 0;
    			}
          */
          while(__emulation_paused)
          {
            usleep(16666);
            if (__emulation_run == 0)
            {
              pthread_exit(NULL);
            }
          }

          if(update_input())
            continue;

          update_gbc_sound(cpu_ticks);
          synchronize();

          update_screen();

          if(update_backup_flag)
            update_backup();

          cheatsCheckKeys(gpsp_gp2x_joystick_read(), gpsp_gp2x_joystick_read() >> 10);

          event_cycles++;
          if(event_cycles == event_cycles_trigger)
          {
            trigger_ext_event();
            continue;
          }

          vcount = 0;
        }

        if(vcount == (dispstat >> 8))
        {
          // vcount trigger
          dispstat |= 0x04;
          if(dispstat & 0x20)
          {
            irq_raised |= IRQ_VCOUNT;
          }
        }
        else
        {
          dispstat &= ~0x04;
        }

        io_registers[REG_VCOUNT] = vcount;
      }
      io_registers[REG_DISPSTAT] = dispstat;
    }

    if(irq_raised)
      raise_interrupt(irq_raised);

    execute_cycles = video_count;

    check_timer(0);
    check_timer(1);
    check_timer(2);
    check_timer(3);
  } while(reg[CPU_HALT_STATE] != CPU_ACTIVE);
  
  if (__saved == 1) 
  {
    load_state(save_filename);
    __saved = 2;
  }
  else if(__saved == 2)
  {
    synchronize_flag = current_synchronize_flag;
    __saved = 3;
  }
  
  return execute_cycles;
}

void save_game_state(char *filepath) {
  u16 *current_screen;
  
  if(update_backup_flag)
    update_backup_force();

  current_screen = copy_screen();
  save_state(filepath, current_screen);
  free(current_screen);
}

void load_game_state(char *filepath) {
  load_state(filepath);
}

u64 last_screen_timestamp = 0;

void synchronize()
{
  u64 new_ticks;
  if(gp2x_fps_debug)
  {
    char print_buffer[128];
    sprintf(print_buffer, "%d (%d)", fps, num_skipped_frames);
    print_string(print_buffer, 0xFFFF, 0x000, 0, 0);
  }

  if(preferences.frameskip == 5)
  {
    current_frameskip_type = auto_frameskip;
    frameskip_value = 6;
  }
  else
  {
    current_frameskip_type = manual_frameskip;
    frameskip_value = preferences.frameskip;
  }
  
  get_ticks_us(&new_ticks);

  skip_next_frame = 0;
  virtual_frame_count++;

  real_frame_count = ((new_ticks -
    frame_count_initial_timestamp) * 60) / 1000;
  
  if(real_frame_count >= virtual_frame_count)
  {
    if((real_frame_count > virtual_frame_count) &&
     (current_frameskip_type == auto_frameskip) &&
     (num_skipped_frames < frameskip_value))
    {
      skip_next_frame = 1;
      num_skipped_frames++;
    }
    else
    {
      virtual_frame_count = real_frame_count;
      num_skipped_frames = 0;
    }
  }
  else
  {
    if(synchronize_flag)
    {
      usleep((virtual_frame_count - real_frame_count) * (1000000.0 / 60.0));
    }
    virtual_frame_count = real_frame_count + 1;
    num_skipped_frames = 0;
  }

  frames++;
  
  if(new_ticks - last_frame_interval_timestamp >= 1000)
  {
    fps = frames;

    virtual_frame_count = 0;
    get_ticks_us(&frame_count_initial_timestamp);
  
    last_frame_interval_timestamp = new_ticks;
    interval_skipped_frames = 0;
    frames = 0;
  }

  if(current_frameskip_type == manual_frameskip)
  {
    frameskip_counter = (frameskip_counter + 1) %
     (frameskip_value + 1);
    if(random_skip)
    {
      if(frameskip_counter != (rand() % (frameskip_value + 1)))
        skip_next_frame = 1;
    }
    else
    {
      if(frameskip_counter)
        skip_next_frame = 1;
    }
  }

  interval_skipped_frames += skip_next_frame;

  if(!synchronize_flag)
    print_string("FAST FORWARDING", 0xFFFF, 0x000, 0, 0);
}

void quit()
{
  __emulation_run = 0;
}

void reset_gba()
{
  init_main();
  init_memory();
  init_cpu();
  reset_sound();
}

s32 load_game_config_file()
{
  u32 i;

  random_skip = 0;
  clock_speed = 333;

  cheatsNumber = 0;
  return -1;
}

u32 file_length(u8 *dummy, FILE *fp)
{
  u32 length;

  fseek(fp, 0, SEEK_END);
  length = ftell(fp);
  fseek(fp, 0, SEEK_SET);

  return length;
}

void delay_us(u32 us_count)
{
  usleep(us_count);
}

void get_ticks_us(u64 *ticks_return)
{
  struct timeval current_time;
  gettimeofday(&current_time, NULL);

  *ticks_return =
   (u64)current_time.tv_sec * 1000 + current_time.tv_usec / 1000;
}

void change_ext(u8 *src, u8 *buffer, u8 *extension)
{
  u8 *dot_position;
  strcpy(buffer, src);
  dot_position = strrchr(buffer, '.');

  if(dot_position)
    strcpy(dot_position, extension);
}

#define main_savestate_builder(type)                                          \
void main_##type##_savestate(file_tag_type savestate_file)                    \
{                                                                             \
  file_##type##_variable(savestate_file, cpu_ticks);                          \
  file_##type##_variable(savestate_file, execute_cycles);                     \
  file_##type##_variable(savestate_file, video_count);                        \
  file_##type##_array(savestate_file, timer);                                 \
}                                                                             \

main_savestate_builder(read_mem);
main_savestate_builder(write_mem);


void printout(void *str, u32 val)
{
  printf(str, val);
}
