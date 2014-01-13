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

#import "ISPhotoService.h"
#import <AFNetworking/AFNetworking.h>

@interface ISPhotoService ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *itemDict;
@property (nonatomic, strong) NSMutableArray *sortedKeys;
@property (nonatomic, weak) ISListViewAdapter *adapter;

@end

static NSString *kServiceRoot = @"http://photos.jbmorley.co.uk";
static NSString *kKeyIdentifier = @"id";
static NSString *kKeyName = @"name";

@implementation ISPhotoService


- (id)init
{
  self = [super init];
  if (self) {
    
    // Determine the path for caching the items.
    NSString *documentsPath
    = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                           NSUserDomainMask,
                                           YES) objectAtIndex:0];
    self.path = [documentsPath stringByAppendingPathComponent:@"ISPhotoService.plist"];
    
    // Load the items or initialise an empty dictionary.
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path
                                             isDirectory:NO]) {
      self.itemDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.path];
    }
    if (self.itemDict == nil) {
      self.itemDict = [NSMutableDictionary dictionaryWithCapacity:3];
    }
    
    // TODO Remove this.
    // It is necessary, for the initial work, to have no entries
    // when the view is created.
    self.itemDict = [NSMutableDictionary dictionaryWithCapacity:3];
    
    // Generate the sorted keys.
    [self sortKeys];

    // Update the service.
    [self update];

  }
  return self;
}


- (void)update
{
  // Fetch the library data.
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  [manager GET:kServiceRoot
    parameters:nil
       success:^(AFHTTPRequestOperation *operation,
                 id responseObject) {
         
         // Initialize the items with an empty array.
         self.itemDict = [NSMutableDictionary dictionaryWithCapacity:3];
         
         // Read in the new values.
         for (NSDictionary *item in responseObject) {
           [self.itemDict setObject:item
                          forKey:item[kKeyIdentifier]];
         }
         
         // Cache the items.
         [self.itemDict writeToFile:self.path
                         atomically:YES];
         
         // Sort the keys.
         [self sortKeys];
         
         // Notify the delegate.
         [self.adapter invalidate];
         
         [self startReversing];
         
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
}


- (void)startReversing
{
  double delayInSeconds = 10.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

    NSLog(@"Reverse!");
    self.sortedKeys = [[[self.sortedKeys reverseObjectEnumerator] allObjects] mutableCopy];
    [self.adapter invalidate];
    
  });
}


- (void)sortKeys
{
  // Clear the sorted keys array.
  self.sortedKeys = [NSMutableArray arrayWithCapacity:self.itemDict.count];
  
  // Generate a sorted list of items.
  NSArray *sortedItems = [[self.itemDict allValues] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
    return [obj1[kKeyName] localizedCaseInsensitiveCompare:obj2[kKeyName]];
  }];

  // Extract the keys.
  for (NSDictionary *item in sortedItems) {
    [self.sortedKeys addObject:item[kKeyIdentifier]];
  }
}


- (NSUInteger)count
{
  return self.sortedKeys.count;
}


- (NSString *)itemAtIndex:(NSUInteger)index
{
  return self.sortedKeys[index];
}


- (NSString *)itemURL:(NSUInteger)index
{
  return [kServiceRoot
          stringByAppendingFormat:
          @"/%@",
          [self itemAtIndex:index]];
}


- (NSString *)itemName:(NSUInteger)index
{
  return [self.itemDict objectForKey:[self itemAtIndex:index]][kKeyName];
}


#pragma mark - ISDBDataSource


- (void)initialize:(ISListViewAdapter *)adapter
{
  self.adapter = adapter;
}


- (void)adapter:(ISListViewAdapter *)adapter
entriesForOffset:(NSUInteger)offset
          limit:(NSInteger)limit
complectionBlock:(ISListViewAdapterBlock)completionBlock
{
  NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.sortedKeys.count];
  for (NSString *identifier in self.sortedKeys) {
    ISListViewAdapterItemDescription *description =
    [ISListViewAdapterItemDescription descriptionWithIdentifier:identifier
                                            summary:@""];
    [items addObject:description];
  }
  completionBlock(items);
}


- (void)adapter:(ISListViewAdapter *)adapter
entryForIdentifier:(id)identifier
   completionBlock:(ISListViewAdapterBlock)completionBlock
{
  completionBlock(@{@"url": [kServiceRoot
                             stringByAppendingFormat:
                             @"/%@",
                             identifier],
                    @"name": [self.itemDict objectForKey:identifier][kKeyName]});
}


@end
