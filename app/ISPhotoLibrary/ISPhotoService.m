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

@end

static NSString *kServiceRoot = @"http://192.168.1.124:8051";

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
    
    // Load the items or initialize an empty dictionary.
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.path
                                             isDirectory:NO]) {
      self.itemDict = [NSMutableDictionary dictionaryWithContentsOfFile:self.path];
    }
    if (self.itemDict == nil) {
      self.itemDict = [NSMutableDictionary dictionaryWithCapacity:3];
    }

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
                          forKey:item[@"id"]];
         }
         
         // Cache the items.
         [self.itemDict writeToFile:self.path
                         atomically:YES];
         
         // Notify the delegate.
         [self.delegate photoServiceDidUpdate:self];
         
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Something went wrong: %@", error);
       }];
}


- (NSArray *)items
{
  return [[[self.itemDict keyEnumerator] allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
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
  return [self.itemDict objectForKey:identifier][@"name"];
}


@end
