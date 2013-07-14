//
//  WebBrowserViewController.h
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIProgressView;
@protocol UIDownloadBarDelegate;

@interface UIDownloadBar : UIProgressView
{
	float           bytesReceived;
	long long       expectedBytes;
  
	BOOL            operationFinished, operationFailed, operationBreaked;
	FILE*           downFile;
	//NSString*     fileUrlPath;
}

- (UIDownloadBar *)initWithURLRequest:(NSURLRequest*)urlRequest progressBarFrame:(CGRect)frame timeout:(NSInteger)timeout delegate:(id<UIDownloadBarDelegate>)theDelegate;

@property (assign) BOOL operationIsOK;
@property (assign) BOOL appendIfExist;

@property (nonatomic, readonly) NSMutableData* receivedData;
@property (nonatomic, readonly, retain) NSURLRequest* DownloadRequest;
@property (nonatomic, readonly, retain) NSURLConnection* DownloadConnection;
@property (nonatomic, assign) id<UIDownloadBarDelegate> delegate;

@property (nonatomic, readonly) float percentComplete;
@property (nonatomic, retain) NSString* possibleFilename;

- (void) forceStop;
- (void) forceContinue;

@end


@protocol UIDownloadBarDelegate<NSObject>

@optional
- (void)downloadBar:(UIDownloadBar *)downloadBar didFinishWithData:(NSData *)fileData suggestedFilename:(NSString *)filename;
- (void)downloadBar:(UIDownloadBar *)downloadBar didFailWithError:(NSError *)error;
- (void)downloadBarUpdated:(UIDownloadBar *)downloadBar;

@end


@interface WebBrowserViewController : UIViewController < UIAlertViewDelegate, UIWebViewDelegate, UIDownloadBarDelegate>
{
	IBOutlet UIWebView*	      webView;
  UIAlertView*              downloadWaitAlertView;
  UIDownloadBar*            downloadProgressView;
  NSURLRequest*             downloadRequest;
  NSString*                 downloadType;  
}


- (void)loadBaseURL;
- (void)startingDownload:(NSURLRequest*)request withType:(NSString*)type;
- (void)dismissWebController;

@end
