//
//  ISViewController.h
//  ISPhotoLibrary
//
//  Created by Jason Barrie Morley on 18/10/2013.
//  Copyright (c) 2013 InSeven Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISDownloadsViewController.h"
#import "ISPhotoService.h"

@interface ISViewController : UIViewController
<UICollectionViewDataSource
,UICollectionViewDelegate
,ISDownloadsViewControllerDelegate
,ISPhotoServiceDelegate>

@end
