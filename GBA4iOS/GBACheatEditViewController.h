//
//  GBACheatEditViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GBACheatEditViewController : UIViewController<UITextViewDelegate>

@property (copy, nonatomic) NSString* currentGame;
@property (nonatomic, assign) id delegate;
@property (strong, nonatomic) UITextView* cheatsTextView;

- (IBAction)closeSettings:(id)sender;
- (void)setGame:(NSString*)game;
- (IBAction)loadCheats;
- (IBAction)saveCheats;
- (void)cancelCheats;
- (void)keyboardWillShow:(NSNotification *)notification;

@end
