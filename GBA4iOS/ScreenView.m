//
//  ScreenView.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

//#define WITH_SIMULATOR 1

#import "GBAMasterViewController.h"
#import "../iGBA/Frameworks/GraphicsServices.h"
#import "../iGBA/Frameworks/UIKit-Private/UIView-Geometry.h"
#import "../iGBA/Frameworks/CoreSurface.h"
#import "ScreenView.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

CoreSurfaceBufferRef screenSurface;
static ScreenView *sharedInstance = nil;

void updateScreen()
{
	[ sharedInstance performSelectorOnMainThread:@selector(updateScreen) withObject:nil waitUntilDone: NO ];
}

@implementation ScreenView 
- (id)initWithFrame:(CGRect)frame
{
  LOGDEBUG("ScreenView.initWithFrame()");

  rect = frame;
  if (self == [ super initWithFrame:frame ])
  {
    sharedInstance = self;
    [ self initializeGraphics ]; 
  }
  return self;
}

- (void)updateScreen
{
  [ self setNeedsDisplay ];
}

- (void)dealloc {
  LOGDEBUG("ScreenView.dealloc()");
//  [ screenLayer release ];
//  [ super dealloc ];
}

- (void)drawRect:(CGRect)rect
{
}

- (void)initializeGraphics
{
#ifndef WITH_SIMULATOR
  CFMutableDictionaryRef dict;
  int w, h;
  int pitch, allocSize;
  char* pixelFormat = "565L";

  LOGDEBUG("ScreenView.initGraphics()");

  /* Landscape Resolutions */
  w = 240;
  h = 160;

  pitch = w * 2;
  allocSize = 2 * w * h;

  LOGDEBUG("ScreenView.initializeGraphics: Allocating for %d x %d", w, h);
  
  LOGDEBUG("ScreenView.initGraphics(): Initializing dictionary");
  dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
      &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal, kCFBooleanTrue);
  CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,
      CFSTR("PurpleGFXMem"));
  CFDictionarySetValue(dict, kCoreSurfaceBufferPitch,
      CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
  CFDictionarySetValue(dict, kCoreSurfaceBufferWidth,
      CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &w));
  CFDictionarySetValue(dict, kCoreSurfaceBufferHeight,
      CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &h));
  CFDictionarySetValue(dict, kCoreSurfaceBufferPixelFormat,
      CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
  CFDictionarySetValue(dict, kCoreSurfaceBufferAllocSize,
      CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize));

  LOGDEBUG("ScreenView.initGraphics(): Creating CoreSurface buffer");
  screenSurface = CoreSurfaceBufferCreate(dict);

  LOGDEBUG("ScreenView.initGraphics(): Locking CoreSurface buffer");
  CoreSurfaceBufferLock(screenSurface, 3);

  LOGDEBUG("ScreenView.initGraphics(): Creating screen layer");
  screenLayer = [CALayer layer]; //[[CALayer layer] retain];
  
  [screenLayer setFrame: CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height)];

  [screenLayer setContents: (__bridge id)(screenSurface)];
  [screenLayer setOpaque: YES];

  if(preferences.smoothscaling)
  {
    [screenLayer setMagnificationFilter:kCAFilterLinear];
    [screenLayer setMinificationFilter:kCAFilterLinear];
  }
  else
  {
    [screenLayer setMagnificationFilter:kCAFilterNearest];
    [screenLayer setMinificationFilter:kCAFilterNearest];
  }
  
  LOGDEBUG("ScreenView.initGraphics(): Adding layer as sublayer");
  [self.layer addSublayer: screenLayer ];

  LOGDEBUG("ScreenView.initGraphics(): Unlocking CoreSurface buffer");
  CoreSurfaceBufferUnlock(screenSurface);

  screenbuffer = CoreSurfaceBufferGetBaseAddress(screenSurface);
  LOGDEBUG("ScreenView.initializeGraphics: New base address %p", screenbuffer);
/*    
  timer = [NSTimer scheduledTimerWithTimeInterval:0.100
               target:self
               selector:@selector(updateScreen)
               userInfo:nil
               repeats:YES];
*/                
  LOGDEBUG("ScreenView.initGraphics(): Done");
  
  //[self rotateForDeviceOrientation:UIDeviceOrientationPortrait]; // Sets default layout
#endif
}

- (void)rotateForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
  int skinfound;
  int skinimage;
  int islandscape = 0;
  char screensize[16];

  if(deviceOrientation != UIDeviceOrientationLandscapeLeft   &&
      deviceOrientation != UIDeviceOrientationLandscapeRight  &&
      deviceOrientation != UIDeviceOrientationPortrait )
  {
    return;
  }
  
  [CATransaction begin];
  [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
  
  if(deviceOrientation == UIDeviceOrientationLandscapeLeft)
  {
    islandscape = 1;
    //self.transform = CGAffineTransformMakeRotation(RADIANS(90.0));
  }
  else if(deviceOrientation == UIDeviceOrientationLandscapeRight)
  {
    islandscape = 1;
    //self.transform = CGAffineTransformMakeRotation(RADIANS(270.0));
  }
  else
  {
    islandscape = 0;
    //self.transform = CGAffineTransformMakeRotation(RADIANS(0.0));
  }

  if(islandscape)
  {
    snprintf(screensize, 16, "%dx%d", (int)([UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale]), (int)([UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale]));
  }
  else
  {
    snprintf(screensize, 16, "%dx%d", (int)([UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale]), (int)([UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale]));
  }
  
  skinfound = -1;
  
  NSLog(@"screenview screensize actual %s", screensize);
  
  for(skinimage = 0; skinimage < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; skinimage++)
  {
    if(strncasecmp(controllerskin.images[skinimage].devicetype, screensize, 16) == 0)
    {
      skinfound = skinimage;
    }
  }
  
  if(skinfound == -1)
  {
    NSLog(@"screenview skin not found!");
    return;
  }
  
  NSLog(@"screenview skin found %d", skinfound);
/*
  if(islandscape)
  {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  }
  else
  {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.bounds = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
  }
*/
  [screenLayer setFrame:CGRectMake((float)controllerskin.images[skinfound].screencoords[0] / [[UIScreen mainScreen] scale], (float)controllerskin.images[skinfound].screencoords[1] / [[UIScreen mainScreen] scale], (float)controllerskin.images[skinfound].screencoords[2] / [[UIScreen mainScreen] scale], (float)controllerskin.images[skinfound].screencoords[3] / [[UIScreen mainScreen] scale])];

  [CATransaction commit];
}

@end
