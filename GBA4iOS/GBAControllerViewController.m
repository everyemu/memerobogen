//
//  GBAControllerViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBAControllerViewController.h"
#import "GBAMasterViewController.h"
#import "helpers.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

static const char* ON_STATES  = "wdxayhujikol";
static const char* OFF_STATES = "eczqtrfnmpgv";
static unsigned long pressedButtons = 0;
static unsigned long newtouches[10];
static unsigned long oldtouches[10];

extern void reset_sound();
extern void sound_exit();
extern void init_sound();

enum
{
  Button_DownLeft = 0, Button_Down = 1, Button_DownRight = 2, Button_Left = 3,
  Button_Right = 4, Button_UpLeft = 5, Button_Up = 6, Button_UpRight = 7,
  Button_Select = 8, Button_Start = 9, Button_A = 10, Button_B = 11,
  Button_AB = 12, Button_LPad = 13, Button_RPad = 14, Button_Menu = 15
};

unsigned int buttonBits[CONTROLLER_BUTTONS_MAX] =
{
  BIT_D|BIT_L, BIT_D, BIT_D|BIT_R, BIT_L,
  BIT_R, BIT_U|BIT_L, BIT_U, BIT_U|BIT_R,
  BIT_SEL, BIT_ST, BIT_A, BIT_B, BIT_A|BIT_B,
  BIT_LPAD, BIT_RPAD, 0
};

enum
{
  GP2X_UP=0x1,       GP2X_LEFT=0x4,       GP2X_DOWN=0x10,  GP2X_RIGHT=0x40,
  GP2X_START=1<<8,   GP2X_SELECT=1<<9,    GP2X_L=1<<10,    GP2X_R=1<<11,
  GP2X_A=1<<12,      GP2X_B=1<<13,        GP2X_X=1<<14,    GP2X_Y=1<<15,
  GP2X_VOL_UP=1<<23, GP2X_VOL_DOWN=1<<22, GP2X_PUSH=1<<27
};

void rt_dispatch_sync_on_main_thread(dispatch_block_t block)
{
  if ([NSThread isMainThread])
  {
    block();
  }
  else
  {
    dispatch_sync(dispatch_get_main_queue(), block);
  }
}

@implementation GBAControllerViewController
@synthesize imageView;
@synthesize infoButton;
@synthesize connectionButton;
@synthesize imageName;
@synthesize controllerImage;
@synthesize landscape;
@synthesize emulatorViewController;
@synthesize editingButtons;
@synthesize movingButton;
@synthesize selectedButton;
@synthesize deselectedButton;
@synthesize buttonRect;
@synthesize buttonRectEdit;
@synthesize iCadeState;
@synthesize controllerSkinActive;
@synthesize currentSkinImage;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	self.infoButton.transform = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(0.0));
  self.connectionButton.transform = CGAffineTransformRotate(CGAffineTransformIdentity, RADIANS(0.0));
	self.view.userInteractionEnabled = YES;
	self.view.multipleTouchEnabled = YES;
 
  self.buttonRects = nil;
  self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
  [self.view addSubview:self.imageView];
  //[self getController:YES];
  
  inputView = [[UIView alloc] initWithFrame:CGRectZero];
  self.controllerSkinActive = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)updateUI
{
  [self getController:YES];
}

#pragma mark - Background Image

- (void)changeBackgroundImage:(NSString *)newImageName
{
  self.imageName = newImageName;
  rt_dispatch_sync_on_main_thread(^{
      self.imageView.image = [UIImage imageWithContentsOfFile:self.imageName];
  });
  [self getController:NO];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated
{
  NSLog(@"controller viewDidAppear 1");
  self.movingButton = NO;
  self.selectedButton = NO;
  self.deselectedButton = NO;
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
  
  self.controllerSkinActive = YES;
  inputView = nil;
}

#define MyCGRectContainsPoint(rect, point)						  \
(((point.x >= rect.origin.x) &&                         \
(point.y >= rect.origin.y) &&                           \
(point.x <= (rect.origin.x) + (rect.size.width)) &&         \
(point.y <= (rect.origin.y) + (rect.size.height))) ? 1 : 0)


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	    
	int i;
  unsigned long currentPressedButtons = 0;
	NSSet *allTouches = [event allTouches];
	int touchcount = [allTouches count];

  if(self.editingButtons)
  {
    UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		if( touch != nil &&
		   ( touch.phase == UITouchPhaseEnded) )
		{
      struct CGPoint point;
      point = [touch locationInView:self.view];
      point.x *= [[UIScreen mainScreen] scale];
      point.y *= [[UIScreen mainScreen] scale];
    
      NSLog(@"touchphase [ %d ] [  x %f  ]   [  y %f  ]", touch.phase, point.x, point.y);
    }
    
    return;
  }
  
  if(!self.controllerSkinActive)
  {
    UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
		
		if( touch != nil &&
		   ( touch.phase == UITouchPhaseEnded) )
		{
      struct CGPoint point;
      point = [touch locationInView:self.view];
      
      if(point.x < 50 && point.x < 50)
      {
        [emulatorViewController pauseMenu];
      }
    }
  }
	
	for(i = 0; i < touchcount; i++) 
	{
		UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
		
		if( touch != nil && 
		   ( touch.phase == UITouchPhaseBegan ||
        touch.phase == UITouchPhaseMoved  ||
        touch.phase == UITouchPhaseStationary) )
		{
      int b;
			struct CGPoint point;
			point = [touch locationInView:self.view];
      point.x *= [[UIScreen mainScreen] scale];
      point.y *= [[UIScreen mainScreen] scale];
      
      for(b = 0; b < CONTROLLER_BUTTONS_MAX; b++)
      {
        if(MyCGRectContainsPoint(buttonRectsData[b], point))
        {
          if(b != Button_Menu)
          {
            currentPressedButtons |= buttonBits[b];
          }
          else
          {
            [emulatorViewController pauseMenu];
          }
        }
      }
		}
	}

  gp2x_pad_status = currentPressedButtons;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBegan:touches withEvent:event];
}


