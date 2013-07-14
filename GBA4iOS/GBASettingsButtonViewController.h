//
//  GBASettingsButtonViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GBASettingsButtonViewController : UITableViewController

@property (nonatomic) NSInteger selectedButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl* orientationSegmentedControl;

@end
