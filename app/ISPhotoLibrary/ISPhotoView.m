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

@interface ISPhotoView ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) ISCacheItem *cacheItem;

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


- (void)setUrl:(NSString *)url
{
  if (![_url isEqualToString:url]) {
    _url = url;
    
    // Stop observing any previous cache item.
    [self stopObservingCacheItem];
    
    UIImageView *__weak weakImageView = self.imageView;
    self.cacheItem =
    [self.imageView setImageWithURL:_url
                   placeholderImage:nil
                           userInfo:@{@"width": @320.0,
                                      @"height": @568.0,
                                      @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                    completionBlock:^(NSError *error) {
                      
                      // Don't bother doing anything on errors.
                      if (error) {
                        return;
                      }
                 
                      // Fade in the image view on success.
                      UIImageView *strongImageView = weakImageView;
                      if (strongImageView) {
                        [UIView animateWithDuration:0.3f
                                         animations:^{
                                           strongImageView.alpha = 1.0f;
                                         }];
                      }
                    }];
    
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
        self.progressView.alpha = 0.0f;
      } else {
        self.progressView.alpha = 1.0f;
      }
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

@end
