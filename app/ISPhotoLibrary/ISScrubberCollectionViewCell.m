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

#import "ISScrubberCollectionViewCell.h"

@interface ISScrubberCollectionViewCell ()

@property (nonatomic, strong) ISCacheImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) NSString *imageURL;

@end

@implementation ISScrubberCollectionViewCell


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.imageView = [[ISCacheImageView alloc] initWithFrame:self.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    self.activityIndicatorView.frame =
    CGRectMake((CGRectGetWidth(self.bounds) - CGRectGetWidth(self.activityIndicatorView.frame)) / 2.0,
               (CGRectGetHeight(self.bounds) - CGRectGetHeight(self.activityIndicatorView.frame)) / 2.0,
               CGRectGetWidth(self.activityIndicatorView.frame),
               CGRectGetHeight(self.activityIndicatorView.frame));
    [self addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
  }
  return self;
}


- (void)setImageURL:(NSString *)imageURL
               size:(CGSize)size
{
  ISScrubberCollectionViewCell *__weak weakSelf = self;
  if (![_imageURL isEqualToString:imageURL]) {
    _imageURL = imageURL;
    [self.imageView setImageWithIdentifier:_imageURL
                                   context:ISCacheImageContext
                               preferences:  @{ISCacheImageWidth: @(size.width),
                                               ISCacheImageHeight: @(size.height),
                                               ISCacheImageScaleMode: @(ISCacheImageScaleAspectFit)}
                          placeholderImage:nil
                                     block:
     ^(NSError *error) {
       ISScrubberCollectionViewCell *strongSelf = weakSelf;
       if (strongSelf) {
         [strongSelf.activityIndicatorView stopAnimating];
       }
     }];
  }
}


@end
