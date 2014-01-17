//
//  ISDownloadsCollectionViewCell.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 16/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISDownloadsCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *label;

@end
