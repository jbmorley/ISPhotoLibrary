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
@property (nonatomic) ISCacheItemState state;

@end

@implementation ISDownloadsCollectionViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
  self.button.enabled = NO;
  UIImage *image = [UIImage imageNamed:@"Stop.imageasset"];
  [self.button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
               forState:UIControlStateNormal];
}


- (void)dealloc
{
  [self stopObservingCacheItem];
}


- (void)setCacheItem:(ISCacheItem *)cacheItem
{
  if (_cacheItem != cacheItem) {
    [self stopObservingCacheItem];
    _cacheItem = cacheItem;
    if (_cacheItem) {
      self.button.enabled = YES;
      self.label.text = _cacheItem.userInfo[ISPhotoServiceKeyName];
      [self startObservingCacheItem];
    }
  }
}


- (void)setState:(ISCacheItemState)state
{
  if (_state != state) {
    _state = state;
    
    if (_state == ISCacheItemStateInProgress) {
      self.button.enabled = YES;
    } else {
      self.button.enabled = NO;
    }
    
    [UIView animateWithDuration:0.3
                     animations:
     ^{
       if (_state ==
           ISCacheItemStateInProgress) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.95
                           alpha:1.0];
       } else if (_state ==
                  ISCacheItemStateNotFound) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.93
                           alpha:1.0];
       } else if (_state ==
                  ISCacheItemStateFound) {
         self.backgroundColor =
         [UIColor colorWithWhite:0.98
                           alpha:1.0];
       }
     }];
  }
}


- (void)startObservingCacheItem
{
  [_cacheItem addObserver:self
               forKeyPath:NSStringFromSelector(@selector(progress))
                  options:NSKeyValueObservingOptionInitial
                  context:NULL];
  [_cacheItem addObserver:self
               forKeyPath:NSStringFromSelector(@selector(state))
                  options:NSKeyValueObservingOptionInitial
                  context:NULL];
  [_cacheItem addObserver:self
               forKeyPath:NSStringFromSelector(@selector(timeRemainingEstimate))
                  options:NSKeyValueObservingOptionInitial
                  context:NULL];
}


- (void)stopObservingCacheItem
{
  @try {
    [_cacheItem removeObserver:self
                    forKeyPath:NSStringFromSelector(@selector(progress))];
    [_cacheItem removeObserver:self
                    forKeyPath:NSStringFromSelector(@selector(state))];
    [_cacheItem removeObserver:self
                    forKeyPath:NSStringFromSelector(@selector(timeRemainingEstimate))];
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
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
      self.state = self.cacheItem.state;
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(timeRemainingEstimate))]) {
      NSTimeInterval timeRemainingEstimate = self.cacheItem.timeRemainingEstimate;
      if (timeRemainingEstimate != 0) {
        self.detailLabel.text = [NSString stringWithFormat:
                                 @"%d seconds remaining...",
                                 (int)self.cacheItem.timeRemainingEstimate];
      } else {
        if (self.cacheItem.state ==
            ISCacheItemStateFound) {
          self.detailLabel.text = @"Download complete";
        } else if (self.cacheItem.lastError) {
          self.detailLabel.text = @"Download failed";
        }
      }
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
