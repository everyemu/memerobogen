//
//  GBACheatMenuViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GBAGameSettingsViewController.h"

@interface GBACheatMenuViewController : UITableViewController

@property (strong, nonatomic) GBAGameSettingsViewController* gameSettingsViewController;
@property (nonatomic, assign) id delegate;
@property (weak, nonatomic) IBOutlet UILabel*   cheatCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel*   cheatCodeNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch*  cheatCodeEnable;

- (void)setGame:(NSString*)game;
- (IBAction)scanCheatDirectory;
- (IBAction)toggleCheats:(id)sender;
//- (void)clearCheats;
- (void)showEditCheats;
//- (void)doneWithCheats;
//- (IBAction)saveCheats;

@end
