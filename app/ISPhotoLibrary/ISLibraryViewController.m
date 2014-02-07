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

#import <ISCache/ISCache.h>
#import <ISListViewAdapter/ISListViewAdapter.h>
#import <ISUtilities/UIAlertView+Block.h>
#import <ISUtilities/ISDevice.h>

#import "ISLibraryViewController.h"
#import "ISLibraryCollectionViewCell.h"
#import "ISPhotoViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISPhotoViewController.h"
#import "ISRotatingFlowLayout.h"

@interface ISLibraryViewController ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, retain) UIRefreshControl *refreshControl;
@property (nonatomic, strong) ISPhotoService *photoService;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;
@property (nonatomic) CGPoint lastContentScrollOffset;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic) BOOL scrollViewIsDragging;
@property (nonatomic, strong) ISRotatingFlowLayout *flowLayout;

@end

@implementation ISLibraryViewController

static NSString *kCollectionViewCellReuseIdentifier = @"ThumbnailCell";
static NSString *kDetailSegueIdentifier = @"DetailSegue";
static NSString *kDownloadsSegueIdentifier = @"DownloadsSegue";

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.photoService = [ISPhotoService new];
  self.photoService.delegate = self;
  self.thumbnail = [UIImage imageNamed:@"Thumbnail.imageasset"];
  
  // Create an adapter and connect it to the collection view.
  self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self.photoService];
  self.connector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  [self.adapter addAdapterObserver:self.connector];
  
  // Add the refresh control.
  self.refreshControl = [UIRefreshControl new];
  [self.refreshControl addTarget:self
                          action:@selector(startRefresh:)
                forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:self.refreshControl];
  
  // Create and configure the flow layout.
  self.flowLayout = [ISRotatingFlowLayout new];
  self.flowLayout.spacing = 5.0f;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    self.flowLayout.minimumItemSize = CGSizeMake(100, 100);
  } else {
    self.flowLayout.minimumItemSize = CGSizeMake(180, 180);
  }
  self.collectionView.collectionViewLayout = self.flowLayout;

  // Star the photo service updating.
  [self.photoService update];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:kDetailSegueIdentifier]) {
    ISLibraryCollectionViewCell *cell = sender;
    ISPhotoViewController *viewController = segue.destinationViewController;
    viewController.adapter = self.adapter;
    viewController.index = cell.index;
    self.chromeState = ISViewControllerChromeStateShown;
  } else if ([segue.identifier isEqualToString:kDownloadsSegueIdentifier]) {
    UINavigationController *navigationController = segue.destinationViewController;
    ISDownloadsViewController *viewController = (ISDownloadsViewController *)navigationController.topViewController;
    viewController.delegate = self;
  }
}


#pragma mark - Utilities


- (void)setChromeState:(ISViewControllerChromeState)chromeState
{
  if (_chromeState != chromeState) {
    _chromeState = chromeState;
    if (_chromeState == ISViewControllerChromeStateHidden) {
      [self.navigationController setToolbarHidden:YES
                                         animated:YES];
    } else if (_chromeState == ISViewControllerChromeStateShown) {
      [self.navigationController setToolbarHidden:NO
                                         animated:YES];
    }
  }
}


#pragma mark - Actions


- (void)startRefresh:(id)sender
{
  [self.photoService update];
}


- (IBAction)refreshClicked:(id)sender
{
  [self.photoService update];
}


- (IBAction)clearClicked:(id)sender
{
  UIAlertView *alertView =
  [[UIAlertView alloc] initWithTitle:@"Delete"
                             message:@"Delete all cached images?"
                     completionBlock:^(NSUInteger buttonIndex)
   {
     if (buttonIndex == 1) {

      ISCache *defaultCache = [ISCache defaultCache];
      NSArray *items = [defaultCache items:
                        [ISCacheStateFilter filterWithStates:ISCacheItemStateAll]];
      [defaultCache removeItems:items];
      [self.photoService update];
       
     }
   }
                   cancelButtonTitle:@"Cancel"
                   otherButtonTitles:@"OK", nil];
  [alertView show];
}


#pragma mark - UITableViewDataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.adapter.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if ([[ISCache defaultCache] debug]) {
    NSLog(@"cellForItemAtIndexPath:%ld", (long)indexPath.item);
  }
  
  // Configure the cell.
  ISLibraryCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier
                                              forIndexPath:indexPath];
  cell.index = indexPath.row;
  cell.imageView.image = self.thumbnail;
  
  ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(NSDictionary *dict) {
    
    if ([[ISCache defaultCache] debug]) {
      NSLog(@"fetch result for index %ld", (long)indexPath.item);
    }
    
    // Re-fetch the cell from the table view to ensure it is valid
    // and still valid. This only works as the fetch operation is
    // guaranteed to be dispatched asynchronously.
    ISLibraryCollectionViewCell *cell = (ISLibraryCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
      ISCacheItem *item =
      [cell.imageView setImageWithIdentifier:dict[ISPhotoServiceKeyURL]
                                     context:ISCacheImageContext
                                    preferences:@{ISCacheImageWidth: @(self.thumbnailSize.width),
                                               ISCacheImageHeight: @(self.thumbnailSize.height),
                                               ISCacheImageScaleMode: @(ISCacheImageScaleAspectFill)}
                            placeholderImage:self.thumbnail
                                       block:NULL];
      item.userInfo = dict;
    }
    
  }];
  
  return cell;
}


#pragma mark - UICollectionViewDelegate


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  self.scrollViewIsDragging = YES;
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (self.scrollViewIsDragging) {
    
    if (self.lastContentScrollOffset.y < scrollView.contentOffset.y) {
      self.chromeState = ISViewControllerChromeStateHidden;
    } else if (self.lastContentScrollOffset.y > scrollView.contentOffset.y) {
      self.chromeState = ISViewControllerChromeStateShown;
    }
    
  }
  
  self.lastContentScrollOffset = scrollView.contentOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
  self.scrollViewIsDragging = NO;
}


- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  self.chromeState = ISViewControllerChromeStateShown;
  ISPhotoViewController *detailViewController = [ISPhotoViewController detailViewController];
  detailViewController.adapter = self.adapter;
  detailViewController.index= indexPath.row;
  [self.navigationController pushViewController:detailViewController
                                       animated:YES];
}


#pragma mark - ISDownloadsViewControllerDelegate


- (void)downloadsViewControllerDidFinish:(ISDownloadsViewController *)downloadsViewController
{
  [self.navigationController dismissViewControllerAnimated:YES
                                                completion:NULL];
}


#pragma mark - ISCollectionViewDelegateFlowLayout


- (CGSize)thumbnailSize
{
  return ((UICollectionViewFlowLayout *)(self.collectionView.collectionViewLayout)).itemSize;
}


#pragma mark - ISPhotoServiceDelegate


- (void)photoServiceWillUpdate:(ISPhotoService *)photoService
{
  [self.refreshControl beginRefreshing];
}


- (void)photoServiceDidUpdate:(ISPhotoService *)photoService
{
  [self.refreshControl endRefreshing];
}

@end
