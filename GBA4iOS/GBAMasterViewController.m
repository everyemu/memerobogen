//
//  GBAMasterViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <AdSdk/AdSdk.h>
#import "GBAMasterViewController.h"
#import "MPAdView.h"
#import "GBAEmulatorViewController.h"
#import "GBAGameSettingsViewController.h"
#import "GBADetailViewController.h"
#import "WebBrowserViewController.h"
#import "helpers.h"

ControllerSkin controllerskin;

typedef enum
{
  AD_PRIORITY_ADSDK = 0,
  AD_PRIORITY_REVMOB,
  AD_MOPUB,
  AD_REVMOB,
  AD_ADSDK,
  AD_NONE, // AD_NONE MUST BE LAST!
} BANNER_AD_TYPE;

BANNER_AD_TYPE currentBannerAd = AD_NONE;

@interface GBAMasterViewController () <UIAlertViewDelegate, AdSdkBannerViewDelegate, MPAdViewDelegate, RevMobAdsDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableDictionary* romDictionary;
@property (strong, nonatomic) NSArray* romSections;
@property (nonatomic) NSInteger currentSection_;
@property (strong, nonatomic) PullToRefreshView* pullToRefreshView_;
@property (copy, nonatomic) NSString* deletingRomPath;
@property (strong, nonatomic) GBAGameSettingsViewController* gameSettingsViewController;
@property (strong, nonatomic) GBAEmulatorViewController* emulatorViewController;
@property (strong, nonatomic) IBOutlet AdSdkBannerView* bannerView;
@property (nonatomic, strong) IBOutlet UITableView* romTableView;

@end

@implementation GBAMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize romDictionary;
@synthesize romSections;
@synthesize currentSection_;
@synthesize currentRomPath;
@synthesize pullToRefreshView_;
@synthesize deletingRomPath;
@synthesize gameSettingsViewController;
@synthesize emulatorViewController;
@synthesize bannerView;
@synthesize romTableView;

- (void)awakeFromNib
{
  /* Z Edit
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
  {
      self.clearsSelectionOnViewWillAppear = NO;
      self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
  }
  */
  [super awakeFromNib];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.navigationItem setTitle:[NSString stringWithFormat:@"gpSPhone v%d.%d.%d", (int)(APP_VERSION_NUM / 10000) % 100, (int)(APP_VERSION_NUM / 100) % 100, APP_VERSION_NUM % 100]];
  
  self.pullToRefreshView_ = [[PullToRefreshView alloc] initWithScrollView:(UIScrollView *) self.romTableView];
  [self.pullToRefreshView_ setDelegate:self];
  [self.romTableView addSubview:self.pullToRefreshView_];

  // Do any additional setup after loading the view, typically from a nib.

  self.navigationItem.leftBarButtonItem.landscapeImagePhone = [UIImage imageNamed:@"GearLandscape"];

  [self performSelector:@selector(scanRomDirectory) withObject:nil afterDelay:0.0];

  self.detailViewController = (GBADetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
  
  currentBannerAd = 0;
  self.adView = nil;
  self.bannerView.clipsToBounds = YES;
  [self.bannerView setFrame:CGRectMake(0.0, 0.0, 320.0f, 50.0f)];
  if([self.bannerView superview] != self.view)
  {
    [self.view addSubview:self.bannerView];
  }
  [self.view bringSubviewToFront:self.bannerView];
  [self requestBannerAdvert:self];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  //[self performSelector:@selector(scanRomDirectory) withObject:nil afterDelay:0.0];
  
  //[self requestBannerAdvert:self];
}

