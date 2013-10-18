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

@interface ISViewController ()

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *items;

@end

@implementation ISViewController

static NSString *kTableViewCellReuseIdentifier = @"Cell";

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Add the table view.
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                style:UITableViewStylePlain];
  [self.tableView registerClass:[UITableViewCell class]
         forCellReuseIdentifier:kTableViewCellReuseIdentifier];
  self.tableView.dataSource = self;
  self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:self.tableView];
  
  // Initialize the items with an empty array.
  self.items = @[];
  
  // Fetch the library data.
  // Ultimately this fetch could be wired up using ISDB and an appropriate
  // adapter to manage all of the animations.
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager GET:@"http://projects.jbmorley.co.uk/photos/library.json"
    parameters:@{@"version": @"1"}
       success:^(AFHTTPRequestOperation *operation, id responseObject) {
         self.items = responseObject[@"photos"];
         [self.tableView reloadData];
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseIdentifier];
  cell.textLabel.text = self.items[indexPath.row][@"thumbnail"];
  
  // Fetch the thumbnail from the cache and display it when ready.
  
  return cell;
}




@end
