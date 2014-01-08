//
//  ISItemViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISItemViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISPhotoView.h"


@interface ISItemViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) ISCache *cache;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, strong) ISCacheItem *cacheItem;

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
  
  // Set the title.
  self.navigationController.title = [self.photoService itemName:self.identifier];
  self.title = [self.photoService itemName:self.identifier];
  
  // Configure the scroll view.
  NSInteger pages = self.photoService.count;
  self.scrollView.contentSize =
  CGSizeMake(CGRectGetWidth(self.view.bounds) * pages,
             CGRectGetHeight(self.view.bounds));
  
  // Add the UIImageViews
  pages = 3;
  for (NSInteger count = 0; count < pages; count++) {
    ISPhotoView *photoView = [ISPhotoView photoView];
    photoView.frame =
    CGRectMake(CGRectGetWidth(self.view.bounds) * count,
               0.0f,
               CGRectGetWidth(self.view.bounds),
               CGRectGetHeight(self.view.bounds));
    photoView.url = [self.photoService itemURLAtIndex:count];
    [self.scrollView addSubview:photoView];
  }
  
  // Position the scroll view for the correct view.
  CGPoint offset =
  CGPointMake(self.index * CGRectGetWidth(self.scrollView.frame),
              0.0f);
  [self.scrollView setContentOffset:offset
                           animated:YES];
  
}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (NSString *)url
{
  return [self.photoService itemURL:self.identifier];
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
}


@end
