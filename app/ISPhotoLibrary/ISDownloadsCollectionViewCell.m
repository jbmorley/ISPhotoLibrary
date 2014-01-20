//
//  ISDownloadsCollectionViewCell.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISDownloadsCollectionViewCell.h"

@implementation ISDownloadsCollectionViewCell

- (void)setCacheItem:(ISCacheItem *)cacheItem
{
  if (_cacheItem != cacheItem) {
    [self stopObservingCacheItem];
    _cacheItem = cacheItem;
    if (_cacheItem) {
      self.label.text = _cacheItem.identifier;
      [self startObservingCacheItem];
    }
  }
}


- (void)startObservingCacheItem
{
  [_cacheItem addObserver:self
               forKeyPath:NSStringFromSelector(@selector(progress))
                  options:NSKeyValueObservingOptionInitial
                  context:NULL];
}


- (void)stopObservingCacheItem
{
  @try {
    [_cacheItem removeObserver:self
                    forKeyPath:NSStringFromSelector(@selector(progress))];
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
    }
  }
}


@end
