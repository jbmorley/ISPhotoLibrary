//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"
#import "ISViewControllerChromeState.h"

typedef enum {
  ISItemViewControllerStateUnknown,
  ISItemViewControllerStateDownloading,
  ISItemViewControllerStateViewing,
} ISItemViewControllerState;


@interface ISItemViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISItemViewControllerState state;
@property (nonatomic) ISViewControllerChromeState chromeState;
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
  self.chromeState = ISViewControllerChromeStateShown;
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
  
  // Set the title.
  self.navigationController.title = [self.photoService itemName:self.identifier];
  self.title = [self.photoService itemName:self.identifier];

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
  return [self.photoService itemURL:self.identifier];
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


- (void)setChromeState:(ISViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISViewControllerChromeStateShown) {
      [[UIApplication sharedApplication] setStatusBarHidden:NO
                                              withAnimation:UIStatusBarAnimationSlide];
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.view.backgroundColor = [UIColor whiteColor];
                         self.navigationController.navigationBar.alpha = 1.0f;
                       }];
    } else if (_chromeState == ISViewControllerChromeStateHidden) {
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
  self.cacheIdentifier =
  [self.imageView setImageWithURL:self.url
                 placeholderImage:nil
                         userInfo:@{@"width": @320.0,
                                    @"height": @568.0,
                                    @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                  completionBlock:^(NSError *error) {
                    self.state = ISItemViewControllerStateViewing;
                  }];
}


- (void)itemDidUpdate:(ISCacheItemInfo *)info
{
  // Watch for the item being removed from the cache and re-request
  // the item from the cache if neccessary.
  if ([info.identifier isEqualToString:self.cacheIdentifier]) {
    
    if (info.state == ISCacheItemStateNotFound) {
      
      // Refetch the item.
      [self fetchItem];
      
    } else if (info.state == ISCacheItemStateFound) {
      
      // The image loading is done by the UIImageView extension
      // and the appropriate UI changes are done in the completion
      // block for this so we do nothing here.
      
    } else if (info.state == ISCacheItemStateInProgress) {
      
      // Display the progress.
      if (info.totalBytesExpectedToRead == ISCacheItemTotalBytesUnknown) {
        self.progressView.progress = 0.0f;
      } else {
        CGFloat progress = (CGFloat)info.totalBytesRead / (CGFloat)info.totalBytesExpectedToRead;
        self.progressView.progress = progress;
      }
      self.state = ISItemViewControllerStateDownloading;
      
    }
  
  }
}


- (void)handleTap:(UITapGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded) {
    if (self.chromeState == ISViewControllerChromeStateShown) {
      self.chromeState = ISViewControllerChromeStateHidden;
    } else {
      self.chromeState = ISViewControllerChromeStateShown;
    }
  }
}


@end
