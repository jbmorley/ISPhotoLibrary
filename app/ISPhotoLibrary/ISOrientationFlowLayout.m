//
//  ISOrientationFlowLayout.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 22/01/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISOrientationFlowLayout.h"

@implementation ISOrientationFlowLayout

- (void)prepareLayout
{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

  if (UIDeviceOrientationIsPortrait(orientation)) {
    self.itemSize = CGSizeMake(100, 100);
    self.minimumInteritemSpacing = 5;
    self.minimumLineSpacing = 5;
    self.sectionInset = UIEdgeInsetsMake(5.0,
                                         5.0,
                                         5.0,
                                         5.0);
  } else if (UIDeviceOrientationIsLandscape(orientation)) {
    self.itemSize = CGSizeMake(100, 100);
    self.minimumInteritemSpacing = 5;
    self.minimumLineSpacing = 5;
    self.sectionInset = UIEdgeInsetsMake(5.0,
                                         20.0,
                                         5.0,
                                         20.0);

  }
  self.scrollDirection = UICollectionViewScrollDirectionVertical;
}

@end