- (int)getController:(BOOL)withImage
{
  int skinfound;
  int skinimage;
  int buttons;
  char screensize[16];
  
  if(landscape)
  {
    snprintf(screensize, 16, "%dx%d", (int)([UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale]), (int)([UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale]));
  }
  else
  {
    snprintf(screensize, 16, "%dx%d", (int)([UIScreen mainScreen].bounds.size.width * [[UIScreen mainScreen] scale]), (int)([UIScreen mainScreen].bounds.size.height * [[UIScreen mainScreen] scale]));
  }

  skinfound = -1;
  
  NSLog(@"getController actual %s", screensize);
  
  for(skinimage = 0; skinimage < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; skinimage++)
  {
    if(strncasecmp(controllerskin.images[skinimage].devicetype, screensize, 16) == 0)
    {
      skinfound = skinimage;
    }
  }

  if(skinfound == -1)
  {
    return -1;
  }
  
  NSLog(@"getController skin found %d", skinfound);
  
  if(withImage == YES)
  {
    UIImage* image = nil;
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    if([fileManager isReadableFileAtPath:[NSString stringWithFormat:@"%s/%s", get_documents_path("skins"), controllerskin.images[skinfound].imagefile]])
    {
      NSLog(@"getController image found %@", [NSString stringWithFormat:@"%s/%s", get_documents_path("skins"), controllerskin.images[skinfound].imagefile]);
      image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%s/%s", get_documents_path("skins"), controllerskin.images[skinfound].imagefile]];
    }
    else if([fileManager isReadableFileAtPath:[NSString stringWithFormat:@"%s/%s", get_resource_path(""), controllerskin.images[skinfound].imagefile]])
    {
      NSLog(@"getController image found %@", [NSString stringWithFormat:@"%s/%s", get_resource_path(""), controllerskin.images[skinfound].imagefile]);
      image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%s/%s", get_resource_path(""), controllerskin.images[skinfound].imagefile]];
    }

    NSLog(@"getController alpha found %d", controllerskin.images[skinfound].alpha);

    [self.imageView setImage:image];
    self.imageView.alpha = (CGFloat)controllerskin.images[skinfound].alpha / 100.0f;
  }
  

  for(buttons = 0; buttons < CONTROLLER_BUTTONS_MAX; buttons++)
  {
    int coords[4];

    coords[0] = controllerskin.images[skinfound].coords[buttons][0];
    coords[1] = controllerskin.images[skinfound].coords[buttons][1];
    coords[2] = controllerskin.images[skinfound].coords[buttons][2];
    coords[3] = controllerskin.images[skinfound].coords[buttons][3];
    /*
    coords[0] = (float)coords[0] / [[UIScreen mainScreen] scale];
    coords[1] = (float)coords[1] / [[UIScreen mainScreen] scale];
    coords[2] = (float)coords[2] / [[UIScreen mainScreen] scale];
    coords[3] = (float)coords[3] / [[UIScreen mainScreen] scale];
    */
    buttonRectsData[buttons] = CGRectMake( coords[0], coords[1], coords[2], coords[3] );
    if(self.editingButtons)
    {
      if(buttons == self.buttonToEdit)
      {
        self.buttonRect = buttonRectsData[buttons];
      }
    }
  }
  
  self.buttonRects = buttonRectsData;
  
  if(self.editingButtons)
  {
    [self showControllerButtons:NO];
  }
  
  self.currentSkinImage = skinfound;
  
  return skinfound;
}

