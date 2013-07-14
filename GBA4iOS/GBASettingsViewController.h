//
//  GBASettingsViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GBASettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl* frameskipSegmentedControl;
@property (weak, nonatomic) IBOutlet UISwitch* scaledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch* audioSwitch;

- (IBAction)closeSettings:(id)sender;
- (IBAction)changeFrameskip:(id)sender;
- (IBAction)toggleScaled:(id)sender;
- (IBAction)toggleAudio:(id)sender;

@end
