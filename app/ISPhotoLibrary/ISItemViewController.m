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

#import "ISItemViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISPhotoViewCell.h"
#import "ISScrubberCell.h"

typedef void (^CleanupBlock)(void);


@interface ISItemViewController () {
  BOOL _prefersStatusBarHidden;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *scrubberView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic, copy) CleanupBlock disappearCleanup;
@property (nonatomic) NSInteger currentIndex;

@end

@implementation ISItemViewController

static NSString *kPhotoCellReuseIdentifier = @"PhotoCell";
static NSString *kScrubberCellReuseIdentifier = @"ScrubberCell";


- (void)viewDidLoad
{
  [super viewDidLoad];
  self.cache = [ISCache defaultCache];
  self.chromeState = ISViewControllerChromeStateShown;
  
  UITapGestureRecognizer *gestureRecognizer =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleTap:)];
  gestureRecognizer.numberOfTapsRequired = 1;
  gestureRecognizer.numberOfTouchesRequired = 1;
  gestureRecognizer.enabled = YES;
  [self.collectionView addGestureRecognizer:gestureRecognizer];
  
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
}


- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  if (self.disappearCleanup) {
    self.disappearCleanup();
    self.disappearCleanup = NULL;
  }
}


- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  // I seem to remember hearing about an official way of doing
  // this in a WWDC session, but I cannot find a reference to it
  // anywhere. In the meantime, we will have to put up with this
  // solution to handle cancelled view disappearance.
  ISViewControllerChromeState state = self.chromeState;
  self.chromeState = ISViewControllerChromeStateShown;
  ISItemViewController *__weak weakSelf = self;
  self.disappearCleanup = ^{
    // Called if the disappearance isn't completed.
    ISItemViewController *strongSelf = weakSelf;
    if (strongSelf) {
      strongSelf.chromeState = state;
    }
  };

}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  self.disappearCleanup = NULL;
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
  return UIStatusBarAnimationNone;
}


- (void)setChromeState:(ISViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISViewControllerChromeStateShown) {
      _prefersStatusBarHidden = NO;
      [self.navigationController setNavigationBarHidden:NO
                                               animated:NO];
      self.navigationController.navigationBar.alpha = 0.0f;
      [UIView animateWithDuration:0.3f
                       animations:^{
                         
                         self.view.backgroundColor = [UIColor whiteColor];
                         self.navigationController.navigationBar.alpha = 1.0f;
                         self.scrubberView.alpha = 1.0f;
                         
                       }];
    } else if (_chromeState == ISViewControllerChromeStateHidden) {
      [UIView animateWithDuration:0.3f
                       animations:^{
                         
                         self.view.backgroundColor = [UIColor blackColor];
                         self.navigationController.navigationBar.alpha = 0.0f;
                         self.scrubberView.alpha = 0.0f;
                         
                       } completion:^(BOOL finished) {

                         _prefersStatusBarHidden = YES;
                         [self.navigationController setNavigationBarHidden:YES
                                                                  animated:YES];
                         
                       }];
    }
  }
}


- (void)setCurrentIndex:(NSInteger)currentIndex
{
  if (_currentIndex == currentIndex) {
    return;
  }
  

  // Update the title.
  _currentIndex = currentIndex;
  self.title = [self.photoService itemName:_currentIndex];
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
  return self.photoService.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (collectionView == self.collectionView) {
    
    ISPhotoViewCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellReuseIdentifier
                                                forIndexPath:indexPath];
    cell.url = [self.photoService itemURL:indexPath.row];
    return cell;
    
  } else if (collectionView == self.scrubberView) {
    
    ISScrubberCell *cell
    = [collectionView dequeueReusableCellWithReuseIdentifier:kScrubberCellReuseIdentifier
                                                forIndexPath:indexPath];
    [cell.imageView setImageWithURL:[self.photoService itemURL:indexPath.row]
                   placeholderImage:nil
                           userInfo:@{@"width": @50.0,
                                      @"height": @50.0,
                                      @"scale": @(ISScalingCacheHandlerScaleAspectFill)}
                              block:nil];
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
  }
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  const static CGFloat scrubberCellWidth = 52.0f;
  
  // TODO Guard against whichever view is driving.
  
  if (scrollView == self.collectionView) {
    
    CGFloat offset = self.collectionView.contentOffset.x / self.collectionView.frame.size.width;
    NSLog(@"Offset: %f", offset);
    self.scrubberView.contentOffset = CGPointMake(offset * scrubberCellWidth,
                                                  0.0f);
    self.currentIndex = offset + 0.5;

    
  } else if (scrollView == self.scrubberView) {
    
    CGFloat offset = self.scrubberView.contentOffset.x / scrubberCellWidth;
    self.collectionView.contentOffset = CGPointMake(offset * self.collectionView.frame.size.width,
                                                    0.0f);
    self.currentIndex = offset + 0.5;
    
  }
  
  
}


@end
