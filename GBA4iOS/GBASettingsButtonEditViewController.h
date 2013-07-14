//
//  GBASettingsButtonEditViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GBAControllerViewController.h"
#import "GBAMasterViewController.h"

@class GBAControllerViewController;

@interface GBASettingsButtonEditViewController : UIViewController
{
  ControllerSkins controllerskins;
}

@property (strong, nonatomic) GBAControllerViewController* controllerViewController;
@property (weak, nonatomic) IBOutlet UILabel* buttonHorizontalLabel;
@property (weak, nonatomic) IBOutlet UILabel* buttonVerticalLabel;
@property (weak, nonatomic) IBOutlet UILabel* buttonHorizontalSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel* buttonVerticalSizeLabel;
@property (weak, nonatomic) IBOutlet UIStepper* buttonHorizontalStepper;
@property (weak, nonatomic) IBOutlet UIStepper* buttonVerticalStepper;
@property (weak, nonatomic) IBOutlet UIStepper* buttonHorizontalSizeStepper;
@property (weak, nonatomic) IBOutlet UIStepper* buttonVerticalSizeStepper;
@property (weak, nonatomic) IBOutlet UIButton* buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton* buttonSave;
@property (nonatomic) NSInteger buttonToEdit;
@property (nonatomic) BOOL viewSet;
@property (nonatomic) CGRect buttonRect;
@property (nonatomic) NSInteger selectedOrientation;

- (IBAction)buttonHorizontalPositionChanged:(id)sender;
- (IBAction)buttonVerticalPositionChanged:(id)sender;
- (IBAction)buttonHorizontalSizeChanged:(id)sender;
- (IBAction)buttonVerticalSizeChanged:(id)sender;
- (IBAction)buttonCanceled:(id)sender;
- (IBAction)buttonSaved:(id)sender;
- (void)setupViews:(BOOL)isRefresh;

@end
