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

#import "ISPhotoService.h"
#import <AFNetworking/AFNetworking.h>

@interface ISPhotoService ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *itemDict;
@property (nonatomic, strong) NSMutableArray *sortedKeys;
@property (nonatomic, weak) ISListViewAdapter *adapter;

@end

const NSString *ISPhotoServiceKeyIdentifier = @"id";
const NSString *ISPhotoServiceKeyURL = @"url";
const NSString *ISPhotoServiceKeyName = @"name";

//static NSString *kServiceRoot = @"http://127.0.0.1:8051";
static NSString *kServiceRoot = @"http://photos.jbmorley.co.uk";

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
                          forKey:item[ISPhotoServiceKeyIdentifier]];
         }
         
         // Cache the items.
         [self.itemDict writeToFile:self.path
                         atomically:YES];
         
         // Sort the keys.
         [self sortKeys];
         
         // Notify the delegate.
         [self.adapter invalidate];
         
//         [self startReversing];
         
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
}


- (void)startReversing
{
  double delayInSeconds = 10.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    self.sortedKeys = [[[self.sortedKeys reverseObjectEnumerator] allObjects] mutableCopy];
    [self.adapter invalidate];
    [self startReversing];
  });
}


- (void)sortKeys
{
  // Clear the sorted keys array.
  self.sortedKeys = [NSMutableArray arrayWithCapacity:self.itemDict.count];
  
  // Generate a sorted list of items.
  NSArray *sortedItems = [[self.itemDict allValues] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
    return [obj1[ISPhotoServiceKeyName] localizedCaseInsensitiveCompare:obj2[ISPhotoServiceKeyName]];
  }];

  // Extract the keys.
  for (NSDictionary *item in sortedItems) {
    [self.sortedKeys addObject:item[ISPhotoServiceKeyIdentifier]];
  }
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
  completionBlock(@{@"url":[kServiceRoot
                            stringByAppendingFormat:
                            @"/%@",
                            identifier],
                    @"name":[self.itemDict objectForKey:identifier][ISPhotoServiceKeyName]});
}


@end
