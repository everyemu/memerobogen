//
//  WebBrowserViewController.m
//  gpSPhone
//
//  Created by ZodTTD LLC.
//  Copyright (c) 2013 ZodTTD LLC. All rights reserved.
//

#import "WebBrowserViewController.h"
#import "GBAMasterViewController.h"
#import "helpers.h"

@class WebPolicyDecisionListenerPrivate;

static WebBrowserViewController* sharedInstance = nil;

@interface WebPolicyDecisionListener : NSObject
{
//    WebPolicyDecisionListenerPrivate *_private;
}
- (id)_initWithTarget:(id)fp8 action:(SEL)fp12;
- (void)dealloc;
- (void)_usePolicy:(int)fp8;
- (void)_invalidate;
- (void)use;
- (void)ignore;
- (void)download;
@end

@implementation NSObject (MyNSObject)

-(void)UIWebView_webView:(id)sender decidePolicyForMIMEType:(NSString*)type request:(NSURLRequest*)request frame:(id)frame decisionListener:(WebPolicyDecisionListener*)listener
{
  if([type isEqualToString:@"application/zip"] || [type isEqualToString:@"application/x-zip"] || [type isEqualToString:@"application/octet-stream"] || [type isEqualToString:@"multipart/x-zip"])
  {
    [listener ignore];
  	
    [sharedInstance startingDownload:request withType:type];
  }
}

@end

#import <objc/runtime.h>
#import <objc/message.h>

#define SetNSError(ERROR_VAR, FORMAT,...)  \
  if (ERROR_VAR) {  \
    NSString *errStr = [@"error:]: " stringByAppendingFormat:FORMAT,##__VA_ARGS__];  \
    *ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain" \
                     code:-1  \
                   userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
  }

@implementation NSObject (doWork)

+ (BOOL)changeMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {

#if OBJC_API_VERSION >= 2
  Method origMethod = class_getInstanceMethod(self, origSel_);
  if (!origMethod) {
    NSLog(@"Couldn't find orig method %@ %@", NSStringFromSelector(origSel_), [self class]);
    SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self class]);
    return NO;
  }

  Method altMethod = class_getInstanceMethod(self, altSel_);
  if (!altMethod) {
    NSLog(@"Couldn't find alt method %@ %@", NSStringFromSelector(altSel_), [self class]);
    SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self class]);
    return NO;
  }

  class_addMethod(self,
          origSel_,
          class_getMethodImplementation(self, origSel_),
          method_getTypeEncoding(origMethod));
  class_addMethod(self,
          altSel_,
          class_getMethodImplementation(self, altSel_),
          method_getTypeEncoding(altMethod));

  method_exchangeImplementations(class_getInstanceMethod(self, origSel_), class_getInstanceMethod(self, altSel_));
  return YES;
#else
  //  Scan for non-inherited methods.
  Method directOriginalMethod = NULL, directAlternateMethod = NULL;

  void *iterator = NULL;
  struct objc_method_list *mlist = class_copyMethodList(self, &iterator);
  while (mlist) {
    int method_index = 0;
    for (; method_index < mlist->method_count; method_index++) {
      if (mlist->method_list[method_index].method_name == origSel_) {
        assert(!directOriginalMethod);
        directOriginalMethod = &mlist->method_list[method_index];
      }
      if (mlist->method_list[method_index].method_name == altSel_) {
        assert(!directAlternateMethod);
        directAlternateMethod = &mlist->method_list[method_index];
      }
    }
    free(mlist);
    mlist = class_copyMethodList(self, &iterator);
  }

  //  If either method is inherited, copy it up to the target class to make it non-inherited.
  if (!directOriginalMethod || !directAlternateMethod) {
    Method inheritedOriginalMethod = NULL, inheritedAlternateMethod = NULL;
    if (!directOriginalMethod) {
      inheritedOriginalMethod = class_getInstanceMethod(self, origSel_);
      if (!inheritedOriginalMethod) {
        SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
        return NO;
      }
    }
    if (!directAlternateMethod) {
      inheritedAlternateMethod = class_getInstanceMethod(self, altSel_);
      if (!inheritedAlternateMethod) {
        SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
        return NO;
      }
    }

    int hoisted_method_count = !directOriginalMethod && !directAlternateMethod ? 2 : 1;
    struct objc_method_list *hoisted_method_list = malloc(sizeof(struct objc_method_list) + (sizeof(struct objc_method)*(hoisted_method_count-1)));
    hoisted_method_list->method_count = hoisted_method_count;
    Method hoisted_method = hoisted_method_list->method_list;

    if (!directOriginalMethod) {
      bcopy(inheritedOriginalMethod, hoisted_method, sizeof(struct objc_method));
      directOriginalMethod = hoisted_method++;
    }
    if (!directAlternateMethod) {
      bcopy(inheritedAlternateMethod, hoisted_method, sizeof(struct objc_method));
      directAlternateMethod = hoisted_method;
    }
    class_addMethod(self, hoisted_method_list);
  }

  //  zle.
  IMP temp = directOriginalMethod->method_imp;
  directOriginalMethod->method_imp = directAlternateMethod->method_imp;
  directAlternateMethod->method_imp = temp;

  return YES;
