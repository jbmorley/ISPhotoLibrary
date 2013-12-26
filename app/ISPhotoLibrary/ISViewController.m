//
//  ISViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 18/10/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "ISCache.h"
#import "ISCollectionViewCell.h"

@interface ISViewController ()

@property (strong, nonatomic) NSArray *items;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ISViewController

static NSString *kCollectionViewCellReuseIdentifier = @"ThumbnailCell";
static NSString *kServiceRoot = @"http://localhost:8051";

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // ; the items with an empty array.
  self.items = @[];
  
  // Fetch the library data.
  // Ultimately this fetch could be wired up using ISDB and an appropriate
  // adapter to manage all of the animations.
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager GET:kServiceRoot
    parameters:nil
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
         self.items = responseObject;
         [self.collectionView reloadData];
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
  
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


#pragma mark - UITableViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  // Determine the item URL.
  NSString *item = [kServiceRoot stringByAppendingFormat:@"/%@", self.items[indexPath.row][@"id"]];
  
  // Configure the cell.
  ISCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier
                                              forIndexPath:indexPath];
  cell.backgroundColor = [UIColor redColor];
  [cell.imageView setImageWithURL:item];
  
  return cell;
}


@end