- (void)viewDidUnload
{
  [super viewDidUnload];

  if(self.adView != nil)
  {
    [self.adView removeFromSuperview];
    self.adView = nil;
  }
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark ROM loading methods

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view;
{
  [self scanRomDirectory];
  currentBannerAd = 0;
  [self requestBannerAdvert:self];
}

- (IBAction)scanRomDirectory
{
  NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
  
  if (self.romDictionary)
  {
    [self.romDictionary removeAllObjects];
  }
  if (!self.romDictionary)
  {
    self.romDictionary = [[NSMutableDictionary alloc] init];
  }
  
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
  
  self.romSections = [NSArray arrayWithArray:[@"A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|#" componentsSeparatedByString:@"|"]];
  
  for (int i = 0; i < contents.count; i++)
  {
    NSString* filename = [contents objectAtIndex:i];
    NSString* filenameExt = [filename pathExtension];
    if( ([filenameExt caseInsensitiveCompare:@"zip"] == NSOrderedSame) ||
        ([filenameExt caseInsensitiveCompare:@"gba"] == NSOrderedSame) ||
        ([filenameExt caseInsensitiveCompare:@"ips"] == NSOrderedSame) )
    {
      NSString* characterIndex = [filename substringWithRange:NSMakeRange(0,1)];
      
      BOOL matched = NO;
      for (int i = 0; i < self.romSections.count && !matched; i++)
      {
        NSString *section = [self.romSections objectAtIndex:i];
        if ([section isEqualToString:characterIndex])
        {
            matched = YES;
        }
      }
      
      if (!matched)
      {
        characterIndex = @"#";
      }
      
      NSMutableArray *sectionArray = [self.romDictionary objectForKey:characterIndex];
      if (sectionArray == nil)
      {
          sectionArray = [[NSMutableArray alloc] init];
      }
      [sectionArray addObject:filename];
      [self.romDictionary setObject:sectionArray forKey:characterIndex];
    }
  }
  
  [self.romTableView reloadData];
  
  double delayInSeconds = 0.5;//gives the pull to refresh animation time to work, less jerky
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.pullToRefreshView_ finishedLoading];
  });  
}

#pragma mark - Download ROMs

