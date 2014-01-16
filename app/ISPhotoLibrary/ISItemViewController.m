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

#import "ISItemViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISPhotoViewCell.h"
#import "ISScrubberCell.h"
#import <ISUtilities/ISListViewAdapter.h>

@interface ISItemViewController () {
  BOOL _prefersStatusBarHidden;
}

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *scrubberView;
@property (nonatomic, weak) UIScrollView *activeScrollView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic, strong) ISListViewAdapterConnector *photoConnector;
@property (nonatomic, strong) ISListViewAdapterConnector *scrubberConnector;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic) NSInteger currentIndex;

@end

@implementation ISItemViewController

static NSString *kPhotoCellReuseIdentifier = @"PhotoCell";
static NSString *kScrubberCellReuseIdentifier = @"ScrubberCell";
static CGFloat kScrubberCellWidth = 42.0f;


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.cache = [ISCache defaultCache];
  _chromeState = ISViewControllerChromeStateShown;
  
  UITapGestureRecognizer *gestureRecognizer =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleTap:)];
  gestureRecognizer.numberOfTapsRequired = 1;
  gestureRecognizer.numberOfTouchesRequired = 1;
  gestureRecognizer.enabled = YES;
  [self.collectionView addGestureRecognizer:gestureRecognizer];
  
  // Configure the scrubber.
  // This is done in code as it doesn't appear to be possible to add a
  // UICollectionView to a UIToolbar in interface builder.
  UIBarButtonItem *negativeSpace =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                target:nil
                                                action:nil];
  negativeSpace.width = -16;
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scrubberView];
  [self setToolbarItems:@[negativeSpace, barButtonItem]];
  
  // Connect to the adapter.
  self.photoConnector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  self.scrubberConnector = [ISListViewAdapterConnector connectorWithCollectionView:self.scrubberView];
  [self.adapter addObserver:self.photoConnector];
  [self.adapter addObserver:self.scrubberConnector];

  // Set the initial status bar state.
  _prefersStatusBarHidden = NO;
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Show the correct item when presenting the view controller.
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.index
                                               inSection:0];
  [self.collectionView scrollToItemAtIndexPath:indexPath
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:NO];
  [self.scrubberView scrollToItemAtIndexPath:indexPath
                            atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                    animated:NO];
  
  self.currentIndex = self.index;
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (BOOL)prefersStatusBarHidden
{
  return _prefersStatusBarHidden;
}


- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
  return UIStatusBarAnimationSlide;
}


- (void)setChromeState:(ISViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISViewControllerChromeStateShown) {

      [UIView animateWithDuration:0.2f
                       animations:^{
                         
                         self.view.backgroundColor = [UIColor whiteColor];
                           _prefersStatusBarHidden = NO;
                         [self setNeedsStatusBarAppearanceUpdate];
                         
                       }];
      [self.navigationController setToolbarHidden:NO
                                         animated:YES];
      [self.navigationController setNavigationBarHidden:NO
                                               animated:YES];

      
    } else if (_chromeState == ISViewControllerChromeStateHidden) {

      [self.navigationController setToolbarHidden:YES
                                         animated:YES];
      [self.navigationController setNavigationBarHidden:YES
                                               animated:YES];
      [UIView animateWithDuration:0.2f
                       animations:^{
                         self.view.backgroundColor = [UIColor blackColor];
                         _prefersStatusBarHidden = YES;
                         [self setNeedsStatusBarAppearanceUpdate];
                       }];
      
    }
  }
}


- (void)setCurrentIndex:(NSInteger)currentIndex
{
  // Ignore repeated sets.
  if (_currentIndex == currentIndex) {
    return;
  }
  
  // Disallow indexes outside of the size of the content.
  if (currentIndex < 0 ||
      currentIndex >= self.adapter.count) {
    return;
  }

  // Update the title.
  _currentIndex = currentIndex;

  ISListViewAdapterItem *item = [self.adapter entryForIndex:_currentIndex];
  [item fetch:^(NSDictionary *dict) {
    self.title = dict[@"name"];
  }];

}


- (void)handleTap:(UITapGestureRecognizer *)sender
{
  if (sender.state == UIGestureRecognizerStateEnded) {
    if (self.chromeState == ISViewControllerChromeStateShown) {
      self.chromeState = ISViewControllerChromeStateHidden;
    } else {
      self.chromeState = ISViewControllerChromeStateShown;
    }
  }
}


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.adapter.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (collectionView == self.collectionView) {
    
    ISPhotoViewCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellReuseIdentifier
                                                forIndexPath:indexPath];
    ISListViewAdapterItem *item = [self.adapter entryForIndex:indexPath.item];
    [item fetch:^(NSDictionary *dict) {
      cell.url = dict[@"url"];
    }];
    return cell;
    
  } else if (collectionView == self.scrubberView) {
    
    ISScrubberCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kScrubberCellReuseIdentifier
                                                forIndexPath:indexPath];
    ISListViewAdapterItem *item = [self.adapter entryForIndex:indexPath.item];
    [item fetch:^(NSDictionary *dict) {
      [cell.imageView setImageWithIdentifier:dict[@"url"]
                                     context:ISCacheImageContext
                            placeholderImage:nil
                                    userInfo:@{@"width": @50.0,
                                               @"height": @50.0,
                                               @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                                       block:nil];
    }];
    return cell;
    
  }
  return nil;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (collectionView == self.scrubberView) {
    [self.collectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self.scrubberView scrollToItemAtIndexPath:indexPath
                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                      animated:YES];
  }
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  // Track which scroll view / collection view the user is interacting with.
  self.activeScrollView = scrollView;
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
  // If the user has finished dragging the scrubber then we adjust the
  // offset to ensure it falls on a page boundary.
  CGFloat offset = (*targetContentOffset).x / kScrubberCellWidth;
  NSInteger currentIndex = offset + 0.5;
  (*targetContentOffset).x = currentIndex * kScrubberCellWidth;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (scrollView == self.activeScrollView) {
  
    if (scrollView == self.collectionView) {
      
      CGFloat offset = self.collectionView.contentOffset.x / self.collectionView.frame.size.width;
      self.scrubberView.contentOffset = CGPointMake(offset * kScrubberCellWidth,
                                                    0.0f);
      self.currentIndex = offset + 0.5;

      
    } else if (scrollView == self.scrubberView) {
      
      CGFloat offset = self.scrubberView.contentOffset.x / kScrubberCellWidth;
      self.collectionView.contentOffset = CGPointMake(offset * self.collectionView.frame.size.width,
                                                      0.0f);
      self.currentIndex = offset + 0.5;
      
    }
    
  }
  
}


@end
