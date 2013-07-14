//
//  GBACheatEditViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "GBACheatEditViewController.h"
#import "GBAAppDelegate.h"
#import "GBACheatMenuViewController.h"
#import "helpers.h"

#import "../iGBA/iphone/gpSPhone/src/iphone.h"

@implementation GBACheatEditViewController
@synthesize currentGame;
@synthesize delegate;
@synthesize cheatsTextView;

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  
  UIBarButtonItem* cancelCheatsButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelCheats)];
  
  UIBarButtonItem* saveCheatsButton = [[UIBarButtonItem alloc ] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveCheats)];
  
  self.navigationItem.leftBarButtonItem = cancelCheatsButton;
  
  self.navigationItem.rightBarButtonItem = saveCheatsButton;
  
  [self.navigationItem setTitle:@"Game Cheats"];
  
  cheatsTextView = [[UITextView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 140.0f)];
  cheatsTextView.text = [NSString stringWithUTF8String:"Supports Gameshark and Codebreaker cheat codes.\nMulti-line cheats are supported.\nCheat codes can be found in a zip inside: /Applications/gpSPhone.app/Cheat_files_for_gpSP_by_PokeDude232425.zip\nThey can be found online at: http://zodttd.com/downloads/Cheat_files_for_gpSP_by_PokeDude232425.zip\nMany of these cheat codes can also be found by searching Codebreaker and Gameshark cheat code sites.\n\nFormat is as follows:\n[cheat code type] [cheat code name]\n[cheat code with proper spacing]\n[if multi line cheat code place one cheat code per line]\nFor example:\nPAR_V3 Master Cheat Enable\n301bd558 4540675c\n39f3ea42 0f4bac42\n\nPAR_V3 Infinite Lives\na04dc49b c9d641b8"];
  cheatsTextView.delegate = self;
  cheatsTextView.tag = 0;
  cheatsTextView.textColor = [UIColor lightGrayColor];
  cheatsTextView.font = [UIFont systemFontOfSize:12.0f];
  cheatsTextView.dataDetectorTypes = UIDataDetectorTypeNone;
  [self.view addSubview:cheatsTextView];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillShow:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
  [cheatsTextView becomeFirstResponder];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
  [self loadCheats];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)textViewDidChange:(UITextView *)textView
{
  if(textView.tag == 0)
  {
    textView.text = @"";
    textView.textColor = [UIColor blackColor];
    textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    textView.tag = 1;
  }
}

- (IBAction)loadCheats
{
  FILE* cheatfile;
  char cheatline[256];
  char cheatfilename[1024];
  NSRange r;
  NSMutableString* cheatString = [NSMutableString stringWithString:@""];
  NSString* cheatDirectory = [NSString stringWithUTF8String:get_documents_path("cheats")];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  [fileManager createDirectoryAtPath:cheatDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  
  snprintf(cheatfilename, 1024, "%s/%s.cht", [cheatDirectory UTF8String], [currentGame UTF8String]);
  cheatfile = fopen(cheatfilename, "r");
    
  if(cheatfile)
  {    
    while(!feof(cheatfile))
    {
      if(fgets(cheatline, 256, cheatfile) != NULL)
      {
        [cheatString appendFormat:@"%s", cheatline];
      }
    }
    fclose(cheatfile);
  }

  r = [cheatString rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]];
  if(r.location != NSNotFound)
  {
    cheatsTextView.tag = 1;
    cheatsTextView.textColor = [UIColor blackColor];
    cheatsTextView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    cheatsTextView.text = cheatString;
  }
}

- (IBAction)saveCheats
{
  FILE* cheatfile;
  char cheatfilename[1024];
  //char cheatfiletext[32 * 1024]; //((256+32) * 100) + 3968
  NSString* cheatDirectory = [NSString stringWithUTF8String:get_documents_path("cheats")];
  NSFileManager *fileManager = [[NSFileManager alloc] init];
  [fileManager createDirectoryAtPath:cheatDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  
  snprintf(cheatfilename, 1024, "%s/%s.cht", [cheatDirectory UTF8String], [currentGame UTF8String]);
  cheatfile = fopen(cheatfilename, "w");
  
  if(cheatfile)
  {
    fprintf(cheatfile, "%s", [cheatsTextView.text UTF8String]);
    fclose(cheatfile);
  }
  
  //[self.delegate scanCheatDirectory];
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)cancelCheats
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification
{
  
  /*
   Reduce the size of the text view so that it's not obscured by the keyboard.
   Animate the resize so that it's in sync with the appearance of the keyboard.
   */
  
  NSDictionary *userInfo = [notification userInfo];
  
  // Get the origin of the keyboard when it's displayed.
  NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
  
  // Get the top of the keyboard as the y coordinate of its origin in self's view's
  // coordinate system. The bottom of the text view's frame should align with the top
  // of the keyboard's final position.
  //
  CGRect keyboardRect = [aValue CGRectValue];
  keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
  
  CGFloat keyboardTop = keyboardRect.origin.y;
  CGRect newTextViewFrame = self.view.bounds;
  newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
  
  // Get the duration of the animation.
  NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
  NSTimeInterval animationDuration;
  [animationDurationValue getValue:&animationDuration];
  
  // Animate the resize of the text view's frame in sync with the keyboard's appearance.
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:animationDuration];
  
  cheatsTextView.frame = newTextViewFrame;
  
  [UIView commitAnimations];
}

#pragma mark - Managing the game rom setting

- (void)setGame:(NSString*)game
{
  currentGame = game;
}

#pragma mark - Dismiss

- (IBAction)closeSettings:(id)sender
{
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
