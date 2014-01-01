//
//  ISPhotoService.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 27/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISPhotoService;

@protocol ISPhotoServiceDelegate <NSObject>

- (void)photoServiceDidUpdate:(ISPhotoService *)photoService;

@end

@interface ISPhotoService : NSObject

@property (nonatomic, weak) id<ISPhotoServiceDelegate> delegate;

- (id)init;
- (void)update;

- (NSArray *)items;

- (NSString *)itemURL:(NSString *)identifier;
- (NSString *)itemName:(NSString *)identifier;

@end
