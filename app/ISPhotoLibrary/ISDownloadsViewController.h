//
//  ISDownloadsViewController.h
//  
//
//  Created by Jason Barrie Morley on 29/12/2013.
//
//

#import <UIKit/UIKit.h>

@class ISDownloadsViewController;

@protocol ISDownloadsViewControllerDelegate <NSObject>

- (void)downloadsViewControllerDidFinish:(ISDownloadsViewController *)downloadsViewController;

@end

@interface ISDownloadsViewController : UIViewController

@property (nonatomic, weak) IBOutlet id<ISDownloadsViewControllerDelegate> delegate;

@end
