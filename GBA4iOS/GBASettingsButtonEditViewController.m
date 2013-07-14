//
//  GBASettingsButtonEditViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBASettingsButtonEditViewController.h"
#import "GBAAppDelegate.h"
#import "GBAMasterViewController.h"
#import "helpers.h"

@interface GBASettingsButtonEditViewController ()
{
    UIDeviceOrientation currentDeviceOrientation_;
}

@end

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

@implementation GBASettingsButtonEditViewController
@synthesize controllerViewController;
@synthesize buttonCancel;
@synthesize buttonSave;
@synthesize buttonHorizontalLabel;
@synthesize buttonHorizontalSizeLabel;
@synthesize buttonVerticalLabel;
@synthesize buttonVerticalSizeLabel;
@synthesize buttonHorizontalStepper;
@synthesize buttonVerticalStepper;
@synthesize buttonHorizontalSizeStepper;
@synthesize buttonVerticalSizeStepper;
@synthesize buttonToEdit;
@synthesize viewSet;
@synthesize buttonRect;
@synthesize selectedOrientation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self)
  {
    // Custom initialization
  }
  return self;
}

- (void)setupViews:(BOOL)isRefresh
{
  self.viewSet = FALSE;
  
  if(!isRefresh)
  {
    self.view.backgroundColor = [UIColor grayColor];
    currentDeviceOrientation_ = UIDeviceOrientationUnknown;
    
    self.controllerViewController = nil;
    self.controllerViewController = [[GBAControllerViewController alloc] init];
  }
  
  if(self.selectedOrientation == 1)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeRight];
  }
  else if(self.selectedOrientation == 2)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeLeft];
  }
  else
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationPortrait];
  }
  
  self.buttonHorizontalSizeStepper.minimumValue = 1;
  self.buttonVerticalSizeStepper.minimumValue = 1;
  self.buttonHorizontalSizeStepper.maximumValue = 1000000;
  self.buttonVerticalSizeStepper.maximumValue = 1000000;
  
  self.buttonHorizontalStepper.minimumValue = 0;
  self.buttonVerticalStepper.minimumValue = 0;
  self.buttonHorizontalStepper.maximumValue = 1000000;
  self.buttonVerticalStepper.maximumValue = 1000000;
  
  self.controllerViewController.buttonToEdit = self.buttonToEdit;
  self.controllerViewController.editingButtons = YES;
  self.controllerViewController.emulatorViewController = (GBAEmulatorViewController*)self;
  
  [self.controllerViewController getController:YES];
  
  if(self.controllerViewController.buttonRects != nil)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
    
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    [self.buttonHorizontalLabel setFrame:CGRectMake((int)((screenwidth  - 320) / 2), 5, 195, 21)];
    [self.buttonHorizontalStepper setFrame:CGRectMake(screenwidth - (int)((screenwidth - 320) / 2) - 100, 5, 94, 27)];
    
    [self.buttonVerticalLabel setFrame:CGRectMake((int)((screenwidth - 320) / 2), 5 + 44, 195, 21)];
    [self.buttonVerticalStepper setFrame:CGRectMake(screenwidth - (int)((screenwidth - 320) / 2) - 100, 5 + 44, 94, 27)];
    
    [self.buttonHorizontalSizeLabel setFrame:CGRectMake((int)((screenwidth - 320) / 2), 5 + (44 * 2), 195, 21)];
    [self.buttonHorizontalSizeStepper setFrame:CGRectMake(screenwidth - (int)((screenwidth - 320) / 2) - 100, 5 + (44 * 2), 94, 27)];
        
    [self.buttonVerticalSizeLabel setFrame:CGRectMake((int)((screenwidth - 320) / 2), 5 + (44 * 3), 195, 21)];
    [self.buttonVerticalSizeStepper setFrame:CGRectMake(screenwidth - (int)((screenwidth - 320) / 2) - 100, 5 + (44 * 3), 94, 27)];

    [self.buttonCancel setFrame:CGRectMake((int)((screenwidth / 2) - 140), 5 + (44 * 4), 90, 30)];
    [self.buttonSave setFrame:CGRectMake((int)((screenwidth / 2) + 50), 5 + (44 * 4), 90, 30)];

    currentButton = self.controllerViewController.buttonToEdit;
    
    if(CGRectEqualToRect(buttonRect, CGRectZero))
    {
      // Default
      self.buttonHorizontalSizeStepper.value = self.controllerViewController.buttonRects[currentButton].size.width;
      self.buttonVerticalSizeStepper.value = self.controllerViewController.buttonRects[currentButton].size.height;
      
      self.buttonHorizontalStepper.value = self.controllerViewController.buttonRects[currentButton].origin.x;
      self.buttonVerticalStepper.value = self.controllerViewController.buttonRects[currentButton].origin.y;
    }
    else
    {
      self.buttonHorizontalSizeStepper.value = buttonRect.size.width;
      if(self.buttonHorizontalSizeStepper.value > (int)((float)screenwidth * [[UIScreen mainScreen] scale]))
      {
        self.buttonHorizontalSizeStepper.value = (int)((float)screenwidth * [[UIScreen mainScreen] scale]);
      }
      
      self.buttonHorizontalStepper.value = buttonRect.origin.x;
      if(self.buttonHorizontalStepper.value + self.buttonHorizontalSizeStepper.value > (int)((float)screenwidth * [[UIScreen mainScreen] scale]))
      {
        self.buttonHorizontalStepper.value = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - (int)self.buttonHorizontalSizeStepper.value;
      }

      self.buttonVerticalSizeStepper.value = buttonRect.size.height;
      if(self.buttonVerticalSizeStepper.value > (int)((float)screenheight * [[UIScreen mainScreen] scale]))
      {
        self.buttonVerticalSizeStepper.value = (int)((float)screenheight * [[UIScreen mainScreen] scale]);
      }
      
      self.buttonVerticalStepper.value = buttonRect.origin.y;
      if(self.buttonVerticalStepper.value + self.buttonVerticalSizeStepper.value > (int)((float)screenheight * [[UIScreen mainScreen] scale]))
      {
        self.buttonVerticalStepper.value = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - (int)self.buttonVerticalSizeStepper.value;
      }
    }
    
    [self.buttonHorizontalSizeLabel setText:[NSString stringWithFormat:@"Horizontal Size: %d", (int)self.buttonHorizontalSizeStepper.value]];
    [self.buttonVerticalSizeLabel setText:[NSString stringWithFormat:@"Vertical Size: %d", (int)self.buttonVerticalSizeStepper.value]];
    [self.buttonHorizontalLabel setText:[NSString stringWithFormat:@"Horizontal Position: %d", (int)self.buttonHorizontalStepper.value]];
    [self.buttonVerticalLabel setText:[NSString stringWithFormat:@"Vertical Position: %d", (int)self.buttonVerticalStepper.value]];

    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - (self.buttonHorizontalStepper.value + self.buttonHorizontalSizeStepper.value);
    if(space >= 0)
    {
      self.buttonHorizontalSizeStepper.maximumValue = self.buttonHorizontalSizeStepper.value + space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 0 !");
    }
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - (self.buttonVerticalStepper.value + self.buttonVerticalSizeStepper.value);
    if(space >= 0)
    {
      self.buttonVerticalSizeStepper.maximumValue = self.buttonVerticalSizeStepper.value + space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 1 !");
    }
    
    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - self.buttonHorizontalSizeStepper.value;
    if(space >= 0)
    {
      self.buttonHorizontalStepper.maximumValue = space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 2 !");
    }
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - self.buttonVerticalSizeStepper.value;
    if(space >= 0)
    {
      self.buttonVerticalStepper.maximumValue = space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 3 !");
    }
  }
  
  self.controllerViewController.buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
  
  [self.controllerViewController showControllerButtons:YES];
  
  if(!isRefresh)
  {
    [self.view addSubview:self.controllerViewController.view];
    [self.view sendSubviewToBack:self.controllerViewController.view];
  
    //[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
  }
  self.viewSet = TRUE;
}

