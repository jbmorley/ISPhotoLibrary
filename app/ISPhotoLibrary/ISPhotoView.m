//
//  ISPhotoView.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 08/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISPhotoView.h"
#import "ISOwnerProxy.h"
#import <ISCache/ISCache.h>

typedef enum {
  ISPhotoViewStateUnknown,
  ISPhotoViewStateDownloading,
  ISPhotoViewStateReady,
} ISPhotoViewState;

@interface ISPhotoView ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) ISCacheItem *cacheItem;
@property (nonatomic) ISPhotoViewState state;

@end

@implementation ISPhotoView


+ (id)photoView
{
  return [ISOwnerProxy viewFromNib:@"ISPhotoView"];
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
  }
  return self;
}


- (void)dealloc
{
  // Remove any lingering cache item observers.
  [self stopObservingCacheItem];
}


- (void)cancel
{
  [self.imageView cancelSetImageWithURL];
  _url = nil;
}


- (void)setUrl:(NSString *)url
{
  if (![_url isEqualToString:url]) {
    _url = url;
    
    // Cancel a previous fetch if one was in progress.
    if (self.cacheItem) {
      ISCache *cache = [ISCache defaultCache];
      [cache cancelItems:@[self.cacheItem]];
    }
    
    // Stop observing any previous cache item.
    [self stopObservingCacheItem];
    
    self.cacheItem =
    [self.imageView setImageWithURL:_url
                   placeholderImage:nil
                           userInfo:@{@"width": @320.0,
                                      @"height": @568.0,
                                      @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                    completionBlock:^(NSError *error) {}];
    
    // Observe the cache item for progress changes.
    [self.cacheItem addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(totalBytesRead))
                        options:NSKeyValueObservingOptionInitial
                        context:NULL];
    [self.cacheItem addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(totalBytesExpectedToRead))
                        options:NSKeyValueObservingOptionInitial
                        context:NULL];
    [self.cacheItem addObserver:self
                     forKeyPath:NSStringFromSelector(@selector(state))
                        options:NSKeyValueObservingOptionInitial
                        context:NULL];
  }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if (object == self.cacheItem) {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(totalBytesRead))] ||
        [keyPath isEqualToString:NSStringFromSelector(@selector(totalBytesExpectedToRead))]) {
      CGFloat totalBytesRead = self.cacheItem.totalBytesRead;
      CGFloat totalBytesExpectedToRead = self.cacheItem.totalBytesExpectedToRead;
      if (totalBytesExpectedToRead ==
          ISCacheItemTotalBytesUnknown) {
        self.progressView.progress = 0.0f;
      } else {
        self.progressView.progress = totalBytesRead/totalBytesExpectedToRead;
      }
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
      if (self.cacheItem.state == ISCacheItemStateFound) {
        self.state = ISPhotoViewStateReady;
      } else {
        self.state = ISPhotoViewStateDownloading;
      }
      // TODO Handle errors here?
    }
  }
}


- (void)stopObservingCacheItem
{
  @try {
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(totalBytesRead))];
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(totalBytesExpectedToRead))];
    [self.cacheItem removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(state))];
  }
  @catch (NSException *exception) {}
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

@end
