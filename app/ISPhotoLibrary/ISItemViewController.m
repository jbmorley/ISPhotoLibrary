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
@property (nonatomic, strong) NSMutableArray *photoViews;
@property (nonatomic) NSInteger currentIndex;

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
    [self.scrollView addSubview:photoView];
    [self.photoViews addObject:photoView];
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
  NSInteger index = scrollView.contentOffset.x / CGRectGetWidth(self.view.frame);
  NSLog(@"Page: %d", index);
  // TODO Unset the preivous ones.
  // Set the next ones.
  // Guard against multiple sets.
  self.currentIndex = index;
  
}


- (void)setCurrentIndex:(NSInteger)currentIndex
{
  if (_currentIndex != currentIndex) {

    // Clean up the previous downloads.
//    [self clearPhotoView:currentIndex + 2];
//    [self clearPhotoView:currentIndex - 2];
    
    // Update the index.
    _currentIndex = currentIndex;
    
    // Schedule the next downloads.
    [self configurePhotoView:_currentIndex - 1];
    [self configurePhotoView:_currentIndex];
    [self configurePhotoView:_currentIndex + 1];
    
    self.title = [self.photoService itemNameAtIndex:_currentIndex];
    
  }
}


- (void)clearPhotoView:(NSInteger)index
{
  if (index >= 0 &&
      index < self.photoViews.count) {
    NSLog(@"clearPhotoView:%d", index);
    ISPhotoView *photoView = self.photoViews[index];
    photoView.url = nil;
  }
}


- (void)configurePhotoView:(NSInteger)index
{
  if (index >= 0 &&
      index < self.photoViews.count) {
    NSLog(@"configurePhotoView:%d", index);
    ISPhotoView *photoView = self.photoViews[index];
    photoView.url = [self.photoService itemURLAtIndex:index];
  }
}


@end
