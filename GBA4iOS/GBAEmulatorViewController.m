//
//  GBAEmulatorViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <AdSdk/AdSdk.h>
#import <RevMobAds/RevMobAds.h>
#import "GBAEmulatorViewController.h"
#import "GBAAppDelegate.h"
#import "GBACheatMenuViewController.h"
#import "GBAGameSettingsViewController.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"
#import "helpers.h"

extern int cheatsFind(const char *code);
extern void cheatsAddCheatCode(const char *code);
extern BOOL cheatsAddGSACode(const char *code);
extern BOOL cheatsAddCBACode(const char *code);
extern void cheatsDelete(int number, BOOL restore);


GameRom gamerom;
char __savefileName[512];
char __lastfileName[512];
char __fileName[512];
int __mute;

typedef enum
{
  AD_PRIORITY_ADSDK = 0,
  AD_PRIORITY_REVMOB,
  AD_MOPUB,
  AD_REVMOB,
  AD_ADSDK,
  AD_NONE, // AD_NONE MUST BE LAST!
} FULLSCREEN_AD_TYPE;

FULLSCREEN_AD_TYPE currentFullscreenAd = AD_NONE;
extern int __emulation_run;
extern unsigned long synchronize_flag;

extern int iphone_main(char* load_filename);

extern void save_game_state(char *filepath);
extern void load_game_state(char *filepath);
extern volatile int __emulation_paused;
extern char *savestate_directory;

void* app_Thread_Start(void* args)
{
  @autoreleasepool
  {
    __emulation_run = 1;
    iphone_main(__fileName);
    __emulation_run = 0;
    return NULL;
  }
}

void stringToUpper(char* s)
{
  unsigned int l;
  
  if(s == NULL)
  {
    return;
  }
  
  for(l = 0; l < strlen(s); l++)
  {
    s[l] = toupper(s[l]);
  }
}

@interface GBAEmulatorViewController ()
{
    UIDeviceOrientation currentDeviceOrientation_;
}

@property (copy, nonatomic) NSString *romSaveStateDirectory;

@end

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)
#define DEGREES(radians) (radians * 180.0/M_PI)

@implementation GBAEmulatorViewController
@synthesize romPath;
@synthesize screenView;
@synthesize controllerViewController;
@synthesize saveStateArray;
@synthesize romSaveStateDirectory;
@synthesize videoInterstitialViewController;
@synthesize menuBar;
@synthesize adTimer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if(self)
  {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.screenView = nil;
  self.controllerViewController = nil;
  
  [self.view sendSubviewToBack:self.menuBar];
  [self.menuBar setHidden:TRUE];

  currentDeviceOrientation_ = UIDeviceOrientationUnknown;

  self.view.backgroundColor = [UIColor blackColor];
  self.view.userInteractionEnabled = YES;
  self.view.multipleTouchEnabled = YES;
  
  currentFullscreenAd = 0;
  self.videoInterstitialViewController = [[AdSdkVideoInterstitialViewController alloc] init];
  self.videoInterstitialViewController.delegate = self;
  //self.videoInterstitialViewController.locationAwareAdverts = YES;
  self.interstitial = nil;
  [self.view addSubview:self.videoInterstitialViewController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  /*
   if (__emulation_run == 0)
   {
   [self loadROM:self.romPath];
   }
   */
  /*
  if(self.presentingViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeLeft];
  }
  else if(self.presentingViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeRight];
  }
  else
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationPortrait];
  }
  */
  [self requestInterstitialAdvert:self];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  [self.controllerViewController.view removeFromSuperview];
  self.controllerViewController = nil;
  [self.screenView removeFromSuperview];
  self.screenView = nil;
  
  if(self.interstitial != nil)
  {
    self.interstitial = nil;
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)loadROM:(NSString *)romFilePath
{
  currentFullscreenAd = 0;
  
  [UIApplication sharedApplication].statusBarHidden = YES;
  
  [self clearCheats];
  self.screenView = nil;
  self.screenView = [[ScreenView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.screenView.backgroundColor = [UIColor blackColor];
  
  self.controllerViewController = nil;
  self.controllerViewController = [[GBAControllerViewController alloc] init];
  
  if(self.presentingViewController.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeLeft];
  }
  else if(self.presentingViewController.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationLandscapeRight];
  }
  else
  {
    [self rotateToDeviceOrientation:UIDeviceOrientationPortrait];
  }
  
  self.controllerViewController.editingButtons = NO;
  self.controllerViewController.emulatorViewController = self;
  [self.controllerViewController getController:YES];
  
  [self.view addSubview:self.screenView];
  [self.view addSubview:self.controllerViewController.view];
  
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
  
  __emulation_run = 1;

  strlcpy(__fileName, [ romFilePath cStringUsingEncoding: NSASCIIStringEncoding], sizeof(__fileName));

  app_Begin();
  
  pthread_create(&emulation_tid, NULL, app_Thread_Start, NULL);
}

- (void)showGameSettings
{
  /*
  GBACheatMenuViewController* cheatMenuViewController = [[GBACheatMenuViewController alloc] init];
  UINavigationController* cheatMenuNavController = [[UINavigationController alloc] initWithRootViewController:cheatMenuViewController];
  NSString* romName = [[self.romPath lastPathComponent] stringByDeletingPathExtension];

  [cheatMenuViewController setDelegate:self];
  [cheatMenuViewController setGame:romName];
  cheatMenuNavController.navigationBar.barStyle = UIBarStyleDefault;
  [self presentModalViewController:cheatMenuNavController animated:YES];
  */
}

- (void)quitROM
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    app_End();
    pthread_join(emulation_tid, NULL);
    [self.view sendSubviewToBack:self.menuBar];
    [self.menuBar setHidden:TRUE];
    __emulation_paused = 0;
  });
  [UIApplication sharedApplication].statusBarHidden = NO;
  [[self presentingViewController] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIStoryboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([[segue identifier] isEqualToString:@"showGameSettings"])
  {
    GBAGameSettingsViewController* viewController = (GBAGameSettingsViewController*)[(UINavigationController*)[segue destinationViewController] topViewController];
    NSString* romName = [[self.romPath lastPathComponent] stringByDeletingPathExtension];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    [viewController setDelegate:self];
    [viewController setGame:romName];
  }
}

