//
//  ISPhotoService.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 27/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISPhotoService.h"
#import <AFNetworking/AFNetworking.h>

@interface ISPhotoService ()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *itemDict;
@property (nonatomic, strong) NSMutableArray *sortedKeys;

@end

static NSString *kServiceRoot = @"http://169.254.45.248:8051";
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
  // TODO Ultimately this fetch could be wired up using ISDB and
  // an appropriate adapter to manage all of the animations.
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
         [self sortedKeys];
         
         // Notify the delegate.
         [self.delegate photoServiceDidUpdate:self];
         
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
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


- (NSArray *)items
{
  return self.sortedKeys;
}


- (NSString *)itemURL:(NSString *)identifier
{
  return [kServiceRoot
          stringByAppendingFormat:
          @"/%@",
          identifier];
}


- (NSString *)itemName:(NSString *)identifier
{
  return [self.itemDict objectForKey:identifier][kKeyName];
}


@end
