//
//  ISViewController.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 18/10/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <ISCache/ISCache.h>

#import "ISViewController.h"
#import "ISCollectionViewCell.h"
#import "ISItemViewController.h"
#import "ISPhotoService.h"

@interface ISViewController ()

@property (strong, nonatomic) NSArray *items;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ISViewController

static NSString *kCollectionViewCellReuseIdentifier = @"ThumbnailCell";
static NSString *kDetailSegueIdentifier = @"DetailSegue";

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self loadData];
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
    viewController.identifier = cell.identifier;
  }
}

#pragma mark - Utilities

- (void)loadData
{
  // Initialize the items with an empty array.
  self.items = @[];
  
  // Fetch the library data.
  // Ultimately this fetch could be wired up using ISDB and an appropriate
  // adapter to manage all of the animations.
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager GET:[ISPhotoService serviceURL]
    parameters:nil
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
         self.items = responseObject;
         [self.collectionView reloadData];
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
}

#pragma mark - Actions

- (IBAction)refreshClicked:(id)sender
{
  [self loadData];
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
  NSString *identifier = self.items[indexPath.row][@"id"];
  NSString *item = [ISPhotoService itemURL:                    identifier];
  
  // Configure the cell.
  ISCollectionViewCell *cell
  = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewCellReuseIdentifier
                                              forIndexPath:indexPath];
  cell.identifier = identifier;
  cell.imageView.alpha = 0.0f;
  [cell.activityIndicatorView startAnimating];
  [cell.imageView setImageWithURL:item
                         userInfo:@{@"width": @152.0,
                                    @"height": @152.0,
                                    @"scale": @(ISScalingCacheHandlerScaleAspectFill)}
                  completionBlock:^{
                    [cell.activityIndicatorView stopAnimating];
                    cell.imageView.alpha = 1.0f;
                  }];
  
  return cell;
}


#pragma mark - UICollectionViewDelegate

@end
