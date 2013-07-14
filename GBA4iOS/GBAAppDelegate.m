//
//  GBAAppDelegate.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBAAppDelegate.h"
#import <RevMobAds/RevMobAds.h>
#import "GBAMasterViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "helpers.h"
#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@class gpSPhone_iphone;

char * __preferencesFilePath;
extern int app_LoadPreferences();
extern int app_SavePreferences();

@implementation GBAAppDelegate

@synthesize window = _window;
@synthesize emulatorViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [RevMobAds startSessionWithAppID:@"519a9afb23dad9a81b00000a"];
  
  // Override point for customization after application launch.
  /*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
      UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
      splitViewController.delegate = (id)navigationController.topViewController;
  }*/
  
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  
/*
  if(![defaults integerForKey:@"version"] ||
     [defaults integerForKey:@"version"] < 80007)
  {
    [defaults setBool:YES forKey:@"gameaudio"];
  }
  if(![defaults integerForKey:@"version"] ||
     [defaults integerForKey:@"version"] < 80008)
  {
    [defaults setObject:@"controller3_default.txt" forKey:@"skinfile"];
  }
*/
  
  if([defaults integerForKey:@"version"] != APP_VERSION_NUM)
  {
    [defaults setInteger:APP_VERSION_NUM forKey:@"version"];
  }
  
  if(![defaults objectForKey:@"firstRun"])
  {
    [defaults setObject:@"controller3_default.txt" forKey:@"skinfile"];
    [defaults setInteger:5 forKey:@"frameskip"];
    [defaults setBool:YES forKey:@"cheatsEnabled"];
    [defaults setBool:YES forKey:@"smoothscaling"];
    [defaults setBool:YES forKey:@"gameaudio"];
    [defaults setObject:[NSDate date] forKey:@"firstRun"];
  }
  
  [self updatePreferences];

  self.emulatorViewController = nil;
  
  [self performSelector:@selector(loadAppData) withObject:nil afterDelay:0.0];

  return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)loadAppData
{
  [self importDefaultSkins];
  [self importSaveStates];
}

- (void)importDefaultSkins
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* documentsDirectory = [NSString stringWithUTF8String:get_documents_path("")];
  NSString* skinsDirectory = [documentsDirectory stringByAppendingPathComponent:@"skins"];
  NSString* originalSkinsDirectory = [NSString stringWithUTF8String:get_resource_path("")];
  int numberOfControllers = 3;
  ControllerSkins skin;
  
  [fileManager createDirectoryAtPath:skinsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  
  for(int i = 0; i < numberOfControllers; i++)
  {
    NSError* error = nil;
    NSString* controllerFilename = [NSString stringWithFormat:@"controller%d_default.txt", i + 1];
    char skintypes[CONTROLLER_SKINS_DEVICETYPES_MAX * 2][32] = CONTROLLER_SKINTYPE_ARRAY;
    
    if(![fileManager fileExistsAtPath:[skinsDirectory stringByAppendingPathComponent:controllerFilename]])
    {
      if([fileManager copyItemAtPath:[originalSkinsDirectory stringByAppendingPathComponent:controllerFilename] toPath:[skinsDirectory stringByAppendingPathComponent:controllerFilename] error:&error] && !error)
      {
        NSLog(@"Successfully copied default controller text file to skins directory");
      }
      else
      {
        NSLog(@"%@. %@.", error, [error userInfo]);
      }
    }
    
    for(int imageIndex = 0; imageIndex < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; imageIndex++)
    {
      NSString* controllerImageFilename = [NSString stringWithFormat:@"controller%d_%@_%s.png", i + 1, imageIndex < CONTROLLER_SKINS_DEVICETYPES_MAX ? @"portrait" : @"landscape",  skintypes[imageIndex]];
      
      if(![fileManager fileExistsAtPath:[skinsDirectory stringByAppendingPathComponent:controllerImageFilename]])
      {
        if([fileManager copyItemAtPath:[originalSkinsDirectory stringByAppendingPathComponent:controllerImageFilename] toPath:[skinsDirectory stringByAppendingPathComponent:controllerImageFilename] error:&error] && !error)
        {
          NSLog(@"Successfully copied default controller image file to skins directory");
        }
        else
        {
          NSLog(@"%@. %@.", error, [error userInfo]);
        }
      }
    }
  }
  
  skin.skins = malloc(sizeof(ControllerSkin) * CONTROLLER_SKINS_MAX);
  if(skin.skins != NULL)
  {
    [self getSkins:&skin];
    free(skin.skins);
  }
}