- (void)setButtonMaximums
{
  if(self.controllerViewController.buttonRects != nil && self.viewSet == TRUE)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
   
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    currentButton = self.controllerViewController.buttonToEdit;
    
    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - (self.buttonHorizontalStepper.value + self.buttonHorizontalSizeStepper.value);
    if(space >= 0)
    {
      self.buttonHorizontalSizeStepper.maximumValue = self.buttonHorizontalSizeStepper.value + space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 4!");
    }
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - (self.buttonVerticalStepper.value + self.buttonVerticalSizeStepper.value);
    if(space >= 0)
    {
      self.buttonVerticalSizeStepper.maximumValue = self.buttonVerticalSizeStepper.value + space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 5!");
    }
    
    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - self.buttonHorizontalSizeStepper.value;
    if(space >= 0)
    {
      self.buttonHorizontalStepper.maximumValue = space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 6 !");
    }
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - self.buttonVerticalSizeStepper.value;
    if(space >= 0)
    {
      self.buttonVerticalStepper.maximumValue = space;
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 7 !");
    }
  }
}

- (IBAction)buttonHorizontalPositionChanged:(id)sender
{
  if(self.controllerViewController.buttonRects != nil && self.viewSet == TRUE)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
    
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    currentButton = self.controllerViewController.buttonToEdit;
        
    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - self.buttonHorizontalSizeStepper.value;
    if(space >= 0)
    {
      if(self.buttonHorizontalStepper.value > space)
      {
        self.buttonHorizontalStepper.value = space;
      }
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 8 !");
    }
  
    [self setButtonMaximums];
    self.controllerViewController.buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
    [self.controllerViewController showControllerButtons:YES];
  }
  
  [self.buttonHorizontalLabel setText:[NSString stringWithFormat:@"Horizontal Position: %d", (int)self.buttonHorizontalStepper.value]];
}

