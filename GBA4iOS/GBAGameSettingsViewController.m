//
//  GBAGameSettingsViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBAGameSettingsViewController.h"
#import "GBAAppDelegate.h"
#import "GBACheatMenuViewController.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@interface GBAGameSettingsViewController ()
@property (copy, nonatomic) NSString* currentGame;
@end

@implementation GBAGameSettingsViewController
@synthesize currentGame;
@synthesize delegate;
@synthesize fastForwardSwitch;
@synthesize audioSwitch;

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if(self)
  {
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  UIBarButtonItem* doneWithOptionsButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneWithOptions)];
  self.navigationItem.rightBarButtonItem = doneWithOptionsButton;
}

- (void)viewDidAppear:(BOOL)animated
{
  fastForwardSwitch.on = [self.delegate isFastForwardEnabled];
  if(app_GetAudioVolume() != 0.0f)
  {
    audioSwitch.on = YES;
  }
  else
  {
    audioSwitch.on = NO;
  }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
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
  if([tableView cellForRowAtIndexPath:indexPath].tag == 1)
  {
    GBACheatMenuViewController* cheatMenuViewController = [[GBACheatMenuViewController alloc] init];
    UINavigationController* cheatMenuNavController = [[UINavigationController alloc] initWithRootViewController:cheatMenuViewController];
    [cheatMenuViewController setGameSettingsViewController:self];
    [cheatMenuViewController setDelegate:self.delegate];
    [cheatMenuViewController setGame:currentGame];
    cheatMenuNavController.navigationBar.barStyle = UIBarStyleDefault;
    [self presentModalViewController:cheatMenuNavController animated:YES];
  }
}

#pragma mark - Managing the game rom setting

- (void)setGame:(NSString*)game
{
  currentGame = game;
}

- (IBAction)toggleFastForward:(id)sender
{
  [self.delegate enableFastForward:fastForwardSwitch.on];
}

- (IBAction)toggleAudio:(id)sender
{
  if(audioSwitch.on)
  {
    app_DemuteSound();
  }
  else
  {
    app_MuteSound();
  }
}

- (void)doneWithOptions
{
  [UIApplication sharedApplication].statusBarHidden = YES;
  [self.delegate doneWithOptions];
}

- (void)doneWithCheats
{
  [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIStoryboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if([[segue identifier] isEqualToString:@"showCheatSettings"])
  {
  }
}

@end
