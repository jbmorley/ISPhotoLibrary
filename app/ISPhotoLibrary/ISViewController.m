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

#import <ISCache/ISCache.h>

#import "ISViewController.h"
#import "ISCollectionViewCell.h"
#import "ISItemViewController.h"
#import "ISViewControllerChromeState.h"
#import "ISDBView.h"
#import "ISDBEntry.h"

@interface ISViewController ()

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) ISPhotoService *photoService;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) ISDBView *adapter;
@property (nonatomic) CGPoint lastContentScrollOffset;
@property (nonatomic) ISViewControllerChromeState chromeState;
@property (nonatomic) BOOL scrollViewIsDragging;

@end

@implementation ISViewController

static NSString *kCollectionViewCellReuseIdentifier = @"ThumbnailCell";
static NSString *kDetailSegueIdentifier = @"DetailSegue";
static NSString *kDownloadsSegueIdentifier = @"DownloadsSegue";

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.photoService = [ISPhotoService new];
  self.photoService.delegate = self;
  self.thumbnail = [UIImage imageNamed:@"Thumbnail.imageasset"];
  
  // Create an ISDBView.
  self.adapter = [[ISDBView alloc] initWithDataSource:self.photoService];
  [self.adapter addObserver:self];

}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
  if ([segue.identifier isEqualToString:kDetailSegueIdentifier]) {
    ISCollectionViewCell *cell = sender;
    ISItemViewController *viewController = segue.destinationViewController;
    viewController.photoService = self.photoService;
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

- (IBAction)refreshClicked:(id)sender
{
  [self.photoService update];
}


- (IBAction)clearClicked:(id)sender
{
  ISCache *defaultCache = [ISCache defaultCache];
  NSArray *items = [defaultCache items:
                    [ISCacheStateFilter filterWithStates:ISCacheItemStateAll]];
  [defaultCache removeItems:items];
  [self.photoService update];
}


- (IBAction)cancelClicked:(id)sender
{
  ISCache *defaultCache = [ISCache defaultCache];
  NSArray *items = [defaultCache items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  [defaultCache cancelItems:items];
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
  // Configure the cell.
  ISCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier
                                              forIndexPath:indexPath];
  cell.index = indexPath.row;
  // cell.imageView.image = self.thumbnail;
  
  ISDBEntry *item = [self.adapter entryForIndex:indexPath.item];
  [item fetch:^(NSDictionary *dict) {
    NSLog(@"Item: %@", dict);
    
    // TODO We need to use a weak reference for the cell?
    // How do we prevent reuse...
    // Is it necessary for this to be done on a different worker?
    // Surely it's perfectly safe to make this single threaded
    // as it only fetches an individual item not the whole batch.
    [cell.imageView setImageWithIdentifier:dict[@"url"]
                                   context:ISCacheImageContext
                          placeholderImage:self.thumbnail
                                  userInfo:@{@"width": @152.0,
                                             @"height": @152.0,
                                             @"scale": @(ISScalingCacheHandlerScaleAspectFill)}
                                     block:NULL];
    
    
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


#pragma mark - ISDownloadsViewControllerDelegate


- (void)downloadsViewControllerDidFinish:(ISDownloadsViewController *)downloadsViewController
{
  [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - ISPhotoServiceDelegate


- (void)photoServiceDidUpdate:(ISPhotoService *)photoService
{
  [self.collectionView reloadData];
}


#pragma mark - ISDBViewDelegate


- (void)beginUpdates:(ISDBView *)view
{
}


- (void)endUpdates:(ISDBView *)view
{
  [self.collectionView reloadData];
}


- (void)view:(ISDBView *)view
entryUpdated:(NSNumber *)index
{
}


- (void)view:(ISDBView *)view
  entryMoved:(NSArray *)indexes
{
  
}


- (void)view:(ISDBView *)view
entryInserted:(NSNumber *)index
{
}


- (void)view:(ISDBView *)view
entryDeleted:(NSNumber *)index
{
  
}


@end