- (IBAction)buttonVerticalPositionChanged:(id)sender
{
  if(self.controllerViewController.buttonRects != nil && self.viewSet == TRUE)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
    
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    currentButton = self.controllerViewController.buttonToEdit;
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - self.buttonVerticalSizeStepper.value;
    if(space >= 0)
    {
      if(self.buttonVerticalStepper.value > space)
      {
        self.buttonVerticalStepper.value = space;
      }
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 9 !");
    }

    [self setButtonMaximums];
    self.controllerViewController.buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
    [self.controllerViewController showControllerButtons:YES];
  }

  [self.buttonVerticalLabel setText:[NSString stringWithFormat:@"Vertical Position: %d", (int)self.buttonVerticalStepper.value]];
}

- (IBAction)buttonHorizontalSizeChanged:(id)sender
{
  if(self.controllerViewController.buttonRects != nil && self.viewSet == TRUE)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
    
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    currentButton = self.controllerViewController.buttonToEdit;
    
    space = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - (self.buttonHorizontalStepper.value + self.buttonHorizontalSizeStepper.value);
    if(space < 0)
    {
      if((int)((float)screenwidth * [[UIScreen mainScreen] scale]) - self.buttonHorizontalStepper.value >= 1)
      {
        self.buttonHorizontalSizeStepper.value = (int)((float)screenwidth * [[UIScreen mainScreen] scale]) - self.buttonHorizontalStepper.value;
      }
      else
      {
        self.buttonHorizontalSizeStepper.value = 1;
        NSLog(@"Controller Coord Edit Error 10 !");
      }
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 11 !");
    }
    
    [self setButtonMaximums];
    self.controllerViewController.buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
    [self.controllerViewController showControllerButtons:YES];
  }
 
  [self.buttonHorizontalSizeLabel setText:[NSString stringWithFormat:@"Horizontal Size: %d", (int)self.buttonHorizontalSizeStepper.value]];
}

