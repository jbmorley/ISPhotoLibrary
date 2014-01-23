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

#import "ISPhotoViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISPhotoCollectionViewCell.h"
#import "ISScrubberCollectionViewCell.h"
#import <ISListViewAdapter/ISListViewAdapter.h>

@interface ISPhotoViewController () {
  BOOL _prefersStatusBarHidden;
}

@property (nonatomic, weak) IBOutlet UICollectionView *photoCollectionView;
@property (nonatomic, weak) IBOutlet UICollectionView *scrubberCollectionView;
@property (nonatomic, weak) UIScrollView *activeScrollView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic, strong) ISListViewAdapterConnector *photoConnector;
@property (nonatomic, strong) ISListViewAdapterConnector *scrubberConnector;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) BOOL isPortrait;

@end

@implementation ISPhotoViewController

static NSString *kPhotoCellReuseIdentifier = @"PhotoCell";
static NSString *kScrubberCellReuseIdentifier = @"ScrubberCell";


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
  [self.photoCollectionView addGestureRecognizer:gestureRecognizer];
  
  // Configure the scrubber.
  // This is done in code as it doesn't appear to be possible to add a
  // UICollectionView to a UIToolbar in interface builder.
  UIBarButtonItem *negativeSpace =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                target:nil
                                                action:nil];
  negativeSpace.width = -16;
  self.scrubberCollectionView.frame = self.navigationController.toolbar.bounds;
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scrubberCollectionView];
  [self setToolbarItems:@[negativeSpace, barButtonItem]];
  
  // Connect to the adapter.
  self.photoConnector = [ISListViewAdapterConnector connectorWithCollectionView:self.photoCollectionView];
  self.scrubberConnector = [ISListViewAdapterConnector connectorWithCollectionView:self.scrubberCollectionView];
  [self.adapter addAdapterObserver:self.photoConnector];
  [self.adapter addAdapterObserver:self.scrubberConnector];

  // Set the initial status bar state.
  _prefersStatusBarHidden = NO;
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  _isPortrait = UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]);
  [self showIndex:self.index
         animated:NO];
  self.currentIndex = self.index;
}