- (void)importSaveStates
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  
  NSString* documentsDirectory = [NSString stringWithUTF8String:get_documents_path("")];
  NSString* saveStateDirectory = [documentsDirectory stringByAppendingPathComponent:@"save_states"];
  
  [fileManager createDirectoryAtPath:saveStateDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  
  NSArray* dirContents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
  [dirContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* filename = obj;
    NSString* filenameExt = [filename pathExtension];
    
    if([filenameExt caseInsensitiveCompare:@"svs"] == NSOrderedSame)
    {
      int arrayCount = 5;
      NSError* error = nil;
      NSString* fullRomName = [filename stringByDeletingPathExtension];
      NSRange r = [fullRomName rangeOfString:@".zip" options:NSBackwardsSearch];
      NSString* romName = fullRomName;
      
      if(r.location == NSNotFound)
      {
        r = [fullRomName rangeOfString:@".gba" options:NSBackwardsSearch];
      }
      if(r.location == NSNotFound)
      {
        r = [fullRomName rangeOfString:@".bin" options:NSBackwardsSearch];
      }
      if(r.location != NSNotFound)
      {
        romName = [fullRomName substringToIndex:r.location];
      }

      NSString* originalFilePath = [documentsDirectory stringByAppendingPathComponent:filename];
      NSString* romSaveStateDirectory = [saveStateDirectory stringByAppendingPathComponent:romName];
      NSString* saveStateInfoPath = [romSaveStateDirectory stringByAppendingPathComponent:@"info.plist"];
      
      [fileManager createDirectoryAtPath:romSaveStateDirectory withIntermediateDirectories:YES attributes:nil error:nil];
      
      NSMutableArray* saveStateArray;
      NSMutableArray* array = [[NSMutableArray alloc] initWithContentsOfFile:saveStateInfoPath];
      
      if([array count] <= 0)
      {
        saveStateArray = [[NSMutableArray alloc] initWithCapacity:5];
        
        for (int i = 0; i < 5; i++)
        {
          [saveStateArray addObject:NSLocalizedString(@"Empty", @"")];
        }
      }
      else
      {
        saveStateArray = array;
      }
      
      if([saveStateArray count] < 5)
      {
        arrayCount = [saveStateArray count];
      }
      else
      {
        arrayCount = 5;
      }
      
      for(int i = 0; i < arrayCount; i++)
      {
        NSString* arrayString = [saveStateArray objectAtIndex:i];
        if([arrayString compare:NSLocalizedString(@"Empty", @"")] == NSOrderedSame)
        {
          [saveStateArray replaceObjectAtIndex:i withObject:NSLocalizedString(@"Imported", @"")];
          [saveStateArray writeToFile:saveStateInfoPath atomically:YES];
          
          NSString* destinationFilename = [NSString stringWithFormat:@"%d.svs", i];
          NSString* destinationFilePath = [romSaveStateDirectory stringByAppendingPathComponent:destinationFilename];
          
          if([fileManager copyItemAtPath:originalFilePath toPath:destinationFilePath error:&error] && !error)
          {
            [fileManager moveItemAtPath:originalFilePath toPath:[originalFilePath stringByAppendingString:@".imported"] error:nil];
            NSLog(@"Successfully copied svs file to save state directory");
          }
          else
          {
            NSLog(@"%@. %@.", error, [error userInfo]);
          }
          break;
        }
      }
    }
  }];
}