#endif
}



+ (BOOL)changeMethodStatic:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {


  Method origMethod = class_getClassMethod(self, origSel_);
  if (!origMethod) {
  //NSLog(@"Couldn't find orig method");
    SetNSError(error_, @"method %@ not found for class %@", NSStringFromSelector(origSel_), [self class]);
    return NO;
  }

  Method altMethod = class_getClassMethod(self, altSel_);
  if (!altMethod) {
  //NSLog(@"Couldn't find alt method");
    SetNSError(error_, @"alt method %@ not found for class %@", NSStringFromSelector(altSel_), [self class]);
    return NO;
  }

  class_addMethod(self,
          origSel_,
          class_getMethodImplementation(self, origSel_),
          method_getTypeEncoding(origMethod));
  class_addMethod(self,
          altSel_,
          class_getMethodImplementation(self, altSel_),
          method_getTypeEncoding(altMethod));

  method_exchangeImplementations(class_getClassMethod(self, origSel_), class_getClassMethod(self, altSel_));
  return YES;

}
@end


@implementation UIDownloadBar

@synthesize DownloadRequest;
@synthesize DownloadConnection;
@synthesize receivedData;
@synthesize delegate;
@synthesize percentComplete;
@synthesize operationIsOK;
@synthesize appendIfExist;
@synthesize possibleFilename;

- (void)forceStop
{
	operationBreaked = YES;
  if(DownloadConnection != nil)
  {
    [DownloadConnection cancel];
    DownloadConnection = nil;
  }
}

- (void)forceContinue
{
	operationBreaked = NO;
  
  //	NSLog(@"%f",bytesReceived);
	NSMutableURLRequest* request = [DownloadRequest mutableCopy];
  
	[request addValue: [NSString stringWithFormat: @"bytes=%.0f-", bytesReceived ] forHTTPHeaderField: @"Range"];
  
	DownloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}


- (UIDownloadBar *)initWithURLRequest:(NSURLRequest*)urlRequest progressBarFrame:(CGRect)frame timeout:(NSInteger)timeout delegate:(id<UIDownloadBarDelegate>)theDelegate
{
	self = [super initWithFrame:frame];
	if(self)
  {
		self.delegate = theDelegate;
		bytesReceived = percentComplete = 0;
		receivedData = [[NSMutableData alloc] initWithLength:0];
		self.progress = 0.0;
		self.backgroundColor = [UIColor clearColor];
		DownloadRequest = [urlRequest copy];
		DownloadConnection = [[NSURLConnection alloc] initWithRequest:DownloadRequest delegate:self startImmediately:YES];
    
		if(DownloadConnection == nil)
    {
			[self.delegate downloadBar:self didFailWithError:[NSError errorWithDomain:@"UIDownloadBar Error" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"NSURLConnection Failed", NSLocalizedDescriptionKey, nil]]];
		}
	}
  
	return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!operationBreaked)
  {
 		[self.receivedData appendData:data];
    
		float receivedLen = [data length];
		bytesReceived = (bytesReceived + receivedLen);
    
		if(expectedBytes != NSURLResponseUnknownLength)
    {
			self.progress = ((bytesReceived/(float)expectedBytes)*100)/100;
			percentComplete = self.progress*100;
		}
    
		[delegate downloadBarUpdated:self];
	}
  else
  {
		[connection cancel];
	}  
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self.delegate downloadBar:self didFailWithError:error];
	operationFailed = YES;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{  
  possibleFilename = [response suggestedFilename];
	NSHTTPURLResponse *r = (NSHTTPURLResponse*) response;
	NSDictionary *headers = [r allHeaderFields];
	if (headers)
  {
		if ([headers objectForKey: @"Content-Range"])
    {
			NSString *contentRange = [headers objectForKey: @"Content-Range"];
			NSRange range = [contentRange rangeOfString: @"/"];
			NSString *totalBytesCount = [contentRange substringFromIndex: range.location + 1];
			expectedBytes = [totalBytesCount floatValue];
		}
    else if ([headers objectForKey: @"Content-Length"])
    {
			expectedBytes = [[headers objectForKey: @"Content-Length"] floatValue];
		}
    else
    {
      expectedBytes = -1;
    }
    
		if ([@"Identity" isEqualToString: [headers objectForKey: @"Transfer-Encoding"]])
    {
			expectedBytes = bytesReceived;
			operationFinished = YES;
		}
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self.delegate downloadBar:self didFinishWithData:self.receivedData suggestedFilename:possibleFilename];
	operationFinished = YES;
	NSLog(@"Connection did finish loading...");
}

@end


