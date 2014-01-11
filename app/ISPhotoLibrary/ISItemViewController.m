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

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic, copy) CleanupBlock disappearCleanup;

@end

@implementation ISItemViewController

static NSString *kPhotoCellReuseIdentifier = @"PhotoCell";


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


#pragma mark - UICollectionViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.photoService.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  // Configure the cell.
  ISPhotoView *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellReuseIdentifier
                                              forIndexPath:indexPath];
  cell.url = [self.photoService itemURL:indexPath.row];
  return cell;
}


@end