- (IBAction)buttonVerticalSizeChanged:(id)sender
{
  if(self.controllerViewController.buttonRects != nil && self.viewSet == TRUE)
  {
    int space;
    int screenwidth;
    int screenheight;
    int currentButton;
    
    if(self.controllerViewController.landscape)
    {
      screenwidth = [UIScreen mainScreen].bounds.size.height;
      screenheight = [UIScreen mainScreen].bounds.size.width;
    }
    else
    {
      screenwidth = [UIScreen mainScreen].bounds.size.width;
      screenheight = [UIScreen mainScreen].bounds.size.height;
    }
    
    currentButton = self.controllerViewController.buttonToEdit;
    
    space = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - (self.buttonVerticalStepper.value + self.buttonVerticalSizeStepper.value);
    if(space < 0)
    {
      if((int)((float)screenheight * [[UIScreen mainScreen] scale]) - self.buttonVerticalStepper.value >= 1)
      {
        self.buttonVerticalSizeStepper.value = (int)((float)screenheight * [[UIScreen mainScreen] scale]) - self.buttonVerticalStepper.value;
      }
      else
      {
        self.buttonVerticalSizeStepper.value = 1;
        NSLog(@"Controller Coord Edit Error 12 !");
      }
    }
    else
    {
      NSLog(@"Controller Coord Edit Error 13 !");
    }
    
    [self setButtonMaximums];
    self.controllerViewController.buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
    [self.controllerViewController showControllerButtons:YES];
  }
  
  [self.buttonVerticalSizeLabel setText:[NSString stringWithFormat:@"Vertical Size: %d", (int)self.buttonVerticalSizeStepper.value]];
}

- (IBAction)buttonCanceled:(id)sender
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)buttonSaved:(id)sender
{
  FILE* skinfile;
  int devicetype;
  GBAAppDelegate* appDelegate;
  char linetext[1024];
  
  if(self.controllerViewController == nil)
  {
    return;
  }
  
  snprintf(linetext, 1024, "%s/%s", get_documents_path("skins"), controllerskin.filename);
  skinfile = fopen(linetext, "w");
  
  if(skinfile == NULL)
  { 
    NSLog(@"buttonSaved failed!");
    return;
  }
  
  fputs(controllerskin.name, skinfile);
  fputs("\n", skinfile);
  
  for(devicetype = 0; devicetype < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; devicetype++)
  {
    int linenum;
    fputs(controllerskin.images[devicetype].devicetype, skinfile);
    fputs("\n", skinfile);
    
    fputs(controllerskin.images[devicetype].imagefile, skinfile);
    fputs("\n", skinfile);
    
    for(linenum = 0; linenum < 16; linenum++)
    {
      if(devicetype == self.controllerViewController.currentSkinImage &&
         linenum == self.controllerViewController.buttonToEdit)
      {
        snprintf(linetext, 1024, "%d,%d,%d,%d\n", (int)self.buttonHorizontalStepper.value, (int)self.buttonVerticalStepper.value, (int)self.buttonHorizontalSizeStepper.value, (int)self.buttonVerticalSizeStepper.value);
        fputs(linetext, skinfile);
      }
      else
      {
        snprintf(linetext, 1024, "%d,%d,%d,%d\n", controllerskin.images[devicetype].coords[linenum][0], controllerskin.images[devicetype].coords[linenum][1], controllerskin.images[devicetype].coords[linenum][2], controllerskin.images[devicetype].coords[linenum][3]);
        fputs(linetext, skinfile);
      }
    }
    
    snprintf(linetext, 1024, "%d\n", (int)controllerskin.images[devicetype].alpha);
    fputs(linetext, skinfile);

    snprintf(linetext, 1024, "%d,%d,%d,%d\n", controllerskin.images[devicetype].screencoords[0], controllerskin.images[devicetype].screencoords[1], controllerskin.images[devicetype].screencoords[2], controllerskin.images[devicetype].screencoords[3]);
    fputs(linetext, skinfile);
    fputs("\n", skinfile);
  }
  
  fclose(skinfile);
  
  appDelegate = [UIApplication sharedApplication].delegate;
  
  if(controllerskins.skins == NULL)
  {
    controllerskins.skins = malloc(sizeof(ControllerSkin) * CONTROLLER_SKINS_MAX);
    controllerskins.numberofskins = 0;
    controllerskins.currentskin = 0;
  }
  if(controllerskins.skins != NULL)
  {
    [appDelegate getSkins:&controllerskins];
    free(controllerskins.skins);
    controllerskins.skins = NULL;
    controllerskins.numberofskins = 0;
    controllerskins.currentskin = 0;
  }
  
  buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
  self.viewSet = FALSE;
  [self setupViews:TRUE];
}

