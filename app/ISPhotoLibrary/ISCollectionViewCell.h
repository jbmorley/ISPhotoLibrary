//
//  ISCollectionViewCell.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 26/12/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ISCache/ISCache.h>

@interface ISCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NSInteger index;

@end
