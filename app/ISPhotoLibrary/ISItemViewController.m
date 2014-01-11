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
#import "ISPhotoView.h"

typedef void (^CleanupBlock)(void);


@interface ISItemViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic, strong) ISCacheItem *cacheItem;
@property (nonatomic, strong) NSMutableArray *photoViews;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic, copy) CleanupBlock disappearCleanup;

@end

@implementation ISItemViewController


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
  [self.view addGestureRecognizer:gestureRecognizer];
  
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  // Configure the scroll view.
  NSInteger count = self.photoService.count;
  self.scrollView.contentSize =
  CGSizeMake(CGRectGetWidth(self.view.bounds) * count,
             CGRectGetHeight(self.view.bounds));
  
  // Create an array to track the photo view instances.
  self.photoViews = [NSMutableArray arrayWithCapacity:count];
  
  // Add the photo views.
  // We do not set the URL for the photo views here as this
  // causes them to display the image.
  // Instead we do this lazily in the on scroll event.
  for (NSInteger i = 0; i < count; i++) {
    ISPhotoView *photoView = [ISPhotoView photoView];
    photoView.frame =
    CGRectMake(CGRectGetWidth(self.view.bounds) * i,
               0.0f,
               CGRectGetWidth(self.view.bounds),
               CGRectGetHeight(self.view.bounds));
//    [self.scrollView addSubview:photoView];
    [self.photoViews addObject:photoView];
  }
  
  // Position the scroll view for the correct view.
  CGPoint offset =
  CGPointMake(self.index * CGRectGetWidth(self.scrollView.frame),
              0.0f);
  [self.scrollView setContentOffset:offset
                           animated:YES];
  
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
    NSLog(@"CANCEL");
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


- (void)setChromeState:(ISViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISViewControllerChromeStateShown) {
      [[UIApplication sharedApplication] setStatusBarHidden:NO
                                              withAnimation:UIStatusBarAnimationSlide];
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.view.backgroundColor = [UIColor whiteColor];
                         self.navigationController.navigationBar.alpha = 1.0f;
                       }];
    } else if (_chromeState == ISViewControllerChromeStateHidden) {
      [[UIApplication sharedApplication] setStatusBarHidden:YES
                                              withAnimation:UIStatusBarAnimationSlide];
      [UIView animateWithDuration:0.3f
                       animations:^{
                         self.view.backgroundColor = [UIColor blackColor];
                         self.navigationController.navigationBar.alpha = 0.0f;
                       }];
    }
  }
}


- (IBAction)refreshClicked:(id)sender
{
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


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  NSInteger index = (scrollView.contentOffset.x + CGRectGetWidth(self.view.frame)/2) / CGRectGetWidth(self.view.frame);
  self.currentIndex = index;
}


- (void)setCurrentIndex:(NSInteger)currentIndex
{
  if (_currentIndex != currentIndex) {

    // Clean up the previous downloads.
    [self clearPhotoView:currentIndex + 2];
    [self clearPhotoView:currentIndex - 2];
    
    // Update the index.
    _currentIndex = currentIndex;
    
    // Schedule the next downloads.
    [self configurePhotoView:_currentIndex - 1];
    [self configurePhotoView:_currentIndex];
    [self configurePhotoView:_currentIndex + 1];
    
    self.title = [self.photoService itemName:_currentIndex];
    
  }
}


- (void)clearPhotoView:(NSInteger)index
{
  if (index >= 0 &&
      index < self.photoViews.count) {
    ISPhotoView *photoView = self.photoViews[index];
    if (photoView.superview) {
      [photoView removeFromSuperview];
    }
    [photoView cancel];
  }
}


- (void)configurePhotoView:(NSInteger)index
{
  if (index >= 0 &&
      index < self.photoViews.count) {
    ISPhotoView *photoView = self.photoViews[index];
    if (!photoView.superview) {
      [self.scrollView addSubview:photoView];
    }
    photoView.url = [self.photoService itemURL:index];
  }
}


@end
