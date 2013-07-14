//
//  GBAGameSettingsViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GBAGameSettingsViewController : UITableViewController

@property (nonatomic, assign) id delegate;
@property (weak, nonatomic) IBOutlet UISwitch* fastForwardSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* audioSwitch;

- (void)setGame:(NSString*)game;
- (IBAction)toggleFastForward:(id)sender;
- (IBAction)toggleAudio:(id)sender;
- (void)doneWithCheats;

@end
