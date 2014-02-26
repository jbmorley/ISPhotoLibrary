//
//  ISItemViewController.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 26/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ISCache/ISCache.h>

@interface ISItemViewController : UIViewController
<ISCacheItemObserver>

@property (nonatomic) NSUInteger index;

- (void)setCacheItem:(NSString *)identifier
             context:(NSString *)context
         preferences:(NSDictionary *)preferences;

@end