- (void)showIndex:(NSUInteger)index
         animated:(BOOL)animated
{
  self.photoCollectionView.contentOffset =
  CGPointMake([self cellWidthWithSpacing:self.photoCollectionView] * index,
              0.0);
  NSLog(@"photo offset: %@", NSStringFromCGPoint(self.photoCollectionView.contentOffset));
  self.scrubberCollectionView.contentOffset =
  CGPointMake([self cellWidthWithSpacing:self.scrubberCollectionView] * index,
              0.0);
  NSLog(@"scrubber offset: %@", NSStringFromCGPoint(self.scrubberCollectionView.contentOffset));
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


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                               duration: (NSTimeInterval)duration
{
  self.isPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
  [self.photoCollectionView reloadData];
  [self.scrubberCollectionView reloadData];
  [self showIndex:self.currentIndex
         animated:NO];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
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

  ISListViewAdapterItem *item = [self.adapter itemForIndex:_currentIndex];
  [item fetch:^(NSDictionary *dict) {
    self.title = dict[ISPhotoServiceKeyName];
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
  if (collectionView == self.photoCollectionView) {
    
    ISPhotoCollectionViewCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellReuseIdentifier
                                                forIndexPath:indexPath];
    ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
    [item fetch:^(NSDictionary *dict) {
      ISPhotoCollectionViewCell *cell = (ISPhotoCollectionViewCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
      if (cell) {
        cell.url = dict[ISPhotoServiceKeyURL];
      }
    }];
    return cell;
    
  } else if (collectionView == self.scrubberCollectionView) {
    
    ISScrubberCollectionViewCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kScrubberCellReuseIdentifier
                                                forIndexPath:indexPath];
    ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
    [item fetch:^(NSDictionary *dict) {
      ISScrubberCollectionViewCell *cell = (ISScrubberCollectionViewCell *)[self.scrubberCollectionView cellForItemAtIndexPath:indexPath];
      if (cell) {
        [cell.imageView setImageWithIdentifier:dict[ISPhotoServiceKeyURL]
                                       context:ISCacheImageContext
                                      preferences:@{@"width": @50.0,
                                                 @"height": @50.0,
                                                 @"scale": @(ISScalingCacheHandlerScaleAspectFit)}
                              placeholderImage:nil
                                         block:nil];
      }
    }];
    return cell;
    
  }
  return nil;
}


#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (collectionView == self.scrubberCollectionView) {
    [self.photoCollectionView scrollToItemAtIndexPath:indexPath
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    [self.scrubberCollectionView scrollToItemAtIndexPath:indexPath
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
  CGFloat offset = (*targetContentOffset).x / [self cellWidthWithSpacing:self.scrubberCollectionView];
  NSInteger currentIndex = offset + 0.5;
  (*targetContentOffset).x = currentIndex * [self cellWidthWithSpacing:self.scrubberCollectionView];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (scrollView == self.activeScrollView) {
  
    if (scrollView == self.photoCollectionView) {
      
      CGFloat offset = self.photoCollectionView.contentOffset.x / [self cellWidthWithSpacing:self.photoCollectionView];
      self.scrubberCollectionView.contentOffset = CGPointMake(offset * [self cellWidthWithSpacing:self.scrubberCollectionView],
                                                    0.0f);
      self.currentIndex = offset + 0.5;

      
    } else if (scrollView == self.scrubberCollectionView) {
      
      CGFloat offset = self.scrubberCollectionView.contentOffset.x / [self cellWidthWithSpacing:self.scrubberCollectionView];
      self.photoCollectionView.contentOffset = CGPointMake(offset * [self cellWidthWithSpacing:self.photoCollectionView],
                                                      0.0f);
      self.currentIndex = offset + 0.5;
      
    }
    
  }
  
}


- (CGFloat)cellWidthWithSpacing:(UICollectionView *)collectionView
{
  CGFloat itemSpacing = [self collectionView:collectionView layout:collectionView.collectionViewLayout minimumInteritemSpacingForSectionAtIndex:0];
  
  return [self cellSize:collectionView].width + itemSpacing;
}


- (CGSize)cellSize:(UICollectionView *)collectionView
{
  return [self collectionView:collectionView
                       layout:collectionView.collectionViewLayout
       sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0
                                                  inSection:0]];
}


#pragma mark - UICollectionViewDelegateFlowLayout


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (collectionView == self.photoCollectionView) {
    return [self screenSize];
  } else if (collectionView == self.scrubberCollectionView) {
    if (self.isPortrait) {
      return CGSizeMake(38.0, 38.0);
    } else {
      return CGSizeMake(26.0, 26.0);
    }
  }
  return CGSizeZero;
}


- (CGSize)screenSize
{
  UIScreen *screen = [UIScreen mainScreen];
  if (self.isPortrait) {
    return screen.bounds.size;
  } else {
    return CGSizeMake(screen.bounds.size.height,
                      screen.bounds.size.width);
  }
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  // TODO Calculate the insets to center the scrubber.
  if (collectionView == self.photoCollectionView) {
    if (self.isPortrait) {
      return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    } else {
      return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
  } else if (collectionView == self.scrubberCollectionView) {
    
    CGSize screenSize = [self screenSize];
    CGSize cellSize = [self cellSize:self.scrubberCollectionView];
    CGFloat inset = (screenSize.width - cellSize.width) / 2;
    if (self.isPortrait) {
      return UIEdgeInsetsMake(2.0, inset, 2.0, inset);
    } else {
      return UIEdgeInsetsMake(2.0, inset, 2.0, inset);
    }
  }
  return UIEdgeInsetsZero;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  if (collectionView == self.photoCollectionView) {
    return 0.0;
  } else if (collectionView == self.scrubberCollectionView) {
    return 4.0;
  }
  return 0.0;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  if (collectionView == self.photoCollectionView) {
    return 0.0;
  } else if (collectionView == self.scrubberCollectionView) {
    return 4.0;
  }
  return 0.0;
}


@end