- (NSString*)isValidSkinFile:(NSString*)file
{
  NSRange r;
  NSFileManager* fileManager = [[NSFileManager alloc] init];
  FILE* skinfile;
  char linetext[1024];
  int skinsloaded;
  int linenum = 0;
  char skintypes[CONTROLLER_SKINS_DEVICETYPES_MAX * 2][16] = CONTROLLER_SKINTYPE_ARRAY;
  int skintypesread[CONTROLLER_SKINS_DEVICETYPES_MAX * 2] = {0,0,0,0,0,0,0,0,0,0};
  
  skinfile = fopen([file UTF8String], "r");
  
  if(skinfile == NULL)
  {
    return [NSString stringWithFormat:@"%@ %@", @"NOT VALID SKIN: FILE NOT FOUND", file];
  }
  
  if(fgets(linetext, 1024, skinfile) == NULL)
  {
    fclose(skinfile);
    return [NSString stringWithFormat:@"%@ %@", @"NOT VALID SKIN: NO SKIN NAME", file];
  }
  
  r = [[NSString stringWithUTF8String:linetext] rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
  
  if(r.location == NSNotFound ||
     linetext[0] == '\0' ||
     linetext[0] == '\n' ||
     linetext[0] == '\r')
  {
    fclose(skinfile);
    return [NSString stringWithFormat:@"%@ %@", @"NOT VALID SKIN: BAD SKIN NAME", file];
  }
  
  for(skinsloaded = 0; skinsloaded < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; skinsloaded++)
  {
    NSString* currentSkinImageFile;
    int skins;
    int skinfound;
    int coordnum;
    char* result;
    int screenwidth = 0;
    int screenheight = 0;
    int coord[4];
    
    if(fgets(linetext, 1024, skinfile) == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %d %@", @"NOT VALID SKIN: NO SKIN TYPE", skinsloaded, file];
    }
    
    r = [[NSString stringWithUTF8String:linetext] rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    
    if(r.location == NSNotFound ||
       linetext[0] == '\0' ||
       linetext[0] == '\n' ||
       linetext[0] == '\r')
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %d %@", @"NOT VALID SKIN: INVALID SKIN TYPE", skinsloaded, file];
    }
    
    if(strlen(linetext) > 2)
    {
      if(linetext[strlen(linetext) - 1] == '\n')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
      if(linetext[strlen(linetext) - 1] == '\r')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
    }
    
    skinfound = 0;
    
    for(skins = 0; skins < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; skins++)
    {
      if(strncasecmp(linetext, skintypes[skins], 16) == 0)
      {
        if(skintypesread[skins] == 0)
        {
          skinfound = 1;
          skintypesread[skins] = 1;
          break;
        }
        else
        {
          fclose(skinfile);
          return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: DUPLICATE SKIN TYPE", skintypes[skins], file];
        }
      }
    }
    
    if(skinfound == 0)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %@", @"NOT VALID SKIN: UNKNOWN SKIN TYPE", file];
    }
    
    result = strtok(skintypes[skins], "x");
    if(result == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: BAD INTERNAL SCREEN SIZE", skintypes[skins], file];
    }
    screenwidth = atoi(result);
    result = strtok(NULL, "x");
    if(result == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: BAD INTERNAL SCREEN SIZE", skintypes[skins], file];
    }
    screenheight = atoi(result);    
    
    if(fgets(linetext, 1024, skinfile) == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: NO SKIN IMAGE FILE", skintypes[skins], file];
    }
    
    r = [[NSString stringWithUTF8String:linetext] rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
    
    if(r.location == NSNotFound ||
       linetext[0] == '\0' ||
       linetext[0] == '\n' ||
       linetext[0] == '\r')
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: INVALID SKIN IMAGE FILENAME", skintypes[skins], file];
    }
    
    if(strlen(linetext) > 2)
    {
      if(linetext[strlen(linetext) - 1] == '\n')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
      if(linetext[strlen(linetext) - 1] == '\r')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
    }
    
    currentSkinImageFile = [NSString stringWithUTF8String:linetext];
    
    if([[currentSkinImageFile pathExtension] caseInsensitiveCompare:@"png"] != NSOrderedSame)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: SKIN IMAGE FILENAME IS NOT A PNG", skintypes[skins], file];
    }
    
    if(![fileManager isReadableFileAtPath:[[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:currentSkinImageFile]])
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@ %@", @"NOT VALID SKIN: SKIN IMAGE IS NOT READABLE", skintypes[skins], currentSkinImageFile, file];
    }
    
    for(linenum = 0; linenum < 16; linenum++)
    {
      coordnum = 0;

      if(fgets(linetext, 1024, skinfile) == NULL)
      {
        fclose(skinfile);
        return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: NO COORDS", skintypes[skins], file];
      }
      
      if(strlen(linetext) > 2)
      {
        if(linetext[strlen(linetext) - 1] == '\n')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
        if(linetext[strlen(linetext) - 1] == '\r')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
      }

      result = strtok(linetext, ",");
      while( coordnum < 4 )
      {
        char* screenresult;
        
        if(result == NULL)
        {
          fclose(skinfile);
          return [NSString stringWithFormat:@"%@ %s %s %@", @"NOT VALID SKIN: BAD COORD COUNT", skintypes[skins], linetext, file];
        }
        
        result = strtok(NULL, ",");
        coordnum++;
      }
    }
    
    if(fgets(linetext, 1024, skinfile) == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: NO ALPHA SET", skintypes[skins], file];
    }
    
    if(strtoul(linetext, NULL, 0) > 100)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: ALPHA SET OUT OF BOUNDS", skintypes[skins], file];
    }

    if(fgets(linetext, 1024, skinfile) == NULL)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: NO SCREEN COORDS", skintypes[skins], file];
    }
    
    if(strlen(linetext) > 2)
    {
      if(linetext[strlen(linetext) - 1] == '\n')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
      if(linetext[strlen(linetext) - 1] == '\r')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
    }
    
    coordnum = 0;
    result = strtok(linetext, ",");
    while( coordnum < 4 )
    {
      if(result == NULL)
      {
        fclose(skinfile);
        return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: BAD SCREEN COORD COUNT", skintypes[skins], file];
      }
      coord[coordnum] = atoi(result);

      result = strtok(NULL, ",");
      coordnum++;
    }
    if(coord[0] < 0 || coord[0] > screenwidth   ||
       coord[1] < 0 || coord[1] > screenheight  ||
       coord[2] < 0 || coord[2] > screenwidth   ||
       coord[3] < 0 || coord[3] > screenheight  ||
       coord[0] + coord[2] > screenwidth        ||
       coord[1] + coord[3] > screenheight )
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %d %d %d %d %d %d %s %@", @"NOT VALID SKIN: BAD SCREEN COORDS", coord[0], coord[1], coord[2], coord[3], screenwidth, screenheight, skintypes[skins], file];
    }
      
    // blank line seperator
    fgets(linetext, 1024, skinfile);
  }
  
  for(skinsloaded = 0; skinsloaded < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; skinsloaded++)
  {
    if(skintypesread[skinsloaded] == 0)
    {
      fclose(skinfile);
      return [NSString stringWithFormat:@"%@ %s %@", @"NOT VALID SKIN: MISSING SKIN TYPE", skintypes[skinsloaded], file];
    }
  }
  
  fclose(skinfile);
  return @"VALID";
}

