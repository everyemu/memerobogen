//
//  GBAEmulatorViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AdSdk/AdSdk.h>
#import <RevMobAds/RevMobAds.h>
#import "MPInterstitialAdController.h"
#import "ScreenView.h"
#import "GBAControllerViewController.h"

typedef struct
{
  int   enabled;
  char  name[256];
  char  code[32];
} GameCheat;

typedef struct
{
  GameCheat   cheat[100];
  int         numberOfCheats;
} GameRom;

@class ScreenView;
@class GBAControllerViewController;

@interface GBAEmulatorViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate, AdSdkVideoInterstitialViewControllerDelegate, MPInterstitialAdControllerDelegate, RevMobAdsDelegate>
{
  pthread_t emulation_tid;
}

@property (copy, nonatomic) NSString *romPath;
@property (strong, nonatomic) ScreenView* screenView;
@property (strong, nonatomic) GBAControllerViewController* controllerViewController;
@property (strong, nonatomic) NSMutableArray* saveStateArray;
@property (strong, nonatomic) AdSdkVideoInterstitialViewController* videoInterstitialViewController;
@property (strong, nonatomic) IBOutlet UIToolbar* menuBar;
@property (nonatomic, retain) MPInterstitialAdController* interstitial;
@property (nonatomic, retain) NSTimer* adTimer;

- (void)loadROM:(NSString *)romFilePath;
- (void)quitROM;
- (void)pauseMenu;
- (void)showActionSheetWithTag:(NSInteger)tag;
- (void)rotateToDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
- (void)showGameSettings;
- (void)clearCheats;
- (void)setNumberOfCheats:(NSInteger)cheatcount;
- (NSInteger)getNumberOfCheats;
- (void)setCheatNumber:(NSInteger)cheatnum withName:(char*)name withCode:(char*)code;
- (char*)getCheatCodeWithNumber:(NSInteger)cheatnum;
- (char*)getCheatNameWithNumber:(NSInteger)cheatnum;
- (NSInteger)getCheatEnabledWithNumber:(NSInteger)cheatnum;
- (void)toggleCheatNumber:(NSInteger)cheatnum willEnable:(BOOL)enable;
- (void)doneWithOptions;
- (IBAction)requestInterstitialAdvert:(id)sender;
- (IBAction)menuDone:(id)sender;
- (IBAction)menuCheats:(id)sender;
- (IBAction)menuLoad:(id)sender;
- (IBAction)menuSave:(id)sender;
- (IBAction)menuQuit:(id)sender;
- (void)enableFastForward:(BOOL)shouldEnable;
- (BOOL)isFastForwardEnabled;

@end