- (IBAction)getMoreROMs
{
  WebBrowserViewController* webViewController = [[WebBrowserViewController alloc] init];
  UINavigationController* webNavController = [[UINavigationController alloc] initWithRootViewController:webViewController];
  webNavController.navigationBar.barStyle = UIBarStyleBlack;
  [self presentModalViewController:webNavController animated:YES];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = nil;
          
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];        
  }
  
  cell.accessoryType = UITableViewCellAccessoryNone;
  NSString *filename = [[self.romDictionary objectForKey:[self.romSections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
  filename = [filename stringByDeletingPathExtension];//cleaner interface
  cell.textLabel.text = filename;
  
  return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  NSInteger numberOfSections = self.romSections.count;    
  return numberOfSections > 0 ? numberOfSections : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  NSString *sectionTitle = nil;    
  if(self.romSections.count)
  {
      NSInteger numberOfRows = [self tableView:tableView numberOfRowsInSection:section];
      if (numberOfRows > 0)
      {
          sectionTitle = [self.romSections objectAtIndex:section];
      }
  }    
  return sectionTitle;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  NSMutableArray *sectionIndexTitles = nil;
  if(self.romSections.count)
  {
      sectionIndexTitles = [NSMutableArray arrayWithArray:[@"A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|#" componentsSeparatedByString:@"|"]];
  }
  return  sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  self.currentSection_ = index;
  return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger numberOfRows = self.romDictionary.count;
  if(self.romSections.count)
  {
    numberOfRows = [[self.romDictionary objectForKey:[self.romSections objectAtIndex:section]] count];
  }
  return numberOfRows;
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (NSString *)romPathAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.romDictionary objectForKey:[self.romSections objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  /* Z Edit
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
  {
    NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];    
    self.currentRomPath = [documentsDirectoryPath stringByAppendingPathComponent:[self romPathAtIndexPath:indexPath]];
    self.detailViewController.detailItem = self.currentRomPath;
  }
  */
  
  NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
  self.currentRomPath = [documentsDirectoryPath stringByAppendingPathComponent:[self romPathAtIndexPath:indexPath]];

  [self performSegueWithIdentifier:@"loadROM" sender:self];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return @"Delete";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
    NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
    
		self.deletingRomPath = [documentsDirectoryPath stringByAppendingPathComponent:[self romPathAtIndexPath:indexPath]];
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete ROM"
															message:@"Also delete save states and save files?"
														   delegate:self
												  cancelButtonTitle:@"Cancel"
												  otherButtonTitles:@"Delete ROM only", @"Delete ROM & saved data", nil];
		[alertView show];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex > 0)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		
		// need to delete rom.
		NSError *error = nil;
		if ([fileManager removeItemAtPath:self.deletingRomPath error:&error] && !error)
    {
			NSLog(@"Successfully delete rom.");
		}
		else
    {
			NSLog(@"%@. %@.", error, [error userInfo]);
		}
		
		if(buttonIndex == 2)
		{
			// need to delete states.
      NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
      NSString* saveStateDirectory = [documentsDirectoryPath stringByAppendingPathComponent:@"save_states"];
      NSString* romName = [[self.deletingRomPath lastPathComponent] stringByDeletingPathExtension];
      NSString* romSaveStateDirectory = [saveStateDirectory stringByAppendingPathComponent:romName];

			NSError *error = nil;
      if ([fileManager removeItemAtPath:romSaveStateDirectory error:&error] && !error)
      {
          NSLog(@"Successfully delete states.");
      }
      else
      {
          NSLog(@"%@. %@.", error, [error userInfo]);
      }
      
      NSString *saveFilePath = [[self.deletingRomPath stringByDeletingPathExtension] stringByAppendingString:@".sav"];
      
      if ([fileManager removeItemAtPath:saveFilePath error:&error] && !error)
      {
          NSLog(@"Successfully deleted save file.");
      }
      else
      {
          NSLog(@"%@. %@.", error, [error userInfo]);
      }
		}
		
		[self scanRomDirectory];
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath;
{
  NSString *rom = [self romPathAtIndexPath:indexPath];
  if(gameSettingsViewController != nil)
  {
    [gameSettingsViewController setGame:rom];
  }
}

#pragma mark - UIStoryboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"showGameSettings"])
  {
    gameSettingsViewController = (GBAGameSettingsViewController*)[segue destinationViewController];
  }
  else if ([[segue identifier] isEqualToString:@"loadROM"])
  {
    /* Z Edit
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    */
    {
      /*
      NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
      UITableViewCell* cell = (UITableViewCell *)sender;
      self.currentRomPath = [documentsDirectoryPath stringByAppendingPathComponent:[self romPathAtIndexPath:[self.tableView indexPathForCell:cell]]];
      */
      [UIApplication sharedApplication].statusBarHidden = YES;
      emulatorViewController = [segue destinationViewController];
      emulatorViewController.wantsFullScreenLayout = YES;
      emulatorViewController.romPath = self.currentRomPath;        
    }
  }
}

#pragma mark AdSdk Banner Methods

- (IBAction)requestBannerAdvert:(id)sender
{
  NSLog(@"requestBannerAdvert [%d]", currentBannerAd);
  
  if(currentBannerAd < AD_NONE && self.bannerView != nil)
  {
    self.bannerView.allowDelegateAssigmentToRequestAd = NO;
    self.bannerView.delegate = self;
    self.bannerView.refreshTimerOff = YES;
    self.bannerView.backgroundColor = [UIColor clearColor];
    self.bannerView.refreshAnimation = UIViewAnimationTransitionFlipFromLeft;
    
    //self.bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    self.bannerView.requestURL = @"http://zodttd.com/ads/madserve/md.request.php";
    
    [self.bannerView requestAd];
  }
  else
  {
    currentBannerAd = AD_NONE;
    [self.bannerView setHidden:NO];
  }
}

#pragma mark AdSdk Banner Delegate Methods

- (NSString *)publisherIdForAdSdkBannerView:(AdSdkBannerView *)banner
{
  if(currentBannerAd == AD_PRIORITY_ADSDK)
  {
    return @"7a754a2290b6396eb23cc319a5d46b29";
  }
  else if(currentBannerAd == AD_PRIORITY_REVMOB)
  {
    return @"d2f8828335b9b918b458cceb82847b63";
  }
  else if(currentBannerAd == AD_MOPUB)
  {
    return @"7f39fd20fae2f6bc5722d9b7c4fdd149";
  }
  else if(currentBannerAd == AD_REVMOB)
  {
    return @"c5eb49f93a8a49a1bb4a44c5b2ef447e";
  }
  
  // currentBannerAd == AD_ADSDK
  return @"fb7018eee96723441fb49a21089bf14d";
}

- (void)adsdkBannerViewDidLoadAdSdkAd:(AdSdkBannerView *)banner
{
  NSLog(@"AdSdk Banner: did load ad");
  
  // Means an advert has been retrieved and configured.
  // Display the ad using the presentAd method and ensure you pass back the advertType
  
  if(currentBannerAd == AD_PRIORITY_ADSDK)
  {
    [banner setHidden:NO];
    [self.view bringSubviewToFront:banner];
  }
  else if(currentBannerAd == AD_PRIORITY_REVMOB)
  {
    [banner setHidden:NO];
    RevMobBannerView* revMobBannerView = [[RevMobAds session] bannerView];
    
    [revMobBannerView loadWithSuccessHandler:^(RevMobBannerView* revMobBanner) {
      revMobBanner.clipsToBounds = YES;
      [revMobBanner setFrame:CGRectMake(0, 0, 320, 50)];
      if([revMobBanner superview] != self.view)
      {
        [self.view addSubview:revMobBanner];
      }
      [self.view bringSubviewToFront:revMobBanner];
      [self revmobAdDidReceive];
    } andLoadFailHandler:^(RevMobBannerView* revMobBanner, NSError* error) {
      [self revmobAdDidFailWithError:error];
    } onClickHandler:^(RevMobBannerView* revMobBanner) {
      [self revmobUserClickedInTheAd];
    }];
  }
  else if(currentBannerAd == AD_MOPUB)
  {
    [banner setHidden:NO];
    if(self.adView == nil)
    {
      self.adView = [[MPAdView alloc] initWithAdUnitId:@"a3e7f7f8bddc11e281c11231392559e4"
                                                  size:MOPUB_BANNER_SIZE];
    }
    
    self.adView.delegate = self;
    self.adView.clipsToBounds = YES;
    self.adView.frame = CGRectMake(0, 0,
                                   MOPUB_BANNER_SIZE.width, MOPUB_BANNER_SIZE.height);

    if([self.adView superview] != self.view)
    {
      [self.view addSubview:self.adView];
    }
    [self.view bringSubviewToFront:self.adView];
    [self.adView loadAd];
  }
  else if(currentBannerAd == AD_REVMOB)
  {
    [banner setHidden:NO];
    RevMobBannerView* revMobBannerView = [[RevMobAds session] bannerView];
    
    [revMobBannerView loadWithSuccessHandler:^(RevMobBannerView* revMobBanner) {
      revMobBanner.clipsToBounds = YES;
      [revMobBanner setFrame:CGRectMake(0, 0, 320, 50)];
      if([revMobBanner superview] != self.view)
      {
        [self.view addSubview:revMobBanner];
      }
      [self.view bringSubviewToFront:revMobBanner];
      [self revmobAdDidReceive];
    } andLoadFailHandler:^(RevMobBannerView* revMobBanner, NSError* error) {
      [self revmobAdDidFailWithError:error];
    } onClickHandler:^(RevMobBannerView* revMobBanner) {
      [self revmobUserClickedInTheAd];
    }];
  }
  else // AD_ADSDK
  {
    [banner setHidden:NO];
    [self.view bringSubviewToFront:banner];
  }
}

- (void)adsdkBannerView:(AdSdkBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	NSLog(@"AdSdk Banner [%d]: did fail to load ad: %@", error.code, [error localizedDescription]);
  
  NSRange r1 = [[error localizedDescription] rangeOfString:@"inventory" options:NSCaseInsensitiveSearch];
  NSRange r2 = [[error localizedDescription] rangeOfString:@"no ad" options:NSCaseInsensitiveSearch];
  if(r1.length > 0 || r2.length > 0)
  {
    currentBannerAd++;
    [self requestBannerAdvert:self];
  }
  else
  {
    currentBannerAd = AD_NONE;
    if(self.bannerView != nil)
    {
      [self.bannerView setHidden:NO];
    }
    RevMobBannerView* revMobBannerView = [[RevMobAds session] bannerView];
    
    [revMobBannerView loadWithSuccessHandler:^(RevMobBannerView* revMobBanner) {
      revMobBanner.clipsToBounds = YES;
      [revMobBanner setFrame:CGRectMake(0, 0, 320, 50)];
      if([revMobBanner superview] != self.view)
      {
        [self.view addSubview:revMobBanner];
      }
      [self.view bringSubviewToFront:revMobBanner];
      [self revmobAdDidReceive];
    } andLoadFailHandler:^(RevMobBannerView* revMobBanner, NSError* error) {
      [self revmobAdDidFailWithError:error];
    } onClickHandler:^(RevMobBannerView* revMobBanner) {
      [self revmobUserClickedInTheAd];
    }];

  }
}

- (void)adsdkBannerViewDidLoadRefreshedAd:(AdSdkBannerView *)banner
{
  NSLog(@"AdSdk Banner: Received a 'refreshed' advert");

  [self adsdkBannerViewDidLoadAdSdkAd:banner];
}

#pragma mark - MoPub delegate methods

- (UIViewController *)viewControllerForPresentingModalView
{
  return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
  NSLog(@"MP Banner load");
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view
{
  NSLog(@"MP Banner failed loading");
  
  currentBannerAd++;
  [self requestBannerAdvert:self];
}

#pragma mark - RevMobAdsDelegate methods

- (void)revmobAdDidReceive
{
  NSLog(@"[RevMob] Ad loaded.");
}

- (void)revmobAdDidFailWithError:(NSError *)error
{
  NSLog(@"[RevMob] Ad failed: %@", error);
  
  if(currentBannerAd == AD_NONE)
  {
    if(self.bannerView != nil)
    {
      [self.bannerView setHidden:NO];
    }
    
    if(self.adView == nil)
    {
      self.adView = [[MPAdView alloc] initWithAdUnitId:@"a3e7f7f8bddc11e281c11231392559e4"
                                                  size:MOPUB_BANNER_SIZE];
    }
    
    self.adView.delegate = self;
    self.adView.clipsToBounds = YES;
    self.adView.frame = CGRectMake(0, 0,
                                   MOPUB_BANNER_SIZE.width, MOPUB_BANNER_SIZE.height);
    
    if([self.adView superview] != self.view)
    {
      [self.view addSubview:self.adView];
    }
    [self.view bringSubviewToFront:self.adView];
    [self.adView loadAd];
  }
  else
  {
    currentBannerAd++;
    [self requestBannerAdvert:self];
  }
}

- (void)revmobAdDisplayed
{
  NSLog(@"[RevMob] Ad displayed.");
}

- (void)revmobUserClosedTheAd
{
  NSLog(@"[RevMob] User clicked in the close button.");
  currentBannerAd = AD_NONE;
}

- (void)revmobUserClickedInTheAd
{
  NSLog(@"[RevMob] User clicked in the Ad.");
  currentBannerAd = AD_NONE;
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
