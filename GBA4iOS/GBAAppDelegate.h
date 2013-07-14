//
//  GBAAppDelegate.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GBAMasterViewController.h"
#import "GBAEmulatorViewController.h"

@interface GBAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) GBAEmulatorViewController* emulatorViewController;

- (void)updatePreferences;
- (NSString*)isValidSkinFile:(NSString*)file;
- (NSInteger)getSkins:(ControllerSkins*)controller;
- (void)importDefaultSkins;
- (void)importSaveStates;
- (void)loadAppData;

@end