- (void)pauseMenu
{
  
}

- (void)quitROM
{
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [UIApplication sharedApplication].statusBarHidden = TRUE;
  self.viewSet = FALSE;
  [self setupViews:FALSE];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);
  
  [UIApplication sharedApplication].statusBarHidden = FALSE;
  [self.controllerViewController.view removeFromSuperview];
  self.controllerViewController = nil;
  self.viewSet = FALSE;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  buttonRect = CGRectZero;
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  
  //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	//	(iOS 5)
	//	Only allow rotation to portrait
  if(self.selectedOrientation == 1)
  {
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
  }
  else if(self.selectedOrientation == 2)
  {
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft);
  }

  return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
	//	(iOS 6)
	//	No auto rotating
	return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
	//	(iOS 6)
	//	Only allow rotation to portrait
  if(self.selectedOrientation == 1)
  {
    return UIInterfaceOrientationMaskLandscapeRight;
  }
  else if(self.selectedOrientation == 2)
  {
    return UIInterfaceOrientationMaskLandscapeLeft;
  }
 
	return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	//	(iOS 6)
	//	Force to portrait
  if(self.selectedOrientation == 1)
  {
    return UIInterfaceOrientationLandscapeRight;
  }
  else if(self.selectedOrientation == 2)
  {
    return UIInterfaceOrientationLandscapeLeft;
  }
  
	return UIInterfaceOrientationPortrait;
}

- (void)didRotate:(NSNotification *)notification
{
/*
  if(self.selectedOrientation != 0)
  {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

    if(deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight)
    {
      buttonRect = CGRectMake(self.buttonHorizontalStepper.value, self.buttonVerticalStepper.value, self.buttonHorizontalSizeStepper.value, self.buttonVerticalSizeStepper.value);

      [self rotateToDeviceOrientation:[[UIDevice currentDevice] orientation]];
      self.viewSet = FALSE;
      [self setupViews:TRUE];
    }
  }
*/
}

- (void)rotateToDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
  if(deviceOrientation != UIDeviceOrientationLandscapeLeft   &&
      deviceOrientation != UIDeviceOrientationLandscapeRight  &&
      deviceOrientation != UIDeviceOrientationPortrait )
  {
    return;
  }

  if(currentDeviceOrientation_ != deviceOrientation)
  {
    currentDeviceOrientation_ = deviceOrientation;
    
    if(deviceOrientation == UIDeviceOrientationLandscapeLeft)
    {
      self.controllerViewController.landscape = YES;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
    else if(deviceOrientation == UIDeviceOrientationLandscapeRight)
    {
      self.controllerViewController.landscape = YES;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
    else if(deviceOrientation == UIDeviceOrientationPortrait)
    {
      self.controllerViewController.landscape = NO;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);      
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
  }
}

@end
