//
//  GBACheatSettingsViewController.m
//  GBA4iOS
//
//  Created by Riley Testut on 6/3/12.
//  Copyright (c) 2012 Testut Tech. All rights reserved.
//

#import "GBACheatSettingsViewController.h"
#import "GBACheatEditViewController.h"
#import "GBAAppDelegate.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

typedef struct
{
  int   enabled;
  char  name[256];
  char  code[32];
} GameCheat;

typedef struct
{
  GameCheat   cheat[100];
  int         numberOfCheats;
} GameRom;

GameRom gamerom;

@interface GBACheatSettingsViewController ()
@property (copy, nonatomic) NSString *currentGame;
@end

@implementation GBACheatSettingsViewController
@synthesize currentGame;
@synthesize cheatCodeNameLabel;
@synthesize cheatCodeLabel;
@synthesize cheatCodeEnable;

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
      // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  //[self clearCheats];
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;

  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)clearCheats
{
  int i;
  for(i = 0; i < 100; i++)
  {
    gamerom.cheat[i].enabled = 0;
    gamerom.cheat[i].name[0] = '\0';
    gamerom.cheat[i].code[0] = '\0';
  }
  gamerom.numberOfCheats = 0;
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
  
  gamerom.numberOfCheats = 0;
  
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
            
            snprintf(gamerom.cheat[cheatcount].name, 256, "%s", cheatname);
            snprintf(gamerom.cheat[cheatcount].code, 32, "%s", cheatcode);
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
  
  gamerom.numberOfCheats = cheatcount;
  [self.tableView reloadData];
}

#pragma mark - Change Settings

- (IBAction)toggleCheats:(id)sender
{
  //[[NSUserDefaults standardUserDefaults] setBool:self.cheatsSwitch.on forKey:@"cheatsEnabled"];
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

  if(indexPath.row < gamerom.numberOfCheats)
  {
    cellCheatNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, 200.0f, 20.0f)];
    cellCheatLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 20.0f, 200.0f, 20.0f)];
    cellCheatEnableSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(236.0f, 8.0f, 79.0f, 27.0f)];
    
    [cellCheatNameLabel setText:[NSString stringWithUTF8String:gamerom.cheat[indexPath.row].name]];
    [cellCheatLabel setText:[NSString stringWithUTF8String:gamerom.cheat[indexPath.row].code]];
    [cellCheatEnableSwitch setOn:FALSE];
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
  return gamerom.numberOfCheats;
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
    GBACheatEditViewController* viewController = (GBACheatEditViewController*)[(UINavigationController*)[segue destinationViewController] visibleViewController];
    [viewController setDelegate:self];
    [viewController setGame:currentGame];
    //[viewController loadCheats];
  }
}

@end
