//
//  GBACheatMenuViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC
//  Copyright (c) ZodTTD LLC. All rights reserved.
//

#import "GBACheatMenuViewController.h"
#import "GBACheatEditViewController.h"
#import "GBAEmulatorViewController.h"
#import "GBAAppDelegate.h"
#import "helpers.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@interface GBACheatMenuViewController ()
@property (copy, nonatomic) NSString *currentGame;
@end

@implementation GBACheatMenuViewController
@synthesize currentGame;
@synthesize cheatCodeNameLabel;
@synthesize cheatCodeLabel;
@synthesize cheatCodeEnable;
@synthesize delegate;
@synthesize gameSettingsViewController;

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
  
  UIBarButtonItem* editCheatsButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(showEditCheats)];

  self.navigationItem.leftBarButtonItem = editCheatsButton;

  UIBarButtonItem* doneWithCheatsButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneWithCheats)];
  self.navigationItem.rightBarButtonItem = doneWithCheatsButton;
  
  [self.navigationItem setTitle:@"Cheat Settings"];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
  [self scanCheatDirectory];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)doneWithCheats
{
  [gameSettingsViewController doneWithCheats];
}

- (void)showEditCheats
{
  GBACheatEditViewController* cheatEditViewController = [[GBACheatEditViewController alloc] init];
  UINavigationController* cheatEditNavController = [[UINavigationController alloc] initWithRootViewController:cheatEditViewController];  
  [cheatEditViewController setDelegate:self];
  [cheatEditViewController setGame:currentGame];
  cheatEditNavController.navigationBar.barStyle = UIBarStyleDefault;
  [self presentModalViewController:cheatEditNavController animated:YES];
}

- (IBAction)scanCheatDirectory
{
  FILE* cheatfile;
  int cheatcount = 0;
  char cheatcode[32];
  char cheatname[256];
  char cheatfilename[1024];
  NSString* cheatDirectory = [NSString stringWithUTF8String:get_documents_path("cheats")];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  [fileManager createDirectoryAtPath:cheatDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  
  snprintf(cheatfilename, 1024, "%s/%s.cht", [cheatDirectory UTF8String], [currentGame UTF8String]);
  cheatfile = fopen(cheatfilename, "r");

  if(cheatfile)
  {
    while(!feof(cheatfile))
    {
      int linesread = 0;
      if(fgets(cheatname, 256, cheatfile) != NULL)
      {
        NSRange r = [[NSString stringWithUTF8String:cheatname] rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
        
        if(r.location == NSNotFound ||
           cheatname[0] == '\0' ||
           cheatname[0] == '\n' ||
           cheatname[0] == '\r')
        {
          continue;
        }

        if(strlen(cheatname) > 2)
        {
          if(cheatname[strlen(cheatname) - 1] == '\n')
          {
            cheatname[strlen(cheatname) - 1] = '\0';
          }
          if(cheatname[strlen(cheatname) - 1] == '\r')
          {
            cheatname[strlen(cheatname) - 1] = '\0';
          }
        }
        
        linesread++;
        
        while(fgets(cheatcode, 32, cheatfile) != NULL)
        {
          if(strlen(cheatcode) > 10 && strlen(cheatcode) < 21)
          {
            if(cheatcode[strlen(cheatcode) - 1] == '\n')
            {
              cheatcode[strlen(cheatcode) - 1] = '\0';
            }
            if(cheatcode[strlen(cheatcode) - 1] == '\r')
            {
              cheatcode[strlen(cheatcode) - 1] = '\0';
            }
            
            [self.delegate setCheatNumber:cheatcount withName:cheatname withCode:cheatcode];
            linesread++;
            
            cheatcount++;
            if(cheatcount >= 100)
            {
              break;
            }
          }
          else
          {
            break;
          }
        }
        
        if(linesread < 2)
        {
          break;
        }
      }
    }
    fclose(cheatfile);
  }
  
  [self.delegate setNumberOfCheats:cheatcount];
  [self.tableView reloadData];
}

#pragma mark - Change Settings

- (IBAction)toggleCheats:(id)sender
{
  UISwitch* cheatSwitch = (UISwitch*)sender;
    
  [self.delegate toggleCheatNumber:cheatSwitch.tag willEnable:cheatSwitch.isOn];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString* CellIdentifier = @"Cell";
  
  UITableViewCell* cell = nil;
  UILabel* cellCheatLabel = nil;
  UILabel* cellCheatNameLabel = nil;
  UISwitch* cellCheatEnableSwitch = nil;
  
  cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  cell.accessoryType = UITableViewCellAccessoryNone;

  if(indexPath.row < [self.delegate getNumberOfCheats])
  {
    cellCheatNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, 200.0f, 20.0f)];
    cellCheatLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 20.0f, 200.0f, 20.0f)];
    cellCheatEnableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(236.0f, 8.0f, 79.0f, 27.0f)];
    
    [cellCheatNameLabel setText:[NSString stringWithUTF8String:[self.delegate getCheatNameWithNumber:indexPath.row]]];
    [cellCheatLabel setText:[NSString stringWithUTF8String:[self.delegate getCheatCodeWithNumber:indexPath.row]]];
    [cellCheatEnableSwitch setOn:([self.delegate getCheatEnabledWithNumber:indexPath.row] != 0 ? TRUE : FALSE)];
    cellCheatEnableSwitch.tag = indexPath.row;
    [cellCheatEnableSwitch addTarget:self action:@selector(toggleCheats:) forControlEvents:UIControlEventValueChanged];

    [cell.contentView addSubview:cellCheatNameLabel];
    [cell.contentView addSubview:cellCheatLabel];
    [cell.contentView addSubview:cellCheatEnableSwitch];
  }
  
  
  return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return @"Cheats Loaded";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.delegate getNumberOfCheats];
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
}

#pragma mark - Managing the game rom setting

- (void)setGame:(NSString*)game
{
  currentGame = game;
}


#pragma mark - UIStoryboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"showCheatEdit"])
  {
    GBACheatEditViewController* viewController = (GBACheatEditViewController*)[segue destinationViewController];
    [viewController setDelegate:self];
    [viewController setGame:currentGame];
    //[viewController loadCheats];
  }
}

@end
