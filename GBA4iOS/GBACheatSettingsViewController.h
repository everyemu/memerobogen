//
//  GBACheatSettingsViewController.h
//  GBA4iOS
//
//  Created by Riley Testut on 6/3/12.
//  Copyright (c) 2012 Testut Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GBACheatSettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel*   cheatCodeLabel;
@property (weak, nonatomic) IBOutlet UILabel*   cheatCodeNameLabel;
@property (weak, nonatomic) IBOutlet UISwitch*  cheatCodeEnable;

- (void)setGame:(NSString*)game;
- (IBAction)scanCheatDirectory;
- (IBAction)toggleCheats:(id)sender;
- (void)clearCheats;
//- (IBAction)saveCheats;

@end
