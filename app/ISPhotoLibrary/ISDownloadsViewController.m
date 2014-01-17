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
@property (nonatomic, strong) ISListViewAdapter *adapter;
@property (nonatomic, strong) ISListViewAdapterConnector *connector;

@end

static NSString *kDownloadsViewCellReuseIdentifier = @"DownloadsCell";

@implementation ISDownloadsViewController


- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Fetch the items.
  // TODO This needs to be moved elsewhere.
  self.items = [[ISCache defaultCache] items:[ISCacheStateFilter filterWithStates:ISCacheItemStateInProgress]];
  
  self.adapter = [[ISListViewAdapter alloc] initWithDataSource:self];
  self.connector = [ISListViewAdapterConnector connectorWithCollectionView:self.collectionView];
  [self.adapter addObserver:self.connector];
  
  [[ISCache defaultCache] addObserver:self];
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
  // Configure the cell.
  ISDownloadsCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kDownloadsViewCellReuseIdentifier
                                              forIndexPath:indexPath];
//  cell.index = indexPath.row;
//  cell.imageView.image = self.thumbnail;
  
  ISListViewAdapterItem *item = [self.adapter itemForIndex:indexPath.item];
  [item fetch:^(ISCacheItem *item) {
    
    cell.label.text = item.identifier;
    cell.progressView.progress = item.progress;

    // TODO We need to use a weak reference for the cell?
    // How do we prevent reuse...
  }];
  
  return cell;

}


#pragma mark - ISListViewAdapterDataSource


- (void)adapter:(ISListViewAdapter *)adapter
  numberOfItems:(ISListViewAdapterCountBlock)completionBlock
{
  completionBlock(self.items.count);
}

- (void)itemsForAdapter:(ISListViewAdapter *)adapter
        completionBlock:(ISListViewAdapterBlock)completionBlock
{
  // Convert them into a structure that the adapter can understand.
  NSMutableArray *descriptions =
  [NSMutableArray arrayWithCapacity:self.items.count];
  for (ISCacheItem *item in self.items) {
    [descriptions addObject:[ISListViewAdapterItemDescription descriptionWithIdentifier:item.identifier
                                                                                summary:nil]];
  }
  completionBlock(descriptions);
}

- (void)adapter:(ISListViewAdapter *)adapter
itemForIdentifier:(id)identifier
completionBlock:(ISListViewAdapterBlock)completionBlock
{
  // TODO Perform a lookup on the item.
  completionBlock(self.items[0]);
}


#pragma mark - ISCacheObserver

- (void)cache:(ISCache *)cache
itemDidUpdate:(ISCacheItem *)item
{
  [self.adapter invalidate];
}



@end
