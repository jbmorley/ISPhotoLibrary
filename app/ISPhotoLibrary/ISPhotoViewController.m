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
#import "ISItemViewController.h"
#import "ISPhotoService.h"
#import "ISViewControllerChromeState.h"
#import "ISScrubberCollectionViewCell.h"
#import <ISCache/ISCache.h>

@interface ISPhotoViewController () {
  BOOL _prefersStatusBarHidden;
}

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic) CGSize photoSize;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic, strong) UICollectionView *scrubberCollectionView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic, strong) ISListViewAdapterConnector *scrubberConnector;
@property (nonatomic) BOOL isPortrait;
@property (nonatomic) NSInteger currentIndex;

@end

static NSString *kScrubberCellReuseIdentifier = @"ScrubberCell";

@implementation ISPhotoViewController

+ (id)detailViewController
{
  ISPhotoViewController *detailViewController =
  [[self alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                options:@{UIPageViewControllerOptionInterPageSpacingKey: @8.0}];
  return detailViewController;
}


- (id)initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style
        navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation
                      options:(NSDictionary *)options
{
  self = [super initWithTransitionStyle:style
                  navigationOrientation:navigationOrientation
                                options:options];
  if (self) {
    self.delegate = self;
    self.dataSource = self;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.photoSize = CGSizeMake(MAX(screenSize.width,
                                    screenSize.height),
                                MAX(screenSize.width,
                                    screenSize.height));
  }
  return self;
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.cache = [ISCache defaultCache];
  _chromeState = ISViewControllerChromeStateShown;
  self.automaticallyAdjustsScrollViewInsets = NO;
  
  // Set the background color.
  self.view.backgroundColor = [UIColor whiteColor];
  
  // Configure the gesture recognizer.
  UITapGestureRecognizer *gestureRecognizer =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleTap:)];
  gestureRecognizer.numberOfTapsRequired = 1;
  gestureRecognizer.numberOfTouchesRequired = 1;
  gestureRecognizer.enabled = YES;
  [self.view addGestureRecognizer:gestureRecognizer];
  
  // Configure the scrubber.
  // This is done in code as it doesn't appear to be possible to add a
  // UICollectionView to a UIToolbar in interface builder.
  UIBarButtonItem *negativeSpace =
  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                target:nil
                                                action:nil];
  negativeSpace.width = -16;
  CGRect toolbarBounds = self.navigationController.toolbar.bounds;
  UICollectionViewFlowLayout *layout =
  [UICollectionViewFlowLayout new];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  self.scrubberCollectionView =
  [[UICollectionView alloc] initWithFrame:toolbarBounds
                     collectionViewLayout:layout];
  [self.scrubberCollectionView registerClass:[ISScrubberCollectionViewCell class] forCellWithReuseIdentifier:kScrubberCellReuseIdentifier];
  self.scrubberCollectionView.showsHorizontalScrollIndicator = NO;
  self.scrubberCollectionView.showsVerticalScrollIndicator = NO;
  self.scrubberCollectionView.dataSource = self;
  self.scrubberCollectionView.delegate = self;
  self.scrubberCollectionView.backgroundColor = [UIColor clearColor];
  self.scrubberCollectionView.autoresizingMask =
  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.scrubberCollectionView];
  [self setToolbarItems:@[negativeSpace, barButtonItem]];
  
  // Connect to the adapter.
  self.scrubberConnector = [ISListViewAdapterConnector connectorWithCollectionView:self.scrubberCollectionView];
  [self.adapter addAdapterObserver:self.scrubberConnector];
  
  // Set the initial status bar state.
  _prefersStatusBarHidden = NO;
  
  self.currentIndex = -1;
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.isPortrait = !UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);
  
  // Update the graphics.
  [self showIndex:self.index
         animated:NO];
}


- (void)showIndex:(NSUInteger)index
         animated:(BOOL)animated
{
  if (self.currentIndex != index) {
    
    // Determine the direciton.
    UIPageViewControllerNavigationDirection direction;
    if (index < self.index) {
      direction = UIPageViewControllerNavigationDirectionReverse;
    } else {
      direction = UIPageViewControllerNavigationDirectionForward;
    }
    
    // Set the index.
    self.index = index;
    self.currentIndex = index;
    
    // Animate the scrubber.
    [self scrubberShowIndex:index
                   animated:animated];
    
    // Show the contents.
    ISItemViewController *viewController = [self viewControllerForIndex:index];
    [self setViewControllers:@[viewController]
                   direction:direction
                    animated:animated
                  completion:NULL];
    
    [self setTitleForViewController:viewController];
  }
}


