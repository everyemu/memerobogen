//
//  GBAMasterViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPAdView.h"
#import "GBAEmulatorViewController.h"
#import "PullToRefreshView.h"
#import <AdSdk/AdSdk.h>

#define APP_VERSION_NUM 80008

#define CONTROLLER_SKINS_MAX 128
#define CONTROLLER_SKINS_DEVICETYPES_MAX 5
#define CONTROLLER_SKINS_BUTTONS_MAX 16

#define CONTROLLER_SKINTYPE_ARRAY { "320x480", "640x960", "640x1136", "768x1024", "1536x2048",  \
"480x320", "960x640", "1136x640", "1024x768", "2048x1536" }

typedef struct
{
  char imagefile[256];
  char devicetype[16];
  int coords[CONTROLLER_SKINS_BUTTONS_MAX][4];
  int screencoords[4];
  unsigned char alpha;
} ControllerSkinImage;

typedef struct
{
  char name[256];
  char filename[256];
  ControllerSkinImage images[CONTROLLER_SKINS_DEVICETYPES_MAX * 2];
} ControllerSkin;

typedef struct
{
  int currentskin;
  int numberofskins;
  ControllerSkin* skins;
} ControllerSkins;


extern ControllerSkin controllerskin;

@class GBADetailViewController;

@interface GBAMasterViewController : UIViewController <PullToRefreshViewDelegate, AdSdkBannerViewDelegate, MPAdViewDelegate, RevMobAdsDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) GBADetailViewController* detailViewController;
@property (copy, nonatomic) NSString* currentRomPath;
@property (nonatomic, retain) MPAdView* adView;

- (IBAction)scanRomDirectory;
- (IBAction)getMoreROMs;
- (IBAction)requestBannerAdvert:(id)sender;

@end
