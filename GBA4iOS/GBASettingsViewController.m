//
//  GBASettingsViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBASettingsViewController.h"
#import "GBAAppDelegate.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@interface GBASettingsViewController ()

@end

@implementation GBASettingsViewController
@synthesize frameskipSegmentedControl;
@synthesize scaledSwitch;
@synthesize audioSwitch;

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self)
  {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.frameskipSegmentedControl.selectedSegmentIndex = preferences.frameskip;

  self.scaledSwitch.contentMode = UIViewContentModeCenter;
  self.scaledSwitch.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  self.scaledSwitch.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.scaledSwitch.on = preferences.smoothscaling;

  self.audioSwitch.contentMode = UIViewContentModeCenter;
  self.audioSwitch.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  self.audioSwitch.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.audioSwitch.on = preferences.gameaudio;
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
  [self setFrameskipSegmentedControl:nil];
  [self setScaledSwitch:nil];
  [self setAudioSwitch:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
}

#pragma mark - Change Settings

- (IBAction)changeFrameskip:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setInteger:self.frameskipSegmentedControl.selectedSegmentIndex forKey:@"frameskip"];
}

- (IBAction)toggleScaled:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setBool:self.scaledSwitch.on forKey:@"smoothscaling"];
}

- (IBAction)toggleAudio:(id)sender
{
  [[NSUserDefaults standardUserDefaults] setBool:self.audioSwitch.on forKey:@"gameaudio"];
  
  if(self.audioSwitch.on)
  {
    app_DemuteSound();
  }
  else
  {
    app_MuteSound();
  }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Dismiss

- (IBAction)closeSettings:(id)sender
{
    GBAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    [appDelegate updatePreferences];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
