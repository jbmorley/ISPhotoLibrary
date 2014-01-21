//
//  ISDownloadsCollectionViewCell.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISDownloadsCollectionViewCell.h"
#import "ISPhotoService.h"

@interface ISDownloadsCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;

@end

@implementation ISDownloadsCollectionViewCell


- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    self.button.enabled = NO;
  }
  return self;
}


- (void)setCacheItem:(ISCacheItem *)cacheItem
{
  if (_cacheItem != cacheItem) {
    [self stopObservingCacheItem];
    _cacheItem = cacheItem;
    if (_cacheItem) {
      self.button.enabled = YES;
      self.label.text = _cacheItem.data[ISPhotoServiceKeyName];
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
      CGFloat progress = self.cacheItem.progress;
      self.progressView.progress = progress;
      NSInteger percentage = (progress * 100);
      self.detailLabel.text = [NSString stringWithFormat:
                               @"%ld%%",
                               (long)percentage];
    }
  }
}


- (IBAction)buttonClicked:(id)sender
{
  if (self.cacheItem) {
    ISCache *defaultCache = [ISCache defaultCache];
    [defaultCache cancelItems:@[self.cacheItem]];
    self.button.enabled = NO;
  }
}


@end
