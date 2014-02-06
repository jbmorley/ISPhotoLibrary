//
//  ISRotatingFlowLayout.m
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 06/02/2014.
//  Copyright (c) 2014 InSeven Limited. All rights reserved.
//

#import "ISRotatingFlowLayout.h"
#import "ISDevice.h"

@interface ISRotatingFlowLayout ()

@property (nonatomic) CGFloat spacing;
@property (nonatomic) CGRect currentBounds;

@end

@implementation ISRotatingFlowLayout

- (id)init
{
  self = [super init];
  if (self) {
    self.spacing = 5.0f;
    self.currentBounds = CGRectZero;
  }
  return self;
}


- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  if ((self.scrollDirection ==
       UICollectionViewScrollDirectionVertical &&
       self.currentBounds.size.width !=
       newBounds.size.width) ||
      (self.scrollDirection ==
       UICollectionViewScrollDirectionHorizontal &&
       self.currentBounds.size.height !=
       newBounds.size.height)) {
    self.currentBounds = newBounds;
    [self invalidateLayout];
    return YES;
  }
  return [super shouldInvalidateLayoutForBoundsChange:newBounds];
}


- (void)prepareLayout
{
  self.minimumLineSpacing = self.spacing;
  self.minimumInteritemSpacing = self.spacing;
  self.itemSize = [self calculateItemSize];
  self.sectionInset = [self calculateSectionInset];
  [super prepareLayout];
}


- (void)setSpacing:(CGFloat)spacing
{
  _spacing = spacing;
  [self invalidateLayout];
}


- (CGSize)calculateItemSize
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    return CGSizeMake(100, 100);
  } else {
    return CGSizeMake(180, 180);
  }
}


- (UIEdgeInsets)calculateSectionInset
{
  NSInteger count = floor((self.collectionView.frame.size.width + self.spacing) / (self.itemSize.width + self.spacing));
  NSInteger margin = floor((self.collectionView.frame.size.width - (self.itemSize.width * count) - (self.spacing * (count - 1))) / 2);
  return UIEdgeInsetsMake(self.spacing,
                          margin,
                          self.spacing,
                          margin);
}


@end