- (void)scrubberShowIndex:(NSUInteger)index
                 animated:(BOOL)animated
{
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index
                                               inSection:0];
  [self.scrubberCollectionView
   scrollToItemAtIndexPath:indexPath
   atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
   animated:animated];
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
  [self.scrubberCollectionView.collectionViewLayout invalidateLayout];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [self scrubberShowIndex:self.index
                 animated:YES];
}


- (NSUInteger)count
{
  return [self.adapter count];
}


- (ISItemViewController *)viewControllerForIndex:(NSInteger)index
{
  if (index >= 0 && index < self.count) {
    
    // Check the controller is still valid.
    ISItemViewController *controller = [[ISItemViewController alloc] init];
    controller.index = index;
    
    // Set the contents.
    ISListViewAdapterItem *item = [self.adapter itemForIndex:index];
    
    ISItemViewController *__weak weakController = controller;
    [item fetch:^(NSDictionary *dict) {
      
      ISItemViewController *strongController = weakController;
      if (strongController == nil) {
        return;
      }
      
      strongController.title = dict[ISPhotoServiceKeyName];
      [strongController setCacheItem:dict[ISPhotoServiceKeyURL]
                             context:ISCacheImageContext
                         preferences:@{ISCacheImageWidth: @(self.photoSize.width),
                                       ISCacheImageHeight: @(self.photoSize.height),
                                       ISCacheImageScaleMode: @(ISCacheImageScaleAspectFit)}];
    }];
    
    return controller;
  }
  return nil;
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


- (void)setTitleForViewController:(ISItemViewController *)viewController
{
  NSInteger index = viewController.index;
  ISListViewAdapterItem *item =
  [self.adapter itemForIndex:viewController.index];
  ISPhotoViewController *__weak weakSelf = self;
  [item fetch:^(NSDictionary *dict) {
    
    ISPhotoViewController *strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    
    // Check that index is the same.
    ISItemViewController *current = self.viewControllers[0];
    if (current.index == index) {
      strongSelf.title = dict[ISPhotoServiceKeyName];
    }
  }];
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
  ISScrubberCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kScrubberCellReuseIdentifier
                                              forIndexPath:indexPath];
  ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(NSDictionary *dict) {
    ISScrubberCollectionViewCell *cell = (ISScrubberCollectionViewCell *)[self.scrubberCollectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
      [cell setImageURL:dict[ISPhotoServiceKeyURL]
                   size:CGSizeMake(50.0f, 50.0f)];      
    }
  }];
  
  return cell;
}



#pragma mark - UICollectionViewDelegate


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self showIndex:indexPath.item
         animated:YES];
}


#pragma mark - UIScrollViewDelegate


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


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
  NSInteger index =  ((ISItemViewController *)viewController).index - 1;
  return [self viewControllerForIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
  NSInteger index = ((ISItemViewController *)viewController).index + 1;
  return [self viewControllerForIndex:index];
}


#pragma mark - UIPageViewControllerDelegate


- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
}


- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
  ISItemViewController *viewController =
  self.viewControllers[0];
  [self scrubberShowIndex:viewController.index
                 animated:YES];
  [self setTitleForViewController:viewController];
}


#pragma mark - UICollectionViewDelegateFlowLayout


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.isPortrait) {
    return CGSizeMake(38.0, 38.0);
  } else {
    return CGSizeMake(26.0, 26.0);
  }
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
  CGSize screenSize = [self screenSize];
  CGSize cellSize = [self cellSize:self.scrubberCollectionView];
  CGFloat inset = (screenSize.width - cellSize.width) / 2;
  if (self.isPortrait) {
    return UIEdgeInsetsMake(2.0, inset, 2.0, inset);
  } else {
    return UIEdgeInsetsMake(2.0, inset, 2.0, inset);
  }
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 4.0;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 4.0;
}


@end
