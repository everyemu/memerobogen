//
//  GBASettingsSkinViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBASettingsSkinViewController.h"
#import "GBAAppDelegate.h"
#import "GBAMasterViewController.h"
#import "helpers.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@implementation GBASettingsSkinViewController

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
  [self.navigationItem setTitle:@"Select Skin"];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
  if(controllerskins.skins == NULL)
  {
    controllerskins.numberofskins = 0;
    controllerskins.currentskin = 0;
    controllerskins.skins = malloc(sizeof(ControllerSkin) * CONTROLLER_SKINS_MAX);
  }
  if(controllerskins.skins != NULL)
  {
    GBAAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate getSkins:&controllerskins];
    [self.tableView reloadData];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  if(controllerskins.skins != NULL)
  {
    free(controllerskins.skins);
    controllerskins.skins = NULL;
    controllerskins.numberofskins = 0;
    controllerskins.currentskin = 0;
  }
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString* CellIdentifier = @"Cell";
  
  UITableViewCell* cell = nil;
  UILabel* cellSkinLabel = nil;
  UILabel* cellSkinNameLabel = nil;
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  if(indexPath.row == controllerskins.currentskin)
  {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  }
  else
  {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  if(indexPath.row >= 0 && indexPath.row < controllerskins.numberofskins)
  {
    cellSkinNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, tableView.bounds.size.width - 50.0f, 20.0f)];
    cellSkinLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 20.0f, tableView.bounds.size.width - 50.0f, 20.0f)];
    
    [cellSkinNameLabel setText:[NSString stringWithUTF8String:controllerskins.skins[indexPath.row].name]];
    [cellSkinLabel setAdjustsFontSizeToFitWidth:YES];
    //[cellSkinLabel setAdjustsLetterSpacingToFitWidth:YES];
    [cellSkinLabel setText:[NSString stringWithUTF8String:controllerskins.skins[indexPath.row].filename]];
    
    [cell.contentView addSubview:cellSkinNameLabel];
    [cell.contentView addSubview:cellSkinLabel];
  }  
  
  return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return @"Skins Loaded";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return controllerskins.numberofskins;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.row >= 0 && indexPath.row < CONTROLLER_SKINS_MAX)
  {
    NSString* controllerSkinFilename = [NSString stringWithUTF8String:controllerskins.skins[indexPath.row].filename];
    
    if([controllerSkinFilename compare:@"controller1_default.txt"] == NSOrderedSame ||
       [controllerSkinFilename compare:@"controller2_default.txt"] == NSOrderedSame ||
       [controllerSkinFilename compare:@"controller3_default.txt"] == NSOrderedSame )
    {
      return @"RESET";
    }
    
    return @"DELETE";
  }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(editingStyle == UITableViewCellEditingStyleDelete)
  {    
    if(indexPath.row >= 0 && indexPath.row < CONTROLLER_SKINS_MAX)
    {
      GBAAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
      NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

      NSFileManager* fileManager = [NSFileManager defaultManager];
      NSError* error = nil;
      NSString* documentsDirectory = [NSString stringWithUTF8String:get_documents_path("")];
      NSString* skinsDirectory = [documentsDirectory stringByAppendingPathComponent:@"skins"];
      NSString* controllerSkinFilename = [NSString stringWithUTF8String:controllerskins.skins[indexPath.row].filename];
      
      if([fileManager removeItemAtPath:[skinsDirectory stringByAppendingPathComponent:controllerSkinFilename] error:&error])
      {
        NSLog(@"Successfully deleted controller skin text file from skins directory");
      }
      else
      {
        NSLog(@"%@. %@.", error, [error userInfo]);
      }
      
      if(strcmp(preferences.skinfile, controllerskins.skins[indexPath.row].filename) == 0)
      {
        [[NSUserDefaults standardUserDefaults] setObject:@"controller3_default.txt" forKey:@"skinfile"];
        
        [appDelegate updatePreferences];
      }
      
      [appDelegate importDefaultSkins];
      
      if(controllerskins.skins == NULL)
      {
        controllerskins.skins = malloc(sizeof(ControllerSkin) * CONTROLLER_SKINS_MAX);
        controllerskins.numberofskins = 0;
        controllerskins.currentskin = 0;
      }
      
      if(controllerskins.skins != NULL)
      {
        [appDelegate getSkins:&controllerskins];
      }

      [tableView reloadData];
    }
  }
}

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
  if(indexPath.row >= 0 && indexPath.row < CONTROLLER_SKINS_MAX)
  {
    GBAAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithUTF8String:controllerskins.skins[indexPath.row].filename] forKey:@"skinfile"];

    [appDelegate updatePreferences];
    
    if(controllerskins.skins == NULL)
    {
      controllerskins.skins = malloc(sizeof(ControllerSkin) * CONTROLLER_SKINS_MAX);
      controllerskins.numberofskins = 0;
      controllerskins.currentskin = 0;
    }
    
    if(controllerskins.skins != NULL)
    {
      [appDelegate getSkins:&controllerskins];
    }
    
    [tableView reloadData];
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
  }
}

@end