#pragma mark Rotation

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotate:(NSNotification *)notification
{
  [self rotateToDeviceOrientation:[[UIDevice currentDevice] orientation]];
}

- (void)rotateToDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
  if (deviceOrientation != UIDeviceOrientationLandscapeLeft   &&
      deviceOrientation != UIDeviceOrientationLandscapeRight  &&
      deviceOrientation != UIDeviceOrientationPortrait )
  {
    return;
  }
  
  if (currentDeviceOrientation_ != deviceOrientation)
  {
    if(self.controllerViewController == nil || self.screenView == nil)
    {
      return;
    }
    
    currentDeviceOrientation_ = deviceOrientation;
    
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft)
    {
      self.controllerViewController.landscape = YES;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
    else if (deviceOrientation == UIDeviceOrientationLandscapeRight)
    {
      self.controllerViewController.landscape = YES;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
    else if (deviceOrientation == UIDeviceOrientationPortrait)
    {
      self.controllerViewController.landscape = NO;
      self.controllerViewController.view.frame = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
      self.controllerViewController.imageView.frame = self.controllerViewController.view.frame;
      
      self.controllerViewController.view.bounds = CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
      self.controllerViewController.imageView.bounds = self.controllerViewController.view.bounds;
    }
    
    [self.screenView rotateForDeviceOrientation:deviceOrientation];
    [self.controllerViewController updateUI];
  }
}

#pragma mark Pause Menu

- (IBAction)menuDone:(id)sender
{
  [self.view sendSubviewToBack:self.menuBar];
  [self.menuBar setHidden:TRUE];
  __emulation_paused = 0;
  app_OpenSound();
}

- (IBAction)menuCheats:(id)sender
{
  [self showGameSettings];
}

- (IBAction)menuLoad:(id)sender
{
  [self showActionSheetWithTag:2];
}

- (IBAction)menuSave:(id)sender
{
  [self showActionSheetWithTag:1];
}

- (IBAction)menuQuit:(id)sender
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
      UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to quit?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"No, my bad!", @"") destructiveButtonTitle:nil otherButtonTitles:@"Yes, quit.", nil];
      actionSheet.tag = 3;
      [actionSheet showInView:self.view];
    });
  });
}

- (void)pauseMenu
{
  __emulation_paused = 1;
  app_CloseSound();
  [self.menuBar setHidden:FALSE];
  [self.view bringSubviewToFront:self.menuBar];
}

