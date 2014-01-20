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

@interface ISDownloadsViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSMutableDictionary *uids;
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *kDownloadsViewCellReuseIdentifier = @"DownloadsCell";

@implementation ISDownloadsViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Fetch the items.
  self.items = [[ISCache defaultCache] items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  
  self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self];
  self.connector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  [self.adapter addObserver:self.connector];
  
}


- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
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


- (IBAction)doneClicked:(id)sender
{
  [self.delegate downloadsViewControllerDidFinish:self];
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
  // Convert them into a structure that the adapter can understand.
  // TODO How is nil handled?
  NSMutableArray *descriptions =
  [NSMutableArray arrayWithCapacity:self.items.count];
  for (ISCacheItem *item in self.items) {
    [descriptions addObject:
     [ISListViewAdapterItemDescription descriptionWithIdentifier:item.uid summary:@"BOB"]];
  }
  completionBlock(descriptions);
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
  self.items = [[ISCache defaultCache] items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  self.uids = [NSMutableDictionary dictionaryWithCapacity:3];
  for (ISCacheItem *item in self.items) {
    [self.uids setObject:item
                  forKey:item.uid];
  }
  [self.adapter invalidate];
}



@end
