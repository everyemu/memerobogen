//
//  ScreenView.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../iGBA/Frameworks/CoreSurface.h"
#include <pthread.h>

#import <QuartzCore/QuartzCore.h>

extern CoreSurfaceBufferRef screenSurface;

@interface ScreenView : UIView 
{
	NSTimer *timer;
    CGRect rect;
    CALayer *screenLayer;
}

void updateScreen();

- (id)initWithFrame:(CGRect)frame;
- (void)dealloc;
- (void)drawRect:(CGRect)frame;
- (void)initializeGraphics;
- (void)rotateForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@end