- (void)showActionSheetWithTag:(NSInteger)tag
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
    if (!self.romSaveStateDirectory)
    {
      NSString* saveStateDirectory = [NSString stringWithUTF8String:get_documents_path("save_states")];
      NSString *romName = [[self.romPath lastPathComponent] stringByDeletingPathExtension];
      self.romSaveStateDirectory = [saveStateDirectory stringByAppendingPathComponent:romName];
        
      NSFileManager *fileManager = [[NSFileManager alloc] init];
      [fileManager createDirectoryAtPath:self.romSaveStateDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *saveStateInfoPath = [self.romSaveStateDirectory stringByAppendingPathComponent:@"info.plist"];

    if (!self.saveStateArray)
    {
      self.saveStateArray = [[NSMutableArray alloc] initWithContentsOfFile:saveStateInfoPath];
    }
    if ([self.saveStateArray count] == 0)
    {
      self.saveStateArray = [[NSMutableArray alloc] initWithCapacity:5];

      for (int i = 0; i < 5; i++)
      {
        [self.saveStateArray addObject:NSLocalizedString(@"Empty", @"")];
      }
      [self.saveStateArray writeToFile:saveStateInfoPath atomically:YES];
    }
        
    dispatch_async(dispatch_get_main_queue(), ^{
      UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Save State", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:[self.saveStateArray objectAtIndex:0], [self.saveStateArray objectAtIndex:1], [self.saveStateArray objectAtIndex:2], [self.saveStateArray objectAtIndex:3], [self.saveStateArray objectAtIndex:4], nil];
      actionSheet.tag = tag;
      [actionSheet showInView:self.view];
    });
  });
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (actionSheet.tag == 3)
  {
    if(buttonIndex == 0)
    {
      [self quitROM];
    }
    else
    {
      [self.view sendSubviewToBack:self.menuBar];
      [self.menuBar setHidden:TRUE];
      __emulation_paused = 0;
      app_OpenSound();
    }
  }
  else
  {
    NSString *saveStateInfoPath = [self.romSaveStateDirectory stringByAppendingPathComponent:@"info.plist"];
    NSString *filepath = [self.romSaveStateDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.svs", buttonIndex]];
    char *saveStateFilepath = strdup((char *)[filepath UTF8String]);

    if (actionSheet.tag == 1 && buttonIndex != 5)
    {
      NSMutableDictionary* dictionary = [[NSThread currentThread] threadDictionary];
      NSDateFormatter* dateFormatter = [dictionary objectForKey:@"dateFormatterShortStyleDate"];
      if (dateFormatter == nil)
      {
          dateFormatter = [[NSDateFormatter alloc] init];
          [dateFormatter setDateStyle:NSDateFormatterShortStyle];
          [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
          [dictionary setObject:dateFormatter forKey:@"dateFormatterShortStyleDate"];
      }
      
      NSString *title = [dateFormatter stringFromDate:[NSDate date]];
      
      [self.saveStateArray replaceObjectAtIndex:buttonIndex withObject:title];
              
      save_game_state(saveStateFilepath);
      
      [self.saveStateArray writeToFile:saveStateInfoPath atomically:YES];
    }
    else if (actionSheet.tag == 2 && buttonIndex != 5)
    {
      load_game_state(saveStateFilepath);
    }

    [self.view sendSubviewToBack:self.menuBar];
    [self.menuBar setHidden:TRUE];
    __emulation_paused = 0;
    app_OpenSound();
  }
}

#pragma mark Cheat Menu

- (void)clearCheats
{
  int i;
  for(i = 0; i < 100; i++)
  {
    gamerom.cheat[i].enabled = 0;
    gamerom.cheat[i].name[0] = '\0';
    gamerom.cheat[i].code[0] = '\0';
  }
  gamerom.numberOfCheats = 0;
}

- (void)setCheatNumber:(NSInteger)cheatnum withName:(char*)name withCode:(char*)code
{
  if(cheatnum < 100)
  {
    if(strcmp(name, gamerom.cheat[cheatnum].name) != 0 ||
       strcmp(code, gamerom.cheat[cheatnum].code) != 0 )
    {
      snprintf(gamerom.cheat[cheatnum].name, 256, "%s", name);
      snprintf(gamerom.cheat[cheatnum].code, 32, "%s", code);
      gamerom.cheat[cheatnum].enabled = 0;
    }
  }
}

- (void)setNumberOfCheats:(NSInteger)cheatcount
{
  gamerom.numberOfCheats = cheatcount;
}

- (void)toggleCheatNumber:(NSInteger)cheatnum willEnable:(BOOL)enable
{
  if(cheatnum < 100)
  {
    char currentcode[32];

    snprintf(currentcode, 32, "%s", gamerom.cheat[cheatnum].code);
    stringToUpper(currentcode);
    
    if(enable)
    {
      BOOL enabled;
      int len = strlen(currentcode);
      
      if (len == 16 || len == 17)
      {
        enabled = cheatsAddGSACode(currentcode);
        NSLog(@"toggleCheatNumber num %d code %s enabled %d", cheatnum, gamerom.cheat[cheatnum].code, enabled);
      }
      else
      {
        enabled = cheatsAddCBACode(currentcode);
      }
      gamerom.cheat[cheatnum].enabled = enabled;
    }
    else
    {
      int i = cheatsFind(currentcode);
      if (i >= 0)
      {
        cheatsDelete(i, TRUE);
      }
      gamerom.cheat[cheatnum].enabled = 0;
    }
  }
}

- (NSInteger)getNumberOfCheats
{
  return gamerom.numberOfCheats;
}

- (NSInteger)getCheatEnabledWithNumber:(NSInteger)cheatnum
{
  if(cheatnum >= 100)
  {
    cheatnum = 99;
  }
  
  return gamerom.cheat[cheatnum].enabled;
}

- (char*)getCheatCodeWithNumber:(NSInteger)cheatnum
{
  if(cheatnum >= 100)
  {
    cheatnum = 99;
  }
  
  return gamerom.cheat[cheatnum].code;
}

- (char*)getCheatNameWithNumber:(NSInteger)cheatnum
{
  if(cheatnum >= 100)
  {
    cheatnum = 99;
  }
  
  return gamerom.cheat[cheatnum].name;
}

- (void)doneWithOptions
{
  [self dismissViewControllerAnimated:YES completion:NULL];
  [self.view sendSubviewToBack:self.menuBar];
  [self.menuBar setHidden:TRUE];
  __emulation_paused = 0;
  app_OpenSound();
}

- (BOOL)isFastForwardEnabled
{
  return (synchronize_flag == 0 ? YES : NO);
}

- (void)enableFastForward:(BOOL)shouldEnable
{
  synchronize_flag = (shouldEnable ? 0 : 1);
}

#pragma mark AdSdk Interstitial Methods

- (void)adTimedOut
{
  self.adTimer = nil;
  [self.videoInterstitialViewController.view setHidden:YES];  
  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

- (IBAction)requestInterstitialAdvert:(id)sender
{
  NSLog(@"requestInterstitialAdvert [%d]", currentFullscreenAd);
  
  if(currentFullscreenAd < AD_NONE && self.videoInterstitialViewController != nil)
  {
    self.videoInterstitialViewController.requestURL = @"http://zodttd.com/ads/madserve/md.request.php";
    self.adTimer = [NSTimer scheduledTimerWithTimeInterval:12.0 target:self selector:@selector(adTimedOut) userInfo:nil repeats:NO];
    [self.videoInterstitialViewController requestAd];
  }
  else
  {
    currentFullscreenAd = AD_NONE;
    [self loadROM:self.romPath];
  }
}

#pragma mark AdSdk Interstitial Delegate Methods

- (NSString *)publisherIdForAdSdkVideoInterstitialView:(AdSdkVideoInterstitialViewController *)videoInterstitial
{
  
  if(currentFullscreenAd == AD_PRIORITY_ADSDK)
  {
    return @"79b674ff7390927b0c7b8da4f6579bf5";
  }
  else if(currentFullscreenAd == AD_PRIORITY_REVMOB)
  {
    return @"a2e17f3dde04a7a4d05e0a0cd3b4e1fe";
  }
  else if(currentFullscreenAd == AD_MOPUB)
  {
    return @"a5e0174b788208018bb52c693f666d52";
  }
  else if(currentFullscreenAd == AD_REVMOB)
  {
    return @"e34386819e2d4cd80a9492eeda233211";
  }

  // currentFullscreenAd == AD_ADSDK
  return @"3f70872f088a0ad7f77f4453f01e3684";
}

- (void)adsdkVideoInterstitialViewDidLoadAdSdkAd:(AdSdkVideoInterstitialViewController *)videoInterstitial advertTypeLoaded:(AdSdkAdType)advertType
{
  NSLog(@"AdSdk Interstitial: did load ad");
  
  // Means an advert has been retrieved and configured.
  // Display the ad using the presentAd method and ensure you pass back the advertType
 
  if(self.adTimer != nil)
  {
    [self.adTimer invalidate];
    self.adTimer = nil;
  }
  else
  {
    return;
  }
  
  if(currentFullscreenAd == AD_PRIORITY_ADSDK)
  {
    [videoInterstitial.view setHidden:NO];
    [self.view bringSubviewToFront:videoInterstitial.view];
    [videoInterstitial presentAd:advertType];
  }
  else if(currentFullscreenAd == AD_PRIORITY_REVMOB)
  {
    [videoInterstitial.view setHidden:YES];
    RevMobFullscreen* fs = [[RevMobAds session] fullscreen];
    fs.delegate = self;
    [fs showAd];
  }
  else if(currentFullscreenAd == AD_MOPUB)
  {
    [videoInterstitial.view setHidden:YES];
    if(self.interstitial != nil)
    {
      self.interstitial = nil;
    }
    
    // Instantiate the interstitial using the class convenience method.
    self.interstitial = [MPInterstitialAdController
                         interstitialAdControllerForAdUnitId:@"f3eddb46bbfc11e295fa123138070049"];
    self.interstitial.delegate = self;
    // Fetch the interstitial ad.
    [self.interstitial loadAd];
  }
  else if(currentFullscreenAd == AD_REVMOB)
  {
    [videoInterstitial.view setHidden:YES];
    RevMobFullscreen* fs = [[RevMobAds session] fullscreen];
    fs.delegate = self;
    [fs showAd];
  }
  else if(currentFullscreenAd == AD_ADSDK)
  {
    [videoInterstitial.view setHidden:NO];
    [self.view bringSubviewToFront:videoInterstitial.view];
    [videoInterstitial presentAd:advertType];
  }
}

- (void)adsdkVideoInterstitialView:(AdSdkVideoInterstitialViewController *)banner didFailToReceiveAdWithError:(NSError *)error
{
	NSLog(@"AdSdk Interstitial [%d]: did fail to load ad: %@", error.code, [error localizedDescription]);

  if(self.adTimer != nil)
  {
    [self.adTimer invalidate];
    self.adTimer = nil;
  }
  else
  {
    return;
  }
  
  NSRange r1 = [[error localizedDescription] rangeOfString:@"inventory" options:NSCaseInsensitiveSearch];
  NSRange r2 = [[error localizedDescription] rangeOfString:@"no ad" options:NSCaseInsensitiveSearch];
  if(r1.length > 0 || r2.length > 0)
  {
    currentFullscreenAd++;
    [self requestInterstitialAdvert:self];
  }
  else
  {
    currentFullscreenAd = AD_NONE;
    if(self.videoInterstitialViewController != nil)
    {
      [self.videoInterstitialViewController.view setHidden:YES];
    }
    RevMobFullscreen* fs = [[RevMobAds session] fullscreen];
    fs.delegate = self;
    [fs showAd];
  }
}

- (void)adsdkVideoInterstitialViewDidDismissScreen:(AdSdkVideoInterstitialViewController *)videoInterstitial
{
	NSLog(@"AdSdk Interstitial: did dismiss screen");

  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

- (void)adsdkVideoInterstitialViewActionWillLeaveApplication:(AdSdkVideoInterstitialViewController *)videoInterstitial
{
	NSLog(@"AdSdk Interstitial: will leave application");

  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

#pragma mark - MoPub delegate methods

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial
{
  [self.interstitial showFromViewController:self];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
{
  currentFullscreenAd++;
  [self requestInterstitialAdvert:self];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial
{
  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial
{
  currentFullscreenAd++;
  [self requestInterstitialAdvert:self];
}

#pragma mark - RevMobAdsDelegate methods

- (void)revmobAdDidReceive
{
  NSLog(@"[RevMob] Ad loaded.");
}

- (void)revmobAdDidFailWithError:(NSError *)error
{
  NSLog(@"[RevMob] Ad failed: %@", error);
  
  if(currentFullscreenAd == AD_NONE)
  {
    if(self.videoInterstitialViewController != nil)
    {
      [self.videoInterstitialViewController.view setHidden:YES];
    }
    if(self.interstitial != nil)
    {
      self.interstitial = nil;
    }
    
    // Instantiate the interstitial using the class convenience method.
    self.interstitial = [MPInterstitialAdController
                         interstitialAdControllerForAdUnitId:@"f3eddb46bbfc11e295fa123138070049"];
    self.interstitial.delegate = self;
    // Fetch the interstitial ad.
    [self.interstitial loadAd];
  }
  else
  {
    currentFullscreenAd++;
    [self requestInterstitialAdvert:self];
  }
}

- (void)revmobAdDisplayed
{
  NSLog(@"[RevMob] Ad displayed.");
}

- (void)revmobUserClosedTheAd
{
  NSLog(@"[RevMob] User clicked in the close button.");
  
  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

- (void)revmobUserClickedInTheAd
{
  NSLog(@"[RevMob] User clicked in the Ad.");

  currentFullscreenAd = AD_NONE;
  [self loadROM:self.romPath];
}

- (void)installDidReceive
{
  NSLog(@"[RevMob] Install did receive.");
}

- (void)installDidFail
{
  NSLog(@"[RevMob] Install did fail.");
}

@end
