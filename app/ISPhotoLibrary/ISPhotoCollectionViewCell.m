//
// Copyright (c) 2013 InSeven Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "ISPhotoCollectionViewCell.h"
#import "ISOwnerProxy.h"
#import <ISCache/ISCache.h>

typedef enum {
  ISPhotoViewStateUnknown,
  ISPhotoViewStateDownloading,
  ISPhotoViewStateReady,
} ISPhotoViewState;

@interface ISPhotoCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) ISCacheItem *cacheItem;
@property (nonatomic) ISPhotoViewState state;

@end

@implementation ISPhotoCollectionViewCell


- (void)dealloc
{
  // Remove any lingering cache item observers.
  [self stopObservingCacheItem];
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
    [self.imageView setImageWithIdentifier:_url
                                   context:ISCacheImageContext
                                  userInfo:@{@"width": @320.0,
                                             @"height": @568.0,
                                             @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                          placeholderImage:nil
                                     block:NULL];
    
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
