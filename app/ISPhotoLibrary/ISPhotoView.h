//
//  ISPhotoView.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 08/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISPhotoView : UIView

@property (strong, nonatomic) NSString *url;

+ (id)photoView;
- (void)cancel;

@end