- (NSInteger)getSkins:(ControllerSkins*)controller
{
  int currentSkin;
  int skincount;
  int fileread;
  NSString* skinDirectory = [NSString stringWithUTF8String:get_documents_path("skins")];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  NSArray *filelist;
  [fileManager createDirectoryAtPath:skinDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  filelist = [fileManager contentsOfDirectoryAtPath:skinDirectory error:NULL];
  
  currentSkin = -1;
  skincount = 0;
  
  NSLog(@"getSkins skin directory count %d", [filelist count]);
  
  for(fileread = 0; fileread < (int)[filelist count]; fileread++)
  {
    NSString* currentSkinFileExt;
    NSString* skinresult;
    FILE* skinfile;
    char linetext[1024];
    char skintypes[CONTROLLER_SKINS_DEVICETYPES_MAX * 2][32] = CONTROLLER_SKINTYPE_ARRAY;
    int devicetype;
    
    NSLog(@"getSkins fileread %d", fileread);
   
    /*
    if(fileread == -2)
    {
      NSLog(@"getSkins skin %@", [NSString stringWithUTF8String:get_resource_path("controller2_default.txt")]);
      
      skinresult = [self isValidSkinFile:[NSString stringWithUTF8String:get_resource_path("controller2_default.txt")]];
      if([skinresult caseInsensitiveCompare:@"VALID"] != NSOrderedSame)
      {
        NSLog(@"SKIN VALIDITY: %@", skinresult);
        continue;
      }
      
      skinfile = fopen(get_resource_path("controller2_default.txt"), "r");
      
      if(skinfile == NULL)
      {
        NSLog(@"getSkins failed!");
        continue;
      }
      
      snprintf(controller->skins[skincount].filename, 256, "%s", get_resource_path("controller2_default.txt"));
    }
    else if(fileread == -1)
    {
      NSLog(@"getSkins skin %@", [NSString stringWithUTF8String:get_resource_path("controller_default.txt")]);
      
      skinresult = [self isValidSkinFile:[NSString stringWithUTF8String:get_resource_path("controller_default.txt")]];
      if([skinresult caseInsensitiveCompare:@"VALID"] != NSOrderedSame)
      {
        NSLog(@"SKIN VALIDITY: %@", skinresult);
        continue;
      }
      
      skinfile = fopen(get_resource_path("controller_default.txt"), "r");
      
      if(skinfile == NULL)
      {
        NSLog(@"getSkins failed!");
        continue;
      }
      
      snprintf(controller->skins[skincount].filename, 256, "%s", get_resource_path("controller_default.txt"));
    }
    else*/
    {
      NSLog(@"getSkin skin %@", filelist[fileread]);
      
      currentSkinFileExt = [filelist[fileread] pathExtension];
      if([currentSkinFileExt caseInsensitiveCompare:@"txt"] != NSOrderedSame)
      {
        continue;
      }
      
      skinresult = [self isValidSkinFile:[NSString stringWithFormat:@"%@/%@", skinDirectory, filelist[fileread]]];
      if([skinresult caseInsensitiveCompare:@"VALID"] != NSOrderedSame)
      {
        NSLog(@"SKIN VALIDITY: %@", skinresult);
        continue;
      }
      
      snprintf(linetext, 1024, "%s/%s", [skinDirectory UTF8String], [filelist[fileread] UTF8String]);
      skinfile = fopen(linetext, "r");
      
      if(skinfile == NULL)
      {
        continue;
      }
      
      snprintf(controller->skins[skincount].filename, 256, "%s", [filelist[fileread] UTF8String]);
    }
    
    if(strncasecmp(preferences.skinfile, controller->skins[skincount].filename, 256) == 0)
    {
      currentSkin = skincount;
      NSLog(@"getSkins currentSkin %d %s", currentSkin, preferences.skinfile);
    }
    
    if(fgets(linetext, 256, skinfile) == NULL)
    {
      fclose(skinfile);
      continue;
    }
    
    if(strlen(linetext) > 2)
    {
      if(linetext[strlen(linetext) - 1] == '\n')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
      if(linetext[strlen(linetext) - 1] == '\r')
      {
        linetext[strlen(linetext) - 1] = '\0';
      }
    }
    
    snprintf(controller->skins[skincount].name, 256, "%s", linetext);
    
    for(devicetype = 0; devicetype < CONTROLLER_SKINS_DEVICETYPES_MAX * 2; devicetype++)
    {
      int linenum;
      int coordnum = 0;
      char* result;
      
      if(fgets(linetext, 256, skinfile) == NULL)
      {
        fclose(skinfile);
        continue;
      }
      
      if(strlen(linetext) > 2)
      {
        if(linetext[strlen(linetext) - 1] == '\n')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
        if(linetext[strlen(linetext) - 1] == '\r')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
      }
      
      snprintf(controller->skins[skincount].images[devicetype].devicetype, 16, "%s", linetext);

      if(fgets(linetext, 256, skinfile) == NULL)
      {
        fclose(skinfile);
        continue;
      }
      
      if(strlen(linetext) > 2)
      {
        if(linetext[strlen(linetext) - 1] == '\n')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
        if(linetext[strlen(linetext) - 1] == '\r')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
      }
      
      snprintf(controller->skins[skincount].images[devicetype].imagefile, 256, "%s", linetext);

      for(linenum = 0; linenum < 16; linenum++)
      {
        coordnum = 0;
        
        if(fgets(linetext, 1024, skinfile) == NULL)
        {
          continue;
        }
        
        if(strlen(linetext) > 2)
        {
          if(linetext[strlen(linetext) - 1] == '\n')
          {
            linetext[strlen(linetext) - 1] = '\0';
          }
          if(linetext[strlen(linetext) - 1] == '\r')
          {
            linetext[strlen(linetext) - 1] = '\0';
          }
        }

        result = strtok(linetext, ",");
        while(coordnum < 4)
        {
          if(result != NULL)
          {
            controller->skins[skincount].images[devicetype].coords[linenum][coordnum] = (int)strtol(result, NULL, 0);
          }
          result = strtok(NULL, ",");
          coordnum++;
        }
      }
      
      if(fgets(linetext, 1024, skinfile) == NULL)
      {
        continue;
      }
      
      if(strlen(linetext) > 2)
      {
        if(linetext[strlen(linetext) - 1] == '\n')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
        if(linetext[strlen(linetext) - 1] == '\r')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
      }
      
      controller->skins[skincount].images[devicetype].alpha = (unsigned char)strtoul(linetext, NULL, 0);
      
      if(fgets(linetext, 1024, skinfile) == NULL)
      {
        continue;
      }
      
      if(strlen(linetext) > 2)
      {
        if(linetext[strlen(linetext) - 1] == '\n')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
        if(linetext[strlen(linetext) - 1] == '\r')
        {
          linetext[strlen(linetext) - 1] = '\0';
        }
      }
      
      coordnum = 0;
      result = strtok(linetext, ",");
      while( coordnum < 4 )
      {
        if(result == NULL)
        {
          continue;
        }
        controller->skins[skincount].images[devicetype].screencoords[coordnum] = (int)atoi(result);

        result = strtok(NULL, ",");
        coordnum++;
      }
      
      // blank line seperator
      fgets(linetext, 1024, skinfile);
    }
    
    skincount++;
    fclose(skinfile);
    if(skincount >= CONTROLLER_SKINS_MAX)
    {
      break;
    }
  }
  
  if(currentSkin != -1)
  {
    memcpy(&controllerskin, &controller->skins[currentSkin], sizeof(ControllerSkin));
  }
  
  NSLog(@"getSkins skin count %d", skincount);
  
  controller->currentskin = currentSkin;
  controller->numberofskins = skincount;
  
  return skincount;
}

#pragma mark - Preferences

- (void)updatePreferences
{
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

  snprintf(preferences.skinfile, 256, "%s", [[defaults stringForKey:@"skinfile"] UTF8String]);
  preferences.frameskip = [defaults integerForKey:@"frameskip"];
  preferences.smoothscaling = [defaults boolForKey:@"smoothscaling"];
  preferences.gameaudio = [defaults boolForKey:@"gameaudio"];
}

@end
