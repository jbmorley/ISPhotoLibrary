//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"
#import "ISPhotoService.h"

typedef enum {
  ISItemViewControllerStateUnknown,
  ISItemViewControllerStateDownloading,
  ISItemViewControllerStateViewing,
} ISItemViewControllerState;

typedef enum {
  ISItemViewControllerChromeStateUnknown,
  ISItemViewControllerChromeStateShown,
  ISItemViewControllerChromeStateHidden,
} ISItemViewControllerChromeState;


@interface ISItemViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISItemViewControllerState state;
@property (nonatomic) ISItemViewControllerChromeState chromeState;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, strong) NSString *cacheIdentifier;

@end

@implementation ISItemViewController


static CGFloat kAnimationDuration = 0.0f;


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.imageView.alpha = 0.0f;
  self.progressView.alpha = 0.0f;
  self.cache = [ISCache defaultCache];
  self.state = ISItemViewControllerStateViewing;
  self.chromeState = ISItemViewControllerChromeStateShown;
  [self.cache addObserver:self];
  
  UITapGestureRecognizer *gestureRecognizer =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleTap:)];
  gestureRecognizer.numberOfTapsRequired = 1;
  gestureRecognizer.numberOfTouchesRequired = 1;
  gestureRecognizer.enabled = YES;
  [self.view addGestureRecognizer:gestureRecognizer];
  
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Begin observing the cache and kick-off
  // the item download.
  [self.cache addObserver:self];
  [self fetchItem];
  
}


- (void)viewDidDisappear:(BOOL)animated
{
  [self.cache removeObserver:self];
  [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (NSString *)url
{
  return [ISPhotoService itemURL:self.identifier];
}


- (void)setState:(ISItemViewControllerState)state
{
  if (_state != state) {
    _state = state;
    if (_state == ISItemViewControllerStateDownloading) {
      [UIView animateWithDuration:kAnimationDuration
                       animations:^{
                         self.progressView.alpha = 1.0f;
                         self.imageView.alpha = 0.0f;
                       }
                       completion:^(BOOL finished) {}];
    } else if (_state == ISItemViewControllerStateViewing) {
      [UIView animateWithDuration:kAnimationDuration
                       animations:^{
                         self.progressView.alpha = 0.0f;
                         self.imageView.alpha = 1.0f;
                       }
                       completion:^(BOOL finished) {}];
    }
  }
}


- (void)setChromeState:(ISItemViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISItemViewControllerChromeStateShown) {
      [[UIApplication sharedApplication] setStatusBarHidden:NO
                                              withAnimation:UIStatusBarAnimationSlide];
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.view.backgroundColor = [UIColor whiteColor];
                         self.navigationController.navigationBar.alpha = 1.0f;
                       }];
    } else if (_chromeState == ISItemViewControllerChromeStateHidden) {
      [[UIApplication sharedApplication] setStatusBarHidden:YES
                                              withAnimation:UIStatusBarAnimationSlide];
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.view.backgroundColor = [UIColor blackColor];
                         self.navigationController.navigationBar.alpha = 0.0f;
                       }];
    }
  }
}


- (IBAction)trashClicked:(id)sender
{
  [self.cache removeObserver:self];
  [self.cache removeItems:@[self.cacheIdentifier]];
  [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)refreshClicked:(id)sender
{
  [self.cache removeItems:@[self.cacheIdentifier]];
}


#pragma mark - ISCacheObserver


- (void)fetchItem
{
  ISItemViewController *__weak weakSelf = self;
  self.cacheIdentifier
  = [self.cache item:self.url
             context:kCacheContextScaleURL
            userInfo:@{@"width": @320.0,
                       @"height": @568.0,
                       @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
               block:^(ISCacheItemInfo *info) {
                 ISItemViewController *strongSelf = weakSelf;
                 if (strongSelf) {
                   [self update:info];
                 }
               }];
}


- (void)update:(ISCacheItemInfo *)info
{
  if (info.state == ISCacheItemStateFound) {
    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:info.path]];
    self.state = ISItemViewControllerStateViewing;
  } else {
    CGFloat progress = (CGFloat)info.totalBytesRead / (CGFloat)info.totalBytesExpectedToRead;
    self.progressView.progress = progress;
    self.state = ISItemViewControllerStateDownloading;
  }
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Watch for the item being removed from the cache and re-request
  // the item from the cache if neccessary.
  if ([info.identifier isEqualToString:self.cacheIdentifier]) {
    [self fetchItem];
  }
}


- (void)handleTap:(UITapGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded) {
    if (self.chromeState == ISItemViewControllerChromeStateShown) {
      self.chromeState = ISItemViewControllerChromeStateHidden;
    } else {
      self.chromeState = ISItemViewControllerChromeStateShown;
    }
  }
}


@end