- (void)showControllerButtons:(BOOL)isRefresh
{
  int i;

  for(UIView* buttonViews in self.view.subviews)
  {
    if(buttonViews.backgroundColor == [UIColor redColor] ||
       buttonViews.backgroundColor == [UIColor greenColor])
    {
      [buttonViews removeFromSuperview];
    }
    /*
    if(!isRefresh)
    {
      if(buttonViews.backgroundColor == [UIColor redColor])
      {
        [buttonViews removeFromSuperview];
      }
    }
    
    if(buttonViews.backgroundColor == [UIColor greenColor])
    {
      [buttonViews removeFromSuperview];
    }
    */
  }
  
  for(i = 0; i < CONTROLLER_BUTTONS_MAX; i++)
  {
    if(i == self.buttonToEdit)
    {
      UIView* buttonView;
      buttonView = [[UIView alloc] initWithFrame:CGRectMake(self.buttonRect.origin.x / [[UIScreen mainScreen] scale], self.buttonRect.origin.y / [[UIScreen mainScreen] scale], self.buttonRect.size.width / [[UIScreen mainScreen] scale], self.buttonRect.size.height / [[UIScreen mainScreen] scale])];
      buttonView.backgroundColor = [UIColor greenColor];
      buttonView.alpha = 0.75;
      [self.view addSubview:buttonView];
    }
    else
    {
      //if(!isRefresh)
      {
        UIView* buttonView;
        buttonView = [[UIView alloc] initWithFrame:CGRectMake(buttonRectsData[i].origin.x / [[UIScreen mainScreen] scale], buttonRectsData[i].origin.y / [[UIScreen mainScreen] scale], buttonRectsData[i].size.width / [[UIScreen mainScreen] scale], buttonRectsData[i].size.height / [[UIScreen mainScreen] scale])];
        buttonView.backgroundColor = [UIColor redColor];
        buttonView.alpha = 0.25;
        [self.view addSubview:buttonView];
      }
    }
  }
}

#pragma mark Rotation

/*
- (BOOL)shouldAutorotate
{
  if(self.editingButtons)
  {
    return NO;
  }
  else
  {
    return YES;
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if(self.editingButtons)
  {
    return NO;
  }
  else
  {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  }
}
*/

#pragma mark iCade

- (void)didEnterBackground
{
  [self resignFirstResponder];
}

- (void)didBecomeActive
{
  [self becomeFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

- (void)setActive:(BOOL)value
{
  [self becomeFirstResponder];
}

- (void)toggleControllerSkin
{
  self.controllerSkinActive = !self.controllerSkinActive;
  
  if(self.controllerSkinActive)
  {
    self.imageView.hidden = NO;
  }
  else
  {
    self.imageView.hidden = YES;
  }
}

#pragma mark -
#pragma mark UIKeyInput Protocol Methods

- (BOOL)hasText
{
  return NO;
}

- (void)insertText:(NSString *)text
{
  char ch = [text characterAtIndex:0];
  char *p = strchr(ON_STATES, ch);
  bool stateChanged = false;
  if(p)
  {
    int index = p-ON_STATES;
    self.iCadeState |= (1 << index);
    stateChanged = true;
    [self buttonDown:(1 << index)];
  }
  else
  {
    p = strchr(OFF_STATES, ch);
    if(p)
    {
      int index = p-OFF_STATES;
      self.iCadeState &= ~(1 << index);
      stateChanged = true;
      [self buttonUp:(1 << index)];
    }
  }
  
  if(stateChanged)
  {
    //[self stateChanged:self.iCadeState];
  }
  
  static int cycleResponder = 0;
  if(++cycleResponder > 20)
  {
    // necessary to clear a buffer that accumulates internally
    cycleResponder = 0;
    [self resignFirstResponder];
    [self becomeFirstResponder];
  }
}

- (void)deleteBackward
{
  // This space intentionally left blank to complete protocol
}

- (UIView*) inputView
{
  return inputView;
}

- (void)setState:(BOOL)state forButton:(iCadeState)button
{
  unsigned long emubutton = 0;
  
  switch (button)
  {
    case iCadeButtonA:
      if(state == FALSE)
      {
        [self toggleControllerSkin];
      }
      break;
    case iCadeButtonB:
      emubutton |= BIT_LPAD;
      break;
    case iCadeButtonC:
      emubutton |= BIT_SEL;
      break;
    case iCadeButtonD:
      emubutton |= BIT_B;
      break;
    case iCadeButtonE:
      emubutton |= BIT_ST;
      break;
    case iCadeButtonF:
      emubutton |= BIT_A;
      break;
    case iCadeButtonG:
      if(state == FALSE)
      {
        [emulatorViewController pauseMenu];
      }
      break;
    case iCadeButtonH:
      emubutton |= BIT_RPAD;
      break;
    case iCadeJoystickUp:
      emubutton |= BIT_U;
      break;
    case iCadeJoystickRight:
      emubutton |= BIT_R;
      break;
    case iCadeJoystickDown:
      emubutton |= BIT_D;
      break;
    case iCadeJoystickLeft:
      emubutton |= BIT_L;
      break;
      
    default:
      break;
  }
  
  if(emubutton != 0)
  {
    if(state != FALSE)
    {
      gp2x_pad_status |= emubutton;
    }
    else
    {
      gp2x_pad_status &= ~(emubutton);
    }
  }
}

- (void)buttonDown:(iCadeState)button
{
  [self setState:YES forButton:button];
}

- (void)buttonUp:(iCadeState)button
{
  [self setState:NO forButton:button];
}

@end
