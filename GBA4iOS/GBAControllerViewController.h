//
//  GBAControllerViewController.h
//  GBAController
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../iGBA/Frameworks/GraphicsServices.h"
#import <UIKit/UIKit.h>
#import "../iGBA/Frameworks/UIKit-Private/UIView-Geometry.h"
#import "ScreenView.h"
#import "GBAEmulatorViewController.h"
#import "iCadeState.h"

/*
 UP ON,OFF  = w,e
 RT ON,OFF  = d,c
 DN ON,OFF  = x,z
 LT ON,OFF  = a,q
 A  ON,OFF  = y,t
 B  ON,OFF  = h,r
 C  ON,OFF  = u,f
 D  ON,OFF  = j,n
 E  ON,OFF  = i,m
 F  ON,OFF  = k,p
 G  ON,OFF  = o,g
 H  ON,OFF  = l,v
*/

#define CONTROLLER_BUTTONS_MAX 16

@class GBAEmulatorViewController;

@interface GBAControllerViewController : UIViewController <UIAlertViewDelegate, UIKeyInput>
{
  UIImage* controllerImage;
  UIImageView* imageView;
  UIButton* infoButton;
  UIButton* connectionButton;
  CGRect buttonRectsData[CONTROLLER_BUTTONS_MAX];
  UIView* inputView;
  
  struct
  {
    bool stateChanged:1;
    bool buttonDown:1;
    bool buttonUp:1;
  } _iCadeDelegateFlags;
}

@property (strong, nonatomic) UIImage* controllerImage;
@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UIButton* infoButton;
@property (nonatomic, strong) IBOutlet UIButton* connectionButton;
@property (copy, nonatomic) NSString* imageName;
@property (nonatomic) BOOL landscape; 
@property (nonatomic) BOOL editingButtons;
@property (nonatomic) NSInteger buttonToEdit;
@property (nonatomic) BOOL movingButton;
@property (nonatomic) BOOL selectedButton;
@property (nonatomic) BOOL deselectedButton;
@property (nonatomic) CGRect buttonRect;
@property (nonatomic) CGRect buttonRectEdit;
@property (nonatomic) CGRect* buttonRects;
@property (nonatomic) NSInteger currentSkinImage;

@property (weak, nonatomic) GBAEmulatorViewController* emulatorViewController;
@property (nonatomic, assign) iCadeState iCadeState;
@property (nonatomic, assign) BOOL controllerSkinActive;

- (void)didEnterBackground;
- (void)didBecomeActive;
- (void)buttonDown:(iCadeState)button;
- (void)buttonUp:(iCadeState)button;
- (void)setActive:(BOOL)value;
- (int)getController:(BOOL)withImage;
- (void)updateUI;
- (void)showControllerButtons:(BOOL)isRefresh;

@end