@implementation WebBrowserViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  sharedInstance = self;
  
  webView = [[UIWebView alloc] initWithFrame:self.view.frame];
  [self.view addSubview:webView];
  
	
	NSLog(@"Swizzling policy delegate");
	[NSClassFromString(@"WebDefaultPolicyDelegate") changeMethod: @selector(webView:decidePolicyForMIMEType:request:frame:decisionListener:) withMethod: @selector(UIWebView_webView:decidePolicyForMIMEType:request:frame:decisionListener:) error:nil];
	webView.delegate = self;

	[webView setScalesPageToFit:NO];
  webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

  
  self.navigationItem.hidesBackButton = YES;
  UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissWebController)];
  self.navigationItem.leftBarButtonItem = doneButton;
	UIBarButtonItem* goBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Go Back"
                                                          style:UIBarButtonItemStylePlain
                                                          target:webView action:@selector(goBack)];
  self.navigationItem.rightBarButtonItem = goBackButton;
  
	//self.contentSizeForViewInPopover = CGSizeMake(600, 700);
	[self loadBaseURL];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  [webView removeFromSuperview];
  webView = nil;  
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
}

- (void)dismissWebController
{
  if([self.presentingViewController respondsToSelector:@selector(scanRomDirectory)])
  {
    GBAMasterViewController* masterViewController = (GBAMasterViewController*)self.presentingViewController;
    [masterViewController scanRomDirectory];
  }
  [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
  NSString* title = [aWebView stringByEvaluatingJavaScriptFromString: @"document.title"];
  self.navigationItem.title = title;
}


- (void)loadBaseURL
{
  NSString *urlAddress = @"http://www.zodttd.com/app/gpSPhone/search.php";
  NSURL *url = [NSURL URLWithString:urlAddress];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];

	NSLog(@"loading URL: %@", url);
  [webView loadRequest:requestObj];
}

- (void)didReceiveMemoryWarning 
{
  [super didReceiveMemoryWarning];
}

-(void)startingDownload:(NSURLRequest*)request withType:(NSString*)type
{
	NSLog(@"Starting Download with request: %@", request);
  downloadRequest = [request copy];
  downloadType = [type copy];
  NSString* alertMessage = [NSString stringWithFormat:@"%@", @"Please confirm that you own and\nare downloading this file legally.\n"];
	UIAlertView* downloadAlertView=[[UIAlertView alloc] initWithTitle:nil
                    message:alertMessage
										delegate:self cancelButtonTitle:nil
                    otherButtonTitles:@"DENY",@"CONFIRM",nil];
  downloadAlertView.tag = 0;
	[downloadAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if(alertView.tag == 0)
  {
    if(buttonIndex == 1)
    {
      downloadWaitAlertView=[[UIAlertView alloc] initWithTitle:nil
                        message:@"Downloading now.\nThis prompt will close when the download is done.\n\n"
                        delegate:self cancelButtonTitle:nil otherButtonTitles:@"CANCEL", nil];
      
      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
      NSLog(@"Downloading...");
      downloadProgressView = [[UIDownloadBar alloc] initWithURLRequest:downloadRequest
                                                    progressBarFrame:CGRectMake(40, 90, 200, 20)
                                                    timeout:30
                                                    delegate:self];
      [downloadWaitAlertView addSubview:downloadProgressView];
      downloadWaitAlertView.tag = 1;
      [downloadWaitAlertView show];
    }
  }
  else if(alertView.tag == 1)
  {
    [downloadProgressView forceStop];
    [downloadWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
  }
}


- (void)downloadBar:(UIDownloadBar *)downloadBar didFinishWithData:(NSData *)fileData suggestedFilename:(NSString *)filename
{
	NSLog(@"%@", filename);
  if(fileData != nil)
  {
    NSString* fileNameFull;
    NSString* fileName = filename;
    NSString* fileNameExt = [fileName pathExtension];
    
    fileNameFull = fileName;
    
    if(([fileNameExt caseInsensitiveCompare:@"zip"] != NSOrderedSame) &&
       ([fileNameExt caseInsensitiveCompare:@"smc"] != NSOrderedSame) &&
       ([fileNameExt caseInsensitiveCompare:@"swc"] != NSOrderedSame) &&
       ([fileNameExt caseInsensitiveCompare:@"bin"] != NSOrderedSame) &&
       ([fileNameExt caseInsensitiveCompare:@"gba"] != NSOrderedSame) )
    {
      if([downloadType isEqualToString:@"application/zip"] || [downloadType isEqualToString:@"application/x-zip"])
      {
        fileNameFull = [fileName stringByAppendingPathExtension:@"zip"];
      }
      else
      {
        fileNameFull = [fileName stringByAppendingPathExtension:@"bin"];
      }
    }
    
    NSString* documentsDirectoryPath = [NSString stringWithUTF8String:get_documents_path("")];
    [fileData writeToFile:[NSString stringWithFormat:@"%@/%@", documentsDirectoryPath, fileNameFull] atomically:NO];
  }
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [downloadWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)downloadBar:(UIDownloadBar *)downloadBar didFailWithError:(NSError *)error
{
	NSLog(@"%@", error);  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [downloadWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)downloadBarUpdated:(UIDownloadBar *)downloadBar
{
}

@end

