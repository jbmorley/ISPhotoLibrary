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

#import "ISDownloadsViewController.h"
#import "ISDownloadsCollectionViewCell.h"
#import <ISUtilities/ISDevice.h>

@interface ISDownloadsViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableDictionary *uids;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;
@property (nonatomic) BOOL isPortrait;
@property (nonatomic) CGSize minimumSize;
@property (nonatomic) CGFloat spacing;

@end

static NSString *kDownloadsViewCellReuseIdentifier = @"DownloadsCell";

@implementation ISDownloadsViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Fetch the items.
  [self update];
  
  self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self];
  self.adapter.debug = YES;
  self.connector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  [self.adapter addAdapterObserver:self.connector];
  
  self.minimumSize = CGSizeMake(283.0, 72.0);
  self.spacing = 2.0;
  
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.isPortrait = [ISDevice isPortrait];
  [[ISCache defaultCache] addCacheObserver:self];
  [self.adapter invalidate];
}


- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [[ISCache defaultCache] removeCacheObserver:self];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                               duration: (NSTimeInterval)duration
{
  self.isPortrait = UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
  [self.collectionView.collectionViewLayout invalidateLayout];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
}


- (IBAction)doneClicked:(id)sender
{
  [self.delegate downloadsViewControllerDidFinish:self];
}


- (void)update
{
  self.items = [[ISCache defaultCache] items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  self.uids = [NSMutableDictionary dictionaryWithCapacity:3];
  for (ISCacheItem *item in self.items) {
    [self.uids setObject:item
                  forKey:item.uid];
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
  ISDownloadsCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kDownloadsViewCellReuseIdentifier forIndexPath:indexPath];

  ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(ISCacheItem *item) {
    
    // Re-fetch the cell.
    ISDownloadsCollectionViewCell *cell = (ISDownloadsCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
      cell.cacheItem = item;
    }
    
  }];
  
  return cell;
}


#pragma mark - ISListViewAdapterDataSource


- (void)itemsForAdapter:(ISListViewAdapter *)adapter
        completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock(self.items);
}


- (id)adapter:(ISListViewAdapter *)adapter
identifierForItem:(id)item
{
  ISCacheItem *cacheItem = item;
  return cacheItem.uid;
}


- (id)adapter:(ISListViewAdapter *)adapter
summaryForItem:(id)item
{
  return @"";
}


- (void)adapter:(ISListViewAdapter *)adapter
itemForIdentifier:(id)identifier
completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock([self.uids objectForKey:identifier]);
}


#pragma mark - ISCacheObserver


- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item
{
}


- (void)cache:(ISCache *)cache
      newItem:(ISCacheItem *)item
{
  [self update];
  [self.adapter invalidate];
}


#pragma mark - UICollectionViewDelegateFlowLayout



- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
//  UIDeviceOrientation orientation =
//  [[UIDevice currentDevice] orientation];
//  if (UIDeviceOrientationIsPortrait(orientation)) {
//    return CGSizeMake(320.0, 72.0);
//  } else {
//    return CGSizeMake(283.0, 72.0);
//  }
  
  // Work out how many minimum size cells we can fit in.
  CGFloat screenWidth = [ISDevice screenSize:self.isPortrait].width;
  NSInteger max = floor((screenWidth + self.spacing) / (self.minimumSize.width + self.spacing));
  assert(max > 0);
  
  // Work out the how much is given over to spacing.
  CGFloat width = floor((screenWidth - (self.spacing * (max - 1))) / max);
  return CGSizeMake(width,
                    self.minimumSize.height);
  
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsZero;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return self.spacing;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return self.spacing;
}


@end
