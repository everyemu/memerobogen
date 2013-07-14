//
//  GBASettingsButtonViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBASettingsButtonViewController.h"
#import "GBAAppDelegate.h"
#import "GBAMasterViewController.h"
#import "GBASettingsButtonEditViewController.h"
#import "helpers.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

//ControllerButtons controllerButtons;

@interface GBASettingsButtonViewController ()

@end

@implementation GBASettingsButtonViewController
@synthesize selectedButton;
@synthesize orientationSegmentedControl;

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if(self)
  {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.navigationItem setTitle:@"Select Button"];
  self.orientationSegmentedControl.selectedSegmentIndex = 0;
}

- (void)viewDidUnload
{
  [self setOrientationSegmentedControl:nil];
  [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

-(BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.row >= 0 && indexPath.row < CONTROLLER_BUTTONS_MAX)
  {
    self.selectedButton = [tableView cellForRowAtIndexPath:indexPath].tag;
    [self performSegueWithIdentifier:@"showButtonEditSettings" sender:self];

/*
    GBAAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:controllerButtons.Buttons[indexPath.row].filename] forKey:@"Buttonfile"];

    [appDelegate updatePreferences];
    
    if(controllerButtons.Buttons == NULL)
    {
      controllerButtons.Buttons = malloc(sizeof(ControllerButton) * CONTROLLER_ButtonS_MAX);
      controllerButtons.numberofButtons = 0;
      controllerButtons.currentButton = 0;
    }
    if(controllerButtons.Buttons != NULL)
    {
      numberOfButtons = [appDelegate getButtons:&controllerButtons];
    }
    
    [tableView reloadData];
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
*/
  }
}

#pragma mark - UIStoryboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([[segue identifier] isEqualToString:@"showButtonEditSettings"])
  {
    GBASettingsButtonEditViewController* viewController = (GBASettingsButtonEditViewController*)[segue destinationViewController];
    viewController.buttonToEdit = self.selectedButton;
    viewController.selectedOrientation = self.orientationSegmentedControl.selectedSegmentIndex;
  }
}

@end
