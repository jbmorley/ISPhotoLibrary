//
//  ISItemViewController.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 12/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ISCache/ISCache.h>
#import "ISPhotoService.h"

@interface ISItemViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) ISPhotoService *photoService;
@property (nonatomic) NSInteger index;

@end
