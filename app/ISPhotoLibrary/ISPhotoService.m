//
//  ISPhotoService.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 27/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import "ISPhotoService.h"

static NSString *kServiceRoot = @"http://localhost:8051";

@implementation ISPhotoService

+ (NSString *)serviceURL
{
  return kServiceRoot;
}

+ (NSString *)itemURL:(NSString *)identifier
{
  return [kServiceRoot
          stringByAppendingFormat:
          @"/%@",
          identifier];
}

@end
