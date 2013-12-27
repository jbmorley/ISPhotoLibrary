//
//  ISPhotoService.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 27/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISPhotoService : NSObject

+ (NSString *)serviceURL;
+ (NSString *)itemURL:(NSString *)identifier;

@end
