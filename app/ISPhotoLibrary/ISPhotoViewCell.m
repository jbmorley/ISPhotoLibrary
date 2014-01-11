/*
 * Copyright (C) 2013-2014 InSeven Limited.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "ISPhotoViewCell.h"
#import "ISOwnerProxy.h"
#import <ISCache/ISCache.h>

typedef enum {
  ISPhotoViewStateUnknown,
  ISPhotoViewStateDownloading,
  ISPhotoViewStateReady,
} ISPhotoViewState;

@interface ISPhotoViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) ISCacheItem *cacheItem;
@property (nonatomic) ISPhotoViewState state;

@end

@implementation ISPhotoViewCell


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
    [self.imageView setImageWithURL:_url
                   placeholderImage:nil
                           userInfo:@{@"width": @320.0,
                                      @"height": @568.0,
                                      @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
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
