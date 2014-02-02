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


#import "ISScrollView.h"


@interface ISScrollView ()

@property (nonatomic) CGPoint pointToCenterAfterResize;
@property (nonatomic) CGFloat scaleToRestoreAfterResize;
@property (nonatomic) CGSize currentContentSize;

@end


@implementation ISScrollView

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    self.delegate = self;
  }
  return self;
}


- (void)setContentView:(UIView *)contentView
{
  [_contentView removeFromSuperview];
  _contentView = contentView;
  self.contentSize = self.contentView.frame.size;
  self.currentContentSize = self.contentView.frame.size;
  [self addSubview:_contentView];
  [self configure];
}


- (void)setContentSize:(CGSize)contentSize
{
  [super setContentSize:contentSize];
  [self setNeedsLayout];
}


- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // center the zoom view as it becomes smaller than the size of the screen
  CGSize boundsSize = self.bounds.size;
  CGRect frameToCenter = self.contentView.frame;
  
  // center horizontally
  if (frameToCenter.size.width < boundsSize.width)
    frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
  else
    frameToCenter.origin.x = 0;
  
  // center vertically
  if (frameToCenter.size.height < boundsSize.height)
    frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
  else
    frameToCenter.origin.y = 0;
  
  self.contentView.frame = frameToCenter;
}


- (void)configure
{
  [self calculateZooms];
  self.zoomScale = self.minimumZoomScale;
}


- (void)calculateZooms
{
  // Determine the minimum scale.
  CGSize bounds = self.bounds.size;
  CGSize content = self.contentView.bounds.size;
  CGFloat xScale = bounds.width / content.width;
  CGFloat yScale = bounds.height / content.height;
  CGFloat minScale = MIN(xScale, yScale);
  
  // Bound minimum scale by maximum scale.
  CGFloat maxScale = 2.0;
  if (minScale > maxScale) {
    minScale = maxScale;
  }
  
  // Set the scales.
  self.maximumZoomScale = maxScale;
  self.minimumZoomScale = minScale;
}


- (void)setFrame:(CGRect)frame
{
  BOOL resize = !CGSizeEqualToSize(frame.size,
                                   self.frame.size);
  
  if (resize) {
    [self prepareToResize];
  }
  
  [super setFrame:frame];
  
  if (resize) {
    [self recoverFromResizing];
  }
}



- (void)prepareToResize
{
  CGPoint boundsCenter =
  CGPointMake(CGRectGetMidX(self.bounds),
              CGRectGetMidY(self.bounds));
  self.pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.contentView];
  
  self.scaleToRestoreAfterResize = self.zoomScale;
  
  // Restore to a minimum of zero if we're already minimum.
  if (self.scaleToRestoreAfterResize <=
      self.minimumZoomScale + FLT_EPSILON)
    self.scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
  [self calculateZooms];
  
  // Step 1: restore zoom scale, first making sure it is within the allowable range.
  CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
  self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
  
  // Step 2: restore center point, first making sure it is within the allowable range.
  
  // 2a: convert our desired center point back to our own coordinate space
  CGPoint boundsCenter = [self convertPoint:self.pointToCenterAfterResize fromView:self.contentView];
  
  // 2b: calculate the content offset that would yield that center point
  CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                               boundsCenter.y - self.bounds.size.height / 2.0);
  
  // 2c: restore offset, adjusted to be within the allowable range
  CGPoint maxOffset = [self maximumContentOffset];
  CGPoint minOffset = [self minimumContentOffset];
  
  CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
  offset.x = MAX(minOffset.x, realMaxOffset);
  
  realMaxOffset = MIN(maxOffset.y, offset.y);
  offset.y = MAX(minOffset.y, realMaxOffset);
  
  self.contentOffset = offset;
}


#pragma mark – UIScrollViewDelegate


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.contentView;
}


- (CGPoint)maximumContentOffset
{
  CGSize contentSize = self.contentSize;
  CGSize boundsSize = self.bounds.size;
  return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}


- (CGPoint)minimumContentOffset
{
  return CGPointZero;
}


@end
