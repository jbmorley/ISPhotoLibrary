//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 26/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"
#import "ISScrollView.h"

typedef enum {
  ISPhotoViewStateUnknown,
  ISPhotoViewStateDownloading,
  ISPhotoViewStateReady,
} ISPhotoViewState;

@interface ISItemViewController ()

@property (nonatomic, strong) ISScrollView *scrollView;
@property (nonatomic, strong) ISCacheImageView *imageView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic) ISPhotoViewState state;
@property (strong, nonatomic) ISCacheItem *cacheItem;

@end

@implementation ISItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor clearColor];

  // Scroll view.
  self.scrollView = [[ISScrollView alloc] initWithFrame:self.view.frame];
  self.scrollView.autoresizingMask =
  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.bounces = YES;
  [self.view addSubview:self.scrollView];
  
  // Image view.
  // It should match the size of the image.
  self.imageView = [[ISCacheImageView alloc] initWithFrame:self.view.frame];
  self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  self.imageView.alpha = 0.0f;
  self.scrollView.contentView = self.imageView;
  
  self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
  self.progressView.frame =
  CGRectMake((int)((CGRectGetWidth(self.view.frame) - CGRectGetWidth(self.progressView.frame)) / 2.0),
             (int)((CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.progressView.frame)) / 2.0),
             CGRectGetWidth(self.progressView.frame),
             CGRectGetHeight(self.progressView.frame));
  self.progressView.autoresizingMask
  = UIViewAutoresizingFlexibleLeftMargin
  | UIViewAutoresizingFlexibleTopMargin
  | UIViewAutoresizingFlexibleBottomMargin
  | UIViewAutoresizingFlexibleRightMargin;
  self.progressView.trackTintColor = [UIColor lightGrayColor];
  self.progressView.alpha = 0.0f;
  [self.view addSubview:self.progressView];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self startObservingCacheItem];
}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self stopObservingCacheItem];
}


- (void)dealloc
{
  [self stopObservingCacheItem];
}


- (void)setState:(ISPhotoViewState)state
{
  if (_state != state) {
    _state = state;
    if (_state == ISPhotoViewStateDownloading) {
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.progressView.alpha = 1.0f;
                         self.imageView.alpha = 0.0f;
                       }];
    } else if (_state == ISPhotoViewStateReady) {
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.progressView.alpha = 0.0f;
                         self.imageView.alpha = 1.0f;
                       }];
    }
  }
}


- (void)setCacheItem:(NSString *)identifier
             context:(NSString *)context
         preferences:(NSDictionary *)preferences
{
  // Fetch the cache item.
  ISCache *cache = [ISCache defaultCache];
  ISCacheItem *cacheItem = [cache itemForIdentifier:identifier
                                            context:context
                                        preferences:preferences];

  // Check to see if we're already processing this cache item.
  if ([self.cacheItem isEqual:cacheItem]) {
    return;
  }
  
  // Clean up.
  if (self.cacheItem) {
    
    // Stop observing any previous cache item.
    [self stopObservingCacheItem];
    
    // Cancel the previous cache item.
    ISCache *cache = [ISCache defaultCache];
    [cache cancelItems:@[_cacheItem]];
  }
  
  // Update the image.
  ISItemViewController *__weak weakSelf = self;
  CGFloat max = MAX(CGRectGetWidth(self.scrollView.bounds),
                    CGRectGetHeight(self.scrollView.bounds));
  self.cacheItem =
  [self.imageView setImageWithIdentifier:identifier
                                 context:context
                             preferences:@{ISCacheImageWidth: @(max),
                                           ISCacheImageHeight: @(max),
                                           ISCacheImageScaleMode: @(ISCacheImageScaleAspectFit)}
                        placeholderImage:nil
                                   block:
   ^(NSError *error) {
     if (error) {
       return;
     }
     
     ISItemViewController *strongSelf = weakSelf;
     if (strongSelf == nil) {
       return;
     }
     
     strongSelf.imageView.frame =
     CGRectMake(0.0f,
                0.0f,
                strongSelf.imageView.image.size.width,
                strongSelf.imageView.image.size.height);
     strongSelf.scrollView.contentSize =
     CGSizeMake(strongSelf.imageView.image.size.width,
                strongSelf.imageView.image.size.height);
     [strongSelf.scrollView configure];
   }];
  
  [self startObservingCacheItem];
}


- (void)startObservingCacheItem
{
  // Observe the cache item for progress changes.
  [self.cacheItem addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(progress))
                      options:NSKeyValueObservingOptionInitial
                      context:NULL];
  [self.cacheItem addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(state))
                      options:NSKeyValueObservingOptionInitial
                      context:NULL];
}


- (void)stopObservingCacheItem
{
  @try {
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(progress))];
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(state))];
  }
  @catch (NSException *exception) {}
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if (object == self.cacheItem) {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(progress))]) {
      self.progressView.progress = self.cacheItem.progress;
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
      if (self.cacheItem.state ==
          ISCacheItemStateFound) {
        self.state = ISPhotoViewStateReady;
      } else if (self.cacheItem.state ==
                 ISCacheItemStateInProgress) {
        self.state = ISPhotoViewStateDownloading;
      } else if (self.cacheItem.state ==
                 ISCacheItemStateNotFound) {
        if (self.cacheItem.lastError) {
          // TODO Show that we encountered an error.
        }
      }
    }
  }
}


@end
